/// Configurações da API do SistemaEG3
class ApiConfig {
  // URL base da API - configurável para diferentes ambientes
  static const String _baseUrl = 'https://sistemaeg3-production.up.railway.app';
  
  /// URL base da API
  static String get baseUrl => _baseUrl;
  
  /// Timeout padrão para requisições HTTP (em segundos)
  static const int defaultTimeout = 15;
  
  /// Timeout para requisições de upload (em segundos)
  static const int uploadTimeout = 60;
  
  /// Timeout para requisições de download (em segundos)
  static const int downloadTimeout = 30;
  
  /// Headers padrão para requisições HTTP
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'AppMotorista/1.0.0',
  };
  
  /// Endpoints da API
  static const Map<String, String> endpoints = {
    'login': '/auth/login/',
    'logout': '/auth/logout/',
    'refresh': '/auth/refresh/',
    'profile': '/auth/profile/',
    'drivers': '/api/usuarios/motorista/',
    'driverLocation': '/api/usuarios/motorista/enviar-localizacao/',
    'driverStartTrip': '/api/fretes/motorista/iniciar-viagem/',
    'driverEndTrip': '/api/fretes/motorista/finalizar-viagem/',
    'driverData': '/api/usuarios/motorista/fretes-ativos/',
    'checkDriver': '/api/usuarios/motorista/verificar-cpf/',
    'fretes': '/fretes/',
    'fretesAtivos': '/fretes/ativos/',
    'fretesPorId': '/fretes/por_id/',
    'rotas': '/rotas/',
    'rotasAtivas': '/rotas/ativas/',
    'materiais': '/materiais/',
    'empresas': '/empresas/',
    'relatorios': '/relatorios/',
  };
  
  /// Obtém URL completa para um endpoint
  static String getEndpointUrl(String endpoint) {
    final path = endpoints[endpoint];
    if (path == null) {
      throw ArgumentError('Endpoint "$endpoint" não encontrado');
    }
    return '$baseUrl$path';
  }
  
  /// Configurações de retry para requisições falhadas
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Configurações de cache
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  
  /// Configurações de logging
  static const bool enableLogging = true;
  static const bool enableRequestLogging = true;
  static const bool enableResponseLogging = true;
  
  /// Configurações de debug
  static const bool enableDebugMode = false;
  static const bool enableMockResponses = false;
  
  /// Configurações de segurança
  static const bool enableCertificatePinning = false;
  static const bool enableRequestEncryption = false;
  
  /// Configurações de performance
  static const int maxConcurrentRequests = 5;
  static const Duration requestInterval = Duration(milliseconds: 100);
  
  /// Validação de configuração
  static bool get isValid {
    try {
      Uri.parse(baseUrl);
      return baseUrl.isNotEmpty && 
             defaultTimeout > 0 && 
             uploadTimeout > 0 && 
             downloadTimeout > 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Informações de debug da configuração
  static Map<String, dynamic> get debugInfo => {
    'baseUrl': baseUrl,
    'defaultTimeout': defaultTimeout,
    'uploadTimeout': uploadTimeout,
    'downloadTimeout': downloadTimeout,
    'maxRetries': maxRetries,
    'retryDelay': retryDelay.inSeconds,
    'cacheTimeout': cacheTimeout.inMinutes,
    'maxCacheSize': maxCacheSize,
    'enableLogging': enableLogging,
    'enableDebugMode': enableDebugMode,
    'isValid': isValid,
    'endpoints': endpoints,
  };
}