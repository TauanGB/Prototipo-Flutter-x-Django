import 'package:flutter/material.dart';
import 'home_motorista_page.dart';
import 'unified_profile_screen.dart';
import 'webview_screen.dart';

/// Tela de navegação principal do aplicativo
/// 
/// Gerenciamento das três abas principais:
/// - Aba 0 (Início): HomeMotoristaPage - Tela operacional principal do motorista
///   Esta é onde o motorista executa sua jornada diária: iniciar viagem,
///   ver fretes, avançar status, etc.
/// - Aba 1 (Painel): WebViewScreen - Apenas para consulta de detalhes
///   administrativos do sistema EG3. NÃO é o local principal para operações.
/// - Aba 2 (Perfil): UnifiedProfileScreen - Configurações e perfil do motorista
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        // Tela operacional principal - Home do motorista
        return const HomeMotoristaPage();
      case 1:
        // WebView apenas para consulta/detalhes (não deve ser usado para operações principais)
        return const WebViewScreen(
          path: '',
          title: 'Painel do Motorista',
        );
      case 2:
        return const UnifiedProfileScreen();
      default:
        return const HomeMotoristaPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.web_outlined),
              activeIcon: Icon(Icons.web),
              label: 'Painel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
