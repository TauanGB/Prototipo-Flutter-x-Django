/// Configurações do App Motorista - Sistema de Gestão de Fretes
/// 
/// Este aplicativo é exclusivamente para dispositivos móveis:
/// - Android (API 21+)
/// - iOS (iOS 12.0+)
class AppConfig {
  // URL base da API - configurável para diferentes ambientes
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static String get apiBaseUrl => _baseUrl;

  // Configurações do app mobile
  static const String appVersion = '1.0.0';
  static const String appName = 'App Motorista';
  static const String appDescription = 'Sistema de Gestão de Fretes para Motoristas';
  
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
  
  // Intervalo de sincronização periódica (usado pelo serviço de background)
  /// Intervalo em segundos para sincronização periódica com o backend
  /// Deve ser usado pelo serviço de background quando rota_ativa = true
  /// Definido conforme especificação em cursorrules
  static const int SYNC_INTERVAL_SECONDS = 30;
  
  // Textos da UI centralizados
  static const String startTrackingText = 'Iniciar Rastreamento';
  static const String stopTrackingText = 'Parar Rastreamento';
  static const String trackingServiceText = 'Rastreamento em Background';
  static const String advancedSettingsText = 'Configurações Avançadas';
}
