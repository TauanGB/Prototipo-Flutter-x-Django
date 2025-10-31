import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  
  // Instância de notificações
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  // Notificadores para UI
  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> lastStopReasonNotifier = ValueNotifier<String?>(null);

  /// Inicializa o serviço de notificações (chamar no init do app)
  static Future<void> initializeNotifications() async {
    if (_notificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings);
    _notificationsInitialized = true;
    developer.log('✅ BG-SYNC: Notificações inicializadas', name: 'BackgroundSyncService');
  }

  /// Exibe notificação de sincronização
  static Future<void> _showSyncNotification() async {
    if (!_notificationsInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'eg3_sync_channel',
      'EG3 Driver - Sincronização',
      channelDescription: 'Notificações de sincronização de rota em segundo plano',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      1001,
      'EG3 Driver',
      'Sincronizando rota...',
      notificationDetails,
    );
    developer.log('📱 BG-SYNC: Notificação exibida', name: 'BackgroundSyncService');
  }

  /// Remove notificação de sincronização
  static Future<void> _hideSyncNotification() async {
    if (!_notificationsInitialized) return;
    await _notifications.cancel(1001);
    developer.log('📱 BG-SYNC: Notificação removida', name: 'BackgroundSyncService');
  }

  /// Inicia o loop de sincronização periódica
  /// 
  /// Verifica se rota_ativa = true antes de iniciar
  /// Usa SYNC_INTERVAL_SECONDS para frequência
  static Future<void> startBackgroundSyncLoop() async {
    // Se já está rodando, parar primeiro para reiniciar limpo
    if (_isRunning) {
      developer.log('⚠️ BG-SYNC: start (reiniciando - já estava rodando)', name: 'BackgroundSyncService');
      await stopBackgroundSyncLoop();
      // Aguardar um pouco para garantir que o timer anterior foi cancelado
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Verificar condição mestre antes de iniciar: rotaAtiva OU frete EM_EXECUCAO
    final state = await SyncStateUtils.loadSyncState();
    final podeRodar = state != null && (state.rotaAtiva || state.freteAtual != null);
    if (!podeRodar) {
      developer.log(
        'ℹ️ BG-SYNC: start bloqueado - sem condições (rota inativa e nenhum frete em execução)',
        name: 'BackgroundSyncService',
      );
      return;
    }

    developer.log(
      '🚀 BG-SYNC: start (intervalo: ${AppConfig.SYNC_INTERVAL_SECONDS}s)',
      name: 'BackgroundSyncService',
    );

    _isRunning = true;
    _lastStopReason = null;
    isRunningNotifier.value = true;
    lastStopReasonNotifier.value = null;

    // Exibir notificação
    await _showSyncNotification();

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
            '🛑 BG-SYNC: tick detectou rota inativa - parando',
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
      developer.log('ℹ️ BG-SYNC: stop ignorado (não estava rodando)', name: 'BackgroundSyncService');
      return;
    }

    developer.log('🛑 BG-SYNC: stop${reason != null ? ' (${reason})' : ''}', name: 'BackgroundSyncService');

    _isRunning = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    _lastStopReason = reason;
    isRunningNotifier.value = false;
    lastStopReasonNotifier.value = reason;

    // Remover notificação
    await _hideSyncNotification();
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
      developer.log('🔄 BG-SYNC: tick executando...', name: 'BackgroundSyncService');

      // 1. Carregar DriverSession
      final session = await SyncStateUtils.loadDriverSession();
      if (session == null || !session.isValid) {
        developer.log(
          '❌ BG-SYNC: tick - sessão inválida - parando (401)',
          name: 'BackgroundSyncService',
        );
        await stopBackgroundSyncLoop(reason: '401');
        return;
      }

      // 2. Carregar SyncState
      final state = await SyncStateUtils.loadSyncState();
      if (state == null) {
        developer.log(
          '❌ BG-SYNC: tick - SyncState não encontrado - encerrando cedo',
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
          developer.log('📤 BG-SYNC: tick - enviando cancelamento pendente...', name: 'BackgroundSyncService');
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
          'ℹ️ BG-SYNC: tick - rota não está ativa - encerrando cedo',
          name: 'BackgroundSyncService',
        );
        return;
      }

      // 4. Capturar localização atual
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        developer.log(
          '⚠️ BG-SYNC: tick - localização não disponível - pulando sync',
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
        '📤 BG-SYNC: tick - enviando sync: lat=${payload['latitude']}, lon=${payload['longitude']}, eventos=${payload['eventos_pendentes'].length}',
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
          '✅ BG-SYNC: tick - bem-sucedido: ${eventosProcessados.length} processados, ${eventosRejeitados.length} rejeitados',
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
          '🔒 BG-SYNC: tick - token inválido/expirado - parando (401)',
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
          '⚠️ BG-SYNC: tick - conflito (409) - parando',
          name: 'BackgroundSyncService',
        );
        // Parar o loop conforme regra de stop seguro para 409
        await stopBackgroundSyncLoop(reason: '409');
      } else {
        // Outro erro HTTP
        developer.log(
          '⚠️ BG-SYNC: tick - erro HTTP ${response.statusCode} - mantendo fila pendente',
          name: 'BackgroundSyncService',
        );
        // NÃO limpar fila em caso de erro - deixar para próxima execução
      }
    } on UnauthorizedException {
      developer.log(
        '🔒 BG-SYNC: tick - não autorizado - parando (401)',
        name: 'BackgroundSyncService',
      );
      await stopBackgroundSyncLoop(reason: '401');
    } catch (e) {
      // Erro de rede/timeout/etc - não limpar fila, apenas logar
      developer.log(
        '❌ BG-SYNC: tick - erro: $e - mantendo fila pendente',
        name: 'BackgroundSyncService',
      );
      // NÃO limpar fila - deixar para próxima execução
    }
  }

  /// Verifica se deve iniciar o serviço baseado no estado atual
  /// Usado quando o app abre para garantir que o serviço rode se necessário
  static Future<void> startIfNeeded() async {
    final state = await SyncStateUtils.loadSyncState();
    final deveRodar = state != null && (state.rotaAtiva || state.freteAtual != null);
    
    if (deveRodar && !_isRunning) {
      developer.log(
        '🔍 BG-SYNC: startIfNeeded - rota ativa detectada, iniciando serviço',
        name: 'BackgroundSyncService',
      );
      await startBackgroundSyncLoop();
    } else if (!deveRodar && _isRunning) {
      developer.log(
        '🔍 BG-SYNC: startIfNeeded - rota inativa detectada, parando serviço',
        name: 'BackgroundSyncService',
      );
      await stopBackgroundSyncLoop(reason: 'rota_inativa');
    } else if (deveRodar && _isRunning) {
      developer.log(
        '🔍 BG-SYNC: startIfNeeded - serviço já está rodando corretamente',
        name: 'BackgroundSyncService',
      );
    } else {
      developer.log(
        '🔍 BG-SYNC: startIfNeeded - não há condições para rodar o serviço',
        name: 'BackgroundSyncService',
      );
    }
  }
}
