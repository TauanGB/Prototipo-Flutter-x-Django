import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:frontend/services/storage_service.dart';
import 'dart:developer' as developer;

/// Cliente HTTP centralizado com interceptors e tratamento de erros
/// Gerencia automaticamente tokens de autenticação e tratamento de erros HTTP
class ApiClient {
  static const Duration _timeout = Duration(seconds: 15);
  
  /// Obtém headers padrão com token de autenticação se necessário
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = await StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
        developer.log('🔑 Token incluído na requisição', name: 'ApiClient');
      } else {
        developer.log('⚠️ Nenhum token encontrado para autenticação', name: 'ApiClient');
      }
    }
    
    return headers;
  }
  
  /// Requisição GET
  static Future<http.Response> get(String url, {bool requiresAuth = true}) async {
    try {
      developer.log('📤 GET: $url', name: 'ApiClient');
      
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeout);
      
      developer.log('📥 GET Response: ${response.statusCode}', name: 'ApiClient');
      await _handleResponse(response);
      return response;
    } on SocketException {
      developer.log('❌ SocketException: Sem conexão com a internet', name: 'ApiClient');
      throw ApiException('Sem conexão com a internet');
    } on TimeoutException {
      developer.log('❌ TimeoutException: Tempo de conexão esgotado', name: 'ApiClient');
      throw ApiException('Tempo de conexão esgotado');
    } catch (e) {
      developer.log('❌ Erro na requisição GET: $e', name: 'ApiClient');
      throw ApiException('Erro na requisição: $e');
    }
  }
  
  /// Requisição POST
  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
    {bool requiresAuth = true}
  ) async {
    try {
      developer.log('📤 POST: $url', name: 'ApiClient');
      developer.log('📤 Body: ${json.encode(body)}', name: 'ApiClient');
      
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(_timeout);
      
      developer.log('📥 POST Response: ${response.statusCode}', name: 'ApiClient');
      await _handleResponse(response);
      return response;
    } on SocketException {
      developer.log('❌ SocketException: Sem conexão com a internet', name: 'ApiClient');
      throw ApiException('Sem conexão com a internet');
    } on TimeoutException {
      developer.log('❌ TimeoutException: Tempo de conexão esgotado', name: 'ApiClient');
      throw ApiException('Tempo de conexão esgotado');
    } catch (e) {
      developer.log('❌ Erro na requisição POST: $e', name: 'ApiClient');
      throw ApiException('Erro na requisição: $e');
    }
  }
  
  /// Requisição PUT
  static Future<http.Response> put(
    String url,
    Map<String, dynamic> body,
    {bool requiresAuth = true}
  ) async {
    try {
      developer.log('📤 PUT: $url', name: 'ApiClient');
      developer.log('📤 Body: ${json.encode(body)}', name: 'ApiClient');
      
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(_timeout);
      
      developer.log('📥 PUT Response: ${response.statusCode}', name: 'ApiClient');
      await _handleResponse(response);
      return response;
    } on SocketException {
      developer.log('❌ SocketException: Sem conexão com a internet', name: 'ApiClient');
      throw ApiException('Sem conexão com a internet');
    } on TimeoutException {
      developer.log('❌ TimeoutException: Tempo de conexão esgotado', name: 'ApiClient');
      throw ApiException('Tempo de conexão esgotado');
    } catch (e) {
      developer.log('❌ Erro na requisição PUT: $e', name: 'ApiClient');
      throw ApiException('Erro na requisição: $e');
    }
  }
  
  /// Requisição PATCH
  static Future<http.Response> patch(
    String url,
    Map<String, dynamic> body,
    {bool requiresAuth = true}
  ) async {
    try {
      developer.log('📤 PATCH: $url', name: 'ApiClient');
      developer.log('📤 Body: ${json.encode(body)}', name: 'ApiClient');
      
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(_timeout);
      
      developer.log('📥 PATCH Response: ${response.statusCode}', name: 'ApiClient');
      await _handleResponse(response);
      return response;
    } on SocketException {
      developer.log('❌ SocketException: Sem conexão com a internet', name: 'ApiClient');
      throw ApiException('Sem conexão com a internet');
    } on TimeoutException {
      developer.log('❌ TimeoutException: Tempo de conexão esgotado', name: 'ApiClient');
      throw ApiException('Tempo de conexão esgotado');
    } catch (e) {
      developer.log('❌ Erro na requisição PATCH: $e', name: 'ApiClient');
      throw ApiException('Erro na requisição: $e');
    }
  }
  
  /// Requisição DELETE
  static Future<http.Response> delete(String url, {bool requiresAuth = true}) async {
    try {
      developer.log('📤 DELETE: $url', name: 'ApiClient');
      
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeout);
      
      developer.log('📥 DELETE Response: ${response.statusCode}', name: 'ApiClient');
      await _handleResponse(response);
      return response;
    } on SocketException {
      developer.log('❌ SocketException: Sem conexão com a internet', name: 'ApiClient');
      throw ApiException('Sem conexão com a internet');
    } on TimeoutException {
      developer.log('❌ TimeoutException: Tempo de conexão esgotado', name: 'ApiClient');
      throw ApiException('Tempo de conexão esgotado');
    } catch (e) {
      developer.log('❌ Erro na requisição DELETE: $e', name: 'ApiClient');
      throw ApiException('Erro na requisição: $e');
    }
  }
  
  /// Trata respostas HTTP e gerencia erros de autenticação
  static Future<void> _handleResponse(http.Response response) async {
    switch (response.statusCode) {
      case 200:
      case 201:
        // Sucesso - não fazer nada
        break;
        
      case 400:
        // Bad Request - erro de validação
        developer.log('⚠️ Bad Request (400): ${response.body}', name: 'ApiClient');
        throw BadRequestException('Dados inválidos enviados');
        
      case 401:
        // Unauthorized - token inválido ou expirado
        developer.log('🔒 Unauthorized (401): Token inválido ou expirado', name: 'ApiClient');
        await StorageService.clearAuthToken();
        await StorageService.clearUserData();
        throw UnauthorizedException('Sessão expirada. Faça login novamente.');
        
      case 403:
        // Forbidden - sem permissão
        developer.log('🚫 Forbidden (403): Sem permissão', name: 'ApiClient');
        throw ForbiddenException('Você não tem permissão para esta ação');
        
      case 404:
        // Not Found
        developer.log('🔍 Not Found (404): Recurso não encontrado', name: 'ApiClient');
        throw NotFoundException('Recurso não encontrado');
        
      case 500:
        // Internal Server Error
        developer.log('💥 Server Error (500): Erro interno do servidor', name: 'ApiClient');
        throw ServerException('Erro no servidor. Tente novamente mais tarde.');
        
      default:
        if (response.statusCode >= 500) {
          developer.log('💥 Server Error (${response.statusCode}): Erro do servidor', name: 'ApiClient');
          throw ServerException('Erro no servidor. Tente novamente mais tarde.');
        } else {
          developer.log('❓ Status desconhecido (${response.statusCode}): ${response.body}', name: 'ApiClient');
          throw ApiException('Erro desconhecido (${response.statusCode})');
        }
    }
  }
  
  /// Testa conectividade com uma URL
  static Future<bool> testConnection(String url) async {
    try {
      developer.log('🔍 Testando conexão: $url', name: 'ApiClient');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      final isConnected = response.statusCode < 500;
      developer.log('🔍 Teste de conexão: ${isConnected ? "✅ Sucesso" : "❌ Falha"} (${response.statusCode})', name: 'ApiClient');
      
      return isConnected;
    } catch (e) {
      developer.log('🔍 Teste de conexão falhou: $e', name: 'ApiClient');
      return false;
    }
  }
}

/// Exceção base para erros da API
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}

/// Exceção para requisições malformadas (400)
class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message);
}

/// Exceção para token inválido/expirado (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

/// Exceção para falta de permissão (403)
class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

/// Exceção para recurso não encontrado (404)
class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

/// Exceção para erros do servidor (500+)
class ServerException extends ApiException {
  ServerException(String message) : super(message);
}
