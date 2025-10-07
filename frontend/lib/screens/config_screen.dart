import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_config.dart';
import '../services/config_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _protocolController = TextEditingController();
  final _basePathController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTestingConnection = false;
  ApiConfig? _currentConfig;
  String? _connectionTestResult;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _protocolController.dispose();
    _basePathController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await ConfigService.getApiConfig();
      setState(() {
        _currentConfig = config;
        _hostController.text = config.host;
        _portController.text = config.port.toString();
        _protocolController.text = config.protocol;
        _basePathController.text = config.basePath;
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar configuração: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = ApiConfig(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        protocol: _protocolController.text.trim(),
        basePath: _basePathController.text.trim(),
      );

      final success = await ConfigService.saveApiConfig(config);
      
      if (success) {
        setState(() {
          _currentConfig = config;
          _connectionTestResult = null;
        });
        _showSuccessSnackBar('Configuração salva com sucesso!');
      } else {
        _showErrorSnackBar('Erro ao salvar configuração');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar configuração: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    try {
      // Primeiro salva a configuração atual para testar
      final config = ApiConfig(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        protocol: _protocolController.text.trim(),
        basePath: _basePathController.text.trim(),
      );

      await ConfigService.saveApiConfig(config);
      
      // Testa a conexão
      final isConnected = await ConfigService.testConnection();
      
      setState(() {
        _connectionTestResult = isConnected 
            ? 'Conexão bem-sucedida!' 
            : 'Falha na conexão. Verifique os parâmetros.';
      });

      if (isConnected) {
        _showSuccessSnackBar('Teste de conexão bem-sucedido!');
      } else {
        _showErrorSnackBar('Falha no teste de conexão');
      }
    } catch (e) {
      setState(() {
        _connectionTestResult = 'Erro ao testar conexão: $e';
      });
      _showErrorSnackBar('Erro ao testar conexão: $e');
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await _showConfirmDialog(
      'Resetar Configuração',
      'Deseja realmente resetar para as configurações padrão?',
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ConfigService.resetApiConfig();
        await _loadCurrentConfig();
        setState(() {
          _connectionTestResult = null;
        });
        _showSuccessSnackBar('Configuração resetada para padrão!');
      } catch (e) {
        _showErrorSnackBar('Erro ao resetar configuração: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da API'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCurrentConfig,
            tooltip: 'Recarregar configuração',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card com informações atuais
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuração Atual',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_currentConfig != null) ...[
                              Text('URL: ${_currentConfig!.baseUrl}'),
                              Text('Host: ${_currentConfig!.host}'),
                              Text('Porta: ${_currentConfig!.port}'),
                              Text('Protocolo: ${_currentConfig!.protocol}'),
                              Text('Caminho: ${_currentConfig!.basePath}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Campos de configuração
                    Text(
                      'Parâmetros de Conexão',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Protocolo
                    DropdownButtonFormField<String>(
                      initialValue: _protocolController.text.isNotEmpty 
                          ? _protocolController.text 
                          : 'http',
                      decoration: const InputDecoration(
                        labelText: 'Protocolo',
                        hintText: 'http ou https',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'http', child: Text('HTTP')),
                        DropdownMenuItem(value: 'https', child: Text('HTTPS')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _protocolController.text = value ?? 'http';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione um protocolo';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Campo Host
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'Host/Endereço IP',
                        hintText: 'Ex: 127.0.0.1 ou 10.0.2.2',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite o host ou endereço IP';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Campo Porta
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Porta',
                        hintText: 'Ex: 8000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.network_check),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite a porta';
                        }
                        final port = int.tryParse(value.trim());
                        if (port == null || port < 1 || port > 65535) {
                          return 'Porta deve ser um número entre 1 e 65535';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Campo Caminho Base
                    TextFormField(
                      controller: _basePathController,
                      decoration: const InputDecoration(
                        labelText: 'Caminho Base da API',
                        hintText: 'Ex: /api/v1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite o caminho base da API';
                        }
                        if (!value.trim().startsWith('/')) {
                          return 'Caminho deve começar com /';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Resultado do teste de conexão
                    if (_connectionTestResult != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionTestResult!.contains('bem-sucedida')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          border: Border.all(
                            color: _connectionTestResult!.contains('bem-sucedida')
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _connectionTestResult!.contains('bem-sucedida')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _connectionTestResult!.contains('bem-sucedida')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionTestResult!,
                                style: TextStyle(
                                  color: _connectionTestResult!.contains('bem-sucedida')
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTestingConnection ? null : _testConnection,
                            icon: _isTestingConnection
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.network_check),
                            label: const Text('Testar Conexão'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetToDefault,
                            icon: const Icon(Icons.restore),
                            label: const Text('Resetar'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Botão Salvar
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveConfig,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Salvar Configuração'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informações de ajuda
                    Card(
                      color: Colors.blue.withOpacity(0.1),
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
                                  'Dicas de Configuração',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Para Android (emulador): use 10.0.2.2 como host\n'
                              '• Para desktop/web: use 127.0.0.1 ou localhost\n'
                              '• Porta padrão do Django: 8000\n'
                              '• Caminho base geralmente é /api/v1',
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}



