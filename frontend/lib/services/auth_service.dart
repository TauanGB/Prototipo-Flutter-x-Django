import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:frontend/config/app_config.dart';

class AuthService {
  static String get _baseUrl => AppConfig.apiBaseUrl;
  
  /// Realiza login do usuário
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final baseUrl = _baseUrl;
      final url = '$baseUrl/auth/login/';
      
      developer.log('AuthService: Tentando login em $url');
      developer.log('AuthService: Email: $email');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      developer.log('AuthService: Status Code: ${response.statusCode}');
      developer.log('AuthService: Headers: ${response.headers}');
      developer.log('AuthService: Body: ${response.body}');

      // Verifica se a resposta é JSON
      if (response.headers['content-type']?.contains('application/json') != true) {
        developer.log('AuthService: Resposta não é JSON! Content-Type: ${response.headers['content-type']}');
        return {
          'success': false,
          'message': 'Servidor retornou resposta não-JSON. Verifique a configuração da API.',
        };
      }

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro no login',
        };
      }
    } catch (e) {
      developer.log('AuthService: Erro: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Realiza logout do usuário
  Future<Map<String, dynamic>> logout() async {
    try {
      final baseUrl = _baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro no logout',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Obtém informações do usuário logado
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final baseUrl = _baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user-info/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao obter informações do usuário',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}
