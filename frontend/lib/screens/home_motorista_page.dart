import 'package:flutter/material.dart';
import '../models/driver_session.dart';
import '../models/sync_state.dart';
import '../models/sync_frete.dart';
import '../services/rota_service.dart';
import '../services/sync_state_service.dart';
import '../services/background_sync_service.dart';
import '../utils/sync_state_utils.dart';
import '../utils/status_utils.dart';
import '../config/app_config.dart';
import 'login_screen.dart';
import 'dart:developer' as developer;
import '../services/api_client.dart';
import '../services/storage_service.dart';
import 'dart:io' show Platform;

/// Tela Principal (Home) Operacional do Motorista
/// 
/// Esta é a tela operacional principal do motorista no aplicativo.
/// É aqui que o motorista deve executar toda a jornada diária:
/// - Iniciar viagem
/// - Ver todos os fretes da rota
/// - Ver qual frete está em execução agora
/// - Avançar o status do frete atual diretamente nos cards
/// - Ver a rota completa e progresso
/// 
/// IMPORTANTE:
/// Esta tela é a "home" do motorista, não apenas um painel de visualização.
/// As ações operacionais (como avançar status de frete) devem ser feitas AQUI,
/// não na WebView.
/// 
/// A WebView (carregada em WebViewScreen) é apenas para consulta de detalhes
/// administrativos/informações adicionais do sistema EG3. Ela NÃO deve ser
/// usada como local principal para o motorista atualizar status de frete.
/// Baseado no README_API_ENDPOINTS.md e SyncState
class HomeMotoristaPage extends StatefulWidget {
  const HomeMotoristaPage({super.key});

  @override
  State<HomeMotoristaPage> createState() => _HomeMotoristaPageState();
}

