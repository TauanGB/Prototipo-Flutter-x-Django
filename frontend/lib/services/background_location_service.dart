import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_location.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class BackgroundLocationService {
  static const String _isRunningKey = 'background_service_running';
  static const String _intervalKey = 'background_service_interval';
  
  static const int _defaultIntervalSeconds = 30;

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
    return prefs.getInt(_intervalKey) ?? _defaultIntervalSeconds;
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
}

/// Ponto de entrada do serviço de background para Android
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // Lida com eventos do serviço (parar, etc.)
  service.on('stop').listen((event) {
    service.stopSelf();
  });

  // Função para enviar localização
  Future<void> sendLocationData() async {
    try {
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

      // Obtém a localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Cria o objeto de localização
      final location = DriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        status: 'online',
        batteryLevel: null,
        isGpsEnabled: true,
        deviceId: 'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
        appVersion: AppConfig.appVersion,
      );

      log('Enviando dados de localização: ${location.toCreateJson()}', name: 'BackgroundService');

      // Envia para a API
      final result = await ApiService.sendDriverLocation(location);
      
      if (result != null) {
        log('Localização enviada com sucesso. Resposta do servidor: ${result.toJson()}', name: 'BackgroundService');
      } else {
        log('Erro ao enviar localização. A API retornou nulo.', name: 'BackgroundService');
      }
    } catch (e, stackTrace) {
      log('Erro crítico ao obter/enviar localização', name: 'BackgroundService', error: e, stackTrace: stackTrace);
    }
  }
  
  // Envia a primeira localização imediatamente
  await sendLocationData();
  
  // Configura o timer para envios periódicos
  int intervalSeconds = await BackgroundLocationService.getCurrentInterval();
  Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
    // Listener para parar o serviço, também para o timer
    service.on('stop').listen((event) {
      timer.cancel();
      service.stopSelf();
    });

    await sendLocationData();
  });
}

/// Handler para iOS background
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
