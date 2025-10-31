import '../models/sync_state.dart';
import '../models/sync_frete.dart';
import '../models/sync_event.dart';
import '../services/storage_service.dart';
import '../utils/sync_state_utils.dart';
import 'background_sync_service.dart';
import 'dart:developer' as developer;

/// Serviço de domínio para manipulação do SyncState
/// 
/// Funções puras que manipulam o estado offline sem depender de UI.
/// Baseado nas especificações do README_API_ENDPOINTS.md e cursorrules.
class SyncStateService {
  /// Faz merge não-regressivo entre o estado local e a resposta remota de rota
  ///
  /// Regras de precedência:
  /// - status_rota: CONCLUIDO=3, EM_EXECUCAO=2, PENDENTE=1
  /// - status_atual: usa tabela de precedência por tipo de serviço
  /// - Se local está mais avançado que remoto → manter local (não regredir)
  /// - Se remoto está mais avançado → aceitar remoto
  /// - Após merge, garante exatamente 1 EM_EXECUCAO quando rota está EM_ANDAMENTO
  ///
  /// Validação:
  /// - Verifica chaves essenciais do payload remoto
  /// - Trata null-safety
  /// - Logs claros de decisões de merge
  static SyncState mergeRemoteRouteIntoLocal(
    SyncState local,
    Map<String, dynamic> apiResponse,
  ) {
    developer.log('🔄 HOME-REFRESH: merge begin', name: 'SyncStateService');
    
    // Validar payload remoto
    if (!_validarPayloadRemoto(apiResponse)) {
      developer.log('⚠️ HOME-REFRESH: payload remoto inválido, mantendo local', name: 'SyncStateService');
      return local;
    }
    // Construir representação remota preservando motoristaId e metadados locais onde necessário
    final remoto = SyncState.fromApiRotaAtual(
      motoristaId: local.motoristaId,
      apiResponse: apiResponse,
      localizacaoAtual: local.localizacaoAtual,
      filaEnvioPendente: local.filaEnvioPendente,
    );

    // Índice auxiliar por freteId e por ordem
    final mapaRemotoPorId = {for (final f in remoto.fretes) f.freteId: f};
    final mapaRemotoPorOrdem = {for (final f in remoto.fretes) f.ordem: f};

    /// Rank de status_rota: CONCLUIDO=3, EM_EXECUCAO=2, PENDENTE=1
    int rankStatusRota(String s) {
      switch (s) {
        case 'PENDENTE':
          return 1;
        case 'EM_EXECUCAO':
          return 2;
        case 'CONCLUIDO':
          return 3;
        default:
          return 0;
      }
    }

    /// Rank de status_atual por tipo de serviço
    /// Maior valor = mais avançado
    int rankStatusAtual(String tipoServico, String statusAtual) {
      switch (tipoServico) {
        case 'TRANSPORTE':
          switch (statusAtual) {
            case 'NAO_INICIADO':
              return 1;
            case 'AGUARDANDO_CARGA':
              return 2;
            case 'EM_TRANSITO':
              return 3;
            case 'EM_DESCARGA':
              return 4;
            case 'EM_DESCARGA_CLIENTE':
              return 4;
            case 'FINALIZADO':
              return 5;
            default:
              return 0;
          }
        case 'MUNCK_CARGA':
          switch (statusAtual) {
            case 'CARREGAMENTO_NAO_INICIADO':
              return 1;
            case 'CARREGAMENTO_INICIADO':
              return 2;
            case 'CARREGAMENTO_CONCLUIDO':
              return 3;
            default:
              return 0;
          }
        case 'MUNCK_DESCARGA':
          switch (statusAtual) {
            case 'DESCARREGAMENTO_NAO_INICIADO':
              return 1;
            case 'DESCARREGAMENTO_INICIADO':
              return 2;
            case 'DESCARREGAMENTO_CONCLUIDO':
              return 3;
            default:
              return 0;
          }
        default:
          return 0;
      }
    }

    SyncFrete resolverFrete(SyncFrete localFrete) {
      // Tentar casar por freteId; se placeholder (-1) usar ordem
      final remotoFrete = localFrete.freteId != -1
          ? mapaRemotoPorId[localFrete.freteId]
          : mapaRemotoPorOrdem[localFrete.ordem];

      if (remotoFrete == null) {
        // Remoto não trouxe este frete: manter local como fonte da verdade
        developer.log(
          '🔒 NO-REGRESSION: frete ${localFrete.freteId} (ordem ${localFrete.ordem}) não encontrado no remoto, mantendo local',
          name: 'SyncStateService',
        );
        return localFrete;
      }

      // Resolver status_rota pelo maior rank (sem regressão)
      final localRankRota = rankStatusRota(localFrete.statusRota);
      final remotoRankRota = rankStatusRota(remotoFrete.statusRota);
      final statusRotaFinal = localRankRota >= remotoRankRota
          ? localFrete.statusRota
          : remotoFrete.statusRota;
      
      if (localRankRota > remotoRankRota) {
        developer.log(
          '🔒 NO-REGRESSION: frete ${localFrete.freteId} status_rota local (${localFrete.statusRota}) > remoto (${remotoFrete.statusRota}), mantendo local',
          name: 'SyncStateService',
        );
      }

      // Resolver status_atual pelo maior rank (sem regressão)
      final localRankStatus = rankStatusAtual(localFrete.tipoServico, localFrete.statusAtual);
      final remotoRankStatus = rankStatusAtual(remotoFrete.tipoServico, remotoFrete.statusAtual);
      final statusAtualFinal = localRankStatus >= remotoRankStatus
          ? localFrete.statusAtual
          : remotoFrete.statusAtual;
      
      if (localRankStatus > remotoRankStatus) {
        developer.log(
          '🔒 NO-REGRESSION: frete ${localFrete.freteId} status_atual local (${localFrete.statusAtual}) > remoto (${remotoFrete.statusAtual}), mantendo local',
          name: 'SyncStateService',
        );
      }

      // Para demais campos, aplicar merge aditivo do remoto (preferindo valores válidos)
      return localFrete.copyWith(
        freteId: localFrete.freteId != -1 ? localFrete.freteId : remotoFrete.freteId,
        ordem: localFrete.ordem, // manter ordem local
        statusRota: statusRotaFinal,
        statusAtual: statusAtualFinal,
        tipoServico: remotoFrete.tipoServico,
        origem: remotoFrete.origem ?? localFrete.origem,
        destino: remotoFrete.destino ?? localFrete.destino,
        clienteNome: remotoFrete.clienteNome ?? localFrete.clienteNome,
        numeroNotaFiscal: remotoFrete.numeroNotaFiscal ?? localFrete.numeroNotaFiscal,
        codigoPublico: remotoFrete.codigoPublico ?? localFrete.codigoPublico,
        origemLinkGoogle: remotoFrete.origemLinkGoogle ?? localFrete.origemLinkGoogle,
        destinoLinkGoogle: remotoFrete.destinoLinkGoogle ?? localFrete.destinoLinkGoogle,
        dataAgendamento: remotoFrete.dataAgendamento ?? localFrete.dataAgendamento,
        horaAgendamento: remotoFrete.horaAgendamento ?? localFrete.horaAgendamento,
      );
    }

    // Mapear todos os fretes locais aplicando regra de não-regressão
    final fretesMesclados = local.fretes.map(resolverFrete).toList();

    // Se o remoto trouxe fretes adicionais (não existentes localmente), anexar
    for (final fRem in remoto.fretes) {
      final existe = fretesMesclados.any((f) => 
        f.freteId == fRem.freteId || (f.freteId == -1 && f.ordem == fRem.ordem)
      );
      if (!existe) {
        developer.log(
          '➕ HOME-REFRESH: frete adicional do remoto adicionado: ${fRem.freteId} (ordem ${fRem.ordem})',
          name: 'SyncStateService',
        );
        fretesMesclados.add(fRem);
      }
    }

    // Ordenar fretes por ordem
    fretesMesclados.sort((a, b) => a.ordem.compareTo(b.ordem));

    // Resolver rotaAtiva: se local está ativo, manter; caso contrário, usar remoto
    // Mas se local indica rotaAtiva=true e remoto ainda está atrasado (ex.: PLANEJADA), manter local
    final statusRemoto = apiResponse['status'] as String?;
    final rotaAtivaRemota = statusRemoto == 'EM_ANDAMENTO';
    
    bool rotaAtivaFinal;
    if (local.rotaAtiva && !rotaAtivaRemota) {
      // Local ativo mas remoto ainda não convergiu: manter local (backend deve convergir via sync)
      rotaAtivaFinal = true;
      developer.log(
        '🔒 NO-REGRESSION: rota local ativa mas remoto ainda PLANEJADA, mantendo local ativa',
        name: 'SyncStateService',
      );
    } else {
      rotaAtivaFinal = local.rotaAtiva || rotaAtivaRemota;
    }

    // Criar estado intermediário
    final estadoIntermediario = local.copyWith(
      rotaId: remoto.rotaId ?? local.rotaId,
      rotaAtiva: rotaAtivaFinal,
      fretes: fretesMesclados,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
    );

    // Garantir exatamente 1 EM_EXECUCAO quando rota está EM_ANDAMENTO
    final estadoFinal = _garantirExatamenteUmEmExecucao(estadoIntermediario);

    developer.log(
      '✅ HOME-REFRESH: merge end - rota_id=${estadoFinal.rotaId}, rota_ativa=${estadoFinal.rotaAtiva}, fretes=${estadoFinal.fretes.length}, em_execucao=${estadoFinal.fretes.where((f) => f.statusRota == 'EM_EXECUCAO').length}',
      name: 'SyncStateService',
    );

    return estadoFinal;
  }

