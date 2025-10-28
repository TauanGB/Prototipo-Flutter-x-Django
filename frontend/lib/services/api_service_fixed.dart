import 'dart:convert';
import 'dart:developer' as developer;
import 'package:frontend/config/api_endpoints_fixed.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/storage_service.dart';

/// Serviço de API corrigido que usa apenas endpoints existentes no backend Django
class ApiServiceFixed {
  static ApiEndpointsFixed? _endpoints;
  
  /// Obtém endpoints configurados
  static Future<ApiEndpointsFixed> _getEndpoints() async {
    if (_endpoints == null) {
      _endpoints = ApiEndpointsFixed();
    }
    return _endpoints!;
  }
  
  // === AUTENTICAÇÃO ===
  
  /// Login com CPF + senha usando endpoint existente
  static Future<Map<String, dynamic>> loginComCpf(String cpf, String password) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🔐 Fazendo login com CPF: $cpf', name: 'ApiServiceFixed');
      
      final response = await ApiClient.post(
        endpoints.loginPorCpf,
        {
          'username': cpf, // O backend espera 'username'
          'password': password,
        },
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Login realizado com sucesso', name: 'ApiServiceFixed');
        
        // Salvar dados do usuário
        await StorageService.saveUserData(data['user'], null);
        await StorageService.saveCpf(cpf);
        
        return {
          'success': true,
          'message': 'Login realizado com sucesso',
          'user': data['user'],
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro no login: ${errorData['message']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['message'] ?? 'CPF ou senha incorretos',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado no login: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao fazer login: $e',
      };
    }
  }
  
  /// Logout usando endpoint existente
  static Future<Map<String, dynamic>> logout() async {
    try {
      final endpoints = await _getEndpoints();
      
      final response = await ApiClient.post(endpoints.logout, {});
      
      if (response.statusCode == 200) {
        developer.log('✅ Logout realizado com sucesso', name: 'ApiServiceFixed');
        await StorageService.clearAll();
        return {
          'success': true,
          'message': 'Logout realizado com sucesso',
        };
      } else {
        developer.log('❌ Erro no logout: ${response.statusCode}', name: 'ApiServiceFixed');
        await StorageService.clearAll(); // Limpar dados locais mesmo com erro
        return {
          'success': false,
          'message': 'Erro no logout',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado no logout: $e', name: 'ApiServiceFixed');
      await StorageService.clearAll(); // Limpar dados locais mesmo com erro
      return {
        'success': false,
        'message': 'Erro ao fazer logout: $e',
      };
    }
  }
  
  /// Obter informações do usuário usando endpoint existente
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final endpoints = await _getEndpoints();
      
      final response = await ApiClient.get(endpoints.userInfo);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Informações do usuário obtidas', name: 'ApiServiceFixed');
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        developer.log('❌ Erro ao obter informações: ${response.statusCode}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': 'Erro ao obter informações do usuário',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao obter informações: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao obter informações: $e',
      };
    }
  }
  
  // === RASTREAMENTO GPS ===
  
  /// Enviar localização GPS por CPF usando endpoint existente
  static Future<Map<String, dynamic>> sendDriverLocation(String cpf, double latitude, double longitude, {
    double? accuracy,
    double? speed,
    int? batteryLevel,
  }) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📍 Enviando localização para CPF: $cpf', name: 'ApiServiceFixed');
      
