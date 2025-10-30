/// Modelo de frete dentro do SyncState
/// 
/// Representa um frete da rota atual com todas as informações necessárias
/// para a UI e para sincronização com o backend
class SyncFrete {
  final int freteId;
  final int ordem;
  final String statusRota; // PENDENTE, EM_EXECUCAO, CONCLUIDO
  final String statusAtual;
  final String tipoServico; // TRANSPORTE, MUNCK_CARGA, MUNCK_DESCARGA
  final String? origem;
  final String? destino;
  final String? clienteNome;
  final String? numeroNotaFiscal;
  final String? codigoPublico;
  final String? origemLinkGoogle;
  final String? destinoLinkGoogle;
  final String? dataAgendamento; // ISO string
  final String? horaAgendamento;

  const SyncFrete({
    required this.freteId,
    required this.ordem,
    required this.statusRota,
    required this.statusAtual,
    required this.tipoServico,
    this.origem,
    this.destino,
    this.clienteNome,
    this.numeroNotaFiscal,
    this.codigoPublico,
    this.origemLinkGoogle,
    this.destinoLinkGoogle,
    this.dataAgendamento,
    this.horaAgendamento,
  });

  /// Cria SyncFrete a partir do formato do endpoint GET /api/fretes/motorista/rota-atual/
  /// 
  /// Estrutura do backend:
  /// {
  ///   "id": 11,
  ///   "ordem": 2,
  ///   "status_rota": "EM_EXECUCAO",
  ///   "frete_info": {
  ///     "id": 101,
  ///     "numero_nota_fiscal": "NF002",
  ///     "codigo_publico": "DEF67890",
  ///     "status_atual": "AGUARDANDO_CARGA",
  ///     "tipo_servico": "TRANSPORTE",
  ///     "origem": "Guarulhos, SP",
  ///     "destino": "Campinas, SP",
  ///     "cliente_nome": "Cliente XYZ",
  ///     ...
  ///   }
  /// }
  factory SyncFrete.fromApiRotaAtual(Map<String, dynamic> json) {
    final freteInfo = json['frete_info'] as Map<String, dynamic>;

    return SyncFrete(
      freteId: freteInfo['id'] as int,
      ordem: json['ordem'] as int,
      statusRota: json['status_rota'] as String,
      statusAtual: freteInfo['status_atual'] as String,
      tipoServico: freteInfo['tipo_servico'] as String,
      origem: freteInfo['origem'] as String?,
      destino: freteInfo['destino'] as String?,
      clienteNome: freteInfo['cliente_nome'] as String?,
      numeroNotaFiscal: freteInfo['numero_nota_fiscal'] as String?,
      codigoPublico: freteInfo['codigo_publico'] as String?,
      origemLinkGoogle: freteInfo['origem_link_google'] as String?,
      destinoLinkGoogle: freteInfo['destino_link_google'] as String?,
      dataAgendamento: freteInfo['data_agendamento'] as String?,
      horaAgendamento: freteInfo['hora_agendamento'] as String?,
    );
  }

  /// Cria SyncFrete a partir de JSON armazenado localmente
  factory SyncFrete.fromJson(Map<String, dynamic> json) {
    return SyncFrete(
      freteId: json['frete_id'] as int,
      ordem: json['ordem'] as int,
      statusRota: json['status_rota'] as String,
      statusAtual: json['status_atual'] as String,
      tipoServico: json['tipo_servico'] as String,
      origem: json['origem'] as String?,
      destino: json['destino'] as String?,
      clienteNome: json['cliente_nome'] as String?,
      numeroNotaFiscal: json['numero_nota_fiscal'] as String?,
      codigoPublico: json['codigo_publico'] as String?,
      origemLinkGoogle: json['origem_link_google'] as String?,
      destinoLinkGoogle: json['destino_link_google'] as String?,
      dataAgendamento: json['data_agendamento'] as String?,
      horaAgendamento: json['hora_agendamento'] as String?,
    );
  }

  /// Converte SyncFrete para JSON (para armazenamento local)
  Map<String, dynamic> toJson() {
    return {
      'frete_id': freteId,
      'ordem': ordem,
      'status_rota': statusRota,
      'status_atual': statusAtual,
      'tipo_servico': tipoServico,
      if (origem != null) 'origem': origem,
      if (destino != null) 'destino': destino,
      if (clienteNome != null) 'cliente_nome': clienteNome,
      if (numeroNotaFiscal != null) 'numero_nota_fiscal': numeroNotaFiscal,
      if (codigoPublico != null) 'codigo_publico': codigoPublico,
      if (origemLinkGoogle != null) 'origem_link_google': origemLinkGoogle,
      if (destinoLinkGoogle != null) 'destino_link_google': destinoLinkGoogle,
      if (dataAgendamento != null) 'data_agendamento': dataAgendamento,
      if (horaAgendamento != null) 'hora_agendamento': horaAgendamento,
    };
  }

  /// Cria cópia do SyncFrete com campos atualizados
  SyncFrete copyWith({
    int? freteId,
    int? ordem,
    String? statusRota,
    String? statusAtual,
    String? tipoServico,
    String? origem,
    String? destino,
    String? clienteNome,
    String? numeroNotaFiscal,
    String? codigoPublico,
    String? origemLinkGoogle,
    String? destinoLinkGoogle,
    String? dataAgendamento,
    String? horaAgendamento,
  }) {
    return SyncFrete(
      freteId: freteId ?? this.freteId,
      ordem: ordem ?? this.ordem,
      statusRota: statusRota ?? this.statusRota,
      statusAtual: statusAtual ?? this.statusAtual,
      tipoServico: tipoServico ?? this.tipoServico,
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
      clienteNome: clienteNome ?? this.clienteNome,
      numeroNotaFiscal: numeroNotaFiscal ?? this.numeroNotaFiscal,
      codigoPublico: codigoPublico ?? this.codigoPublico,
      origemLinkGoogle: origemLinkGoogle ?? this.origemLinkGoogle,
      destinoLinkGoogle: destinoLinkGoogle ?? this.destinoLinkGoogle,
      dataAgendamento: dataAgendamento ?? this.dataAgendamento,
      horaAgendamento: horaAgendamento ?? this.horaAgendamento,
    );
  }

  /// Verifica se o frete está liberado para ação (status_rota == EM_EXECUCAO)
  bool get isLiberado => statusRota == 'EM_EXECUCAO';

  /// Verifica se o frete está concluído
  bool get isConcluido => statusRota == 'CONCLUIDO';

  /// Verifica se é status final baseado no tipo de serviço
  bool get isStatusFinal {
    switch (tipoServico) {
      case 'TRANSPORTE':
        return statusAtual == 'FINALIZADO';
      case 'MUNCK_CARGA':
        return statusAtual == 'CARREGAMENTO_CONCLUIDO';
      case 'MUNCK_DESCARGA':
        return statusAtual == 'DESCARREGAMENTO_CONCLUIDO';
      default:
        return false;
    }
  }

  @override
  String toString() {
    return 'SyncFrete(freteId: $freteId, ordem: $ordem, statusRota: $statusRota, statusAtual: $statusAtual)';
  }
}

