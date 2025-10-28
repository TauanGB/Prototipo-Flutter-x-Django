import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/auth_service_eg3.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida CPF
  bool _isValidCpf(String cpf) {
    // Remove caracteres não numéricos
    final cleanCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    
    // Verifica se tem 11 dígitos
    if (cleanCpf.length != 11) return false;
    
    // Verifica se não são todos iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;
    
    // Validação básica do CPF
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanCpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;
    
    if (int.parse(cleanCpf[9]) != digit1) return false;
    
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cleanCpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;
    
    return int.parse(cleanCpf[10]) == digit2;
  }

  /// Formata CPF
  String _formatCpf(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCpf.length <= 11) {
      if (cleanCpf.length <= 3) return cleanCpf;
      if (cleanCpf.length <= 6) return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3)}';
      if (cleanCpf.length <= 9) return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6)}';
      return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9)}';
    }
    return cpf;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('🔐 Iniciando login por CPF', name: 'LoginScreen');
      
      final authService = AuthServiceEG3();
      final cpf = _usernameController.text.trim();
      final password = _passwordController.text;
      
      // Login direto - uma única requisição
      final result = await authService.loginComCpf(cpf, password);

      if (result['success']) {
        developer.log('✅ Login realizado com sucesso', name: 'LoginScreen');
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      } else {
        developer.log('❌ Falha no login: ${result['message']}', name: 'LoginScreen');
        setState(() {
          _errorMessage = result['message'] ?? 'CPF ou senha incorretos';
        });
      }
    } catch (e) {
      developer.log('❌ Erro inesperado no login: $e', name: 'LoginScreen');
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique sua internet.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo da empresa
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white.withOpacity(0.05) 
                              : Colors.white,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/Logo_App_Motoristas.png',
                            fit: BoxFit.contain,
                            // Para modo escuro, aplicamos um filtro para melhorar a visibilidade
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withOpacity(0.9)
                                : null,
                            colorBlendMode: Theme.of(context).brightness == Brightness.dark 
                                ? BlendMode.modulate
                                : BlendMode.srcOver,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SistemaEG3',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.headlineMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login do Motorista',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Mensagem de erro
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Campo de CPF ou Username
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'CPF ou Username',
                          hintText: '000.000.000-00 ou seu_username',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          // Tenta formatar como CPF apenas se não contiver letras
                          if (!value.contains(RegExp(r'[a-zA-Z]'))) {
                            final formatted = _formatCpf(value);
                            if (formatted != value) {
                              _usernameController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'CPF ou Username é obrigatório';
                          }

                          // Verifica se contém letras para decidir se é username ou CPF
                          final containsLetters = value.contains(RegExp(r'[a-zA-Z]'));

                          if (containsLetters) {
                            // Validação de Username
                            if (value.length < 3) {
                              return 'Username deve ter pelo menos 3 caracteres';
                            }
                          } else {
                            // Validação de CPF
                            final cleanCpf = value.replaceAll(RegExp(r'[^\d]'), '');
                            if (cleanCpf.length != 11) {
                              return 'CPF deve conter 11 dígitos';
                            }
                            if (!_isValidCpf(cleanCpf)) {
                              return 'CPF inválido';
                            }
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo de senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Digite sua senha',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Senha é obrigatória';
                          }
                          if (value.length < 6) {
                            return 'Senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botão de login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Informações adicionais
                      Text(
                        'Entre em contato com o administrador se não conseguir acessar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
