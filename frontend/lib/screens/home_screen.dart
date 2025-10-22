import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/driver_location.dart';
import '../models/driver_trip.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../config/app_config.dart';
import '../utils/cpf_validator.dart';
import 'config_screen.dart';
import 'cpf_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DriverLocation? _lastLocation;
  DriverTrip? _activeTrip;
  bool _isLoading = false;
  String _status = 'online';
  double? _batteryLevel;
  String _cpf = '';
  bool _hasCpfConfigured = false;
  final List<String> _statusOptions = AppConfig.driverStatuses;
  final TextEditingController _batteryController = TextEditingController();
  
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
    _validateTripRequirement();
  }

  @override
  void dispose() {
    _batteryController.dispose();
    _tripValidationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    // Verifica permissões usando o sistema padrão
    bool hasPermission = await LocationService.hasPermission();
    if (!hasPermission) {
      await LocationService.requestPermission();
    }
  }

  Future<void> _loadBackgroundServiceState() async {
    final isRunning = await BackgroundLocationService.isServiceRunning();
    final interval = await BackgroundLocationService.getCurrentInterval();
    setState(() {
      _isBackgroundServiceRunning = isRunning;
      _backgroundServiceInterval = interval;
    });
    
    // Valida se há viagem ativa quando o serviço está rodando
    if (isRunning && _activeTrip == null) {
      await _validateTripRequirement();
    }
  }

  Future<void> _loadSavedCpf() async {
    final savedCpf = await BackgroundLocationService.getSavedCpf();
    setState(() {
      _cpf = savedCpf;
      _hasCpfConfigured = savedCpf.isNotEmpty;
    });
  }

  Future<void> _validateTripRequirement() async {
    // Verifica se o rastreamento está ativo mas sem viagem associada
    if (_isBackgroundServiceRunning && _activeTrip == null) {
      // Para o rastreamento automaticamente
      await BackgroundLocationService.stopService();
      setState(() {
        _isBackgroundServiceRunning = false;
      });
      
      // Para o timer de validação
      _tripValidationTimer?.cancel();
      
      // Mostra aviso ao usuário
      if (mounted) {
        _showSnackBar('Rastreamento encerrado: viagem é obrigatória', isError: true);
      }
    }
  }

  void _startTripValidationTimer() {
    _tripValidationTimer?.cancel();
    _tripValidationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isBackgroundServiceRunning && _activeTrip == null) {
        _validateTripRequirement();
      }
    });
  }

  Future<void> _startTripAndTracking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verifica CPF antes de iniciar
      if (!_hasCpfConfigured) {
        _showCpfRequiredDialog();
        return;
      }
      
      // Verifica permissões antes de iniciar
      bool hasPermission = await LocationService.hasPermission();
      if (!hasPermission) {
        await LocationService.requestPermission();
        hasPermission = await LocationService.hasPermission();
        if (!hasPermission) {
          _showSnackBar('Permissões de localização são necessárias para iniciar viagem', isError: true);
          return;
        }
      }

      // Obtém a localização atual para iniciar a viagem
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _showSnackBar('Não foi possível obter a localização para iniciar viagem', isError: true);
        return;
      }

      // 1. Inicia a viagem na API
      final trip = await ApiService.startTrip(
        CpfValidator.cleanCpf(_cpf),
        position.latitude,
        position.longitude,
      );
      
      if (trip == null) {
        _showSnackBar('Erro ao iniciar viagem na API', isError: true);
        return;
      }

      // 2. Salva o CPF para uso no background service
      await BackgroundLocationService.saveCpf(CpfValidator.cleanCpf(_cpf));
      
      // 3. Inicia o serviço de rastreamento
      await BackgroundLocationService.startService();
      
      // 4. Atualiza estado local
      setState(() {
        _activeTrip = trip;
      });
      
      // 5. Salva status da viagem ativa
      await BackgroundLocationService.setActiveTripStatus(true);
      
      // 6. Inicia timer de validação
      _startTripValidationTimer();
      
      _showSnackBar('Viagem iniciada e rastreamento ativo!');
      await _loadBackgroundServiceState();
    } catch (e) {
      _showSnackBar('Erro ao iniciar viagem: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopTripAndTracking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Para o serviço de rastreamento
      await BackgroundLocationService.stopService();
      
      // 2. Se há viagem ativa, finaliza ela
      if (_activeTrip != null) {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          await ApiService.endTrip(
            CpfValidator.cleanCpf(_cpf),
            position.latitude,
            position.longitude,
          );
        }
      }
      
      // 3. Atualiza estado local
      setState(() {
        _activeTrip = null;
      });
      
      // 4. Salva status da viagem ativa
      await BackgroundLocationService.setActiveTripStatus(false);
      
      // 5. Para o timer de validação
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

  Future<void> _updateBackgroundServiceInterval() async {
    final newInterval = await _showIntervalDialog();
    if (newInterval != null && newInterval != _backgroundServiceInterval) {
      setState(() {
        _isLoading = true;
      });

      try {
        await BackgroundLocationService.updateInterval(newInterval);
        setState(() {
          _backgroundServiceInterval = newInterval;
        });
        _showSnackBar('Intervalo atualizado para ${newInterval}s');
      } catch (e) {
        _showSnackBar('Erro ao atualizar intervalo: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int?> _showIntervalDialog() async {
    final controller = TextEditingController(text: _backgroundServiceInterval.toString());
    
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Intervalo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Digite o intervalo em segundos (mínimo: ${AppConfig.minBackgroundInterval}s):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Intervalo (segundos)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= AppConfig.minBackgroundInterval && value <= AppConfig.maxBackgroundInterval) {
                Navigator.of(context).pop(value);
              } else {
                _showSnackBar('Intervalo deve estar entre ${AppConfig.minBackgroundInterval} e ${AppConfig.maxBackgroundInterval} segundos', isError: true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verifica CPF antes de enviar
      if (!_hasCpfConfigured) {
        _showCpfRequiredDialog();
        return;
      }

      // Obtém a localização atual
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _showSnackBar('Não foi possível obter a localização', isError: true);
        return;
      }

      // Cria o objeto de localização
      final location = DriverLocation(
        cpf: CpfValidator.cleanCpf(_cpf),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        batteryLevel: _batteryLevel?.round(),
      );

      // Envia para a API
      final result = await ApiService.sendDriverLocation(location);
      
      if (result != null) {
        setState(() {
          _lastLocation = result;
        });
        _showSnackBar('Localização enviada com sucesso!');
      } else {
        _showSnackBar('Erro ao enviar localização', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      // CPF foi configurado, recarrega os dados
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Motorista'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfigScreen()),
              );
            },
            tooltip: 'Configurações da API',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  // Card Principal - Rastreamento em Background
                  Card(
                    elevation: 8,
                    color: _isBackgroundServiceRunning 
                        ? Colors.green.shade50 
                        : _hasCpfConfigured 
                            ? Colors.grey.shade50 
                            : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com ícone e título
                    Row(
                      children: [
                        Icon(
                          _isBackgroundServiceRunning ? Icons.my_location : Icons.location_off,
                          color: _isBackgroundServiceRunning ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConfig.trackingServiceText,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: _isBackgroundServiceRunning ? Colors.green.shade700 : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                BackgroundLocationService.getImplementationInfo(),
                                style: TextStyle(
                                  color: _isBackgroundServiceRunning ? Colors.green.shade600 : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                            const SizedBox(height: 20),

                            // Alerta de CPF não configurado
                            if (!_hasCpfConfigured) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CPF não configurado',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Configure seu CPF nas configurações avançadas para usar o aplicativo.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Status e informações
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isBackgroundServiceRunning 
                                    ? Colors.green.shade100 
                                    : _hasCpfConfigured 
                                        ? Colors.grey.shade100 
                                        : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isBackgroundServiceRunning ? Icons.play_circle_filled : Icons.pause_circle_filled,
                                color: _isBackgroundServiceRunning ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBackgroundServiceRunning 
                                  ? 'Rastreamento Ativo'
                                  : 'Rastreamento Inativo',
                                style: TextStyle(
                                  color: _isBackgroundServiceRunning ? Colors.green.shade800 : Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (_isBackgroundServiceRunning) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Enviando a cada $_backgroundServiceInterval segundos',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue, size: 16),
                                const SizedBox(width: 4),
                                const Text('Funciona mesmo com app fechado'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                            // Botão principal
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || !_hasCpfConfigured) ? null : (_isBackgroundServiceRunning ? _stopTripAndTracking : _startTripAndTracking),
                                icon: Icon(_isBackgroundServiceRunning ? Icons.stop : Icons.play_arrow, size: 24),
                                label: Text(
                                  !_hasCpfConfigured 
                                      ? 'Configure CPF primeiro'
                                      : _isBackgroundServiceRunning 
                                          ? 'Parar Viagem' 
                                          : 'Iniciar Viagem',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_hasCpfConfigured 
                                      ? Colors.grey
                                      : _isBackgroundServiceRunning 
                                          ? Colors.red 
                                          : Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

                            // Card de Status da Viagem e Rastreamento
            if (_activeTrip != null || _isBackgroundServiceRunning) ...[
              Card(
                elevation: 4,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            _activeTrip != null ? 'Viagem Ativa' : 'Rastreamento Ativo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'EM ANDAMENTO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_activeTrip != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Iniciada em:',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    _activeTrip!.startedAt != null 
                                        ? _formatDateTime(_activeTrip!.startedAt!)
                                        : 'N/A',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duração:',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    _activeTrip!.formattedDuration,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Localização sendo enviada automaticamente a cada $_backgroundServiceInterval segundos',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red.shade700, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Rastreamento ativo sem viagem associada',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'O rastreamento será encerrado automaticamente em breve. Viagem é obrigatória.',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Configurações Avançadas (ExpansionTile)
            Card(
              child: ExpansionTile(
                title: Text(
                  AppConfig.advancedSettingsText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: const Icon(Icons.settings),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Configuração de CPF
                        Card(
                          color: _hasCpfConfigured ? Colors.green.shade50 : Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _hasCpfConfigured ? Icons.check_circle : Icons.warning,
                                      color: _hasCpfConfigured ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CPF do Motorista',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _hasCpfConfigured ? Colors.green.shade700 : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_hasCpfConfigured) ...[
                                  Text(
                                    'CPF configurado: ${CpfValidator.formatCpf(_cpf)}',
                                    style: TextStyle(color: Colors.green.shade700),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Você pode alterar nas configurações.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ] else ...[
                                  const Text(
                                    'CPF não configurado. É obrigatório para usar o aplicativo.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _navigateToCpfConfig(),
                                    icon: Icon(_hasCpfConfigured ? Icons.edit : Icons.add),
                                    label: Text(_hasCpfConfigured ? 'Alterar CPF' : 'Configurar CPF'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Status do Motorista
                        Row(
                          children: [
                            const Text('Status: '),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
                            items: _statusOptions.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(AppConfig.statusDisplayNames[status] ?? status),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _status = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                        
                    const SizedBox(height: 16),
                        
                        // Bateria
                    Row(
                      children: [
                        const Text('Bateria (%): '),
                        Expanded(
                          child: TextField(
                            controller: _batteryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _batteryLevel = double.tryParse(value);
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Ex: 85',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
            ),
            
            const SizedBox(height: 16),

                        // Botões de ação
                    Row(
                      children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _updateBackgroundServiceInterval,
                                icon: const Icon(Icons.timer),
                                label: const Text('Intervalo'),
                              ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _sendLocation,
                                icon: const Icon(Icons.location_on),
                                label: const Text('Teste Manual'),
                              ),
                            ),
                          ],
                        ),
                        
                    const SizedBox(height: 8),
                        
                        
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Última Localização
            if (_lastLocation != null) ...[
              Text(
                'Última Localização Enviada',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Motorista', _lastLocation!.driverName ?? _lastLocation!.driverUsername ?? 'N/A'),
                      _buildInfoRow('Latitude', _lastLocation!.latitude.toString()),
                      _buildInfoRow('Longitude', _lastLocation!.longitude.toString()),
                      if (_lastLocation!.accuracy != null)
                        _buildInfoRow('Precisão', '${_lastLocation!.accuracy!.toStringAsFixed(2)} m'),
                      if (_lastLocation!.speed != null)
                        _buildInfoRow('Velocidade', '${_lastLocation!.speed!.toStringAsFixed(2)} km/h'),
                      if (_lastLocation!.batteryLevel != null)
                        _buildInfoRow('Bateria', '${_lastLocation!.batteryLevel}%'),
                      _buildInfoRow('Status', AppConfig.statusDisplayNames[_lastLocation!.status] ?? _lastLocation!.status),
                      if (_lastLocation!.timestamp != null)
                        _buildInfoRow('Enviado em', _formatDateTime(_lastLocation!.timestamp!)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Nenhuma localização enviada ainda',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Informações sobre a API
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Informações da API',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: AppConfig.apiBaseUrl,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text('• Servidor: ${snapshot.data!.replaceAll('/api/v1', '')}');
                        }
                        return const Text('• Servidor: Carregando...');
                      },
                    ),
                    const Text('• Endpoint: /api/drivers/send_location/'),
                    const Text('• CPF obrigatório e deve estar cadastrado'),
                    const Text('• Motorista deve existir previamente'),
                    const Text('• Iniciar Viagem → Cria viagem + inicia rastreamento'),
                    const Text('• Parar Viagem → Para rastreamento + finaliza viagem'),
                  ],
                ),
              ),
            ),
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
            width: 80,
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
}
