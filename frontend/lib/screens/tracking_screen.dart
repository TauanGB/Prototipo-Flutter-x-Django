import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver_location.dart';
import '../models/driver_trip.dart';
import '../services/background_location_service.dart';
import '../config/app_config.dart';
import '../utils/animations.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  DriverLocation? _lastLocation;
  DriverTrip? _activeTrip;
  
  // Variáveis para o serviço de background
  bool _isBackgroundServiceRunning = false;
  int _backgroundServiceInterval = AppConfig.defaultBackgroundInterval;
  Timer? _tripValidationTimer;

  @override
  void initState() {
    super.initState();
    _loadBackgroundServiceState();
    _restoreActiveTrip();
  }

  @override
  void dispose() {
    _tripValidationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBackgroundServiceState() async {
    final isRunning = await BackgroundLocationService.isServiceRunning();
    final interval = await BackgroundLocationService.getCurrentInterval();
    setState(() {
      _isBackgroundServiceRunning = isRunning;
      _backgroundServiceInterval = interval;
    });
  }


  Future<void> _restoreActiveTrip() async {
    try {
      final savedTripData = await BackgroundLocationService.restoreActiveTripData();
      if (savedTripData != null) {
        final restoredTrip = DriverTrip.fromJson(savedTripData);
        setState(() {
          _activeTrip = restoredTrip;
        });
      }
    } catch (e) {
      // Erro silencioso
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreamento'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBackgroundServiceState();
          await _restoreActiveTrip();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de Status do Rastreamento
              AppAnimations.cardAnimation(
                child: _buildTrackingStatusCard(),
              ),
              
              const SizedBox(height: 16),
              
              
              const SizedBox(height: 16),
              
              // Card de Informações da Viagem
              if (_activeTrip != null)
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

  Widget _buildTrackingStatusCard() {
    return Card(
      elevation: 8,
      color: _isBackgroundServiceRunning 
          ? Colors.green.shade50 
          : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        'Status do Rastreamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _isBackgroundServiceRunning ? Colors.green.shade700 : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isBackgroundServiceRunning 
                          ? 'Rastreamento ativo em background'
                          : 'Rastreamento inativo',
                        style: TextStyle(
                          color: _isBackgroundServiceRunning ? Colors.green.shade600 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isBackgroundServiceRunning 
                    ? Colors.green.shade100 
                    : Colors.grey.shade100,
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
          ],
        ),
      ),
    );
  }


  Widget _buildTripInfoCard() {
    return Card(
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
                  'Viagem Ativa',
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
          ],
        ),
      ),
    );
  }

  Widget _buildLastLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última Localização Enviada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
