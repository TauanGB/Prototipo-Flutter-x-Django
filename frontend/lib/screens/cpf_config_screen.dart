import 'package:flutter/material.dart';
import '../services/cpf_validation_service.dart';
import '../services/background_location_service.dart';
import '../utils/cpf_validator.dart';
import '../widgets/cpf_input_field.dart';

class CpfConfigScreen extends StatefulWidget {
  const CpfConfigScreen({super.key});

  @override
  State<CpfConfigScreen> createState() => _CpfConfigScreenState();
}

class _CpfConfigScreenState extends State<CpfConfigScreen> {
  final TextEditingController _cpfController = TextEditingController();
  CpfValidationResult? _cpfValidation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCpf();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCpf() async {
    final savedCpf = await BackgroundLocationService.getSavedCpf();
    if (savedCpf.isNotEmpty) {
      setState(() {
        _cpfController.text = CpfValidator.formatCpf(savedCpf);
      });
      
      // Valida o CPF salvo automaticamente
      if (mounted) {
        try {
          final result = await CpfValidationService.validateAndCheckCpf(savedCpf);
          if (mounted) {
            setState(() {
              _cpfValidation = result;
            });
          }
        } catch (e) {
          // Silenciosamente ignora erro de validação ao carregar
        }
      }
    }
  }

  Future<void> _saveCpf() async {
    if (_cpfValidation == null || !_cpfValidation!.isRegistered) {
      _showSnackBar('CPF deve estar cadastrado no sistema', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cleanCpf = CpfValidator.cleanCpf(_cpfController.text);
      await BackgroundLocationService.saveCpf(cleanCpf);
      
      _showSnackBar('CPF salvo com sucesso!');
      
      // Volta para a tela anterior
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Erro ao salvar CPF: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _validateCpf() async {
    if (_cpfController.text.isEmpty) {
      _showSnackBar('Digite um CPF para validar', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CpfValidationService.validateAndCheckCpf(_cpfController.text);
      setState(() {
        _cpfValidation = result;
      });
      
      if (result.hasError) {
        _showSnackBar('Erro: ${result.error}', isError: true);
      } else if (result.isRegistered) {
        _showSnackBar('CPF cadastrado: ${result.name ?? "Motorista"}');
      } else {
        _showSnackBar('CPF não cadastrado no sistema', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao verificar CPF: $e', isError: true);
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de CPF'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de informações
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
                          'Configuração de CPF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• O CPF é obrigatório para usar o aplicativo'),
                    const Text('• Deve estar cadastrado no sistema'),
                    const Text('• Será validado automaticamente'),
                    const Text('• Fica salvo para próximas sessões'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Campo de CPF
            CpfInputField(
              controller: _cpfController,
              onValidationComplete: (result) {
                setState(() {
                  _cpfValidation = result;
                });
              },
            ),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _validateCpf,
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verificar CPF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _cpfValidation?.isRegistered != true) 
                        ? null 
                        : _saveCpf,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar CPF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status atual
            if (_cpfValidation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status do CPF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusInfo(),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Informações sobre o sistema
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre o Sistema',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Este aplicativo é destinado exclusivamente a motoristas cadastrados no sistema.'),
                    const SizedBox(height: 8),
                    const Text('O CPF será validado contra a base de dados oficial antes de permitir o uso das funcionalidades de rastreamento.'),
                    const SizedBox(height: 8),
                    const Text('Se você não possui cadastro, entre em contato com a administração.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    if (_cpfValidation!.hasError) {
      return Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _cpfValidation!.error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      );
    }
    
    if (_cpfValidation!.isRegistered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CPF Cadastrado',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_cpfValidation!.name != null) ...[
            const SizedBox(height: 8),
            Text('Motorista: ${_cpfValidation!.name}'),
          ],
          if (_cpfValidation!.phone != null) ...[
            Text('Telefone: ${_cpfValidation!.phone}'),
          ],
          if (_cpfValidation!.lastActivity != null) ...[
            Text('Última atividade: ${_formatDate(_cpfValidation!.lastActivity!)}'),
          ],
        ],
      );
    }
    
    return Row(
      children: [
        Icon(Icons.warning, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _cpfValidation!.message ?? 'CPF não cadastrado no sistema',
            style: TextStyle(color: Colors.orange.shade700),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
