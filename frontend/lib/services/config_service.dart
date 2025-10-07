import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_config.dart';

class ConfigService {
  static const String _apiConfigKey = 'api_config';
  static ApiConfig? _cachedConfig;

  /// Obtém a configuração da API salva ou retorna a configuração padrão
  static Future<ApiConfig> getApiConfig() async {
    // Retorna cache se disponível
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_apiConfigKey);

      if (configJson != null) {
        _cachedConfig = ApiConfig.fromJsonString(configJson);
      } else {
        // Usa configuração padrão baseada na plataforma
        _cachedConfig = Platform.isAndroid 
            ? ApiConfig.defaultAndroid 
            : ApiConfig.defaultDesktop;
      }

      return _cachedConfig!;
    } catch (e) {
      print('Erro ao carregar configuração da API: $e');
      // Retorna configuração padrão em caso de erro
      _cachedConfig = Platform.isAndroid 
          ? ApiConfig.defaultAndroid 
          : ApiConfig.defaultDesktop;
      return _cachedConfig!;
    }
  }

  /// Salva a configuração da API
  static Future<bool> saveApiConfig(ApiConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_apiConfigKey, config.toJsonString());
      
      if (success) {
        _cachedConfig = config;
      }
      
      return success;
    } catch (e) {
      print('Erro ao salvar configuração da API: $e');
      return false;
    }
  }

  /// Reseta a configuração para os valores padrão
  static Future<bool> resetApiConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_apiConfigKey);
      
      if (success) {
        _cachedConfig = null; // Limpa o cache
      }
      
      return success;
    } catch (e) {
      print('Erro ao resetar configuração da API: $e');
      return false;
    }
  }


  /// Obtém a URL base da API atual
  static Future<String> getApiBaseUrl() async {
    final config = await getApiConfig();
    return config.baseUrl;
  }


  /// Testa a conectividade com a configuração atual
  static Future<bool> testConnection() async {
    try {
      final config = await getApiConfig();
      final uri = Uri.parse('${config.baseUrl}/');
      
      // Faz uma requisição simples para testar a conectividade
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      client.close();
      
      // Considera sucesso se receber qualquer resposta (mesmo erro 404)
      return response.statusCode >= 200 && response.statusCode < 600;
    } catch (e) {
      print('Erro ao testar conexão: $e');
      return false;
    }
  }

}



