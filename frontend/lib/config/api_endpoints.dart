import 'app_config.dart';

/// Classe centralizada para gerenciar todos os endpoints da API
/// Sistema de Gestão de Fretes para Motoristas
class ApiEndpoints {
  // URL base da API - usa configuração centralizada
  static String get _baseUrl => AppConfig.apiBaseUrl;
  
  // === AUTENTICAÇÃO ===
  /// Verificar se CPF existe (API pública)
  String get verificarCpfPublico => 
    '$_baseUrl/api/usuarios/publico/verificar-cpf/';
  
  /// Login por CPF + senha (API pública)
  String get loginPorCpf => 
    '$_baseUrl/api/usuarios/publico/login-cpf/';
  
  /// Obter token de autenticação
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
  
  // === FRETES ===
  /// Listar todos os fretes (filtrado por motorista)
  String get fretes => '$_baseUrl/api/fretes/fretes/';
  
  /// Fretes ativos
  String get fretesAtivos => '$_baseUrl/api/fretes/fretes/ativos/';
  
  /// Fretes elegíveis para um motorista
  String get fretesElegiveis => '$_baseUrl/api/fretes/fretes/elegiveis/';
  
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
  
  /// Rota atual do motorista (GET autenticado)
  /// Usando endpoint dedicado /motorista/rota-atual/ (funciona em localhost e produção)
  String get rotaAtualMotorista => 
    '$_baseUrl/api/fretes/motorista/rota-atual/';
  
  /// ID da rota ativa do motorista (lightweight)
  String get motoristaRotaId => 
    '$_baseUrl/api/fretes/motorista/rota-id/';

  /// Fretes detalhados de uma rota específica
  String rotaFretesDetail(int rotaId) => 
    '$_baseUrl/api/fretes/rotas/$rotaId/fretes/';

  /// Rota completa do motorista (dados + fretes em uma requisição)
  String get motoristaRotaCompleta => 
    '$_baseUrl/api/fretes/motorista/rota-completa/';

  // === MOBILE INCREMENTAL (localhost e compatível) ===
  /// Contagem de fretes da rota atual
  String get mobileRotaAtualCount =>
    '$_baseUrl/api/mobile/motorista/rota-atual/count/';

  /// Dados gerais da rota (sem fretes)
  String get mobileRotaAtualInfo =>
    '$_baseUrl/api/mobile/motorista/rota-atual/info/';

  /// Frete por índice (zero-based)
  String mobileFreteByIndex(int rotaId, int index) =>
    '$_baseUrl/api/mobile/motorista/rotas/$rotaId/fretes/$index/';

  /// Iniciar rota explicitamente (motorista)
  String mobileIniciarRota(int rotaId) =>
    '$_baseUrl/api/mobile/motorista/rotas/$rotaId/iniciar/';
  
  /// Cancelar rota atual do motorista (mobile)
  String get mobileCancelarRotaAtual =>
    '$_baseUrl/api/mobile/motorista/rota-atual/cancelar/';
  
  /// Rota atual do motorista (legado - listar todas)
  String get rotaAtual => '$_baseUrl/api/fretes/rotas/';
  
  /// Sincronização periódica do motorista (POST autenticado)
  String get syncMotorista => 
    '$_baseUrl/api/fretes/motorista/sync/';
  
  /// Sincronização periódica do motorista (legado)
  String get syncMotoristaLegado => '$_baseUrl/api/fretes/motorista/iniciar-viagem/';

  // === DRIVERS (API de Rastreamento) ===
  /// Base URL para endpoints de drivers
  String get drivers => '$_baseUrl/api/usuarios/motorista';
  
  // === ROTAS ===
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
  
  // === CLIENTES ===
  /// Listar clientes
  String get clientes => '$_baseUrl/api/fretes/clientes/';
  
  /// Detalhes de um cliente
  String clienteDetail(int id) => '$_baseUrl/api/fretes/clientes/$id/';
  
  // === RELATÓRIOS ===
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
  
  // === RASTREAMENTO GPS ===
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