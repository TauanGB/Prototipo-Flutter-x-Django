import '../models/api_config.dart';

/// Configurações do Sistema EG3 - App para Motoristas
/// 
/// Este aplicativo é exclusivamente para dispositivos móveis:
/// - Android (API 21+)
/// - iOS (iOS 12.0+)
class AppConfig {
  // URL base da API do backend Django - hard-coded
  static String get apiBaseUrl => ApiConfig.baseUrl;

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
}
