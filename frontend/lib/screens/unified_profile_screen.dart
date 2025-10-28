import 'dart:async';
import 'package:flutter/material.dart';
import '../services/background_location_service.dart';
import '../services/storage_service.dart';
import '../config/app_theme.dart';
import '../utils/animations.dart';
import 'login_screen.dart';

class UnifiedProfileScreen extends StatefulWidget {
  const UnifiedProfileScreen({super.key});

  @override
  State<UnifiedProfileScreen> createState() => _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  
  // Dados do usuário
  Map<String, dynamic>? _userData;
  bool _hasCpfConfigured = false;
  
  // Dados de rastreamento (apenas para status)
  bool _isBackgroundServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadUserData();
    await _loadBackgroundServiceState();
  }

  Future<void> _loadUserData() async {
    final userData = await StorageService.getUserData();
    setState(() {
      _userData = userData;
    });
  }

  Future<void> _loadBackgroundServiceState() async {
    final isRunning = await BackgroundLocationService.isServiceRunning();
    setState(() {
      _isBackgroundServiceRunning = isRunning;
    });
  }


  /// Obtém o nome completo do usuário dos dados salvos
  String _getFullName() {
    if (_userData == null) return 'Usuário';
    
    final user = _userData!['user'];
    if (user == null) return 'Usuário';
    
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    
    // Se tem primeiro e último nome, retorna nome completo
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    
    // Se tem apenas primeiro nome
    if (firstName.isNotEmpty) {
      return firstName;
    }
    
    // Se tem apenas último nome
    if (lastName.isNotEmpty) {
      return lastName;
    }
    
    // Fallback para username
    return user['username'] ?? 'Usuário';
  }


  Future<void> _handleLogout() async {
    if (_isBackgroundServiceRunning) {
      await BackgroundLocationService.stopService();
    }

    await StorageService.clearUserData();

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
              Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
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
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: AppTheme.warningColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Atenção:',
                          style: TextStyle(
                            color: AppTheme.warningColor,
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
                        color: AppTheme.warningColor.withOpacity(0.8),
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
                backgroundColor: Theme.of(context).colorScheme.error,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _buildProfileTab(),
    );
  }

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de Informações do Usuário
            AppAnimations.cardAnimation(
              child: _buildUserInfoCard(),
            ),
            
            const SizedBox(height: 16),
            
            // Card de Status da Conta
            AppAnimations.cardAnimation(
              child: _buildAccountStatusCard(),
            ),
            
            const SizedBox(height: 16),
            
            // Card de Ações da Conta
            AppAnimations.cardAnimation(
              child: _buildAccountActionsCard(),
            ),
          ],
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nome do usuário
            Text(
              _getFullName(),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Status online
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppTheme.successColor, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: AppTheme.successColor,
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
                Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Status da Conta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatusItem(
              'CPF Configurado',
              _hasCpfConfigured ? 'Sim' : 'Não',
              _hasCpfConfigured ? AppTheme.successColor : AppTheme.warningColor,
              _hasCpfConfigured ? Icons.check_circle : Icons.warning,
            ),
            
            const SizedBox(height: 12),
            
            _buildStatusItem(
              'Rastreamento',
              _isBackgroundServiceRunning ? 'Ativo' : 'Inativo',
              _isBackgroundServiceRunning ? AppTheme.successColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              _isBackgroundServiceRunning ? Icons.my_location : Icons.location_off,
            ),
            
            const SizedBox(height: 12),
            
            _buildStatusItem(
              'Último Login',
              _userData?['last_login'] != null 
                  ? _formatDateTime(DateTime.parse(_userData!['last_login']))
                  : 'N/A',
              Theme.of(context).colorScheme.primary,
              Icons.access_time,
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
                Icon(Icons.security, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Ações da Conta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
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
                  backgroundColor: Theme.of(context).colorScheme.error,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
