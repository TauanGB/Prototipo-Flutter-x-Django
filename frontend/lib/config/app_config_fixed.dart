import 'dart:io';

/// Configurações do Sistema EG3 - App para Motoristas
/// 
/// Este aplicativo é exclusivamente para dispositivos móveis:
/// - Android (API 21+)
/// - iOS (iOS 12.0+)
class AppConfigFixed {
  // URL base da API do backend Django - CORRIGIDA para local
  static String get apiBaseUrl => 'http://127.0.0.1:8000/api/v1';

  // Configurações do app mobile
  static const String appVersion = '1.0.0';
  static const String appName = 'Sistema EG3 - Motoristas';
  static const String appDescription = 'App para Motoristas (Android e iOS)';
  
  // Plataformas suportadas
  static const List<String> supportedPlatforms = ['android', 'ios'];
  
  // Status disponíveis para motoristas
  static const List<String> driverStatuses = [
    'online',
    'offline', 
    'driving',
    'stopped',
    'break',
  ];
  
  // Mapeamento de status para nomes em português
  static const Map<String, String> statusDisplayNames = {
    'online': 'Online',
    'offline': 'Offline',
    'driving': 'Dirigindo',
    'stopped': 'Parado',
    'break': 'Em Pausa',
  };
  
  // Configurações de UI mobile
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Configurações do serviço de background mobile
  static const int defaultBackgroundInterval = 30; // segundos
  static const int minBackgroundInterval = 15; // segundos
  static const int maxBackgroundInterval = 300; // 5 minutos
  
  // Textos da UI centralizados
  static const String startTrackingText = 'Iniciar Rastreamento';
  static const String stopTrackingText = 'Parar Rastreamento';
  static const String trackingServiceText = 'Rastreamento em Background';
  static const String advancedSettingsText = 'Configurações Avançadas';
  
  // URLs específicas para diferentes plataformas
  static String get baseUrlForPlatform {
    // Para Android emulador
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    // Para iOS simulador
    else if (Platform.isIOS) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    // Fallback para localhost
    else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }
}
