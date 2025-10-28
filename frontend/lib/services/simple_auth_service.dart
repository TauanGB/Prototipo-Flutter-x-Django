import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:frontend/config/simple_config.dart';

class SimpleAuthService {
  /// Realiza login do usuário
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = '${SimpleConfig.apiBaseUrl}/auth/login/';
      
      developer.log('SimpleAuthService: Tentando login em $url');
      developer.log('SimpleAuthService: Username: $username');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      developer.log('SimpleAuthService: Status Code: ${response.statusCode}');
      developer.log('SimpleAuthService: Headers: ${response.headers}');
      developer.log('SimpleAuthService: Body: ${response.body}');

      // Verifica se a resposta é JSON
      if (response.headers['content-type']?.contains('application/json') != true) {
        developer.log('SimpleAuthService: Resposta não é JSON! Content-Type: ${response.headers['content-type']}');
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
      developer.log('SimpleAuthService: Erro: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}
