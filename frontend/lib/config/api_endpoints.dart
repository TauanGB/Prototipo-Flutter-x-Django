/// Classe centralizada para gerenciar todos os endpoints da API
/// URL hard-coded para produção no Railway
class ApiEndpoints {
  // URL hard-coded de produção
  static const String _baseUrl = 'https://sistemaeg3-production.up.railway.app';
  
  // === AUTENTICAÇÃO (SistemaEG3) ===
  /// Verificar se CPF existe (API pública)
  String get verificarCpfPublico => 
    '$_baseUrl/api/usuarios/publico/verificar-cpf/';
  
  /// Login por CPF + senha (API pública)
  String get loginPorCpf => 
    '$_baseUrl/api/usuarios/publico/login-cpf/';
  
  /// Obter token de autenticação (fallback)
  String get obtainAuthToken => '$_baseUrl/api/auth/token/';
  
  /// Login alternativo (session-based)
  String get login => '$_baseUrl/api/usuarios/auth/login/';
  
  /// Logout
  String get logout => '$_baseUrl/api/usuarios/auth/logout/';
  
  /// Informações do usuário logado
  String get userInfo => '$_baseUrl/api/usuarios/auth/user-info/';
  
  /// Perfil completo do usuário
  String get perfilUsuario => '$_baseUrl/api/usuarios/usuarios/perfil/';
  
  /// Alterar senha
  String get alterarSenha => '$_baseUrl/api/usuarios/usuarios/alterar-senha/';
  
  // === FRETES (SistemaEG3) ===
  /// Listar todos os fretes (filtrado por motorista)
  String get fretes => '$_baseUrl/api/fretes/fretes/';
  
  /// Fretes ativos
  String get fretesAtivos => '$_baseUrl/api/fretes/fretes/ativos/';
  
  /// Fretes do motorista logado
  String get fretesPorMotorista => '$_baseUrl/api/fretes/fretes-por-motorista/';
  
  /// Detalhes de um frete específico
  String freteDetail(int id) => '$_baseUrl/api/fretes/fretes/$id/';
  
  /// Atualizar status do frete
  String freteAtualizarStatus(int freteId) => 
    '$_baseUrl/api/fretes/fretes/$freteId/atualizar-status/';
  
  /// Buscar frete por código público
  String fretePorCodigo(String codigo) => 
    '$_baseUrl/api/fretes/fretes/codigo/$codigo/';
  
  /// Estatísticas de fretes
  String get fretesStats => '$_baseUrl/api/fretes/fretes/stats/';

  // === DRIVERS (API de Rastreamento) ===
  /// Base URL para endpoints de drivers
  String get drivers => '$_baseUrl/api/drivers';
  
  // === ROTAS (SistemaEG3) ===
  /// Listar rotas do motorista
  String get rotas => '$_baseUrl/api/fretes/rotas/';
  
  /// Detalhes de uma rota
  String rotaDetail(int id) => '$_baseUrl/api/fretes/rotas/$id/';
  
  /// Iniciar rota
  String rotaIniciar(int id) => '$_baseUrl/api/fretes/rotas/$id/iniciar/';
  
  /// Concluir rota
  String rotaConcluir(int id) => '$_baseUrl/api/fretes/rotas/$id/concluir/';
  
  /// Sugerir ordem de fretes na rota
  String get rotaSugerirOrdem => '$_baseUrl/api/fretes/rotas/sugerir-ordem/';
  
  /// Atualizar ordem dos fretes na rota
  String rotaAtualizarOrdem(int id) => 
    '$_baseUrl/api/fretes/rotas/$id/atualizar-ordem/';
  
  // === CLIENTES (SistemaEG3) ===
  /// Listar clientes
  String get clientes => '$_baseUrl/api/fretes/clientes/';
  
  /// Detalhes de um cliente
  String clienteDetail(int id) => '$_baseUrl/api/fretes/clientes/$id/';
  
  // === RELATÓRIOS (SistemaEG3) ===
  /// Dashboard de estatísticas
  String get dashboardStats => '$_baseUrl/api/relatorios/dashboard/stats/';
  
  /// Configurações do dashboard
  String get dashboardConfig => '$_baseUrl/api/relatorios/dashboard/config/';
  
  /// Relatório de produtividade do motorista
  String get produtividadeMotorista => 
    '$_baseUrl/api/relatorios/produtividade/motorista/';
  
  /// Indicadores de performance
  String get indicadoresPerformance => 
    '$_baseUrl/api/relatorios/indicadores-performance/';
  
  // === RASTREAMENTO GPS (SistemaEG3 - APIs Migradas) ===
  /// Enviar localização GPS por CPF
  String get rastreioSendLocation => 
    '$_baseUrl/api/usuarios/motorista/enviar-localizacao/';
  
  /// Iniciar viagem de rastreamento por CPF
  String get rastreioStartTrip => 
    '$_baseUrl/api/fretes/motorista/iniciar-viagem/';
  
  /// Finalizar viagem de rastreamento por CPF
  String get rastreioEndTrip => 
    '$_baseUrl/api/fretes/motorista/finalizar-viagem/';
  
  /// Verificar se motorista existe por CPF
  String get rastreioCheckDriver => 
    '$_baseUrl/api/usuarios/motorista/verificar-cpf/';
  
  /// Obter fretes ativos por CPF
  String get rastreioActiveFretes => 
    '$_baseUrl/api/usuarios/motorista/fretes-ativos/';
  
  /// Obter fretes ativos por ID do motorista (alternativa)
  String get rastreioActiveFretesPorId => 
    '$_baseUrl/api/usuarios/motorista/fretes-ativos-por-id/';
  
  /// Enviar localização com frete (compatibilidade)
  String get rastreioSendLocationWithFrete => 
    '$_baseUrl/api/usuarios/motorista/enviar-localizacao/';
  
  // === UTILIDADES ===
  /// Verificar se URL é válida
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  /// Validar configuração
  bool get isValid {
    return isValidUrl(_baseUrl);
  }
  
  /// Obter informações de debug
  Map<String, dynamic> get debugInfo => {
    'baseUrl': _baseUrl,
    'isValid': isValid,
  };
  
  @override
  String toString() {
    return 'ApiEndpoints(baseUrl: $_baseUrl)';
  }
}