import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_location.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

/// Implementação específica para iOS do serviço de background
/// 
/// IMPORTANTE: iOS tem limitações severas para background tasks contínuos.
/// Esta implementação usa uma abordagem híbrida:
/// 1. Significant Location Changes para mudanças importantes de localização
/// 2. Background App Refresh para atualizações periódicas (limitado pelo sistema)
/// 3. Região monitoring como fallback
/// 
/// O iOS pode suspender ou terminar o app a qualquer momento.
/// Esta implementação é mais eficiente em termos de bateria mas menos confiável
/// que a implementação Android.
class BackgroundLocationServiceIOS {
  static const String _isRunningKey = 'background_service_running_ios';
  static const String _intervalKey = 'background_service_interval_ios';
  static const String _lastLocationKey = 'last_location_ios';
  static const String _cpfKey = 'driver_cpf_ios';
  
  static StreamSubscription<Position>? _positionStream;
  static Timer? _periodicTimer;
  static bool _isRunning = false;
  
  // Contadores para estatísticas
  static int _successCount = 0;
  static int _errorCount = 0;
  static DateTime? _lastSentTime;

  /// Inicia o serviço de background para iOS
  static Future<void> startService() async {
    if (_isRunning) return;
    
    try {
      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        log('Permissão de localização negada para iOS background service', name: 'BackgroundServiceIOS');
        return;
      }

      _isRunning = true;
      await _saveServiceState(true);

      // Notificações removidas para compatibilidade com Windows

      // Inicia significant location changes (mais eficiente para iOS)
      await _startSignificantLocationChanges();
      
      // Inicia timer periódico como backup (limitado pelo iOS)
      await _startPeriodicUpdates();
      
      // Notificação inicial removida para compatibilidade
      log('Rastreamento iniciado - Localização será enviada periodicamente', name: 'BackgroundServiceIOS');
      
      log('Serviço de background iOS iniciado', name: 'BackgroundServiceIOS');
    } catch (e) {
      log('Erro ao iniciar serviço iOS: $e', name: 'BackgroundServiceIOS');
      _isRunning = false;
      await _saveServiceState(false);
    }
  }
  
  /// Para o serviço de background
  static Future<void> stopService() async {
    if (!_isRunning) return;
    
    try {
      _isRunning = false;
      await _saveServiceState(false);
      
      // Para o stream de localização
      await _positionStream?.cancel();
      _positionStream = null;
      
      // Para o timer periódico
      _periodicTimer?.cancel();
      _periodicTimer = null;
      
      // Notificação de parada removida para compatibilidade
      log('Rastreamento parado - Serviço de localização desativado', name: 'BackgroundServiceIOS');
      
      log('Serviço de background iOS parado', name: 'BackgroundServiceIOS');
    } catch (e) {
      log('Erro ao parar serviço iOS: $e', name: 'BackgroundServiceIOS');
    }
  }
  
  /// Verifica se o serviço está rodando
  static Future<bool> isServiceRunning() async {
    return _isRunning;
  }
  
  /// Atualiza o intervalo do serviço
  static Future<void> updateInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalKey, seconds);
    
    // Reinicia o timer se estiver rodando
    if (_isRunning) {
      _periodicTimer?.cancel();
      await _startPeriodicUpdates();
    }
  }
  
  /// Obtém o intervalo atual
  static Future<int> getCurrentInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_intervalKey) ?? AppConfig.defaultBackgroundInterval;
  }
  
  /// Inicia significant location changes
  static Future<void> _startSignificantLocationChanges() async {
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.medium, // Menos preciso mas mais eficiente
          distanceFilter: 100, // Mínimo 100 metros para considerar mudança significativa
        ),
      ).listen(
        (position) async {
          log('Significant location change detectada', name: 'BackgroundServiceIOS');
          await _sendLocationData(position);
        },
        onError: (error) {
          log('Erro no stream de localização iOS: $error', name: 'BackgroundServiceIOS');
        },
      );
    } catch (e) {
      log('Erro ao iniciar significant location changes: $e', name: 'BackgroundServiceIOS');
    }
  }
  
  /// Inicia atualizações periódicas como backup
  static Future<void> _startPeriodicUpdates() async {
    final intervalSeconds = await getCurrentInterval();
    
    // Timer com intervalo maior para iOS (iOS é mais restritivo)
    final iosInterval = Duration(seconds: intervalSeconds * 2); // Dobra o intervalo para iOS
    
    _periodicTimer = Timer.periodic(iosInterval, (timer) async {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: AppleSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15), // Timeout maior para iOS
          ),
        );
        await _sendLocationData(position);
      } catch (e) {
        log('Erro no timer periódico iOS: $e', name: 'BackgroundServiceIOS');
      }
    });
  }
  
  /// Envia dados de localização
  static Future<void> _sendLocationData(Position position) async {
    try {
      // Verifica se há viagem ativa (obrigatório)
      final hasActiveTripStatus = await hasActiveTrip();
      if (!hasActiveTripStatus) {
        log('Sem viagem ativa, parando rastreamento iOS', name: 'BackgroundServiceIOS');
        await stopService();
        return;
      }
      
      // Verifica se a localização mudou significativamente
      final lastLocation = await _getLastLocation();
      if (lastLocation != null) {
        final distance = Geolocator.distanceBetween(
          lastLocation.latitude,
          lastLocation.longitude,
          position.latitude,
          position.longitude,
        );
        
        // Só envia se mudou pelo menos 50 metros
        if (distance < 50) {
          log('Localização não mudou significativamente, ignorando envio', name: 'BackgroundServiceIOS');
          return;
        }
      }

      // Obtém CPF salvo
      final prefs = await SharedPreferences.getInstance();
      final cpf = prefs.getString(_cpfKey) ?? '';
      
      if (cpf.isEmpty) {
        log('CPF não configurado, pulando envio', name: 'BackgroundServiceIOS');
        return;
      }

      // Cria o objeto de localização
      final location = DriverLocation(
        cpf: cpf,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        batteryLevel: null,
      );

      log('Enviando dados de localização iOS: ${location.toCreateJson()}', name: 'BackgroundServiceIOS');

      // Envia para a API
      final result = await ApiService.sendDriverLocation(location);

      if (result['success']) {
        _successCount++;
        _lastSentTime = DateTime.now();
        log('Localização enviada com sucesso (iOS). Resposta: ${result['data']}', name: 'BackgroundServiceIOS');
        await _saveLastLocation(position);

        // Log de sucesso (apenas a cada 5 envios para não spammar)
        if (_successCount % 5 == 0) {
             log(
               'Rastreamento ativo - $_successCount localizações enviadas • Último: ${_formatTime(_lastSentTime!)}',
               name: 'BackgroundServiceIOS'
             );
        }
      } else {
        _errorCount++;
        log('❌ ERRO CRÍTICO: Falha ao enviar localização para API (iOS)', name: 'BackgroundServiceIOS');
        log('❌ Erro ao enviar localização ($_errorCount erros total)', name: 'BackgroundServiceIOS');
        log('❌ Detalhes do erro: ${result['error']}', name: 'BackgroundServiceIOS');
        log('❌ Verifique conexão com internet e configurações da API', name: 'BackgroundServiceIOS');
        
        // Se muitos erros consecutivos, para o serviço
        if (_errorCount >= 5) {
          log('🛑 Muitos erros consecutivos, parando serviço de background iOS', name: 'BackgroundServiceIOS');
          await stopService();
        }
        
        // Log de erro
        log(
          'Erro no rastreamento - Falha ao enviar localização • $_errorCount erros',
          name: 'BackgroundServiceIOS'
        );
      }
    } catch (e, stackTrace) {
      log('Erro crítico ao enviar localização iOS', name: 'BackgroundServiceIOS', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Salva o estado do serviço
  static Future<void> _saveServiceState(bool isRunning) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRunningKey, isRunning);
  }
  
  /// Salva a última localização enviada
  static Future<void> _saveLastLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, '${position.latitude},${position.longitude}');
  }
  
  /// Obtém a última localização enviada
  static Future<Position?> _getLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationString = prefs.getString(_lastLocationKey);
      
      if (locationString != null) {
        final parts = locationString.split(',');
        if (parts.length == 2) {
          return Position(
            latitude: double.parse(parts[0]),
            longitude: double.parse(parts[1]),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
    } catch (e) {
      log('Erro ao obter última localização: $e', name: 'BackgroundServiceIOS');
    }
    return null;
  }
  
  /// Verifica se o serviço estava rodando antes
  static Future<bool> wasServiceRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRunningKey) ?? false;
  }
  
  /// Limpa dados salvos
  static Future<void> clearSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isRunningKey);
    await prefs.remove(_intervalKey);
    await prefs.remove(_lastLocationKey);
    await prefs.remove(_cpfKey);
  }
  
  /// Salva o CPF do motorista
  static Future<void> saveCpf(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cpfKey, cpf);
  }
  
  /// Obtém o CPF salvo
  static Future<String> getSavedCpf() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cpfKey) ?? '';
  }
  
  /// Salva o status da viagem ativa
  static Future<void> setActiveTripStatus(bool hasActiveTrip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_trip_ios', hasActiveTrip);
  }
  
  /// Verifica se há viagem ativa
  static Future<bool> hasActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_active_trip_ios') ?? false;
  }
  
  /// Salva dados da viagem ativa
  static Future<void> saveActiveTripData(Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_trip_data_ios', json.encode(tripData));
  }
  
  /// Restaura dados da viagem ativa
  static Future<Map<String, dynamic>?> restoreActiveTripData() async {
    final prefs = await SharedPreferences.getInstance();
    final tripDataJson = prefs.getString('active_trip_data_ios');
    if (tripDataJson != null) {
      try {
        return json.decode(tripDataJson);
      } catch (e) {
        log('Erro ao decodificar dados da viagem iOS: $e', name: 'BackgroundServiceIOS');
        return null;
      }
    }
    return null;
  }
  
  /// Limpa dados da viagem ativa
  static Future<void> clearActiveTripData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_trip_data_ios');
  }
  
  /// Notificações removidas para compatibilidade com Windows
  
  /// Função auxiliar para formatar tempo
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
