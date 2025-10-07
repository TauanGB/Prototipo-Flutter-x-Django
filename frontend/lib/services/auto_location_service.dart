import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/driver_location.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../config/app_config.dart';

class AutoLocationService extends ChangeNotifier {
  static final AutoLocationService _instance = AutoLocationService._internal();
  factory AutoLocationService() => _instance;
  AutoLocationService._internal();

  Timer? _timer;
  bool _isRunning = false;
  int _intervalSeconds = 30; // Intervalo padrão de 30 segundos
  String _status = 'online';
  double? _batteryLevel;
  String? _deviceId;
  int _successCount = 0;
  int _errorCount = 0;
  DateTime? _lastSentTime;
  String? _lastError;

  // Getters
  bool get isRunning => _isRunning;
  int get intervalSeconds => _intervalSeconds;
  String get status => _status;
  double? get batteryLevel => _batteryLevel;
  String? get deviceId => _deviceId;
  int get successCount => _successCount;
  int get errorCount => _errorCount;
  DateTime? get lastSentTime => _lastSentTime;
  String? get lastError => _lastError;

  /// Inicia o serviço automático de envio de localização
  Future<void> start() async {
    if (_isRunning) return;

    // Verifica permissões de localização
    bool hasPermission = await LocationService.hasPermission();
    if (!hasPermission) {
      await LocationService.requestPermission();
      // Verifica novamente após solicitar permissão
      hasPermission = await LocationService.hasPermission();
      if (!hasPermission) {
        _lastError = 'Permissão de localização negada';
        notifyListeners();
        return;
      }
    }

    _isRunning = true;
    _deviceId ??= 'flutter_app_${DateTime.now().millisecondsSinceEpoch}';
    
    // Envia a primeira localização imediatamente
    await _sendLocation();
    
    // Inicia o timer para envios periódicos
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (timer) {
      _sendLocation();
    });

    notifyListeners();
  }

  /// Para o serviço automático de envio de localização
  void stop() {
    if (!_isRunning) return;

    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }


  /// Atualiza o status do motorista sem notificar listeners (para evitar loops)
  void updateStatusSilent(String status) {
    _status = status;
  }

  /// Atualiza o nível da bateria sem notificar listeners (para evitar loops)
  void updateBatteryLevelSilent(double? batteryLevel) {
    _batteryLevel = batteryLevel;
  }

  /// Envia a localização atual
  Future<void> _sendLocation() async {
    try {
      // Obtém a localização atual
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _errorCount++;
        _lastError = 'Não foi possível obter a localização';
        notifyListeners();
        return;
      }

      // Cria o objeto de localização
      final location = DriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        status: _status,
        batteryLevel: _batteryLevel?.round(),
        isGpsEnabled: true,
        deviceId: _deviceId!,
        appVersion: AppConfig.appVersion,
      );

      // Envia para a API
      final result = await ApiService.sendDriverLocation(location);
      
      if (result != null) {
        _successCount++;
        _lastSentTime = DateTime.now();
        _lastError = null;
      } else {
        _errorCount++;
        _lastError = 'Erro ao enviar localização para a API';
      }
    } catch (e) {
      _errorCount++;
      _lastError = 'Erro: $e';
    }
    
    notifyListeners();
  }


  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
