import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/driver_location.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/auto_location_service.dart';
import '../services/background_location_service.dart';
import '../config/app_config.dart';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DriverLocation? _lastLocation;
  bool _isLoading = false;
  String _status = 'online';
  double? _batteryLevel;
  final List<String> _statusOptions = AppConfig.driverStatuses;
  final TextEditingController _batteryController = TextEditingController();
  late AutoLocationService _autoLocationService;
  
  // Variáveis para o serviço de background
  bool _isBackgroundServiceRunning = false;
  int _backgroundServiceInterval = 30;

  @override
  void initState() {
    super.initState();
    _autoLocationService = AutoLocationService();
    _autoLocationService.addListener(_onAutoLocationServiceChanged);
    _checkLocationPermission();
    _loadBackgroundServiceState();
  }

  @override
  void dispose() {
    _batteryController.dispose();
    _autoLocationService.removeListener(_onAutoLocationServiceChanged);
    super.dispose();
  }

  void _onAutoLocationServiceChanged() {
    setState(() {
      // Apenas atualiza a UI, não chama métodos que disparam notifyListeners
    });
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
  }

  Future<void> _toggleBackgroundService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isBackgroundServiceRunning) {
        await BackgroundLocationService.stopService();
        _showSnackBar('Serviço de background parado');
      } else {
        // Verifica permissões antes de iniciar
        bool hasPermission = await LocationService.hasPermission();
        if (!hasPermission) {
          await LocationService.requestPermission();
          hasPermission = await LocationService.hasPermission();
          if (!hasPermission) {
            _showSnackBar('Permissões de localização são necessárias para o serviço de background', isError: true);
            return;
          }
        }
        
        await BackgroundLocationService.startService();
        _showSnackBar('Serviço de background iniciado');
      }
      
      await _loadBackgroundServiceState();
    } catch (e) {
      _showSnackBar('Erro ao controlar serviço de background: $e', isError: true);
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
            const Text('Digite o intervalo em segundos (mínimo: 15s):'),
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
              if (value != null && value >= 15) {
                Navigator.of(context).pop(value);
              } else {
                _showSnackBar('Intervalo deve ser pelo menos 15 segundos', isError: true);
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
      // Obtém a localização atual
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _showSnackBar('Não foi possível obter a localização', isError: true);
        return;
      }

      // Cria o objeto de localização
      final location = DriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        status: _status,
        batteryLevel: _batteryLevel?.round(),
        isGpsEnabled: true,
        deviceId: 'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
        appVersion: AppConfig.appVersion,
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

  Future<void> _updateStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.updateDriverStatus(_status);
      if (result != null) {
        setState(() {
          _lastLocation = result;
        });
        _showSnackBar('Status atualizado com sucesso!');
      } else {
        _showSnackBar('Erro ao atualizar status', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final location = await ApiService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _lastLocation = location;
        });
        _showSnackBar('Localização atual obtida!');
      } else {
        _showSnackBar('Nenhuma localização encontrada', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _toggleAutoLocation() async {
    if (_autoLocationService.isRunning) {
      _autoLocationService.stop();
      _showSnackBar('Serviço automático pausado');
    } else {
      // Verifica permissões antes de iniciar
      bool hasPermission = await LocationService.hasPermission();
      if (!hasPermission) {
        await LocationService.requestPermission();
        hasPermission = await LocationService.hasPermission();
        if (!hasPermission) {
          _showSnackBar('Permissões de localização são necessárias para iniciar o serviço', isError: true);
          return;
        }
      }
      
      await _autoLocationService.start();
      String message = 'Serviço automático iniciado - Enviando a cada ${_autoLocationService.intervalSeconds}s';
      _showSnackBar(message);
    }
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Obter Localização Atual',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status do Motorista',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
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
                                // Atualiza o status no serviço automático
                                _autoLocationService.updateStatusSilent(_status);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              // Atualiza o nível da bateria no serviço automático
                              _autoLocationService.updateBatteryLevelSilent(_batteryLevel);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Ex: 85',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Botão de Controle Automático
            Card(
              color: _autoLocationService.isRunning ? Colors.green.shade50 : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _autoLocationService.isRunning ? Icons.play_circle : Icons.pause_circle,
                          color: _autoLocationService.isRunning ? Colors.green : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Serviço Automático de Localização',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _autoLocationService.isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _autoLocationService.isRunning 
                        ? 'Enviando localização a cada ${_autoLocationService.intervalSeconds} segundos'
                        : 'Serviço pausado',
                      style: TextStyle(
                        color: _autoLocationService.isRunning ? Colors.green.shade600 : Colors.grey.shade600,
                      ),
                    ),
                    if (_autoLocationService.isRunning) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text('Sucessos: ${_autoLocationService.successCount}'),
                          const SizedBox(width: 16),
                          Icon(Icons.error, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text('Erros: ${_autoLocationService.errorCount}'),
                        ],
                      ),
                      if (_autoLocationService.lastSentTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Último envio: ${_formatDateTime(_autoLocationService.lastSentTime!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleAutoLocation,
                        icon: Icon(_autoLocationService.isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_autoLocationService.isRunning ? 'Pausar Serviço' : 'Iniciar Serviço'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _autoLocationService.isRunning ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card do Serviço de Background
            Card(
              color: _isBackgroundServiceRunning ? Colors.blue.shade50 : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isBackgroundServiceRunning ? Icons.sync : Icons.sync_disabled,
                          color: _isBackgroundServiceRunning ? Colors.blue : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Serviço de Background',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _isBackgroundServiceRunning ? Colors.blue.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isBackgroundServiceRunning 
                        ? 'Enviando localização a cada $_backgroundServiceInterval segundos (mesmo com app fechado)'
                        : 'Serviço parado',
                      style: TextStyle(
                        color: _isBackgroundServiceRunning ? Colors.blue.shade600 : Colors.grey.shade600,
                      ),
                    ),
                    if (_isBackgroundServiceRunning) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          const Text('Funciona mesmo com app fechado'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _toggleBackgroundService,
                            icon: Icon(_isBackgroundServiceRunning ? Icons.stop : Icons.play_arrow),
                            label: Text(_isBackgroundServiceRunning ? 'Parar Serviço' : 'Iniciar Serviço'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isBackgroundServiceRunning ? Colors.red : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _updateBackgroundServiceInterval,
                          icon: const Icon(Icons.timer),
                          label: const Text('Intervalo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botões de Ação Manual
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _autoLocationService.isRunning) ? null : _sendLocation,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.location_on),
                    label: Text(_isLoading ? 'Enviando...' : 'Enviar Localização'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateStatus,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.update),
                    label: Text(_isLoading ? 'Atualizando...' : 'Atualizar Status'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

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
                    const Text('• Endpoint: /api/v1/driver-locations/'),
                    const Text('• Permite envio de dados sem autenticação'),
                    const Text('• Cria usuário anônimo automaticamente'),
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