class _HomeMotoristaPageState extends State<HomeMotoristaPage> with WidgetsBindingObserver {
  DriverSession? _session;
  SyncState? _syncState;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isRefreshing = false; // Controle de debounce para refresh

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // Verificar e reiniciar serviço se necessário ao voltar para a Home
      developer.log('🔍 HomeMotoristaPage: app resumed - verificando serviço', name: 'HomeMotoristaPage');
      try {
        await BackgroundSyncService.startIfNeeded();
      } catch (e) {
        developer.log('⚠️ Erro ao verificar serviço ao resume: $e', name: 'HomeMotoristaPage');
      }
    }
  }

  /// Carrega sessão e estado inicial
  Future<void> _loadData() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // 1. Carregar sessão
      final session = await SyncStateUtils.loadDriverSession();
      if (session == null || !session.isValid) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // 2. Carregar estado local
      SyncState? state = await SyncStateUtils.loadSyncState();

      // Removido: normalização que derrubava rotaAtiva sem frete EM_EXECUCAO.

      // 3. Se não há estado ou não há rota, usar fluxo incremental (count → info → loop)
      if (state == null || state.rotaId == null) {
        await _carregarIncremental();
        state = await SyncStateUtils.loadSyncState();
      }

      // 4. Se rota ativa OU há frete em execução, garantir que o serviço está rodando
      if (state != null && (state.rotaAtiva || state.freteAtual != null)) {
        developer.log(
          '🔍 HomeMotoristaPage: rota ativa detectada (rotaAtiva=${state.rotaAtiva}, freteAtual=${state.freteAtual?.freteId}) - verificando serviço',
          name: 'HomeMotoristaPage',
        );
        await BackgroundSyncService.startIfNeeded();
      } else if (state != null) {
        developer.log(
          '🔍 HomeMotoristaPage: rota inativa - parando serviço se estiver rodando',
          name: 'HomeMotoristaPage',
        );
        // Verificar se precisa parar o serviço (caso contrário)
        if (BackgroundSyncService.isRunning) {
          await BackgroundSyncService.stopBackgroundSyncLoop(reason: 'rota_inativa');
        }
      }

      // 5. Atualizar com status do backend quando rotaAtiva=false (evita "downgrade" local)
      try {
        if (state != null && !state.rotaAtiva) {
          await RotaService.sincronizarRotaAtualDoServidor();
          state = await SyncStateUtils.loadSyncState();
        }
      } catch (_) {
        // Offline ou erro de rede: manter estado local
      }

      setState(() {
        _session = session;
        _syncState = state;
        _isInitializing = false;
      });
    } catch (e) {
      developer.log('❌ Erro ao carregar dados: $e', name: 'HomeMotoristaPage');
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isInitializing = false;
      });
    }
  }

  /// Fluxo incremental: count → info → loop por índice
  Future<void> _carregarIncremental() async {
    try {
      await RotaService.carregarRotaIncremental(
        onCount: (total) {
          // Mostrar placeholders enquanto carrega
          developer.log('Count total_fretes=$total', name: 'HomeMotoristaPage');
        },
        onInfo: (rotaInfo) {
          developer.log('Info rota: $rotaInfo', name: 'HomeMotoristaPage');
        },
        onFrete: (frete) async {
          // Atualizar UI progressivamente
          final s = await SyncStateUtils.loadSyncState();
          if (!mounted) return;
          setState(() {
            _syncState = s;
          });
        },
      );
    } on UnauthorizedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.'), backgroundColor: Colors.red),
      );
      await BackgroundSyncService.stopBackgroundSyncLoop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on ConflictException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota inconsistente. Contate o gestor.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  /// Handler para pull-to-refresh
  /// 
  /// Fluxo:
  /// 1. Debounce para evitar múltiplos refresh seguidos
  /// 2. Carregar DriverSession e SyncState do storage
  /// 3. Chamar API atual (getRotaAtual ou incremental)
  /// 4. Validar payload remoto
  /// 5. Mesclar remoto → local via merge não-regressivo
  /// 6. Persistir novo SyncState
  /// 7. Atualizar UI
  /// 8. Iniciar/parar serviço de background conforme resultado
  /// 9. Tratamento completo de erros (401, 409, timeout)
  Future<void> _onRefresh() async {
    // Debounce: evitar múltiplos refresh seguidos
    if (_isRefreshing) {
      developer.log('⏭️ HOME-REFRESH: ignorado (já em execução)', name: 'HomeMotoristaPage');
      return;
    }

    _isRefreshing = true;
    developer.log('🔄 HOME-REFRESH: begin', name: 'HomeMotoristaPage');

    try {
      // 1. Carregar DriverSession e SyncState do storage
      final session = await SyncStateUtils.loadDriverSession();
      if (session == null || !session.isValid) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      final stateLocal = await SyncStateUtils.loadSyncState();

      // 2. Chamar API atual (getRotaAtual para rota ativa, incremental para sem rota)
      Map<String, dynamic>? apiResponse;
      bool rotaAtivaLocal = stateLocal?.rotaAtiva ?? false;
      bool temFreteEmExecucao = stateLocal?.freteAtual != null;

      if (rotaAtivaLocal || temFreteEmExecucao) {
        // Rota ativa: usar getRotaAtual e aplicar merge não-regressivo
        try {
          apiResponse = await RotaService.getRotaAtual();
          
          // Se API retornar has_rota=false por atraso → NÃO desligue a rota local
          // Manter e tentar novamente no próximo ciclo
          if (apiResponse['rota_id'] == null && rotaAtivaLocal) {
            developer.log(
              '⚠️ HOME-REFRESH: API retornou sem rota mas local está ativa, mantendo local',
              name: 'HomeMotoristaPage',
            );
            // Manter estado local, apenas atualizar UI
            if (!mounted) return;
            setState(() {
              _syncState = stateLocal;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rota ativa localmente. Aguardando sincronização...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        } on UnauthorizedException {
          // 401 (token expirado): parar background, exibir aviso, navegar para login
          developer.log('🔒 HOME-REFRESH: 401 - token expirado', name: 'HomeMotoristaPage');
          await BackgroundSyncService.stopBackgroundSyncLoop(reason: '401');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sessão expirada. Faça login novamente.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
          return;
        } on ConflictException catch (e) {
          // 409 (rota inconsistente): não regredir local; exibir banner
          developer.log('⚠️ HOME-REFRESH: 409 - rota inconsistente', name: 'HomeMotoristaPage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rota inconsistente. Contate o gestor. ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 6),
              ),
            );
            // Manter estado local
            setState(() {
              _syncState = stateLocal;
            });
          }
          return;
        } catch (e) {
          // Timeout/rede: manter estado local e permitir operação offline
          developer.log('⚠️ HOME-REFRESH: erro de rede/timeout: $e', name: 'HomeMotoristaPage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro de conexão. Mantendo dados locais.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            setState(() {
              _syncState = stateLocal;
            });
          }
          return;
        }
      } else {
        // Sem rota ativa: usar fluxo incremental
        try {
          await _carregarIncremental();
          final stateFinal = await SyncStateUtils.loadSyncState();
          if (!mounted) return;
          setState(() {
            _syncState = stateFinal;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lista atualizada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        } catch (e) {
          // Erro no incremental: tratar igual
          developer.log('❌ HOME-REFRESH: erro no incremental: $e', name: 'HomeMotoristaPage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // 3. Validar payload (já feito no merge, mas garantir que temos resposta)
      // apiResponse não pode ser null aqui devido ao fluxo acima (já foi atribuído no bloco try acima)

      // 4. Mesclar remoto → local via função pura (não-regressiva)
      final stateMesclado = SyncStateService.mergeRemoteRouteIntoLocal(
        stateLocal ?? SyncState.empty(motoristaId: session.motoristaId),
        apiResponse,
      );

      // 5. Persistir novo SyncState
      await SyncStateUtils.saveSyncState(stateMesclado);

      // 6. Atualizar UI
      if (!mounted) return;
      setState(() {
        _syncState = stateMesclado;
      });

      // 7. Se rota estiver ativa após merge → garantir start do serviço de background
      // Caso contrário, stop
      if (stateMesclado.rotaAtiva || stateMesclado.freteAtual != null) {
        developer.log('🚀 HOME-REFRESH: rota ativa após merge, garantindo BG-SYNC start', name: 'HomeMotoristaPage');
        await BackgroundSyncService.startIfNeeded();
      } else {
        developer.log('🛑 HOME-REFRESH: rota inativa após merge, parando BG-SYNC se necessário', name: 'HomeMotoristaPage');
        if (BackgroundSyncService.isRunning) {
          await BackgroundSyncService.stopBackgroundSyncLoop(reason: 'rota_concluida');
        }
      }

      // Mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista atualizada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      developer.log('✅ HOME-REFRESH: end', name: 'HomeMotoristaPage');
    } catch (e) {
      developer.log('❌ HOME-REFRESH: erro: $e', name: 'HomeMotoristaPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }


  /// Handler para botão "INICIAR VIAGEM"
  Future<void> _iniciarViagem() async {
    if (_syncState == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1) Recarregar estado atual do storage
      final stateAtual = await SyncStateUtils.loadSyncState() ?? _syncState!;

      // 2) Se já houver frete EM_EXECUCAO, apenas atualizar UI
      if (stateAtual.freteAtual != null) {
        setState(() {
          _syncState = stateAtual;
          _isLoading = false;
        });
        return;
      }

      // 3) Ativar rota local e liberar primeiro frete
      final novoState = await SyncStateService.ativarPrimeiroFreteEIniciarRotaLocalmente(stateAtual);

      // 4) Iniciar serviço de sync em background se não estiver rodando
      if (!BackgroundSyncService.isRunning) {
        await BackgroundSyncService.startBackgroundSyncLoop();
      }

      // 5) Forçar 1 tick agora
      await BackgroundSyncService.performSyncTick();

      // 6) Checar conflito 409 sinalizado pelo serviço
      final lastCode = await StorageService.getString('sync_last_error_code');
      if (lastCode == '409') {
        // Mostrar banner e não esconder o botão
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rota inconsistente no servidor. Corrija a rota no sistema web.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 8),
            ),
          );
        }
        // Limpar flags para próximos ciclos
        await StorageService.remove('sync_last_error_code');
        await StorageService.remove('sync_last_error_message');

        // Recarregar incrementalmente para manter UI consistente com servidor
        await _carregarIncremental();
        final s = await SyncStateUtils.loadSyncState();
        setState(() {
          _syncState = s ?? novoState;
          _isLoading = false;
        });
        return;
      }

      // 7) Atualizar UI
      final s = await SyncStateUtils.loadSyncState();
      setState(() {
        _syncState = s ?? novoState;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem iniciada localmente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Erro ao iniciar viagem: $e', name: 'HomeMotoristaPage');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar viagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handler para avancar status de um frete (com diálogo de confirmação)
  Future<void> _avancarStatusFrete(SyncFrete frete) async {
    if (_syncState == null) return;

    // Calcular próximo status
    final proximoStatus = StatusUtils.getProximoStatus(
      frete.tipoServico,
      frete.statusAtual,
    );

    if (proximoStatus == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há próximo status válido para este frete'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Obter label amigável para confirmação
    final labelConfirmacao = StatusUtils.getLabelConfirmacaoProximoStatus(
      frete.tipoServico,
      frete.statusAtual,
    );

    // Log de debug
    developer.log(
      '🔄 Iniciando avanço de status: frete ${frete.freteId} (ordem ${frete.ordem}) de "$labelConfirmacao"',
      name: 'HomeMotoristaPage',
    );

    // Mostrar diálogo de confirmação
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar ação'),
        content: Text(
          labelConfirmacao != null
              ? "Confirmar: marcar este frete como '$labelConfirmacao'?"
              : 'Confirmar: avançar status deste frete?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado != true) {
      return; // Usuário cancelou
    }

    // Bloquear botão imediatamente
    setState(() {
      _isLoading = true;
    });

    try {
      // Chamar SyncStateService.registrarAvancoStatus
      developer.log(
        '📝 Registrando avanço de status localmente...',
        name: 'HomeMotoristaPage',
      );
      
      final novoState = await SyncStateService.registrarAvancoStatus(
        _syncState!,
        frete.freteId,
        proximoStatus,
        null, // observacoes opcional
      );

      developer.log(
        '✅ Status atualizado localmente. Novo estado: rota_ativa=${novoState.rotaAtiva}, evento na fila',
        name: 'HomeMotoristaPage',
      );

      // Recarregar o SyncState do storage para garantir sincronização
      final stateRecarregado = await SyncStateUtils.loadSyncState();

      setState(() {
        _syncState = stateRecarregado ?? novoState;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status atualizado: ${StatusUtils.statusParaTexto(proximoStatus)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Erro ao avançar status: $e', name: 'HomeMotoristaPage');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar status. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handler para logout
  Future<void> _handleLogout() async {
    await SyncStateUtils.clearAll();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Início'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Início'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_session == null || _syncState == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Início'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: const Center(
          child: Text('Erro: Sessão ou estado não encontrado'),
        ),
      );
    }

    // Ordenar fretes por ordem ascendente
    final fretesOrdenados = List<SyncFrete>.from(_syncState!.fretes)
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Cabeçalho com informações do motorista e rota
            SliverToBoxAdapter(
              child: _buildHeader(context, _session!, _syncState!, fretesOrdenados),
            ),

            // Aviso: sincronizando em segundo plano (Android)
            SliverToBoxAdapter(
              child: _buildBackgroundSyncBanner(context),
            ),

            // Mensagem "Rota concluída" ou botão INICIAR VIAGEM
            if (fretesOrdenados.isNotEmpty) ...[
              // Verificar se todos os fretes estão concluídos
              if (fretesOrdenados.every((f) => f.statusRota == 'CONCLUIDO'))
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                        const SizedBox(width: 12),
                        const Text(
                          'Rota concluída',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if ((_syncState!.rotaId != null) && !_syncState!.rotaAtiva && (fretesOrdenados.every((f) => f.statusRota != 'EM_EXECUCAO')))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _iniciarViagem,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'INICIAR VIAGEM',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // Lista de fretes ordenados
            if (fretesOrdenados.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final frete = fretesOrdenados[index];
                    return _buildFreteCard(context, frete, fretesOrdenados);
                  },
                  childCount: fretesOrdenados.length,
                ),
              )
            else
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('Nenhum frete disponível na rota'),
                  ),
                ),
              ),

            // Info de sincronização (rodapé)
            SliverToBoxAdapter(
              child: _buildSyncInfo(context),
            ),
            // Aviso de cancelamento pendente
            SliverToBoxAdapter(
              child: FutureBuilder<String?>(
                future: StorageService.getString('pending_cancel_route'),
                builder: (context, snap) {
                  if (snap.data == '1') {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.outbox, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Cancelamento pendente de envio',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói cabeçalho com informações do motorista e rota
  Widget _buildHeader(BuildContext context, DriverSession session, SyncState state, List<SyncFrete> fretesOrdenados) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do motorista
            Row(
              children: [
                const Icon(Icons.person, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.nomeMotorista,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'CPF: ${session.cpf}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Informações da rota
            if (state.rotaId != null) ...[
              Row(
                children: [
                  const Icon(Icons.route, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rota #${state.rotaId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (state.rotaAtiva)
                          Text(
                            'Status: Em Andamento',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Status: Planejada',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (fretesOrdenados.isNotEmpty) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: fretesOrdenados.isEmpty
                      ? 0
                      : fretesOrdenados.where((f) => f.statusRota == 'CONCLUIDO').length /
                          fretesOrdenados.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fretesOrdenados.where((f) => f.statusRota == 'CONCLUIDO').length}/${fretesOrdenados.length} fretes concluídos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Nenhuma rota ativa',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói card de um frete
  Widget _buildFreteCard(BuildContext context, SyncFrete frete, List<SyncFrete> todosFretes) {
    // Placeholder: quando frete ainda não chegou do backend
    if (frete.freteId == -1) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 1,
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    child: Text('${frete.ordem}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 36,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isEmExecucao = frete.statusRota == 'EM_EXECUCAO';
    final isPendente = frete.statusRota == 'PENDENTE';
    final isConcluido = frete.statusRota == 'CONCLUIDO';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: isEmExecucao ? 4 : 2,
      color: isPendente
          ? Colors.grey[200]
          : isConcluido
              ? Colors.green[50]
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do frete
            Row(
              children: [
                // Badge de ordem
                CircleAvatar(
                  backgroundColor: isEmExecucao
                      ? Colors.green[700]
                      : isConcluido
                          ? Colors.grey
                          : Colors.grey[400],
                  foregroundColor: Colors.white,
                  child: Text('${frete.ordem}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de status
                      if (isEmExecucao)
                        Chip(
                          label: const Text(
                            'Em execução agora',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green[700],
                          padding: EdgeInsets.zero,
                        )
                      else if (isPendente)
                        Chip(
                          label: Text(
                            todosFretes.length == 1 ? 'Pendente' : 'Aguardando frete anterior',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.grey[600],
                          padding: EdgeInsets.zero,
                        )
                      else if (isConcluido)
                        Chip(
                          label: const Text(
                            'Frete concluído',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.zero,
                        ),
                      if (frete.numeroNotaFiscal != null)
                        Text(
                          'NF: ${frete.numeroNotaFiscal}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Origem → Destino
            if (frete.origem != null || frete.destino != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${frete.origem ?? "?"} → ${frete.destino ?? "?"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Cliente
            if (frete.clienteNome != null)
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      frete.clienteNome!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Tipo de serviço e status atual
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    StatusUtils.tipoServicoParaTexto(frete.tipoServico),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    StatusUtils.statusParaTexto(frete.statusAtual),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isConcluido ? Colors.green[700] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botão de ação ou status final
            if (isConcluido)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Frete concluído',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (isEmExecucao)
              Builder(
                builder: (context) {
                  // Obter label amigável para o botão
                  final labelBotao = StatusUtils.getLabelParaProximoStatus(
                    frete.tipoServico,
                    frete.statusAtual,
                  );

                  if (labelBotao == null) {
                    // Não há próximo status (frete já finalizado mas ainda em execução na rota)
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Frete concluído',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Botão único e grande para avançar status
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _avancarStatusFrete(frete),
                      icon: const Icon(Icons.arrow_forward, size: 24),
                      label: Text(
                        labelBotao,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                },
              )
            else if (isPendente)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  todosFretes.length == 1 
                      ? 'Clique em "Iniciar Viagem" para começar' 
                      : 'Aguardando conclusão do frete anterior',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói informação de sincronização (rodapé)
  Widget _buildSyncInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Sincronização automática a cada ${AppConfig.SYNC_INTERVAL_SECONDS} segundos enquanto a rota estiver ativa.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Banner superior indicando estado do serviço de background
  Widget _buildBackgroundSyncBanner(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: BackgroundSyncService.isRunningNotifier,
      builder: (context, isRunning, _) {
        // Se não estiver rodando, pode exibir mensagem de erro se a razão for 401
        if (!isRunning) {
          return ValueListenableBuilder<String?>(
            valueListenable: BackgroundSyncService.lastStopReasonNotifier,
            builder: (context, reason, __) {
              if (reason == '401') {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sincronização parada — faça login novamente.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (reason == '409') {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sincronização parada — rota inconsistente. Contate o gestor.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        }

        // Rodando: exibir barra informativa
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.sync, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sincronizando em segundo plano...',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

