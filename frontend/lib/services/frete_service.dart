import 'dart:convert';
import 'package:frontend/config/api_endpoints.dart';
import 'package:frontend/models/frete_eg3.dart';
import 'package:frontend/models/frete_ativo.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/storage_service.dart';
import 'dart:developer' as developer;

/// Serviço de fretes integrado com SistemaEG3
/// Gerencia fretes do motorista com autenticação por token
class FreteService {
  static ApiEndpoints? _endpoints;
  
  /// Obtém endpoints configurados
  static Future<ApiEndpoints> _getEndpoints() async {
    if (_endpoints == null) {
      _endpoints = ApiEndpoints();
    }
    return _endpoints!;
  }
  
  /// Lista fretes ativos do motorista logado usando CPF
  static Future<List<FreteAtivo>> getFretesAtivos() async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Buscando fretes ativos por CPF...', name: 'FreteService');
      
      // Obter CPF do motorista logado (salvo durante o login)
      final cpf = await StorageService.getCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF do motorista não encontrado. Faça login novamente.');
      }
      
      // Usar endpoint correto que aceita CPF
      final url = '${endpoints.rastreioActiveFretes}?cpf=$cpf';
      
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Verificar se a resposta é uma lista ou um objeto com lista
        List<dynamic> jsonList;
        if (responseData is List) {
          jsonList = responseData;
        } else if (responseData is Map && responseData.containsKey('fretes_ativos')) {
          jsonList = responseData['fretes_ativos'];
        } else {
          developer.log('⚠️ Formato de resposta inesperado: ${responseData.runtimeType}', name: 'FreteService');
          developer.log('⚠️ Chaves disponíveis: ${responseData is Map ? responseData.keys.toList() : "N/A"}', name: 'FreteService');
          throw Exception('Formato de resposta inválido');
        }
        
        final fretes = jsonList.map((json) => FreteAtivo.fromJson(json)).toList();
        
        developer.log('✅ ${fretes.length} fretes ativos encontrados', name: 'FreteService');
        return fretes;
      } else {
        developer.log('❌ Erro ao buscar fretes: ${response.statusCode}', name: 'FreteService');
        throw Exception('Erro ao buscar fretes: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de fretes: $e', name: 'FreteService');
      rethrow;
    }
  }
  
  /// Lista fretes ativos do motorista logado usando ID do motorista
  static Future<List<FreteAtivo>> getFretesAtivosPorId() async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Buscando fretes ativos por ID do motorista...', name: 'FreteService');
      
      // Obter ID do motorista logado (salvo durante o login)
      final motoristaId = await StorageService.getDriverId();
      if (motoristaId == null) {
        throw Exception('ID do motorista não encontrado. Faça login novamente.');
      }
      
      // Usar endpoint que aceita motorista_id
      final url = '${endpoints.rastreioActiveFretesPorId}?motorista_id=$motoristaId';
      
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Verificar se a resposta é uma lista ou um objeto com lista
        List<dynamic> jsonList;
        if (responseData is List) {
          jsonList = responseData;
        } else if (responseData is Map && responseData.containsKey('fretes_ativos')) {
          jsonList = responseData['fretes_ativos'];
        } else {
          developer.log('⚠️ Formato de resposta inesperado: ${responseData.runtimeType}', name: 'FreteService');
          developer.log('⚠️ Chaves disponíveis: ${responseData is Map ? responseData.keys.toList() : "N/A"}', name: 'FreteService');
          throw Exception('Formato de resposta inválido');
        }
        
        final fretes = jsonList.map((json) => FreteAtivo.fromJson(json)).toList();
        
        developer.log('✅ ${fretes.length} fretes ativos encontrados por ID', name: 'FreteService');
        return fretes;
      } else {
        developer.log('❌ Erro ao buscar fretes por ID: ${response.statusCode}', name: 'FreteService');
        throw Exception('Erro ao buscar fretes: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de fretes por ID: $e', name: 'FreteService');
      rethrow;
    }
  }
  
  /// Lista todos os fretes do motorista (ativos e inativos)
  static Future<List<FreteEG3>> getTodosFretes() async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Buscando todos os fretes...', name: 'FreteService');
      
      // Obter ID do motorista logado
      final motoristaId = await StorageService.getDriverId();
      if (motoristaId == null) {
        throw Exception('ID do motorista não encontrado. Faça login novamente.');
      }
      
      // Construir URL com parâmetro motorista_id
      final url = '${endpoints.fretes}?motorista_id=$motoristaId';
      
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final fretes = jsonList.map((json) => FreteEG3.fromJson(json)).toList();
        
        developer.log('✅ ${fretes.length} fretes encontrados', name: 'FreteService');
        return fretes;
      } else {
        developer.log('❌ Erro ao buscar fretes: ${response.statusCode}', name: 'FreteService');
        throw Exception('Erro ao buscar fretes: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de fretes: $e', name: 'FreteService');
      rethrow;
    }
  }
  
  /// Obtém detalhes de um frete específico
  static Future<FreteEG3> getFreteDetalhes(int freteId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Buscando detalhes do frete $freteId...', name: 'FreteService');
      
      final response = await ApiClient.get(endpoints.freteDetail(freteId));
      
      if (response.statusCode == 200) {
        final frete = FreteEG3.fromJson(json.decode(response.body));
        developer.log('✅ Detalhes do frete obtidos: ${frete.codigoPublico}', name: 'FreteService');
        return frete;
      } else {
        developer.log('❌ Erro ao buscar detalhes: ${response.statusCode}', name: 'FreteService');
        throw Exception('Erro ao buscar detalhes do frete: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de detalhes: $e', name: 'FreteService');
      rethrow;
    }
  }
  
  /// Busca frete por código público
  static Future<FreteEG3?> buscarFretePorCodigo(String codigo) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🔍 Buscando frete por código: $codigo', name: 'FreteService');
      
      final response = await ApiClient.get(endpoints.fretePorCodigo(codigo));
      
      if (response.statusCode == 200) {
        final frete = FreteEG3.fromJson(json.decode(response.body));
        developer.log('✅ Frete encontrado: ${frete.codigoPublico}', name: 'FreteService');
        return frete;
      } else if (response.statusCode == 404) {
        developer.log('❌ Frete não encontrado: $codigo', name: 'FreteService');
        return null;
      } else {
        developer.log('❌ Erro ao buscar frete: ${response.statusCode}', name: 'FreteService');
        throw Exception('Erro ao buscar frete: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca por código: $e', name: 'FreteService');
      rethrow;
    }
  }
  
  /// Atualiza status do frete
  static Future<bool> atualizarStatusFrete(int freteId, String novoStatus, {String? observacoes}) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📦 Atualizando status do frete $freteId para $novoStatus', name: 'FreteService');
      
      final response = await ApiClient.post(
        endpoints.freteAtualizarStatus(freteId),
        {
          'status_novo': novoStatus,
          if (observacoes != null) 'observacoes': observacoes,
        },
      );
      
      if (response.statusCode == 200) {
        developer.log('✅ Status atualizado com sucesso', name: 'FreteService');
        return true;
      } else {
        developer.log('❌ Erro ao atualizar status: ${response.statusCode}', name: 'FreteService');
        return false;
      }
    } catch (e) {
      developer.log('❌ Erro na atualização de status: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Aceita frete (atualiza status para AGUARDANDO_CARGA)
  static Future<bool> aceitarFrete(int freteId) async {
    try {
      developer.log('✅ Aceitando frete $freteId', name: 'FreteService');
      return await atualizarStatusFrete(freteId, 'AGUARDANDO_CARGA');
    } catch (e) {
      developer.log('❌ Erro ao aceitar frete: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Recusa frete (atualiza status para CANCELADO)
  static Future<bool> recusarFrete(int freteId, {String? motivo}) async {
    try {
      developer.log('❌ Recusando frete $freteId', name: 'FreteService');
      return await atualizarStatusFrete(freteId, 'CANCELADO', observacoes: motivo);
    } catch (e) {
      developer.log('❌ Erro ao recusar frete: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Inicia carregamento
  static Future<bool> iniciarCarregamento(int freteId) async {
    try {
      developer.log('🚛 Iniciando carregamento do frete $freteId', name: 'FreteService');
      return await atualizarStatusFrete(freteId, 'AGUARDANDO_CARGA');
    } catch (e) {
      developer.log('❌ Erro ao iniciar carregamento: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Inicia viagem
  static Future<bool> iniciarViagem(int freteId) async {
    try {
      developer.log('🚛 Iniciando viagem do frete $freteId', name: 'FreteService');
      return await atualizarStatusFrete(freteId, 'EM_TRANSITO');
    } catch (e) {
      developer.log('❌ Erro ao iniciar viagem: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Chegou no destino
  static Future<bool> chegouDestino(int freteId) async {
    try {
      developer.log('📍 Chegou no destino do frete $freteId', name: 'FreteService');
      return await atualizarStatusFrete(freteId, 'EM_DESCARGA_CLIENTE');
    } catch (e) {
      developer.log('❌ Erro ao marcar chegada: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Finaliza entrega
  static Future<bool> finalizarEntrega(int freteId) async {
    try {
      developer.log('✅ Finalizando entrega do frete $freteId', name: 'FreteService');
      return await atualizarStatusFrete(freteId, 'FINALIZADO');
    } catch (e) {
      developer.log('❌ Erro ao finalizar entrega: $e', name: 'FreteService');
      return false;
    }
  }
  
  /// Obtém estatísticas de fretes
  static Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('📊 Buscando estatísticas de fretes...', name: 'FreteService');
      
      final response = await ApiClient.get(endpoints.fretesStats);
      
      if (response.statusCode == 200) {
        final stats = json.decode(response.body);
        developer.log('✅ Estatísticas obtidas', name: 'FreteService');
        return stats;
      } else {
        developer.log('❌ Erro ao buscar estatísticas: ${response.statusCode}', name: 'FreteService');
        throw Exception('Erro ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de estatísticas: $e', name: 'FreteService');
      rethrow;
    }
  }
  
  /// Filtra fretes por status
  static List<FreteEG3> filtrarPorStatus(List<FreteEG3> fretes, String status) {
    return fretes.where((frete) => frete.statusAtual == status).toList();
  }
  
  /// Filtra fretes por tipo de serviço
  static List<FreteEG3> filtrarPorTipoServico(List<FreteEG3> fretes, String tipoServico) {
    return fretes.where((frete) => frete.tipoServico == tipoServico).toList();
  }
  
  /// Ordena fretes por data de agendamento
  static List<FreteEG3> ordenarPorDataAgendamento(List<FreteEG3> fretes) {
    final sortedFretes = List<FreteEG3>.from(fretes);
    sortedFretes.sort((a, b) {
      if (a.dataHoraAgendamento == null && b.dataHoraAgendamento == null) return 0;
      if (a.dataHoraAgendamento == null) return 1;
      if (b.dataHoraAgendamento == null) return -1;
      return a.dataHoraAgendamento!.compareTo(b.dataHoraAgendamento!);
    });
    return sortedFretes;
  }
  
  /// Obtém informações de debug
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final endpoints = await _getEndpoints();
    final cpf = await StorageService.getDriverCpf();
    
    return {
      'endpoints': endpoints.debugInfo,
      'cpf_motorista': cpf,
      'url_fretes_por_motorista': endpoints.fretesPorMotorista,
    };
  }
}
