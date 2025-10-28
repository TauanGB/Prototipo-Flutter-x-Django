import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/config/app_theme.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/widgets/splash_screen.dart';
import 'dart:developer' as developer;

/// Sistema EG3 - App para Motoristas
/// 
/// Este aplicativo é exclusivamente para dispositivos móveis:
/// - Android (API 21+)
/// - iOS (iOS 12.0+)
/// 
/// Não há suporte para web, desktop ou outras plataformas.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Solicita permissões necessárias para dispositivos móveis
  await _requestPermissions();
  
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Permissões para localização
  await Permission.location.request();
  await Permission.locationAlways.request();
  await Permission.locationWhenInUse.request();
  
  // Permissões para notificações
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  
  // Permissões para armazenamento (Android)
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  
  developer.log('🔐 Permissões solicitadas', name: 'Main');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(
        duration: Duration(seconds: 3),
        child: AuthWrapper(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      developer.log('🔍 Verificando status de autenticação...', name: 'AuthWrapper');
      
      // Verifica se está logado (apenas local, sem requisições HTTP)
      final isLoggedIn = await StorageService.isLoggedIn();
      
      if (isLoggedIn) {
        // Valida token localmente apenas (sem requisições HTTP)
        final token = await StorageService.getAuthToken();
        final isValidToken = token != null && token.isNotEmpty;
        
        developer.log('🔑 Token válido: $isValidToken', name: 'AuthWrapper');
        
        setState(() {
          _isLoggedIn = isValidToken;
          _isLoading = false;
        });
      } else {
        developer.log('❌ Usuário não está logado', name: 'AuthWrapper');
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('❌ Erro ao verificar autenticação: $e', name: 'AuthWrapper');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainNavigationScreen() : const LoginScreen();
  }
}