  /// Valida chaves essenciais do payload remoto
  static bool _validarPayloadRemoto(Map<String, dynamic> apiResponse) {
    // Validar estrutura básica (pode não ter rota_id se não há rota)
    if (apiResponse['rota_id'] != null && apiResponse['rota_id'] is! int && apiResponse['rota_id'] is! num) {
      developer.log('⚠️ Payload inválido: rota_id deve ser int ou null', name: 'SyncStateService');
      return false;
    }
    
    // Validar fretes_rota se existir
    if (apiResponse.containsKey('fretes_rota') && apiResponse['fretes_rota'] is! List) {
      developer.log('⚠️ Payload inválido: fretes_rota deve ser List ou não existir', name: 'SyncStateService');
      return false;
    }

    return true;
  }

  /// Garante exatamente 1 frete EM_EXECUCAO quando rota está EM_ANDAMENTO
  /// Se nenhum estiver em execução: ativa o primeiro não concluído
  /// Se todos concluídos: rota fica CONCLUIDA
  static SyncState _garantirExatamenteUmEmExecucao(SyncState state) {
    if (!state.rotaAtiva || state.fretes.isEmpty) {
      return state;
    }

    final fretesEmExecucao = state.fretes.where((f) => f.statusRota == 'EM_EXECUCAO').toList();
    
    // Já tem exatamente 1: perfeito
    if (fretesEmExecucao.length == 1) {
      return state;
    }

    // Tem 0 ou mais de 1: corrigir
    final fretesOrdenados = List<SyncFrete>.from(state.fretes)
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    final novosFretes = fretesOrdenados.map((f) {
      if (f.statusRota == 'CONCLUIDO') {
        return f; // manter concluído
      }
      
      // Se já tinha mais de 1 EM_EXECUCAO, manter apenas o primeiro (menor ordem)
      if (fretesEmExecucao.length > 1) {
        final primeiroEmExecucao = fretesEmExecucao.first;
        if (f.freteId == primeiroEmExecucao.freteId) {
          return f.copyWith(statusRota: 'EM_EXECUCAO');
        } else {
          return f.copyWith(statusRota: 'PENDENTE');
        }
      }
      
      // Se tinha 0, ativar o primeiro não concluído
      if (fretesEmExecucao.isEmpty) {
        final primeiroNaoConcluido = fretesOrdenados.firstWhere(
          (f) => f.statusRota != 'CONCLUIDO',
          orElse: () => fretesOrdenados.first,
        );
        if (f.freteId == primeiroNaoConcluido.freteId) {
          developer.log(
            '🔧 HOME-REFRESH: ativando primeiro frete ${f.freteId} (ordem ${f.ordem}) como EM_EXECUCAO',
            name: 'SyncStateService',
          );
          return f.copyWith(statusRota: 'EM_EXECUCAO');
        } else {
          return f.copyWith(statusRota: 'PENDENTE');
        }
      }
      
      return f;
    }).toList();

    // Verificar se todos estão concluídos
    final todosConcluidos = novosFretes.every((f) => f.statusRota == 'CONCLUIDO');
    final novaRotaAtiva = todosConcluidos ? false : state.rotaAtiva;

    if (todosConcluidos && state.rotaAtiva) {
      developer.log(
        '🏁 HOME-REFRESH: todos os fretes concluídos, desativando rota',
        name: 'SyncStateService',
      );
    }

    return state.copyWith(
      fretes: novosFretes,
      rotaAtiva: novaRotaAtiva,
    );
  }
  /// Ativa a rota localmente e libera o primeiro frete não concluído
  ///
  /// - Se já houver frete EM_EXECUCAO, retorna o estado sem alterações
  /// - Marca exatamente 1 frete como EM_EXECUCAO (o primeiro na ordem com status_rota != CONCLUIDO)
  /// - Marca os demais não concluídos como PENDENTE
  /// - Define rotaAtiva = true
  /// - Persiste imediatamente no StorageService
  static Future<SyncState> ativarPrimeiroFreteEIniciarRotaLocalmente(
    SyncState state,
  ) async {
    // Se já existe frete em execução, não altera
    final jaEmExecucao = state.fretes.any((f) => f.statusRota == 'EM_EXECUCAO');
    if (jaEmExecucao) {
      return state;
    }

    // Encontrar primeiro frete não concluído pela ordem
    final fretesOrdenados = List<SyncFrete>.from(state.fretes)
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    // Verificar se há fretes
    if (fretesOrdenados.isEmpty) {
      throw StateError('Sem fretes na rota');
    }

    final primeiroNaoConcluido = fretesOrdenados.firstWhere(
      (f) => f.statusRota != 'CONCLUIDO',
      orElse: () => fretesOrdenados.first, // Se todos estão concluídos, retornar o primeiro (permite reabrir rota)
    );

    // Aplicar regras de status_rota
    final novosFretes = state.fretes.map((f) {
      if (f.freteId == primeiroNaoConcluido.freteId) {
        return f.copyWith(statusRota: 'EM_EXECUCAO');
      }
      if (f.statusRota != 'CONCLUIDO') {
        return f.copyWith(statusRota: 'PENDENTE');
      }
      return f;
    }).toList();

    final novoState = state.copyWith(
      rotaAtiva: true,
      fretes: novosFretes,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
    );

    await StorageService.saveSyncState(novoState.toJson());

    developer.log(
      '🚚 Rota ativada localmente. Frete inicial: ${primeiroNaoConcluido.freteId}',
      name: 'SyncStateService',
    );

    return novoState;
  }
  /// Atualiza a localização atual e ultima_atualizacao no SyncState
  /// 
  /// Parâmetros:
  /// - state: SyncState atual
  /// - latitude: Nova latitude
  /// - longitude: Nova longitude
  /// 
  /// Retorna: Novo SyncState com localização atualizada
  static SyncState atualizarLocalizacao(
    SyncState state,
    double latitude,
    double longitude,
  ) {
    final novaLocalizacao = LocalizacaoAtual(
      latitude: latitude,
      longitude: longitude,
    );

    final novoState = state.copyWith(
      localizacaoAtual: novaLocalizacao,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
    );

    developer.log(
      '📍 Localização atualizada: $latitude, $longitude',
      name: 'SyncStateService',
    );

    return novoState;
  }

