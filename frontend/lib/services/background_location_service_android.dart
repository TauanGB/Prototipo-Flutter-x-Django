import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_location.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class BackgroundLocationServiceAndroid {
  static const String _isRunningKey = 'background_service_running';
  static const String _intervalKey = 'background_service_interval';
  static const String _cpfKey = 'driver_cpf';

  /// Inicia o serviço de background
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (!isRunning) {
      service.startService();
      await _saveServiceState(true);
    }
  }
  
  /// Para o serviço de background
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (isRunning) {
      service.invoke('stop');
      await _saveServiceState(false);
    }
  }
  
  /// Verifica se o serviço está rodando
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }
  
  /// Atualiza o intervalo do serviço
  static Future<void> updateInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalKey, seconds);
    
    // Se o serviço estiver rodando, reinicia com novo intervalo
    if (await isServiceRunning()) {
      await stopService();
      await Future.delayed(const Duration(seconds: 1));
      await startService();
    }
  }
  
  /// Obtém o intervalo atual
  static Future<int> getCurrentInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_intervalKey) ?? AppConfig.defaultBackgroundInterval;
  }
  
  /// Salva o estado do serviço
  static Future<void> _saveServiceState(bool isRunning) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRunningKey, isRunning);
  }
  
  /// Verifica se o serviço estava rodando antes
  static Future<bool> wasServiceRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRunningKey) ?? false;
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
    await prefs.setBool('has_active_trip', hasActiveTrip);
  }
  
  /// Verifica se há viagem ativa
  static Future<bool> hasActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_active_trip') ?? false;
  }
}

/// Ponto de entrada do serviço de background para Android
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // Lida com eventos do serviço (parar, etc.)
  service.on('stop').listen((event) {
    service.stopSelf();
  });
  

  // Contadores para estatísticas
  int successCount = 0;
  int errorCount = 0;

  // Função para enviar localização
  Future<void> sendLocationData() async {
    try {
      // Verifica se há viagem ativa (obrigatório)
      final prefs = await SharedPreferences.getInstance();
      final hasActiveTrip = prefs.getBool('has_active_trip') ?? false;
      
      if (!hasActiveTrip) {
        log('Sem viagem ativa, parando rastreamento', name: 'BackgroundService');
        await BackgroundLocationServiceAndroid.stopService();
        return;
      }

      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Serviço de localização desabilitado', name: 'BackgroundService');
        return;
      }

      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        log('Permissão de localização negada', name: 'BackgroundService');
        return;
      }

      // Obtém a localização atual com configurações específicas de plataforma
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );

      // Obtém CPF salvo
      final cpf = prefs.getString('driver_cpf') ?? '';
      
      if (cpf.isEmpty) {
        log('CPF não configurado, pulando envio', name: 'BackgroundService');
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

      log('Enviando dados de localização: ${location.toCreateJson()}', name: 'BackgroundService');

      // Envia para a API
      final result = await ApiService.sendDriverLocation(location);
      
      if (result != null) {
        successCount++;
        log('Localização enviada com sucesso. Resposta do servidor: ${result.toJson()}', name: 'BackgroundService');
        
        // Log do sucesso (notificação será atualizada via logs)
        log('✅ Localização enviada com sucesso ($successCount total)', name: 'BackgroundService');
      } else {
        errorCount++;
        log('Erro ao enviar localização. A API retornou nulo.', name: 'BackgroundService');
        
        // Log do erro
        log('❌ Erro ao enviar localização ($errorCount erros total)', name: 'BackgroundService');
      }
    } catch (e, stackTrace) {
      errorCount++;
      log('Erro crítico ao obter/enviar localização', name: 'BackgroundService', error: e, stackTrace: stackTrace);
      
      // Log do erro crítico
      log('💥 Erro crítico ao enviar localização ($errorCount erros total)', name: 'BackgroundService');
    }
  }
  
  // Envia a primeira localização imediatamente
  await sendLocationData();
  
  // Configura o timer para envios periódicos
  int intervalSeconds = await BackgroundLocationServiceAndroid.getCurrentInterval();
  Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
    // Listener para parar o serviço, também para o timer
    service.on('stop').listen((event) {
      timer.cancel();
      service.stopSelf();
    });

    await sendLocationData();
  });
}