      final requestData = {
        'cpf': cpf,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (batteryLevel != null) 'battery_level': batteryLevel,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioSendLocation,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        developer.log('✅ Localização enviada com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Localização enviada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao enviar localização: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao enviar localização',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao enviar localização: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao enviar localização: $e',
      };
    }
  }
  
  /// Iniciar viagem usando endpoint existente
  static Future<Map<String, dynamic>> startTrip(String cpf, double latitude, double longitude) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🚀 Iniciando viagem para CPF: $cpf', name: 'ApiServiceFixed');
      
      final requestData = {
        'cpf': cpf,
        'start_latitude': latitude,
        'start_longitude': longitude,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioStartTrip,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        developer.log('✅ Viagem iniciada com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Viagem iniciada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao iniciar viagem: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao iniciar viagem',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao iniciar viagem: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao iniciar viagem: $e',
      };
    }
  }
  
  /// Finalizar viagem usando endpoint existente
  static Future<Map<String, dynamic>> endTrip(String cpf, double latitude, double longitude, {double? distanceKm}) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🏁 Finalizando viagem para CPF: $cpf', name: 'ApiServiceFixed');
      
      final requestData = {
        'cpf': cpf,
        'end_latitude': latitude,
        'end_longitude': longitude,
        if (distanceKm != null) 'distance_km': distanceKm,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioEndTrip,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Viagem finalizada com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Viagem finalizada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao finalizar viagem: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao finalizar viagem',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao finalizar viagem: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao finalizar viagem: $e',
      };
    }
  }
  
  /// Verificar se motorista existe usando endpoint existente
  static Future<Map<String, dynamic>> checkDriver(String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🔍 Verificando motorista CPF: $cpf', name: 'ApiServiceFixed');
      
      final response = await ApiClient.get(
        '${endpoints.rastreioCheckDriver}?cpf=$cpf',
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Motorista verificado: ${data['is_registered']}', name: 'ApiServiceFixed');
        return {
          'success': true,
          'exists': data['is_registered'],
          'data': data,
        };
      } else {
        developer.log('❌ Erro ao verificar motorista: ${response.statusCode}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'exists': false,
          'message': 'Erro ao verificar motorista',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao verificar motorista: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'exists': false,
        'message': 'Erro ao verificar motorista: $e',
      };
    }
  }
  
  /// Obter dados completos do motorista usando endpoint existente
  static Future<Map<String, dynamic>> getDriverData(String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('👤 Obtendo dados do motorista CPF: $cpf', name: 'ApiServiceFixed');
      
      final response = await ApiClient.get(
        '${endpoints.rastreioGetDriverData}?cpf=$cpf',
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Dados do motorista obtidos', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao obter dados: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao obter dados do motorista',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao obter dados: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao obter dados: $e',
      };
    }
  }
  
  /// Obter fretes ativos usando endpoint existente
  static Future<Map<String, dynamic>> getActiveFretes(String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Obtendo fretes ativos para CPF: $cpf', name: 'ApiServiceFixed');
      
      final response = await ApiClient.get(
        '${endpoints.rastreioActiveFretes}?cpf=$cpf',
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Fretes ativos obtidos: ${data['total']}', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao obter fretes: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao obter fretes ativos',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao obter fretes: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao obter fretes: $e',
      };
    }
  }
  
  /// Obter rotas ativas usando endpoint existente
  static Future<Map<String, dynamic>> getActiveRotas(String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🛣️ Obtendo rotas ativas para CPF: $cpf', name: 'ApiServiceFixed');
      
      final response = await ApiClient.get(
        '${endpoints.rastreioActiveRotas}?cpf=$cpf',
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Rotas ativas obtidas: ${data['total']}', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao obter rotas: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao obter rotas ativas',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao obter rotas: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao obter rotas: $e',
      };
    }
  }
  
  /// Enviar localização com frete usando endpoint existente
  static Future<Map<String, dynamic>> sendLocationWithFrete(String cpf, double latitude, double longitude, {
    int? freteId,
    double? accuracy,
    double? speed,
    int? batteryLevel,
  }) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📍 Enviando localização com frete para CPF: $cpf', name: 'ApiServiceFixed');
      
      final requestData = {
        'cpf': cpf,
        'latitude': latitude,
        'longitude': longitude,
        if (freteId != null) 'frete_id': freteId,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (batteryLevel != null) 'battery_level': batteryLevel,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioSendLocationWithFrete,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        developer.log('✅ Localização com frete enviada com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Localização enviada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao enviar localização: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao enviar localização',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao enviar localização: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao enviar localização: $e',
      };
    }
  }
  
  /// Atualizar status de frete usando endpoint existente
  static Future<Map<String, dynamic>> updateFreteStatus(int freteId, String novoStatus, String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Atualizando status do frete $freteId para $novoStatus', name: 'ApiServiceFixed');
      
      final requestData = {
        'frete_id': freteId,
        'novo_status': novoStatus,
        'cpf': cpf,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioUpdateFreteStatus,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Status atualizado com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Status atualizado com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao atualizar status: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao atualizar status',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao atualizar status: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao atualizar status: $e',
      };
    }
  }
  
  /// Iniciar rota usando endpoint existente
  static Future<Map<String, dynamic>> startRota(int rotaId, String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🚀 Iniciando rota $rotaId', name: 'ApiServiceFixed');
      
      final requestData = {
        'rota_id': rotaId,
        'cpf': cpf,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioStartRota,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Rota iniciada com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Rota iniciada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao iniciar rota: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao iniciar rota',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao iniciar rota: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao iniciar rota: $e',
      };
    }
  }
  
  /// Concluir rota usando endpoint existente
  static Future<Map<String, dynamic>> completeRota(int rotaId, String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🏁 Concluindo rota $rotaId', name: 'ApiServiceFixed');
      
      final requestData = {
        'rota_id': rotaId,
        'cpf': cpf,
      };
      
      final response = await ApiClient.post(
        endpoints.rastreioCompleteRota,
        requestData,
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Rota concluída com sucesso', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
          'message': 'Rota concluída com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao concluir rota: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao concluir rota',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao concluir rota: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao concluir rota: $e',
      };
    }
  }
  
  // === FRETES ===
  
  /// Listar fretes usando endpoint existente
  static Future<Map<String, dynamic>> getFretes({String? motoristaId, String? status}) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Obtendo fretes', name: 'ApiServiceFixed');
      
      String url = endpoints.fretes;
      List<String> params = [];
      
      if (motoristaId != null) params.add('motorista=$motoristaId');
      if (status != null) params.add('status=$status');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Fretes obtidos: ${data.length}', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
        };
      } else {
        developer.log('❌ Erro ao obter fretes: ${response.statusCode}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': 'Erro ao obter fretes',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao obter fretes: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao obter fretes: $e',
      };
    }
  }
  
  /// Obter fretes por motorista usando endpoint existente
  static Future<Map<String, dynamic>> getFretesByDriver(String cpf) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Obtendo fretes por motorista CPF: $cpf', name: 'ApiServiceFixed');
      
      final response = await ApiClient.get(
        '${endpoints.fretesPorMotorista}?cpf=$cpf',
        requiresAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ Fretes por motorista obtidos', name: 'ApiServiceFixed');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        developer.log('❌ Erro ao obter fretes: ${errorData['error']}', name: 'ApiServiceFixed');
        return {
          'success': false,
          'message': errorData['error'] ?? 'Erro ao obter fretes',
        };
      }
    } catch (e) {
      developer.log('❌ Erro inesperado ao obter fretes: $e', name: 'ApiServiceFixed');
      return {
        'success': false,
        'message': 'Erro ao obter fretes: $e',
      };
    }
  }
  
  /// Obter informações de debug
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final endpoints = await _getEndpoints();
    final cpf = await StorageService.getCpf();
    
    return {
      'endpoints': endpoints.debugInfo,
      'cpf_motorista': cpf,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