  /// Registra o avanço de status de um frete
  /// 
  /// Faz todas as ações necessárias:
  /// 1. Atualiza localmente o statusAtual do frete
  /// 2. Se é status final, marca statusRota como CONCLUIDO
  /// 3. (Opcional) Libera o próximo frete localmente se o backend faria isso
  /// 4. Adiciona evento na filaEnvioPendente
  /// 5. Salva SyncState em disco imediatamente
  /// 
  /// Parâmetros:
  /// - state: SyncState atual
  /// - freteId: ID do frete a atualizar
  /// - statusNovo: Novo status para aplicar
  /// - observacoes: Observações opcionais
  /// 
  /// Retorna: Novo SyncState com mudanças aplicadas
  static Future<SyncState> registrarAvancoStatus(
    SyncState state,
    int freteId,
    String statusNovo,
    String? observacoes,
  ) async {
    // Encontrar o frete na lista
    final freteIndex = state.fretes.indexWhere((f) => f.freteId == freteId);
    
    if (freteIndex == -1) {
      developer.log(
        '⚠️ Frete $freteId não encontrado no SyncState',
        name: 'SyncStateService',
      );
      return state;
    }

    final freteAtual = state.fretes[freteIndex];
    final statusAnterior = freteAtual.statusAtual;

    // 1. Atualizar status do frete localmente
    final freteAtualizado = freteAtual.copyWith(statusAtual: statusNovo);

    // 2. Verificar se é status final e marcar como CONCLUIDO na rota
    String novoStatusRota = freteAtualizado.statusRota;
    if (freteAtualizado.isStatusFinal && freteAtualizado.statusRota != 'CONCLUIDO') {
      novoStatusRota = 'CONCLUIDO';
      developer.log(
        '✅ Frete $freteId concluído - status final: $statusNovo',
        name: 'SyncStateService',
      );
    }

    final freteComStatusRota = freteAtualizado.copyWith(
      statusRota: novoStatusRota,
    );

    // 3. (Opcional) Liberar próximo frete localmente se este foi concluído
    List<SyncFrete> novosFretes = List.from(state.fretes);
    novosFretes[freteIndex] = freteComStatusRota;

    if (novoStatusRota == 'CONCLUIDO') {
      // Buscar próximo frete na ordem
      final proximaOrdem = freteComStatusRota.ordem + 1;
      final proximoFreteIndex = novosFretes.indexWhere(
        (f) => f.ordem == proximaOrdem && f.statusRota == 'PENDENTE',
      );

      if (proximoFreteIndex != -1) {
        final proximoFrete = novosFretes[proximoFreteIndex];
        // Marcar próximo frete como EM_EXECUCAO localmente
        // (O backend também fará isso, mas isso melhora a experiência offline)
        novosFretes[proximoFreteIndex] = proximoFrete.copyWith(
          statusRota: 'EM_EXECUCAO',
        );
        developer.log(
          '🔓 Próximo frete $proximaOrdem liberado localmente',
          name: 'SyncStateService',
        );
      } else {
        // Não há mais fretes pendentes, verificar se rota deve ser finalizada
        final todosConcluidos = novosFretes.every(
          (f) => f.statusRota == 'CONCLUIDO',
        );
        if (todosConcluidos) {
          developer.log(
            '🏁 Todos os fretes concluídos - rota pode ser finalizada',
            name: 'SyncStateService',
          );
        }
      }
    }

    // 4. Adicionar evento na fila de envio pendente
    final novoEvento = SyncEvent.now(
      freteId: freteId,
      statusNovo: statusNovo,
      observacoes: observacoes,
    );

    final novaFilaEnvio = List<SyncEvent>.from(state.filaEnvioPendente);
    novaFilaEnvio.add(novoEvento);

    // 5. Criar novo state
    final novoState = state.copyWith(
      fretes: novosFretes,
      filaEnvioPendente: novaFilaEnvio,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
    );

    // 6. Verificar se rota deve ser finalizada
    bool novaRotaAtiva = novoState.rotaAtiva;
    if (novosFretes.every((f) => f.statusRota == 'CONCLUIDO')) {
      novaRotaAtiva = false;
      developer.log(
        '🛑 Todos os fretes concluídos - rota_ativa = false',
        name: 'SyncStateService',
      );
    }

    final stateFinal = novoState.copyWith(rotaAtiva: novaRotaAtiva);

    // 7. Persistir em disco imediatamente
    await StorageService.saveSyncState(stateFinal.toJson());

    developer.log(
      '✅ Status atualizado: frete $freteId: $statusAnterior → $statusNovo',
      name: 'SyncStateService',
    );

    // 8. Verificar se todos concluídos e parar sync se necessário
    final stateVerificado = await verificarEPararSyncSeNecessario(stateFinal);

    return stateVerificado;
  }

