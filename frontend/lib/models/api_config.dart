import 'dart:convert';

class ApiConfig {
  final String host;
  final int port;
  final String protocol;
  final String basePath;

  const ApiConfig({
    this.host = '127.0.0.1',
    this.port = 8000,
    this.protocol = 'http',
    this.basePath = '/api/v1',
  });

  /// Constrói a URL completa da API
  String get baseUrl => '$protocol://$host:$port$basePath';


  /// Converte para Map para serialização
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'protocol': protocol,
      'basePath': basePath,
    };
  }

  /// Cria uma instância a partir de um Map
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      host: json['host'] ?? '127.0.0.1',
      port: json['port'] ?? 8000,
      protocol: json['protocol'] ?? 'http',
      basePath: json['basePath'] ?? '/api/v1',
    );
  }

  /// Converte para String JSON
  String toJsonString() {
    return json.encode(toJson());
  }

  /// Cria uma instância a partir de uma String JSON
  factory ApiConfig.fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return ApiConfig.fromJson(jsonMap);
  }

  /// Configuração padrão para Android (emulador)
  static const ApiConfig defaultAndroid = ApiConfig(
    host: '10.0.2.2',
    port: 8000,
    protocol: 'http',
    basePath: '/api/v1',
  );

  /// Configuração padrão para outras plataformas
  static const ApiConfig defaultDesktop = ApiConfig(
    host: '127.0.0.1',
    port: 8000,
    protocol: 'http',
    basePath: '/api/v1',
  );

}
