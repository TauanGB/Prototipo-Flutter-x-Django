import 'package:flutter/material.dart';
import 'cpf_config_screen.dart';
import '../services/background_location_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _cpf = '';
  bool _hasCpfConfigured = false;
  bool _isBackgroundServiceRunning = false;
  int _backgroundServiceInterval = AppConfig.defaultBackgroundInterval;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedCpf = await BackgroundLocationService.getSavedCpf();
    final isRunning = await BackgroundLocationService.isServiceRunning();
    final interval = await BackgroundLocationService.getCurrentInterval();
    
    setState(() {
      _cpf = savedCpf;
      _hasCpfConfigured = savedCpf.isNotEmpty;
      _isBackgroundServiceRunning = isRunning;
      _backgroundServiceInterval = interval;
    });
  }

  Future<void> _navigateToCpfConfig() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CpfConfigScreen()),
    );
    
    if (result == true) {
      await _loadSettings();
      _showSnackBar('CPF configurado com sucesso!');
    }
  }

  Future<void> _navigateToApiConfig() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CpfConfigScreen()),
    );
    await _loadSettings();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: AppConfig.snackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de Configurações do Motorista
            _buildDriverConfigCard(),
            
            const SizedBox(height: 16),
            
            // Card de Configurações da API
            _buildApiConfigCard(),
            
            const SizedBox(height: 16),
            
            // Card de Status do Serviço
            _buildServiceStatusCard(),
            
            const SizedBox(height: 16),
            
            // Card de Informações do App
            _buildAppInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverConfigCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Configurações do Motorista',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // CPF Configuration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasCpfConfigured ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasCpfConfigured ? Colors.green.shade300 : Colors.orange.shade300,
                ),
              ),
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
                      'CPF configurado: ${_formatCpf(_cpf)}',
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
                      onPressed: _navigateToCpfConfig,
                      icon: Icon(_hasCpfConfigured ? Icons.edit : Icons.add),
                      label: Text(_hasCpfConfigured ? 'Alterar CPF' : 'Configurar CPF'),
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

  Widget _buildApiConfigCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Configurações da API',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Configure a URL da API e outras configurações de conexão.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _navigateToApiConfig,
                icon: const Icon(Icons.settings),
                label: const Text('Configurar API'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.engineering, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Status do Serviço',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isBackgroundServiceRunning 
                    ? Colors.green.shade50 
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isBackgroundServiceRunning 
                      ? Colors.green.shade300 
                      : Colors.grey.shade300,
                ),
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
                          ? 'Serviço de Rastreamento Ativo'
                          : 'Serviço de Rastreamento Inativo',
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
                      'Intervalo: $_backgroundServiceInterval segundos',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
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

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Informações do App',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Nome do App', AppConfig.appName),
            _buildInfoRow('Versão', AppConfig.appVersion),
            _buildInfoRow('Implementação', BackgroundLocationService.getImplementationInfo()),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Dicas:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Configure o CPF antes de usar o app\n• O rastreamento funciona em background\n• Verifique as permissões de localização',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
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

  String _formatCpf(String cpf) {
    if (cpf.length == 11) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    }
    return cpf;
  }
}
