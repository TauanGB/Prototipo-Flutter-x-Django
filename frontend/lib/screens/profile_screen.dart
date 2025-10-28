import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/background_location_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  String _cpf = '';
  bool _hasCpfConfigured = false;
  bool _isBackgroundServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await StorageService.getUserData();
    final savedCpf = await BackgroundLocationService.getSavedCpf();
    final isRunning = await BackgroundLocationService.isServiceRunning();
    
    setState(() {
      _userData = userData;
      _cpf = savedCpf;
      _hasCpfConfigured = savedCpf.isNotEmpty;
      _isBackgroundServiceRunning = isRunning;
    });
  }

  Future<void> _handleLogout() async {
    // Para o serviço de rastreamento se estiver ativo
    if (_isBackgroundServiceRunning) {
      await BackgroundLocationService.stopService();
    }

    // Limpa todos os dados de autenticação
    await StorageService.clearUserData();

    // Navega para a tela de login
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Confirmar Logout'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tem certeza que deseja sair da sua conta?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Atenção:',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• O rastreamento será interrompido\n• Você precisará fazer login novamente\n• Os dados locais serão limpos',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de Informações do Usuário
              _buildUserInfoCard(),
              
              const SizedBox(height: 16),
              
              // Card de Status da Conta
              _buildAccountStatusCard(),
              
              const SizedBox(height: 16),
              
              // Card de Configurações Pessoais
              _buildPersonalSettingsCard(),
              
              const SizedBox(height: 16),
              
              // Card de Ações da Conta
              _buildAccountActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nome do usuário
            Text(
              _userData?['name'] ?? _userData?['username'] ?? 'Usuário',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Username
            if (_userData?['username'] != null)
              Text(
                '@${_userData!['username']}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Status online
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildAccountStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Status da Conta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatusItem(
              'CPF Configurado',
              _hasCpfConfigured ? 'Sim' : 'Não',
              _hasCpfConfigured ? Colors.green : Colors.orange,
              _hasCpfConfigured ? Icons.check_circle : Icons.warning,
            ),
            
            const SizedBox(height: 12),
            
            _buildStatusItem(
              'Rastreamento',
              _isBackgroundServiceRunning ? 'Ativo' : 'Inativo',
              _isBackgroundServiceRunning ? Colors.green : Colors.grey,
              _isBackgroundServiceRunning ? Icons.my_location : Icons.location_off,
            ),
            
            const SizedBox(height: 12),
            
            _buildStatusItem(
              'Último Login',
              _userData?['last_login'] != null 
                  ? _formatDateTime(DateTime.parse(_userData!['last_login']))
                  : 'N/A',
              Colors.blue,
              Icons.access_time,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSettingsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Configurações Pessoais',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSettingItem(
              'CPF do Motorista',
              _hasCpfConfigured ? _formatCpf(_cpf) : 'Não configurado',
              _hasCpfConfigured ? Colors.green : Colors.orange,
              Icons.person,
            ),
            
            const SizedBox(height: 12),
            
            _buildSettingItem(
              'ID do Usuário',
              _userData?['id']?.toString() ?? 'N/A',
              Colors.blue,
              Icons.fingerprint,
            ),
            
            const SizedBox(height: 12),
            
            _buildSettingItem(
              'Email',
              _userData?['email'] ?? 'N/A',
              Colors.blue,
              Icons.email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Ações da Conta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutConfirmationDialog,
                icon: const Icon(Icons.logout),
                label: const Text('Sair da Conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCpf(String cpf) {
    if (cpf.length == 11) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    }
    return cpf;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
