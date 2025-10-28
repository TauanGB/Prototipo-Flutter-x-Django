import 'dart:convert';
import 'package:frontend/config/api_endpoints.dart';
import 'package:frontend/models/rota.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/storage_service.dart';
import 'dart:developer' as developer;

/// Serviço de rotas integrado com SistemaEG3
/// Gerencia rotas do motorista com autenticação por token
class RotaService {
  static ApiEndpoints? _endpoints;
  
  /// Obtém endpoints configurados
  static Future<ApiEndpoints> _getEndpoints() async {
    if (_endpoints == null) {
      _endpoints = ApiEndpoints();
    }
    return _endpoints!;
  }
  
  /// Lista rotas do motorista logado
  static Future<List<Rota>> getRotas() async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🛣️ Buscando rotas...', name: 'RotaService');
      
      final response = await ApiClient.get(endpoints.rotas);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final rotas = jsonList.map((json) => Rota.fromJson(json)).toList();
        
        developer.log('✅ ${rotas.length} rotas encontradas', name: 'RotaService');
        return rotas;
      } else {
        developer.log('❌ Erro ao buscar rotas: ${response.statusCode}', name: 'RotaService');
        throw Exception('Erro ao buscar rotas: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de rotas: $e', name: 'RotaService');
      rethrow;
    }
  }
  
  /// Obtém detalhes de uma rota específica
  static Future<Rota> getRotaDetalhes(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🛣️ Buscando detalhes da rota $rotaId...', name: 'RotaService');
      
      final response = await ApiClient.get(endpoints.rotaDetail(rotaId));
      
      if (response.statusCode == 200) {
        final rota = Rota.fromJson(json.decode(response.body));
        developer.log('✅ Detalhes da rota obtidos: ${rota.nome}', name: 'RotaService');
        return rota;
      } else {
        developer.log('❌ Erro ao buscar detalhes: ${response.statusCode}', name: 'RotaService');
        throw Exception('Erro ao buscar detalhes da rota: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro na busca de detalhes: $e', name: 'RotaService');
      rethrow;
    }
  }
  
  /// Inicia uma rota
  static Future<bool> iniciarRota(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🚀 Iniciando rota $rotaId', name: 'RotaService');
      
      final response = await ApiClient.post(
        endpoints.rotaIniciar(rotaId),
        {},
      );
      
      if (response.statusCode == 200) {
        developer.log('✅ Rota iniciada com sucesso', name: 'RotaService');
        return true;
      } else {
        developer.log('❌ Erro ao iniciar rota: ${response.statusCode}', name: 'RotaService');
        return false;
      }
    } catch (e) {
      developer.log('❌ Erro ao iniciar rota: $e', name: 'RotaService');
      return false;
    }
  }
  
  /// Conclui uma rota
  static Future<bool> concluirRota(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🏁 Concluindo rota $rotaId', name: 'RotaService');
      
      final response = await ApiClient.post(
        endpoints.rotaConcluir(rotaId),
        {},
      );
      
      if (response.statusCode == 200) {
        developer.log('✅ Rota concluída com sucesso', name: 'RotaService');
        return true;
      } else {
        developer.log('❌ Erro ao concluir rota: ${response.statusCode}', name: 'RotaService');
        return false;
      }
    } catch (e) {
      developer.log('❌ Erro ao concluir rota: $e', name: 'RotaService');
      return false;
    }
  }
  
  /// Sugere ordem de fretes para uma rota
  static Future<List<Map<String, dynamic>>?> sugerirOrdemRota(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🧭 Sugerindo ordem para rota $rotaId', name: 'RotaService');
      
      final response = await ApiClient.post(
        endpoints.rotaSugerirOrdem,
        {'rota_id': rotaId},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final sugestoes = jsonList.cast<Map<String, dynamic>>();
        developer.log('✅ Ordem sugerida: ${sugestoes.length} fretes', name: 'RotaService');
        return sugestoes;
      } else {
        developer.log('❌ Erro ao sugerir ordem: ${response.statusCode}', name: 'RotaService');
        return null;
      }
    } catch (e) {
      developer.log('❌ Erro ao sugerir ordem: $e', name: 'RotaService');
      return null;
    }
  }
  
  /// Atualiza ordem dos fretes na rota
  static Future<bool> atualizarOrdemFretes(int rotaId, List<int> fretesIds) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🔄 Atualizando ordem dos fretes na rota $rotaId', name: 'RotaService');
      
      final response = await ApiClient.post(
        endpoints.rotaAtualizarOrdem(rotaId),
        {
          'fretes_ids': fretesIds,
        },
      );
      
      if (response.statusCode == 200) {
        developer.log('✅ Ordem atualizada com sucesso', name: 'RotaService');
        return true;
      } else {
        developer.log('❌ Erro ao atualizar ordem: ${response.statusCode}', name: 'RotaService');
        return false;
      }
    } catch (e) {
      developer.log('❌ Erro ao atualizar ordem: $e', name: 'RotaService');
      return false;
    }
  }
  
  /// Filtra rotas por status
  static List<Rota> filtrarPorStatus(List<Rota> rotas, String status) {
    return rotas.where((rota) => rota.status == status).toList();
  }
  
  /// Filtra rotas ativas (planejadas e em andamento)
  static List<Rota> filtrarAtivas(List<Rota> rotas) {
    return rotas.where((rota) => rota.isPlanejada || rota.isEmAndamento).toList();
  }
  
  /// Filtra rotas concluídas
  static List<Rota> filtrarConcluidas(List<Rota> rotas) {
    return rotas.where((rota) => rota.isConcluida).toList();
  }
  
  /// Ordena rotas por data de criação
  static List<Rota> ordenarPorDataCriacao(List<Rota> rotas) {
    final sortedRotas = List<Rota>.from(rotas);
    sortedRotas.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
    return sortedRotas;
  }
  
  /// Ordena rotas por progresso
  static List<Rota> ordenarPorProgresso(List<Rota> rotas) {
    final sortedRotas = List<Rota>.from(rotas);
    sortedRotas.sort((a, b) => b.progressoPercentual.compareTo(a.progressoPercentual));
    return sortedRotas;
  }
  
  /// Obtém estatísticas das rotas
  static Map<String, dynamic> getEstatisticas(List<Rota> rotas) {
    final total = rotas.length;
    final planejadas = rotas.where((r) => r.isPlanejada).length;
    final emAndamento = rotas.where((r) => r.isEmAndamento).length;
    final concluidas = rotas.where((r) => r.isConcluida).length;
    final canceladas = rotas.where((r) => r.isCancelada).length;
    
    final totalFretes = rotas.fold<int>(0, (sum, rota) => sum + rota.totalFretes);
    final fretesConcluidos = rotas.fold<int>(0, (sum, rota) => sum + rota.fretesConcluidos);
    
    final progressoMedio = total > 0 ? rotas.fold<double>(0, (sum, rota) => sum + rota.progressoPercentual) / total : 0.0;
    
    return {
      'total_rotas': total,
      'rotas_planejadas': planejadas,
      'rotas_em_andamento': emAndamento,
      'rotas_concluidas': concluidas,
      'rotas_canceladas': canceladas,
      'total_fretes': totalFretes,
      'fretes_concluidos': fretesConcluidos,
      'progresso_medio': progressoMedio,
    };
  }
  
  /// Obtém informações de debug
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final endpoints = await _getEndpoints();
    final motoristaId = await StorageService.getDriverId();
    
    return {
      'endpoints': endpoints.debugInfo,
      'motorista_id': motoristaId,
      'url_rotas': endpoints.rotas,
    };
  }
}
