import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/sync_state_service.dart';
import '../utils/sync_state_utils.dart';
import '../services/storage_service.dart';

/// Serviço de sincronização periódica em background
/// 
/// Executa sync com o backend a cada SYNC_INTERVAL_SECONDS quando rota_ativa = true
/// Baseado no README_API_ENDPOINTS.md endpoint POST /api/fretes/motorista/sync/
class BackgroundSyncService {
  static Timer? _syncTimer;
  static bool _isRunning = false;
  static String? _lastStopReason; // '401', 'rota_inativa', 'manual', 'concluida', 'erro'

  // Notificadores para UI
  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> lastStopReasonNotifier = ValueNotifier<String?>(null);

  /// Inicia o loop de sincronização periódica
  /// 
  /// Verifica se rota_ativa = true antes de iniciar
  /// Usa SYNC_INTERVAL_SECONDS para frequência
  static Future<void> startBackgroundSyncLoop() async {
    // Se já está rodando, parar primeiro para reiniciar limpo
    if (_isRunning) {
      developer.log('⚠️ BackgroundSyncService já está rodando - reiniciando...', name: 'BackgroundSyncService');
      await stopBackgroundSyncLoop();
      // Aguardar um pouco para garantir que o timer anterior foi cancelado
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Verificar condição mestre antes de iniciar: rotaAtiva OU frete EM_EXECUCAO
    final state = await SyncStateUtils.loadSyncState();
    final podeRodar = state != null && (state.rotaAtiva || state.freteAtual != null);
    if (!podeRodar) {
      developer.log(
        'ℹ️ Sem condições para rodar (rota inativa e nenhum frete em execução) - sync não iniciado',
        name: 'BackgroundSyncService',
      );
      return;
    }

    developer.log(
      '🚀 Iniciando BackgroundSyncService (intervalo: ${AppConfig.SYNC_INTERVAL_SECONDS}s)',
      name: 'BackgroundSyncService',
    );

    _isRunning = true;
    _lastStopReason = null;
    isRunningNotifier.value = true;
    lastStopReasonNotifier.value = null;

    // Executar primeiro sync imediatamente
    await performSyncTick();

    // Configurar timer periódico
    _syncTimer = Timer.periodic(
      Duration(seconds: AppConfig.SYNC_INTERVAL_SECONDS),
      (timer) async {
        // Verificar se ainda está rodando (pode ter sido parado)
        if (!_isRunning) {
          timer.cancel();
          return;
        }

        // Verificar condição mestre continuamente
        final currentState = await SyncStateUtils.loadSyncState();
        final aindaPodeRodar = currentState != null && (currentState.rotaAtiva || currentState.freteAtual != null);
        if (!aindaPodeRodar) {
          developer.log(
            '🛑 Condição para rodar não atendida (rota inativa e nenhum frete em execução) - parando sync',
            name: 'BackgroundSyncService',
          );
          await stopBackgroundSyncLoop(reason: 'rota_inativa');
          timer.cancel();
          return;
        }

        await performSyncTick();
      },
    );
  }

  /// Para o loop de sincronização
  static Future<void> stopBackgroundSyncLoop({String? reason}) async {
    if (!_isRunning) {
      developer.log('ℹ️ BackgroundSyncService não está rodando', name: 'BackgroundSyncService');
      return;
    }

    developer.log('🛑 Parando BackgroundSyncService', name: 'BackgroundSyncService');

    _isRunning = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    _lastStopReason = reason;
    isRunningNotifier.value = false;
    lastStopReasonNotifier.value = reason;
  }

  /// Verifica se o serviço está rodando
  static bool get isRunning => _isRunning;
  static String? get lastStopReason => _lastStopReason;

  /// Executa UMA iteração de sincronização
  /// 
  /// 1. Carrega DriverSession e SyncState
  /// 2. Verifica se rota_ativa = true
  /// 3. Captura localização atual
  /// 4. Atualiza SyncState com localização
  /// 5. Prepara payload para POST /api/fretes/motorista/sync/
  /// 6. Envia requisição
  /// 7. Processa resposta e limpa eventos confirmados
  static Future<void> performSyncTick() async {
    try {
      developer.log('🔄 Executando sync tick...', name: 'BackgroundSyncService');

      // 1. Carregar DriverSession
      final session = await SyncStateUtils.loadDriverSession();
      if (session == null || !session.isValid) {
        developer.log(
          '❌ Sessão inválida - parando sync',
          name: 'BackgroundSyncService',
        );
        await stopBackgroundSyncLoop(reason: '401');
        return;
      }

      // 2. Carregar SyncState
      final state = await SyncStateUtils.loadSyncState();
      if (state == null) {
        developer.log(
          '❌ SyncState não encontrado - encerrando cedo',
          name: 'BackgroundSyncService',
        );
        return;
      }

      // 3a. Se houver cancelamento pendente, priorizar este envio
      try {
        final pending = await StorageService.getString('pending_cancel_route');
        if (pending == '1') {
          final endpoints = ApiEndpoints();
          final urlCancel = endpoints.mobileCancelarRotaAtual;
          developer.log('📤 Enviando cancelamento de rota pendente...', name: 'BackgroundSyncService');
          final respCancel = await ApiClient.post(urlCancel, {}, requiresAuth: true);
          if (respCancel.statusCode == 200) {
            await StorageService.remove('pending_cancel_route');
            // Após cancelar no backend, parar o loop
            await stopBackgroundSyncLoop(reason: 'manual');
            return;
          }
        }
      } catch (_) {}

      // 3b. Verificar se rota está ativa
      if (!state.rotaAtiva) {
        developer.log(
          'ℹ️ Rota não está ativa - encerrando cedo',
          name: 'BackgroundSyncService',
        );
        return;
      }

      // 4. Capturar localização atual
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        developer.log(
          '⚠️ Não foi possível obter localização - pulando sync',
          name: 'BackgroundSyncService',
        );
        return;
      }

      // 5. Atualizar SyncState com localização
      final stateComLocalizacao = SyncStateService.atualizarLocalizacao(
        state,
        position.latitude,
        position.longitude,
      );
      await SyncStateUtils.saveSyncState(stateComLocalizacao);

      // 6. Detectar frete em execução
      final freteEmExecucao = stateComLocalizacao.freteAtual;
      final freteIdEmExecucao = freteEmExecucao?.freteId;

      // 7. Preparar payload
      final payload = SyncStateService.prepararPayloadSync(
        stateComLocalizacao,
        freteIdEmExecucao,
      );

      developer.log(
        '📤 Enviando sync: lat=${payload['latitude']}, lon=${payload['longitude']}, eventos=${payload['eventos_pendentes'].length}',
        name: 'BackgroundSyncService',
      );

      // 8. Enviar requisição POST /api/fretes/motorista/sync/
      final endpoints = ApiEndpoints();
      final url = endpoints.syncMotorista;

      final response = await ApiClient.post(
        url,
        payload,
        requiresAuth: true,
      );

      // 9. Processar resposta
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        final eventosProcessados = 
            responseData['eventos_processados_detalhes'] as List<dynamic>? ?? [];
        final eventosRejeitados = 
            responseData['eventos_rejeitados_detalhes'] as List<dynamic>? ?? [];

        developer.log(
          '✅ Sync bem-sucedido: ${eventosProcessados.length} processados, ${eventosRejeitados.length} rejeitados',
          name: 'BackgroundSyncService',
        );

        // 10. Limpar eventos confirmados do backend
        final stateAtualizado = SyncStateService.limparEventosConfirmadosDoBackend(
          stateComLocalizacao,
          eventosProcessados.map((e) => e as Map<String, dynamic>).toList(),
          eventosRejeitados.map((e) => e as Map<String, dynamic>).toList(),
        );

        // 11. Salvar SyncState atualizado
        await SyncStateUtils.saveSyncState(stateAtualizado);

      } else if (response.statusCode == 401) {
        // Token inválido/expirado
        developer.log(
          '🔒 Token inválido/expirado - parando sync',
          name: 'BackgroundSyncService',
        );
        await stopBackgroundSyncLoop(reason: '401');
      } else if (response.statusCode == 409) {
        // Conflito de rota/frete - registrar para UI exibir banner
        try {
          await StorageService.setString('sync_last_error_code', '409');
          await StorageService.setString('sync_last_error_message', 'Rota inconsistente no servidor. Corrija a rota no sistema web.');
        } catch (_) {}
        developer.log(
          '⚠️ Conflito (409) no sync - sinalizado para UI',
          name: 'BackgroundSyncService',
        );
        // Parar o loop conforme regra de stop seguro para 409
        await stopBackgroundSyncLoop(reason: '409');
      } else {
        // Outro erro HTTP
        developer.log(
          '⚠️ Erro HTTP ${response.statusCode} no sync - mantendo fila pendente',
          name: 'BackgroundSyncService',
        );
        // NÃO limpar fila em caso de erro - deixar para próxima execução
      }
    } on UnauthorizedException {
      developer.log(
        '🔒 Não autorizado - parando sync',
        name: 'BackgroundSyncService',
      );
      await stopBackgroundSyncLoop(reason: '401');
    } catch (e) {
      // Erro de rede/timeout/etc - não limpar fila, apenas logar
      developer.log(
        '❌ Erro no sync tick: $e - mantendo fila pendente para próxima execução',
        name: 'BackgroundSyncService',
      );
      // NÃO limpar fila - deixar para próxima execução
    }
  }
}