  /// Remove da filaEnvioPendente os eventos confirmados pelo backend
  /// 
  /// Após chamar POST /api/fretes/motorista/sync/, o backend retorna:
  /// {
  ///   "eventos_processados_detalhes": [
  ///     {
  ///       "frete_id": 100,
  ///       "status_anterior": "EM_DESCARGA_CLIENTE",
  ///       "status_novo": "FINALIZADO",
  ///       "timestamp": "2025-01-20T10:30:00Z"
  ///     }
  ///   ],
  ///   "eventos_rejeitados_detalhes": [...]
  /// }
  /// 
  /// Esta função remove da fila os eventos processados.
  /// Eventos rejeitados são mantidos para debug/tentativa manual posterior.
  /// 
  /// Parâmetros:
  /// - state: SyncState atual
  /// - eventosProcessados: Lista de eventos processados pelo backend
  /// - eventosRejeitados: Lista de eventos rejeitados (para log/debug)
  /// 
  /// Retorna: Novo SyncState com eventos processados removidos
  static SyncState limparEventosConfirmadosDoBackend(
    SyncState state,
    List<Map<String, dynamic>> eventosProcessados,
    List<Map<String, dynamic>> eventosRejeitados,
  ) {
    // Criar conjunto de identificadores únicos dos eventos processados
    // Usamos frete_id + status_novo + timestamp para identificar
    final eventosProcessadosSet = <String>{};
    for (var evento in eventosProcessados) {
      final freteId = evento['frete_id'] as int? ?? evento['freteId'] as int?;
      final statusNovo = evento['status_novo'] as String? ?? evento['statusNovo'] as String?;
      final timestamp = evento['timestamp'] as String?;
      
      if (freteId != null && statusNovo != null && timestamp != null) {
        eventosProcessadosSet.add('$freteId|$statusNovo|$timestamp');
      }
    }

    // Filtrar fila removendo eventos que foram processados
    final novaFilaEnvio = state.filaEnvioPendente.where((evento) {
      final identificador = '${evento.freteId}|${evento.statusNovo}|${evento.timestamp}';
      final foiProcessado = eventosProcessadosSet.contains(identificador);
      
      if (foiProcessado) {
        developer.log(
          '✅ Evento confirmado e removido: frete ${evento.freteId}, status ${evento.statusNovo}',
          name: 'SyncStateService',
        );
      }
      
      return !foiProcessado;
    }).toList();

    // Log de eventos rejeitados (mantidos na fila)
    if (eventosRejeitados.isNotEmpty) {
      developer.log(
        '⚠️ ${eventosRejeitados.length} evento(s) rejeitado(s) pelo backend - mantidos na fila',
        name: 'SyncStateService',
      );
      for (var eventoRejeitado in eventosRejeitados) {
        developer.log(
          '  ⚠️ Rejeitado: ${eventoRejeitado['motivo']}',
          name: 'SyncStateService',
        );
      }
    }

    final novoState = state.copyWith(
      filaEnvioPendente: novaFilaEnvio,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
    );

    return novoState;
  }

