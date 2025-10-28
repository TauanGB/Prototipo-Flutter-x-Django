/// Classe centralizada para gerenciar todos os endpoints da API
/// CORRIGIDA para funcionar com o backend Django local
class ApiEndpointsFixed {
  // URL do backend Django local
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';
  
  // === AUTENTICAÇÃO (Backend Django) ===
  /// Login por CPF + senha (usando endpoint existente)
  String get loginPorCpf => '$_baseUrl/auth/login/';
  
  /// Logout (usando endpoint existente)
  String get logout => '$_baseUrl/auth/logout/';
  
  /// Informações do usuário logado (usando endpoint existente)
  String get userInfo => '$_baseUrl/auth/user-info/';
  
  // === DRIVERS (API de Rastreamento - EXISTENTE) ===
  /// Enviar localização GPS por CPF
  String get rastreioSendLocation => '$_baseUrl/drivers/send_location/';
  
  /// Iniciar viagem de rastreamento por CPF
  String get rastreioStartTrip => '$_baseUrl/drivers/start_trip/';
  
  /// Finalizar viagem de rastreamento por CPF
  String get rastreioEndTrip => '$_baseUrl/drivers/end_trip/';
  
  /// Verificar se motorista existe por CPF
  String get rastreioCheckDriver => '$_baseUrl/drivers/check_driver/';
  
  /// Obter dados completos do motorista
  String get rastreioGetDriverData => '$_baseUrl/drivers/get_driver_data/';
  
  /// Obter fretes ativos por CPF
  String get rastreioActiveFretes => '$_baseUrl/drivers/get_active_fretes/';
  
  /// Obter rotas ativas por CPF
  String get rastreioActiveRotas => '$_baseUrl/drivers/get_active_rotas/';
  
  /// Enviar localização com frete
  String get rastreioSendLocationWithFrete => '$_baseUrl/drivers/send_location_with_frete/';
  
  /// Atualizar status de frete
  String get rastreioUpdateFreteStatus => '$_baseUrl/drivers/update_frete_status/';
  
  /// Iniciar rota
  String get rastreioStartRota => '$_baseUrl/drivers/start_rota/';
  
  /// Concluir rota
  String get rastreioCompleteRota => '$_baseUrl/drivers/complete_rota/';
  
  // === FRETES (Backend Django - EXISTENTE) ===
  /// Listar todos os fretes
  String get fretes => '$_baseUrl/fretes/fretes/';
  
  /// Detalhes de um frete específico
  String freteDetail(int id) => '$_baseUrl/fretes/fretes/$id/';
  
  /// Atualizar status do frete
  String freteAtualizarStatus(int freteId) => '$_baseUrl/fretes/fretes/$freteId/update_status/';
  
  /// Fretes por motorista (usando endpoint existente)
  String get fretesPorMotorista => '$_baseUrl/fretes/by_driver/';
  
  /// Adicionar localização ao frete
  String freteAddLocation(int freteId) => '$_baseUrl/fretes/fretes/$freteId/add_location/';
  
  /// Enviar localização com frete (endpoint existente)
  String get fretesSendLocationWithFrete => '$_baseUrl/fretes/send_location_with_frete/';
  
  // === MATERIAIS (Backend Django - EXISTENTE) ===
  String get materiais => '$_baseUrl/fretes/materiais/';
  
  // === HISTÓRICO DE STATUS (Backend Django - EXISTENTE) ===
  String get historicoStatus => '$_baseUrl/fretes/historico-status/';
  
  // === FOTOS (Backend Django - EXISTENTE) ===
  String get fotos => '$_baseUrl/fretes/fotos/';
  
  // === LOCALIZAÇÕES (Backend Django - EXISTENTE) ===
  String get localizacoes => '$_baseUrl/fretes/localizacoes/';
  
  // === ROTAS (Backend Django - EXISTENTE) ===
  String get rotas => '$_baseUrl/fretes/rotas/';
  
  // === FRETES ROTA (Backend Django - EXISTENTE) ===
  String get fretesRota => '$_baseUrl/fretes/fretes-rota/';
  
  // === DRIVER LOCATIONS (Backend Django - EXISTENTE) ===
  String get driverLocations => '$_baseUrl/driver-locations/';
  
  // === DRIVER TRIPS (Backend Django - EXISTENTE) ===
  String get driverTrips => '$_baseUrl/driver-trips/';
  
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
    return 'ApiEndpointsFixed(baseUrl: $_baseUrl)';
  }
}
