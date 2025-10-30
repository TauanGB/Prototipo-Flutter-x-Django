import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer' as developer;

/// Tela WebView para Consulta/Detalhes Administrativos
/// 
/// ⚠️ ATENÇÃO: Esta tela WebView é APENAS PARA CONSULTA.
/// 
/// O motorista NÃO deve alterar status de frete aqui.
/// Toda alteração operacional deve acontecer exclusivamente na HomeMotoristaPage.
/// 
/// PROPÓSITO:
/// Esta tela carrega páginas web do sistema EG3 e serve APENAS para consulta
/// de detalhes administrativos, histórico e informações adicionais.
/// 
/// A tela principal operacional do motorista é a HomeMotoristaPage, onde ele
/// deve executar TODAS as ações da jornada diária:
/// - Iniciar viagem
/// - Ver rota e fretes
/// - Avançar status do frete atual (OFFLINE)
/// - Concluir fretes
/// 
/// Esta WebView é complementar e apenas consultiva.
/// Nenhuma ação de mudança de status deve ser executada através desta WebView.
/// 
/// OBSERVAÇÃO TÉCNICA:
/// Se houver qualquer lógica neste código que tente detectar cliques em botões
/// do painel web para atualizar status de frete (via JS bridge / postMessage /
/// interceptação de URL), essa lógica DEVE SER REMOVIDA.
/// A WebView não deve enviar ações de mudança de status para o backend.
class WebViewScreen extends StatefulWidget {
  static const String _baseUrl = 'https://sistemaeg3-production.up.railway.app';
  
  // Construtor pode receber path relativo
  const WebViewScreen({
    super.key,
    this.path = '',
    this.title = 'Painel do Motorista',
  });
  
  final String path;
  final String title;
  
  String get fullUrl => '$_baseUrl$path';

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isSSLErrorFlag = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 AppMotorista/1.0')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            developer.log('📊 Progresso do carregamento: $progress%', name: 'WebView');
          },
          onPageStarted: (String url) {
            developer.log('🚀 Iniciando carregamento: $url', name: 'WebView');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            developer.log('✅ Página carregada com sucesso: $url', name: 'WebView');
            setState(() {
              _isLoading = false;
              _retryCount = 0; // Reset retry count on success
            });
          },
          onWebResourceError: (WebResourceError error) {
            developer.log('❌ Erro no WebView: ${error.description} (Código: ${error.errorCode})', name: 'WebView');
            _handleWebResourceError(error);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Navegação permitida - WebView é apenas consulta
            // Não interceptamos aqui nenhuma ação de atualização de status
            // Pois toda operação deve acontecer na HomeMotoristaPage
            developer.log('🧭 Navegação solicitada: ${request.url}', name: 'WebView');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.fullUrl));
  }

  void _handleWebResourceError(WebResourceError error) {
    _isSSLErrorFlag = _isSSLError(error);
    
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = _getErrorMessage(error);
    });

    // Tentar novamente automaticamente para erros SSL
    if (_isSSLErrorFlag && _retryCount < _maxRetries) {
      _retryCount++;
      developer.log('🔄 Tentativa de reconexão $_retryCount/$_maxRetries', name: 'WebView');
      
      Future.delayed(Duration(seconds: _retryCount * 2), () {
        if (mounted) {
          _retryLoad();
        }
      });
    }
  }

  bool _isSSLError(WebResourceError error) {
    // Códigos de erro SSL comuns
    return error.errorCode == -200 || // SSL handshake failed
           error.errorCode == -1200 || // SSL certificate error
           error.errorCode == -1201 || // SSL certificate not trusted
           error.errorCode == -1202 || // SSL certificate invalid
           error.errorCode == -1203 || // SSL certificate expired
           error.errorCode == -1204 || // SSL certificate required
           error.errorCode == -1205 || // SSL certificate weak
           error.errorCode == -1206 || // SSL certificate unknown
           error.description.toLowerCase().contains('ssl') ||
           error.description.toLowerCase().contains('handshake') ||
           error.description.toLowerCase().contains('certificate');
  }

  String _getErrorMessage(WebResourceError error) {
    if (_isSSLError(error)) {
      return 'Erro de conexão SSL. Verificando certificado...';
    }
    
    switch (error.errorCode) {
      case -1009:
        return 'Sem conexão com a internet';
      case -1001:
        return 'Tempo limite de conexão excedido';
      case -1003:
        return 'Servidor não encontrado';
      case -1004:
        return 'Conexão recusada pelo servidor';
      default:
        return 'Erro ao carregar a página: ${error.description}';
    }
  }

  void _retryLoad() {
    developer.log('🔄 Tentando recarregar a página...', name: 'WebView');
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...'),
                ],
              ),
            ),
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSSLErrorFlag ? Icons.security : Icons.error_outline,
                      size: 64,
                      color: _isSSLErrorFlag ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSSLErrorFlag ? 'Problema de Conexão Segura' : 'Erro ao carregar a página',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_retryCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tentativa $_retryCount de $_maxRetries',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _retryCount < _maxRetries ? _retryLoad : null,
                          icon: const Icon(Icons.refresh),
                          label: Text(_retryCount < _maxRetries ? 'Tentar Novamente' : 'Máximo de tentativas'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _isLoading = true;
                              _retryCount = 0;
                            });
                            _controller.reload();
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Voltar ao Início'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}