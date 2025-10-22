import '../services/config_service.dart';

class AppConfig {
  // URL base da API do backend Django - agora obtida dinamicamente
  static Future<String> get apiBaseUrl async {
    return await ConfigService.getApiBaseUrl();
  }

  
  
  // Configurações do app
  static const String appVersion = '1.0.0';
  static const String appName = 'App Motorista';
  
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
  
  // Configurações de UI
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Configurações do serviço de background
  static const int defaultBackgroundInterval = 30; // segundos
  static const int minBackgroundInterval = 15; // segundos
  static const int maxBackgroundInterval = 300; // 5 minutos
  
  // Textos da UI centralizados
  static const String startTrackingText = 'Iniciar Rastreamento';
  static const String stopTrackingText = 'Parar Rastreamento';
  static const String trackingServiceText = 'Rastreamento em Background';
  static const String advancedSettingsText = 'Configurações Avançadas';
}
