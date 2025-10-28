import 'dart:convert';

class ApiConfig {
  // URL de produção hard-coded
  static const String baseUrl = 'https://sistemaeg3-production.up.railway.app';
  
  // Construtor padrão
  const ApiConfig();
  
  // Getters para compatibilidade
  String get url => baseUrl;
  
  /// Converte para Map para serialização (mantido para compatibilidade)
  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
    };
  }
  
  /// Cria uma instância a partir de um Map (mantido para compatibilidade)
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig();
  }
  
  /// Converte para JSON string (mantido para compatibilidade)
  String toJsonString() {
    return json.encode(toJson());
  }
  
  /// Cria a partir de JSON string (mantido para compatibilidade)
  factory ApiConfig.fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return ApiConfig.fromJson(jsonMap);
  }
}