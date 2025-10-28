import 'dart:developer' as developer;
import '../models/api_config.dart';

class ConfigService {
  static ApiConfig? _cachedConfig;

  /// Obtém a configuração da API (sempre retorna URL hard-coded)
  static Future<ApiConfig> getApiConfig() async {
    // Retorna cache se disponível
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    // Sempre retorna a URL hard-coded
    _cachedConfig = const ApiConfig();
    developer.log('🔧 Configuração carregada: ${ApiConfig.baseUrl}', name: 'ConfigService');
    
    return _cachedConfig!;
  }

  /// Limpa cache de configuração
  static void clearCache() {
    _cachedConfig = null;
    developer.log('🗑️ Cache de configuração limpo', name: 'ConfigService');
  }

  /// Obtém informações de debug
  static Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'baseUrl': ApiConfig.baseUrl,
      'cached': _cachedConfig != null,
    };
  }
}