  /// Atualiza SyncState a partir da resposta do endpoint GET /api/fretes/motorista/rota-atual/
  /// 
  /// Preserva localização atual e fila de envio pendente existentes.
  /// 
  /// Parâmetros:
  /// - stateAtual: SyncState atual (para preservar localização e fila)
  /// - apiResponse: Resposta JSON do endpoint rota-atual
  /// 
  /// Retorna: Novo SyncState atualizado
  static SyncState atualizarSyncStateDesdeApi(
    SyncState stateAtual,
    Map<String, dynamic> apiResponse,
  ) {
    final novoState = SyncState.fromApiRotaAtual(
      motoristaId: stateAtual.motoristaId,
      apiResponse: apiResponse,
      localizacaoAtual: stateAtual.localizacaoAtual,
      filaEnvioPendente: stateAtual.filaEnvioPendente,
    );

    developer.log(
      '🔄 SyncState atualizado da API: rota ${novoState.rotaId}, ${novoState.fretes.length} fretes',
      name: 'SyncStateService',
    );

    return novoState;
  }

  /// Prepara payload para POST /api/fretes/motorista/sync/
  /// 
  /// Converte SyncState para o formato esperado pelo endpoint de sync
  /// 
  /// Parâmetros:
  /// - state: SyncState atual
  /// - freteIdEmExecucao: ID do frete em execução (opcional)
  /// 
  /// Retorna: Map pronto para enviar ao backend
  static Map<String, dynamic> prepararPayloadSync(
    SyncState state,
    int? freteIdEmExecucao,
  ) {
    return {
      'latitude': state.localizacaoAtual.latitude,
      'longitude': state.localizacaoAtual.longitude,
      if (freteIdEmExecucao != null) 'frete_id_em_execucao': freteIdEmExecucao,
      'eventos_pendentes': state.filaEnvioPendente
          .map((e) => e.toJson())
          .toList(),
    };
  }

