import 'dart:io';
import 'background_location_service_android.dart' as android;
import 'background_location_service_ios.dart' as ios;

// Re-export das funções necessárias do Android para manter compatibilidade
export 'background_location_service_android.dart' show onStart;

/// Factory/Interface para o serviço de background de localização
/// Escolhe automaticamente a implementação correta baseada na plataforma
class BackgroundLocationService {
  
  /// Inicia o serviço de background
  static Future<void> startService() async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.startService();
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.startService();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Para o serviço de background
  static Future<void> stopService() async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.stopService();
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.stopService();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Verifica se o serviço está rodando
  static Future<bool> isServiceRunning() async {
    if (Platform.isAndroid) {
      return await android.BackgroundLocationServiceAndroid.isServiceRunning();
    } else if (Platform.isIOS) {
      return await ios.BackgroundLocationServiceIOS.isServiceRunning();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Atualiza o intervalo do serviço
  static Future<void> updateInterval(int seconds) async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.updateInterval(seconds);
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.updateInterval(seconds);
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Obtém o intervalo atual
  static Future<int> getCurrentInterval() async {
    if (Platform.isAndroid) {
      return await android.BackgroundLocationServiceAndroid.getCurrentInterval();
    } else if (Platform.isIOS) {
      return await ios.BackgroundLocationServiceIOS.getCurrentInterval();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Verifica se o serviço estava rodando antes
  static Future<bool> wasServiceRunning() async {
    if (Platform.isAndroid) {
      return await android.BackgroundLocationServiceAndroid.wasServiceRunning();
    } else if (Platform.isIOS) {
      return await ios.BackgroundLocationServiceIOS.wasServiceRunning();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Retorna informações sobre a implementação atual
  static String getImplementationInfo() {
    if (Platform.isAndroid) {
      return 'Android Foreground Service - Funciona com app fechado';
    } else if (Platform.isIOS) {
      return 'iOS Background Tasks - Limitado pelo sistema';
    } else {
      return 'Plataforma não suportada';
    }
  }
  
  /// Salva o CPF do motorista
  static Future<void> saveCpf(String cpf) async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.saveCpf(cpf);
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.saveCpf(cpf);
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Obtém o CPF salvo
  static Future<String> getSavedCpf() async {
    if (Platform.isAndroid) {
      return await android.BackgroundLocationServiceAndroid.getSavedCpf();
    } else if (Platform.isIOS) {
      return await ios.BackgroundLocationServiceIOS.getSavedCpf();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Salva o status da viagem ativa
  static Future<void> setActiveTripStatus(bool hasActiveTrip) async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.setActiveTripStatus(hasActiveTrip);
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.setActiveTripStatus(hasActiveTrip);
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Verifica se há viagem ativa
  static Future<bool> hasActiveTrip() async {
    if (Platform.isAndroid) {
      return await android.BackgroundLocationServiceAndroid.hasActiveTrip();
    } else if (Platform.isIOS) {
      return await ios.BackgroundLocationServiceIOS.hasActiveTrip();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Salva dados da viagem ativa
  static Future<void> saveActiveTripData(Map<String, dynamic> tripData) async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.saveActiveTripData(tripData);
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.saveActiveTripData(tripData);
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Restaura dados da viagem ativa
  static Future<Map<String, dynamic>?> restoreActiveTripData() async {
    if (Platform.isAndroid) {
      return await android.BackgroundLocationServiceAndroid.restoreActiveTripData();
    } else if (Platform.isIOS) {
      return await ios.BackgroundLocationServiceIOS.restoreActiveTripData();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
  
  /// Limpa dados da viagem ativa
  static Future<void> clearActiveTripData() async {
    if (Platform.isAndroid) {
      await android.BackgroundLocationServiceAndroid.clearActiveTripData();
    } else if (Platform.isIOS) {
      await ios.BackgroundLocationServiceIOS.clearActiveTripData();
    } else {
      throw UnsupportedError('Plataforma não suportada para background service');
    }
  }
}