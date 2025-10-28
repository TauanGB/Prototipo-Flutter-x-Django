import 'dart:convert';
import 'package:frontend/config/api_endpoints.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/storage_service.dart';
import 'dart:developer' as developer;

/// Serviço de autenticação para SistemaEG3
/// Gerencia login com CPF/senha e token de autenticação
class AuthServiceEG3 {
  static ApiEndpoints? _endpoints;
  
  /// Obtém endpoints configurados
  static Future<ApiEndpoints> _getEndpoints() async {
    if (_endpoints == null) {
      _endpoints = ApiEndpoints();
    }
    return _endpoints!;
  }
  
  /// Verifica se CPF existe no sistema (API pública)
  Future<Map<String, dynamic>> verificarCpf(String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🔍 Verificando CPF: $cpf', name: 'AuthServiceEG3');
      
      final response = await ApiClient.post(
        endpoints.verificarCpfPublico,
        {'cpf': cpf},
        requiresAuth: false, // API pública
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ CPF verificado: ${data['exists']}', name: 'AuthServiceEG3');
        return {
          'success': true,
          'exists': data['exists'],
          'can_login': data['can_login'],
          'message': data['message'],
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao verificar CPF: ${errorData['error']}', name: 'AuthServiceEG3');
        return {
          'success': false,
          'exists': false,
          'can_login': false,
          'message': errorData['error'] ?? 'Erro ao verificar CPF',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao verificar CPF: $e', name: 'AuthServiceEG3');
      return {
        'success': false,
        'exists': false,
        'can_login': false,
        'message': 'Erro ao verificar CPF: $e',
      };
    }
  }
  
  /// Login com CPF + senha (API pública)
  Future<Map<String, dynamic>> loginComCpf(String cpf, String password) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🔐 Fazendo login com CPF: $cpf', name: 'AuthServiceEG3');
      
      final response = await ApiClient.post(
        endpoints.loginPorCpf,
        {
          'cpf': cpf,
          'password': password,
        },
        requiresAuth: false, // API pública
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        
        if (token == null) {
          developer.log('❌ Token não recebido do servidor', name: 'AuthServiceEG3');
          return {
            'success': false,
            'message': 'Token não recebido do servidor',
          };
        }
        
        developer.log('✅ Login realizado com sucesso', name: 'AuthServiceEG3');
        
        // Salvar token e dados do usuário
        await StorageService.saveAuthToken(token);
        await StorageService.saveUserData(data['user'], data['perfil']);
        
        // Salvar CPF do motorista
        await StorageService.saveCpf(data['perfil']['cpf']);
        
        // Salvar último login
        await StorageService.saveLastLogin(DateTime.now());
        
        developer.log('✅ Login completo - CPF e último login salvos', name: 'AuthServiceEG3');
        
        return {
          'success': true,
          'message': 'Login realizado com sucesso',
          'user': data['user'],
          'perfil': data['perfil'],
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'CPF ou senha incorretos';
        
        // Padronizar mensagens de erro para segurança
        String standardizedMessage;
        if (errorMessage.contains('não encontrado') || 
            errorMessage.contains('Senha incorreta') ||
            errorMessage.contains('Credenciais inválidas')) {
          standardizedMessage = 'CPF ou senha incorretos';
        } else if (errorMessage.contains('inativo')) {
          standardizedMessage = errorMessage; // Manter mensagem específica para usuário inativo
        } else {
          standardizedMessage = 'CPF ou senha incorretos';
        }
        
        developer.log('❌ Erro no login: $errorMessage', name: 'AuthServiceEG3');
        return {
          'success': false,
          'message': standardizedMessage,
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado no login: $e', name: 'AuthServiceEG3');
      return {
        'success': false,
        'message': 'Erro ao fazer login: $e',
      };
    }
  }
  
  /// Login com CPF ou Username + Senha (método legado - manter para compatibilidade)
  /// Retorna token e dados do usuário
  Future<Map<String, dynamic>> login(String usernameOrCpf, String password) async {
    // Usar o novo método de login por CPF otimizado
    return await loginComCpf(usernameOrCpf, password);
  }
  
  /// Logout - limpa token e dados do usuário
  Future<void> logout() async {
    try {
      final endpoints = await _getEndpoints();
      
      // Tentar fazer logout no servidor (opcional, não bloqueia)
      try {
        await ApiClient.post(endpoints.logout, {});
        developer.log('✅ Logout no servidor realizado', name: 'AuthServiceEG3');
      } catch (e) {
        developer.log('⚠️ Erro ao fazer logout no servidor: $e', name: 'AuthServiceEG3');
      }
      
      // Limpar dados locais (principal)
      await StorageService.clearAll();
      
      developer.log('✅ Logout local realizado com sucesso', name: 'AuthServiceEG3');
    } catch (e) {
      developer.log('❌ Erro ao fazer logout: $e', name: 'AuthServiceEG3');
      // Mesmo com erro, limpar dados locais
      await StorageService.clearAll();
    }
  }
  
  /// Verifica se usuário está logado
  Future<bool> isLoggedIn() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    developer.log('🔐 Status de login: ${isLoggedIn ? "✅ Logado" : "❌ Não logado"}', name: 'AuthServiceEG3');
    return isLoggedIn;
  }
  
  /// Obtém dados do usuário logado
  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await StorageService.getUserData();
    developer.log('👤 Dados do usuário: ${userData != null ? "✅ Existem" : "❌ Não existem"}', name: 'AuthServiceEG3');
    return userData;
  }
  
  /// Valida token atual
  Future<bool> validateToken() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        developer.log('🔑 Token não encontrado', name: 'AuthServiceEG3');
        return false;
      }
      
      developer.log('🔑 Token encontrado, considerando válido', name: 'AuthServiceEG3');
      return true;
    } catch (e) {
      developer.log('❌ Erro ao validar token: $e', name: 'AuthServiceEG3');
      return false;
    }
  }
  
  /// Altera senha do usuário
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final endpoints = await _getEndpoints();
      
      final response = await ApiClient.post(
        endpoints.alterarSenha,
        {
          'senha_atual': currentPassword,
          'nova_senha': newPassword,
        },
      );
      
      if (response.statusCode == 200) {
        developer.log('✅ Senha alterada com sucesso', name: 'AuthServiceEG3');
        return {
          'success': true,
          'message': 'Senha alterada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao alterar senha';
        developer.log('❌ Erro ao alterar senha: $errorMessage', name: 'AuthServiceEG3');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao alterar senha: $e', name: 'AuthServiceEG3');
      return {
        'success': false,
        'message': 'Erro ao alterar senha: $e',
      };
    }
  }
  
  /// Obtém informações de debug
  Future<Map<String, dynamic>> getDebugInfo() async {
    final storageDebug = await StorageService.getDebugInfo();
    final endpoints = await _getEndpoints();
    
    return {
      'storage': storageDebug,
      'endpoints': endpoints.debugInfo,
      'isLoggedIn': await isLoggedIn(),
    };
  }
}
