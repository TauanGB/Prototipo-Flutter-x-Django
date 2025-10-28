import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_location.dart';
import '../models/driver_trip.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';
import '../utils/cpf_validator.dart';
import '../utils/animations.dart';
import '../models/frete_ativo.dart';
import '../services/frete_service.dart';
import '../services/rota_execution_service.dart';
import '../models/rota.dart';
import '../models/frete_rota.dart';
import '../widgets/frete_action_button.dart';
import 'cpf_config_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DriverLocation? _lastLocation;
  DriverTrip? _activeTrip;
  bool _isLoading = false;
  String _cpf = '';
  bool _hasCpfConfigured = false;
  List<FreteAtivo> _fretesAtivos = [];
  bool _loadingFretes = false;
  bool _hasActiveRota = false;
  Rota? _rotaAtiva;
  bool _loadingRota = false;
  bool _expandedFretes = false;
  
  // Variáveis para o serviço de background
  bool _isBackgroundServiceRunning = false;
  int _backgroundServiceInterval = AppConfig.defaultBackgroundInterval;
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
      final interval = await BackgroundLocationService.getCurrentInterval();
      
      setState(() {
        _isBackgroundServiceRunning = isRunning;
        _backgroundServiceInterval = interval;
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
      final tripData = await BackgroundLocationService.restoreActiveTripData();
      if (tripData != null) {
        setState(() {
          _activeTrip = DriverTrip.fromJson(tripData);
        });
        _validateTripRequirement();
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
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar fretes: $e', isError: true);
    } finally {
      setState(() {
        _loadingFretes = false;
      });
    }
  }

  Future<void> _checkActiveRota() async {
    try {
      final rotaAtiva = await RotaExecutionService.getRotaAtiva();
      setState(() {
        _hasActiveRota = rotaAtiva != null;
        _rotaAtiva = rotaAtiva;
      });
    } catch (e) {
      developer.log('Erro ao verificar rota ativa: $e');
    }
  }

  void _validateTripRequirement() {
    if (_activeTrip != null) {
      _tripValidationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          // Validação periódica da viagem
        }
      });
    }
  }

  Future<void> _startTripAndTracking() async {
    setState(() {
      _isLoading = true;
      _loadingRota = true;
    });

    try {
      if (!_hasCpfConfigured) {
        _showCpfRequiredDialog();
        return;
      }
      
      // Buscar rota ativa automaticamente
      final rota = await RotaExecutionService.buscarRotaAtivaAutomatica();
      
      if (rota == null) {
        // Não há rota ativa
        _showNoActiveRotaDialog();
        return;
      }

      // Iniciar viagem com rota automaticamente
      final sucesso = await RotaExecutionService.iniciarViagemComRota();
      
      if (sucesso) {
        setState(() {
          _rotaAtiva = rota;
          _hasActiveRota = true;
          _expandedFretes = true;
        });
        
        _showSnackBar('Viagem iniciada! Rastreamento ativo.');
        await _loadBackgroundServiceState();
      } else {
        _showSnackBar('Erro ao iniciar viagem. Tente novamente.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao iniciar viagem: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _loadingRota = false;
      });
    }
  }

  Future<void> _stopTripAndTracking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await BackgroundLocationService.stopService();
      
      if (_activeTrip != null) {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          final finalTripResult = await ApiService.endTrip(
            CpfValidator.cleanCpf(_cpf),
            position.latitude,
            position.longitude,
          );
          
          if (!finalTripResult['success']) {
            _showApiErrorDialog(
              'Erro ao Finalizar Viagem', 
              'Não foi possível finalizar a viagem na API. Verifique sua conexão com a internet e tente novamente.',
              errorDetails: finalTripResult['error']
            );
            return;
          }
        }
      }
      
      setState(() {
        _activeTrip = null;
      });
      
      await BackgroundLocationService.setActiveTripStatus(false);
      await BackgroundLocationService.clearActiveTripData();
      
      _tripValidationTimer?.cancel();
      
      _showSnackBar('Viagem finalizada e rastreamento parado!');
      await _loadBackgroundServiceState();
    } catch (e) {
      _showSnackBar('Erro ao parar viagem: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _atualizarStatusFrete(int freteId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sucesso = await RotaExecutionService.atualizarStatusFrete(freteId);
      
      if (sucesso) {
        // Buscar rota atualizada do servidor para refletir mudanças
        await _recarregarRotaAtiva();
        
        _showSnackBar('Status atualizado com sucesso!');
      } else {
        _showSnackBar('Erro ao atualizar status. Tente novamente.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao atualizar status: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        developer.log('✅ Rota recarregada com status atualizados', name: 'Dashboard');
      }
    } catch (e) {
      developer.log('❌ Erro ao recarregar rota: $e', name: 'Dashboard');
    }
  }

  Future<void> _finalizarViagem() async {
    if (_rotaAtiva == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sucesso = await RotaExecutionService.finalizarRota(_rotaAtiva!.id);
      
      if (sucesso) {
        await BackgroundLocationService.stopService();
        await _loadBackgroundServiceState();
        
        setState(() {
          _rotaAtiva = null;
          _hasActiveRota = false;
          _expandedFretes = false;
        });
        
        _showSnackBar('Viagem finalizada com sucesso!');
      } else {
        _showSnackBar('Erro ao finalizar viagem. Tente novamente.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao finalizar viagem: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showNoActiveRotaDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              const Text('Nenhuma Rota Ativa'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Não há rotas ativas disponíveis para você no momento.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text('• Contacte o gestor para receber uma nova rota'),
              Text('• Verifique se há fretes pendentes'),
              Text('• Aguarde a atribuição de uma nova rota'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCpfRequiredDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Text('CPF Obrigatório'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para usar o aplicativo, você precisa configurar seu CPF.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text('• O CPF deve estar cadastrado no sistema'),
              Text('• Será validado automaticamente'),
              Text('• Fica salvo para próximas sessões'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToCpfConfig();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Configurar CPF'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToCpfConfig() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CpfConfigScreen()),
    );
    
    if (result == true) {
      await _loadSavedCpf();
      _showSnackBar('CPF configurado com sucesso!');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: AppConfig.snackBarDuration,
      ),
    );
  }

  void _showApiErrorDialog(String title, String message, {String? errorDetails}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (errorDetails != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      errorDetails,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEndTripConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Text('Finalizar Viagem'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tem certeza que deseja finalizar a viagem atual?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text('• O rastreamento será parado'),
              Text('• A viagem será marcada como concluída'),
              Text('• Esta ação não pode ser desfeita'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _stopTripAndTracking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finalizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await StorageService.clearAll();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBackgroundServiceState();
          await _loadSavedCpf();
          await _restoreActiveTrip();
          await _loadFretesAtivos();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de Status Principal
              AppAnimations.cardAnimation(
                child: _buildStatusCard(),
              ),
              
              const SizedBox(height: 16),
              
              // Card de Rota Ativa (quando há viagem em andamento) - MOVIDO PARA CIMA
              if (_hasActiveRota && _rotaAtiva != null)
                AppAnimations.cardAnimation(
                  child: _buildRotaAtivaCard(),
                ),
              
              if (_hasActiveRota && _rotaAtiva != null)
                const SizedBox(height: 16),
              
              // Card de Fretes Ativos
              AppAnimations.cardAnimation(
                child: _buildFretesAtivosCard(),
              ),
              
              const SizedBox(height: 16),
              
              // Card de Informações da Viagem
              if (_activeTrip != null || _isBackgroundServiceRunning)
                AppAnimations.cardAnimation(
                  child: _buildTripInfoCard(),
                ),
              
              const SizedBox(height: 16),
              
              // Card de Última Localização
              if (_lastLocation != null)
                AppAnimations.cardAnimation(
                  child: _buildLastLocationCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isBackgroundServiceRunning ? Icons.gps_fixed : Icons.gps_off,
                  color: _isBackgroundServiceRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status do Sistema',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isBackgroundServiceRunning ? Colors.green : Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_isBackgroundServiceRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ATIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'INATIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Botão principal de ação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || !_hasCpfConfigured) ? null : (_isBackgroundServiceRunning ? _showEndTripConfirmationDialog : _startTripAndTracking),
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isBackgroundServiceRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_isLoading 
                  ? 'Processando...' 
                  : _isBackgroundServiceRunning 
                    ? 'Finalizar Viagem' 
                    : _hasActiveRota 
                      ? 'Continuar Rota' 
                      : 'Iniciar Viagem'
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBackgroundServiceRunning ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            if (!_hasCpfConfigured) ...[
              const SizedBox(height: 8),
              Text(
                'Configure seu CPF para usar o aplicativo',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFretesAtivosCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Fretes Ativos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_loadingFretes)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_loadingFretes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_fretesAtivos.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, color: Colors.grey, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum frete ativo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fretesAtivos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final frete = _fretesAtivos[index];
                  return _buildFreteItem(frete);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreteItem(FreteAtivo frete) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  frete.rota,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(frete.statusAtual ?? ''),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  frete.statusFormatado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if ((frete.clienteNome ?? '').isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  frete.clienteNome ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${frete.origem ?? 'N/A'} → ${frete.destino ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotaAtivaCard() {
    if (_rotaAtiva == null) return const SizedBox.shrink();

    final fretesConcluidos = _rotaAtiva!.fretesRota?.where((fr) => fr.statusRota == 'CONCLUIDO').length ?? 0;
    final totalFretes = _rotaAtiva!.fretesRota?.length ?? 0;
    final isRotaCompleta = fretesConcluidos == totalFretes;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da rota
            Row(
              children: [
                Icon(Icons.route, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rotaAtiva!.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_expandedFretes ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _expandedFretes = !_expandedFretes;
                    });
                  },
                ),
              ],
            ),
            
            // Progresso da rota
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Progresso: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '$fretesConcluidos de $totalFretes fretes concluídos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRotaCompleta ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalFretes > 0 ? fretesConcluidos / totalFretes : 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isRotaCompleta ? Colors.green : Colors.blue,
              ),
            ),
            
            // Lista de fretes (expansível)
            if (_expandedFretes) ...[
              const SizedBox(height: 16),
              if (_rotaAtiva!.fretesRota != null && _rotaAtiva!.fretesRota!.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rotaAtiva!.fretesRota!.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final freteRota = _rotaAtiva!.fretesRota![index];
                    return _buildFreteRotaItem(freteRota);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Nenhum frete na rota',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
            
            // Botão finalizar viagem (só aparece quando todos os fretes estão concluídos)
            if (isRotaCompleta) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _finalizarViagem,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                  label: Text(_isLoading ? 'Finalizando...' : 'Finalizar Viagem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreteRotaItem(FreteRota freteRota) {
    final frete = freteRota.frete;
    final isAtual = freteRota.statusRota == 'EM_EXECUCAO';
    final isConcluido = freteRota.statusRota == 'CONCLUIDO';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAtual 
          ? Colors.blue.shade50 
          : isConcluido 
            ? Colors.green.shade50 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtual 
            ? Colors.blue.shade200 
            : isConcluido 
              ? Colors.green.shade200 
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do frete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAtual 
                    ? Colors.blue 
                    : isConcluido 
                      ? Colors.green 
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${freteRota.ordem}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  frete.codigoPublico,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isAtual ? Colors.blue.shade700 : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(frete.statusAtual),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  frete.statusAtualDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Informações do frete
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  frete.clienteNome,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Row(
            children: [
              Icon(Icons.local_shipping, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  frete.tipoServicoDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          
          if (frete.origem != null && frete.origem!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Origem: ${frete.origem}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          if (frete.destino != null && frete.destino!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Destino: ${frete.destino}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Botão de ação
          FreteActionButton(
            frete: frete,
            enabled: !isConcluido,
            isLoading: _isLoading,
            onPressed: () => _atualizarStatusFrete(frete.id),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Informações da Viagem',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_activeTrip != null) ...[
              _buildInfoRow('ID da Viagem', _activeTrip!.id.toString()),
              _buildInfoRow('Início', _activeTrip!.createdAt != null ? _formatDateTime(_activeTrip!.createdAt!) : 'N/A'),
              if (_activeTrip!.updatedAt != null)
                _buildInfoRow('Fim', _formatDateTime(_activeTrip!.updatedAt!)),
              _buildInfoRow('Status', _activeTrip!.status),
            ],
            
            _buildInfoRow('Rastreamento', _isBackgroundServiceRunning ? 'Ativo' : 'Inativo'),
            _buildInfoRow('Intervalo', '${_backgroundServiceInterval}s'),
          ],
        ),
      ),
    );
  }

  Widget _buildLastLocationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Última Localização',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Latitude', _lastLocation!.latitude.toString()),
            _buildInfoRow('Longitude', _lastLocation!.longitude.toString()),
            _buildInfoRow('Precisão', '${_lastLocation!.accuracy}m'),
            _buildInfoRow('Velocidade', '${_lastLocation!.speed} km/h'),
            _buildInfoRow('Timestamp', _lastLocation!.timestamp != null ? _formatDateTime(_lastLocation!.timestamp!) : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aguardando_carga':
        return Colors.orange;
      case 'em_transito':
        return Colors.blue;
      case 'em_descarga_cliente':
        return Colors.purple;
      case 'finalizado':
        return Colors.green;
      case 'carregamento_iniciado':
        return Colors.blue;
      case 'carregamento_concluido':
        return Colors.green;
      case 'descarregamento_iniciado':
        return Colors.blue;
      case 'descarregamento_concluido':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}