import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_location.dart';
import '../models/driver_trip.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';
import '../models/frete_ativo.dart';
import '../services/frete_service.dart';
import '../services/rota_execution_service.dart';
import '../models/rota.dart';
import '../models/frete_rota.dart';
import '../widgets/frete_action_button.dart';
import 'cpf_config_screen.dart';
import 'login_screen.dart';

/// Sistema EG3 - App para Motoristas (Mobile)
/// 
/// Este aplicativo é exclusivamente para dispositivos móveis:
/// - Android (API 21+)
/// - iOS (iOS 12.0+)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DriverLocation? _lastLocation;
  DriverTrip? _activeTrip;
  bool _isLoading = false;
  String _cpf = '';
  bool _hasCpfConfigured = false;
  List<FreteAtivo> _fretesAtivos = [];
  bool _loadingFretes = false;
  bool _hasActiveRota = false;
  Rota? _rotaAtiva;
  bool _expandedFretes = false;
  
  // Variáveis para o serviço de background
  bool _isBackgroundServiceRunning = false;
  Timer? _tripValidationTimer;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadBackgroundServiceState();
    _loadSavedCpf();
    _restoreActiveTrip();
    _loadFretesAtivos();
    _checkActiveRota();
  }

  @override
  void dispose() {
    _tripValidationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await LocationService.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      await LocationService.requestPermission();
      }
    } catch (e) {
      developer.log('Erro ao verificar permissão de localização: $e');
    }
  }

  Future<void> _loadBackgroundServiceState() async {
    try {
    final isRunning = await BackgroundLocationService.isServiceRunning();
      
    setState(() {
      _isBackgroundServiceRunning = isRunning;
      });
    } catch (e) {
      developer.log('Erro ao carregar estado do serviço de background: $e');
    }
  }

  Future<void> _loadSavedCpf() async {
    try {
      final cpf = await StorageService.getCpf();
    setState(() {
        _cpf = cpf ?? '';
        _hasCpfConfigured = cpf != null && cpf.isNotEmpty;
    });
    } catch (e) {
      developer.log('Erro ao carregar CPF salvo: $e');
    }
  }

  Future<void> _restoreActiveTrip() async {
    try {
      // Verificar se há viagem ativa no storage
      final hasActiveTrip = await StorageService.getString('active_trip') != null;
      if (hasActiveTrip) {
        _startTripValidationTimer();
      }
    } catch (e) {
      developer.log('Erro ao restaurar viagem ativa: $e');
    }
  }

  Future<void> _loadFretesAtivos() async {
    if (!_hasCpfConfigured) return;
    
    setState(() {
      _loadingFretes = true;
    });

    try {
      final fretes = await FreteService.getFretesAtivos();
          setState(() {
        _fretesAtivos = fretes;
        _loadingFretes = false;
          });
      developer.log('✅ ${fretes.length} fretes carregados no dashboard');
        } catch (e) {
      setState(() {
        _loadingFretes = false;
      });
      developer.log('❌ Erro ao carregar fretes: $e');
      _showSnackBar('Erro ao carregar fretes: $e', true);
    }
  }

  Future<void> _checkActiveRota() async {
    try {
      final rotaAtiva = await RotaExecutionService.getRotaAtiva();
      setState(() {
        _rotaAtiva = rotaAtiva;
        _hasActiveRota = rotaAtiva != null;
      });
    } catch (e) {
      developer.log('Erro ao verificar rota ativa: $e');
    }
  }

  void _startTripValidationTimer() {
    _tripValidationTimer?.cancel();
    _tripValidationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_activeTrip != null) {
        _validateActiveTrip();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _validateActiveTrip() async {
    try {
      final hasActiveTrip = await StorageService.getString('active_trip') != null;
      if (!hasActiveTrip) {
        _tripValidationTimer?.cancel();
      }
    } catch (e) {
      developer.log('Erro ao validar viagem ativa: $e');
    }
  }

  Future<void> _startTripAndTracking() async {
    if (!_hasCpfConfigured) {
      _showCpfRequiredDialog();
        return;
      }

    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar rota ativa automaticamente
      final rotaAtiva = await RotaExecutionService.buscarRotaAtivaAutomatica();
      
      if (rotaAtiva == null) {
        _showNoActiveRotaDialog();
            return;
      }
      
      // Iniciar viagem com rota
      await RotaExecutionService.iniciarViagemComRota();
      
      setState(() {
        _rotaAtiva = rotaAtiva;
        _hasActiveRota = true;
        _expandedFretes = true;
      });

      _showSnackBar('Viagem iniciada com sucesso!', false);
      await _loadBackgroundServiceState();
      
      } catch (e) {
      developer.log('Erro ao iniciar viagem: $e');
      _showSnackBar('Erro ao iniciar viagem: $e', true);
      } finally {
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _showNoActiveRotaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nenhuma Rota Ativa'),
        content: const Text(
          'Não foi encontrada nenhuma rota ativa para este motorista.\n\n'
          'Entre em contato com o gestor para receber uma nova rota.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _atualizarStatusFrete(int freteId) async {
    try {
      await RotaExecutionService.atualizarStatusFrete(freteId);
      
      // Buscar rota atualizada do servidor para refletir mudanças
      await _recarregarRotaAtiva();
      
      _showSnackBar('Status atualizado com sucesso!', false);
    } catch (e) {
      developer.log('Erro ao atualizar status do frete: $e');
      _showSnackBar('Erro ao atualizar status: $e', true);
    }
  }

  Future<void> _recarregarRotaAtiva() async {
    try {
      // Buscar rota ativa atualizada do servidor
      final rotaAtualizada = await RotaExecutionService.buscarRotaAtivaAutomatica();
      if (rotaAtualizada != null) {
        setState(() {
          _rotaAtiva = rotaAtualizada;
        });
        developer.log('✅ Rota recarregada com status atualizados', name: 'HomeScreen');
      }
    } catch (e) {
      developer.log('❌ Erro ao recarregar rota: $e', name: 'HomeScreen');
    }
  }

  Future<void> _finalizarViagem() async {
    if (_rotaAtiva == null) return;

    try {
      await RotaExecutionService.finalizarRota(_rotaAtiva!.id);
      
        setState(() {
        _rotaAtiva = null;
        _hasActiveRota = false;
        _expandedFretes = false;
      });

      _showSnackBar('Viagem finalizada com sucesso!', false);
      await _loadBackgroundServiceState();
      
    } catch (e) {
      developer.log('Erro ao finalizar viagem: $e');
      _showSnackBar('Erro ao finalizar viagem: $e', true);
    }
  }

  void _showCpfRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CPF Necessário'),
        content: const Text(
          'É necessário configurar o CPF antes de iniciar uma viagem.\n\n'
          'Deseja configurar agora?',
          ),
          actions: [
            TextButton(
            onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToCpfConfig();
              },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  void _navigateToCpfConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CpfConfigScreen(),
      ),
    ).then((_) {
      _loadSavedCpf();
      _loadFretesAtivos();
    });
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: AppConfig.snackBarDuration,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRotaAtivaCard() {
    if (_rotaAtiva == null) return const SizedBox.shrink();

    final fretesConcluidos = _rotaAtiva!.fretesRota
        ?.where((fr) => fr.statusRota == 'CONCLUIDO')
        .length ?? 0;
    final totalFretes = _rotaAtiva!.fretesRota?.length ?? 0;
    final progresso = totalFretes > 0 ? fretesConcluidos / totalFretes : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                Icon(
                  Icons.route,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                            const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rota Ativa',
                              style: TextStyle(
                      fontSize: 18,
                                fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _expandedFretes = !_expandedFretes;
                    });
                  },
                  icon: Icon(
                    _expandedFretes ? Icons.expand_less : Icons.expand_more,
                              ),
                            ),
                          ],
                        ),
            const SizedBox(height: 12),
            _buildInfoRow('ID da Rota', _rotaAtiva!.id.toString()),
            _buildInfoRow('Status', _rotaAtiva!.status),
            _buildInfoRow('Progresso', '$fretesConcluidos de $totalFretes fretes'),
                        const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progresso,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 12),
            if (_expandedFretes) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fretes da Rota',
                            style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...(_rotaAtiva!.fretesRota ?? []).map((freteRota) => 
                _buildFreteRotaItem(freteRota)
                  ),
                ],
                const SizedBox(height: 16),
            if (fretesConcluidos == totalFretes && totalFretes > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finalizarViagem,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar Viagem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFreteRotaItem(FreteRota freteRota) {
    final frete = freteRota.frete;
    final isConcluido = freteRota.statusRota == 'CONCLUIDO';
    final isEmExecucao = freteRota.statusRota == 'EM_EXECUCAO';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isConcluido 
          ? Colors.green.shade50 
          : isEmExecucao 
              ? Colors.blue.shade50 
              : Colors.grey.shade50,
      child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                Icon(
                  isConcluido 
                      ? Icons.check_circle 
                      : isEmExecucao 
                          ? Icons.play_circle 
                          : Icons.pending,
                  color: isConcluido 
                      ? Colors.green 
                      : isEmExecucao 
                          ? Colors.blue 
                          : Colors.grey,
                  size: 20,
                ),
                        const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    frete.codigoPublico,
                    style: const TextStyle(
                            fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConcluido 
                        ? Colors.green 
                        : isEmExecucao 
                            ? Colors.blue 
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    freteRota.statusRota,
                    style: const TextStyle(
                      color: Colors.white,
                        fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 8),
            Text('Cliente: ${frete.clienteNome}'),
            if (frete.origem != null)
              Text('Origem: ${frete.origem}'),
            if (frete.destino != null)
              Text('Destino: ${frete.destino}'),
            Text('Tipo: ${frete.tipoServico}'),
            const SizedBox(height: 12),
            FreteActionButton(
              frete: frete,
              onPressed: isConcluido ? null : () => _atualizarStatusFrete(frete.id),
              ),
            ],
          ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema EG3 - Motoristas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de informações do motorista
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                              Text(
                          'Informações do Motorista',
                          style: TextStyle(
                            fontSize: 18,
                                  fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('CPF', _hasCpfConfigured ? _cpf : 'Não configurado'),
                    _buildInfoRow('Status', _isBackgroundServiceRunning ? 'Online' : 'Offline'),
                    if (_activeTrip != null) ...[
                      _buildInfoRow('Viagem Ativa', 'Sim'),
                      _buildInfoRow('Início', _formatDateTime(_activeTrip!.createdAt!)),
                      _buildInfoRow('Última Atualização', _formatDateTime(_activeTrip!.updatedAt!)),
                    ] else ...[
                      _buildInfoRow('Viagem Ativa', 'Não'),
                    ],
                    if (_lastLocation != null) ...[
                      _buildInfoRow('Última Localização', 
                        '${_lastLocation!.latitude.toStringAsFixed(6)}, '
                        '${_lastLocation!.longitude.toStringAsFixed(6)}'),
                      _buildInfoRow('Precisão', '${_lastLocation!.accuracy?.toStringAsFixed(1)}m'),
                      _buildInfoRow('Velocidade', '${_lastLocation!.speed?.toStringAsFixed(1)} km/h'),
                      _buildInfoRow('Direção', '${_lastLocation!.heading?.toStringAsFixed(0)}°'),
                      _buildInfoRow('Altitude', '${_lastLocation!.altitude?.toStringAsFixed(1)}m'),
                      _buildInfoRow('Timestamp', _formatDateTime(_lastLocation!.timestamp!)),
                    ],
                      ],
                    ),
                        ),
            ),

            const SizedBox(height: 16),

            // Card de rota ativa (se houver)
            if (_hasActiveRota) _buildRotaAtivaCard(),

            // Botão principal de ação
            Card(
              child: Padding(
                                padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                    if (!_hasCpfConfigured) ...[
                      const Text(
                        'Configure seu CPF para começar',
                                            style: TextStyle(
                          fontSize: 16,
                                              fontWeight: FontWeight.bold,
            ),
                              ),
            const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToCpfConfig,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Configurar CPF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ] else if (!_hasActiveRota) ...[
                      const Text(
                        'Inicie uma viagem para começar o rastreamento',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _startTripAndTracking,
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isLoading ? 'Iniciando...' : 'Iniciar Viagem'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Viagem em andamento',
                          style: TextStyle(
                            fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                          onPressed: _finalizarViagem,
                          icon: const Icon(Icons.stop),
                          label: const Text('Finalizar Viagem'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card de fretes ativos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                          Text(
                          'Fretes Ativos',
                            style: TextStyle(
                            fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const Spacer(),
                        if (_loadingFretes)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                      const SizedBox(height: 12),
                    if (_fretesAtivos.isEmpty && !_loadingFretes)
                      const Text('Nenhum frete ativo encontrado.')
                    else
                      ..._fretesAtivos.map((frete) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            Icons.local_shipping,
                            color: Colors.blue.shade700,
                          ),
                          title: Text(frete.codigoPublico ?? 'Frete ${frete.id}'),
                          subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              if (frete.clienteNome != null) Text('Cliente: ${frete.clienteNome}'),
                              if (frete.origem != null) Text('Origem: ${frete.origem}'),
                              if (frete.destino != null) Text('Destino: ${frete.destino}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                          ),
                                child: Text(
                              frete.statusAtual ?? 'Pendente',
                              style: const TextStyle(
                                color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                        ),
                      )),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}