  /// Verifica se há eventos pendentes na fila
  static bool temEventosPendentes(SyncState state) {
    return state.filaEnvioPendente.isNotEmpty;
  }

  /// Conta quantos eventos estão pendentes
  static int contarEventosPendentes(SyncState state) {
    return state.filaEnvioPendente.length;
  }

  /// Verifica se todos os fretes estão concluídos e para o sync se necessário
  /// 
  /// Chamado após registrarAvancoStatus quando todos os fretes ficam CONCLUIDO
  static Future<SyncState> verificarEPararSyncSeNecessario(SyncState state) async {
    final todosConcluidos = state.fretes.every(
      (f) => f.statusRota == 'CONCLUIDO',
    );

    if (todosConcluidos && state.rotaAtiva) {
      developer.log(
        '🏁 Todos os fretes concluídos - desativando rota e parando sync',
        name: 'SyncStateService',
      );

      final stateFinal = state.copyWith(
        rotaAtiva: false,
        ultimaAtualizacao: DateTime.now().toIso8601String(),
      );

      await SyncStateUtils.saveSyncState(stateFinal);

      // Parar o serviço de sync em background
      try {
        await BackgroundSyncService.stopBackgroundSyncLoop();
      } catch (e) {
        developer.log(
          '⚠️ Erro ao parar BackgroundSyncService: $e',
          name: 'SyncStateService',
        );
        // Não falha - o sync vai parar na próxima verificação de rota_ativa
      }

      return stateFinal;
    }

    return state;
  }

  /// Cancela a rota localmente, preservando apenas fretes CONCLUIDO
  /// - Define rotaAtiva = false
  /// - Remove da lista os fretes não concluídos
  /// - Persiste imediatamente e tenta parar o background
  static Future<SyncState> cancelarRotaLocalmente(SyncState state) async {
    final fretesPreservados = state.fretes.where((f) => f.statusRota == 'CONCLUIDO').toList();

    final novoState = state.copyWith(
      rotaAtiva: false,
      fretes: fretesPreservados,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
    );

    await StorageService.saveSyncState(novoState.toJson());

    try {
      await BackgroundSyncService.stopBackgroundSyncLoop(reason: 'manual');
    } catch (_) {}

    return novoState;
  }
}

// Helper para importação dinâmica
dynamic import(String module) => throw UnimplementedError('Use import statement');

