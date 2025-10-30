import 'dart:convert';
import '../config/api_endpoints.dart';
import '../models/sync_state.dart';
import '../models/sync_frete.dart';
import '../services/api_client.dart';
import '../utils/sync_state_utils.dart';
import '../services/sync_state_service.dart';
import 'dart:developer' as developer;

/// Serviço de API para operações relacionadas a rotas do motorista
/// Baseado no README_API_ENDPOINTS.md
class RotaService {
  /// Incremental: GET count
  static Future<Map<String, dynamic>> getRotaAtualCount() async {
    final endpoints = ApiEndpoints();
    final url = endpoints.mobileRotaAtualCount;
    developer.log('GET $url', name: 'RotaService');
    final response = await ApiClient.get(url, requiresAuth: true);
    if (response.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (response.statusCode == 409) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw ConflictException(body['message'] ?? 'Rota inconsistente');
    }
    if (response.statusCode != 200) {
      throw Exception('Erro (${response.statusCode}) ao obter count');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Incremental: GET info (sem fretes)
  static Future<Map<String, dynamic>> getRotaAtualInfo() async {
    final endpoints = ApiEndpoints();
    final url = endpoints.mobileRotaAtualInfo;
    developer.log('GET $url', name: 'RotaService');
    final response = await ApiClient.get(url, requiresAuth: true);
    if (response.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (response.statusCode == 409) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw ConflictException(body['message'] ?? 'Rota inconsistente');
    }
    if (response.statusCode != 200) {
      throw Exception('Erro (${response.statusCode}) ao obter info');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Incremental: GET frete por índice com 1 retry simples
  static Future<Map<String, dynamic>> getFreteByIndex(
    int rotaId,
    int index,
  ) async {
    final endpoints = ApiEndpoints();
    final url = endpoints.mobileFreteByIndex(rotaId, index);
    developer.log('GET $url', name: 'RotaService');
    var response = await ApiClient.get(url, requiresAuth: true);
    if (response.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (response.statusCode == 409) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw ConflictException(body['message'] ?? 'Rota inconsistente');
    }
    // Retry leve (ex.: instabilidades momentâneas)
    if (response.statusCode >= 500) {
      developer.log('Retry frete index=$index', name: 'RotaService');
      response = await ApiClient.get(url, requiresAuth: true);
    }
    if (response.statusCode != 200) {
      throw Exception('Erro (${response.statusCode}) ao obter frete index=$index');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Busca a rota atual do motorista do backend
  /// 
  /// Faz GET /api/fretes/motorista/rota-atual/ com Authorization: Token <token>
  /// 
  /// Retorna o JSON da resposta ou lança exceção em caso de erro
  static Future<Map<String, dynamic>> getRotaAtual() async {
    try {
      final session = await SyncStateUtils.loadDriverSession();
      if (session == null || !session.isValid) {
        throw Exception('Sessão inválida. Faça login novamente.');
      }

      final endpoints = ApiEndpoints();
      final url = endpoints.motoristaRotaCompleta;
      
      developer.log('GET $url', name: 'RotaService');
      final response = await ApiClient.get(url, requiresAuth: true);
      developer.log('Response: ${response.statusCode}', name: 'RotaService');
      developer.log('Body: ${response.body}', name: 'RotaService');
      
      // Erro
      if (response.statusCode != 200) {
        try {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['error'] ?? errorBody['message'] ?? 'Erro ao buscar rota');
        } catch (_) {
          throw Exception('Erro ao buscar rota (${response.statusCode})');
        }
      }
      
      // Parse resposta
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
        developer.log('Parsed data: $responseData', name: 'RotaService');
      } catch (e) {
        developer.log('JSON Parse error: $e', name: 'RotaService');
        throw Exception('Erro ao processar resposta: $e');
      }
      
      // TESTE: Extrair todos os dados recebidos
      final rotaId = responseData['rota_id'];
      final nomeRota = responseData['nome_rota'];
      final status = responseData['status'];
      final totalFretes = responseData['total_fretes'];
      final fretesConcluidos = responseData['fretes_concluidos'];
      
      developer.log('Dados recebidos (5 campos):', name: 'RotaService');
      developer.log('  rota_id: $rotaId (type: ${rotaId?.runtimeType})', name: 'RotaService');
      developer.log('  nome_rota: $nomeRota (type: ${nomeRota?.runtimeType})', name: 'RotaService');
      developer.log('  status: $status (type: ${status?.runtimeType})', name: 'RotaService');
      developer.log('  total_fretes: $totalFretes (type: ${totalFretes?.runtimeType})', name: 'RotaService');
      developer.log('  fretes_concluidos: $fretesConcluidos (type: ${fretesConcluidos?.runtimeType})', name: 'RotaService');
      
      if (rotaId == null) {
        return {
          'rota_id': null,
          'status': null,
          'fretes_rota': [],
          'message': 'Nenhuma rota ativa encontrada',
        };
      }
      
      // Retornar estrutura com os 5 campos recebidos
      return {
        'rota_id': rotaId,
        'nome_rota': nomeRota,
        'status': status,
        'total_fretes': totalFretes ?? 0,
        'fretes_concluidos': fretesConcluidos ?? 0,
        'fretes_rota': [],
      };
      
    } on UnauthorizedException {
      developer.log('Token inválido', name: 'RotaService');
      rethrow;
    } catch (e) {
      developer.log('Erro: $e', name: 'RotaService');
      rethrow;
    }
  }

  /// Sincroniza a rota atual do servidor com o estado local
  /// 
  /// 1. Chama getRotaAtual()
  /// 2. Constrói/atualiza SyncState usando SyncState.fromApiRotaAtual()
  /// 3. Define rotaAtiva baseado no status (EM_ANDAMENTO => true)
  /// 4. Salva SyncState via saveSyncState()
  /// 
  /// Preserva localização atual e fila de eventos pendentes do estado anterior
  static Future<void> sincronizarRotaAtualDoServidor() async {
    try {
      developer.log('🔄 Iniciando sincronização da rota atual', name: 'RotaService');

      // 1. Carregar sessão
      final session = await SyncStateUtils.loadDriverSession();
      if (session == null || !session.isValid) {
        throw Exception('Sessão inválida. Faça login novamente.');
      }

      // 2. Carregar estado atual para preservar localização e fila
      final stateAtual = await SyncStateUtils.loadSyncState();

      // 3. Buscar rota do servidor
      final apiResponse = await getRotaAtual();

      // 4. Construir/atualizar SyncState com regra de não-regressão se rota ativa/local em execução
      final status = apiResponse['status'] as String?;
      final rotaAtivaRemota = status == 'EM_ANDAMENTO';

      SyncState stateFinal;
      if (stateAtual != null && (stateAtual.rotaAtiva || stateAtual.freteAtual != null)) {
        // Fonte da verdade local: aplicar merge não-regressivo
        stateFinal = SyncStateService.mergeRemoteRouteIntoLocal(stateAtual, apiResponse);
      } else {
        // Sem rota ativa local: pode substituir normalmente
        final novoState = SyncState.fromApiRotaAtual(
          motoristaId: session.motoristaId,
          apiResponse: apiResponse,
          localizacaoAtual: stateAtual?.localizacaoAtual,
          filaEnvioPendente: stateAtual?.filaEnvioPendente ?? [],
        );
        stateFinal = novoState.copyWith(rotaAtiva: rotaAtivaRemota);
      }

      // 5. Salvar SyncState
      await SyncStateUtils.saveSyncState(stateFinal);

      developer.log(
        '✅ Rota sincronizada: rota_id=${stateFinal.rotaId}, rota_ativa=${stateFinal.rotaAtiva}, fretes=${stateFinal.fretes.length}',
        name: 'RotaService',
      );
    } catch (e) {
      developer.log('❌ Erro ao sincronizar rota: $e', name: 'RotaService');
      rethrow;
    }
  }

  /// Fluxo incremental completo: count → info → loop por índice
  /// Atualiza o SyncState progressivamente a cada frete recebido
  static Future<void> carregarRotaIncremental({
    void Function(int totalFretes)? onCount,
    void Function(Map<String, dynamic> rotaInfo)? onInfo,
    void Function(SyncFrete frete)? onFrete,
  }) async {
    final session = await SyncStateUtils.loadDriverSession();
    if (session == null || !session.isValid) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    // Count
    final countResp = await getRotaAtualCount();
    final hasRota = countResp['has_rota'] == true;
    if (!hasRota) {
      final vazio = SyncState.semRota(motoristaId: session.motoristaId);
      await SyncStateUtils.saveSyncState(vazio);
      onCount?.call(0);
      return;
    }
    final rotaId = countResp['rota_id'] as int;
    final totalFretes = (countResp['total_fretes'] as num?)?.toInt() ?? 0;
    onCount?.call(totalFretes);

    // Info
    final infoResp = await getRotaAtualInfo();
    if (infoResp['has_rota'] != true) {
      final vazio = SyncState.semRota(motoristaId: session.motoristaId);
      await SyncStateUtils.saveSyncState(vazio);
      return;
    }
    final rota = infoResp['rota'] as Map<String, dynamic>;
    onInfo?.call(rota);

    // Inicializar estado local com placeholders
    final stateAtual = await SyncStateUtils.loadSyncState();
    final baseState = SyncState(
      motoristaId: session.motoristaId,
      rotaId: rotaId,
      rotaAtiva: (rota['status'] as String?) == 'EM_ANDAMENTO',
      ultimaAtualizacao: DateTime.now().toIso8601String(),
      localizacaoAtual: stateAtual?.localizacaoAtual ?? const LocalizacaoAtual(latitude: 0, longitude: 0),
      fretes: List.generate(totalFretes, (i) =>
        // Placeholder mínimo (ordem = i+1, pendente)
        SyncFrete(
          freteId: -1,
          ordem: i + 1,
          statusRota: 'PENDENTE',
          statusAtual: 'NAO_INICIADO',
          tipoServico: 'TRANSPORTE',
        )
      ),
      filaEnvioPendente: stateAtual?.filaEnvioPendente ?? [],
    );
    await SyncStateUtils.saveSyncState(baseState);

    // Loop por index 0..N-1
    for (var i = 0; i < totalFretes; i++) {
      try {
        final f = await getFreteByIndex(rotaId, i);
        final syncFrete = SyncFrete.fromApiRotaAtual(f);

        // Atualizar storage incremental
        final s = await SyncStateUtils.loadSyncState();
        if (s != null && s.rotaId == rotaId && s.fretes.length == totalFretes) {
          final novaLista = List<SyncFrete>.from(s.fretes);
          // posicionar pela ordem (1-based)
          final pos = (syncFrete.ordem - 1);
          if (pos >= 0 && pos < novaLista.length) {
            novaLista[pos] = syncFrete;
          } else {
            // fallback: substituir pelo índice do loop
            novaLista[i] = syncFrete;
          }
          final s2 = s.copyWith(
            fretes: novaLista,
            ultimaAtualizacao: DateTime.now().toIso8601String(),
          );
          await SyncStateUtils.saveSyncState(s2);
          onFrete?.call(syncFrete);
        }
      } catch (_) {
        // Erro individual do frete: segue adiante (UI pode manter placeholder)
      }
    }
  }

  /// Inicia a rota explicitamente e recarrega incrementalmente depois (chamada pela Home)
  static Future<void> iniciarRota(int rotaId) async {
    final endpoints = ApiEndpoints();
    final url = endpoints.mobileIniciarRota(rotaId);
    developer.log('POST $url', name: 'RotaService');
    final resp = await ApiClient.post(url, {}, requiresAuth: true);
    if (resp.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (resp.statusCode == 409) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      throw ConflictException(body['message'] ?? 'Rota inconsistente');
    }
    if (resp.statusCode != 200) {
      throw Exception('Erro (${resp.statusCode}) ao iniciar rota');
    }
  }

  /// Cancelar a rota atual do motorista (mobile)
  /// POST /api/mobile/motorista/rota-atual/cancelar/
  static Future<Map<String, dynamic>> cancelarRotaAtual() async {
    final endpoints = ApiEndpoints();
    final url = endpoints.mobileCancelarRotaAtual;
    developer.log('POST $url', name: 'RotaService');
    final resp = await ApiClient.post(url, {}, requiresAuth: true);
    if (resp.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (resp.statusCode == 409) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      throw ConflictException(body['message'] ?? 'Rota inconsistente');
    }
    if (resp.statusCode != 200) {
      throw Exception('Erro (${resp.statusCode}) ao cancelar rota');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }
}

