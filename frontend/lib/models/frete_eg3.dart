import 'package:json_annotation/json_annotation.dart';
import 'material.dart';
import 'status_history.dart';

part 'frete_eg3.g.dart';

/// Modelo de frete do SistemaEG3 (alinhado com FreteSerializer)
@JsonSerializable()
class FreteEG3 {
  final int id;
  @JsonKey(name: 'numero_nota_fiscal')
  final String? numeroNotaFiscal;
  @JsonKey(name: 'codigo_publico')
  final String codigoPublico;
  final int cliente;
  @JsonKey(name: 'cliente_nome')
  final String clienteNome;
  final int? motorista;
  @JsonKey(name: 'motorista_id')
  final int? motoristaId;
  @JsonKey(name: 'motorista_nome')
  final String? motoristaNome;
  @JsonKey(name: 'tipo_servico')
  final String tipoServico;
  @JsonKey(name: 'tipo_servico_display')
  final String tipoServicoDisplay;
  final String? origem;
  @JsonKey(name: 'origem_link_google')
  final String? origemLinkGoogle;
  final String? destino;
  @JsonKey(name: 'destino_link_google')
  final String? destinoLinkGoogle;
  @JsonKey(name: 'data_agendamento')
  final DateTime? dataAgendamento;
  @JsonKey(name: 'hora_agendamento')
  final String? horaAgendamento;
  @JsonKey(name: 'data_hora_agendamento')
  final DateTime? dataHoraAgendamento;
  @JsonKey(name: 'tempo_estimado_horas')
  final int tempoEstimadoHoras;
  @JsonKey(name: 'data_limite_notificacao')
  final DateTime? dataLimiteNotificacao;
  @JsonKey(name: 'status_atual')
  final String statusAtual;
  @JsonKey(name: 'status_atual_display')
  final String statusAtualDisplay;
  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;
  @JsonKey(name: 'data_atualizacao')
  final DateTime dataAtualizacao;
  @JsonKey(name: 'data_chegada_cd')
  final DateTime? dataChegadaCd;
  @JsonKey(name: 'data_inicio_viagem')
  final DateTime? dataInicioViagem;
  @JsonKey(name: 'data_chegada_destino')
  final DateTime? dataChegadaDestino;
  @JsonKey(name: 'data_finalizacao')
  final DateTime? dataFinalizacao;
  @JsonKey(name: 'data_inicio_operacao_munck')
  final DateTime? dataInicioOperacaoMunck;
  @JsonKey(name: 'data_fim_operacao_munck')
  final DateTime? dataFimOperacaoMunck;
  final String? observacoes;
  final bool ativo;
  final List<Material>? materiais;
  @JsonKey(name: 'historico_status')
  final List<StatusHistory>? historicoStatus;
  @JsonKey(name: 'tempo_carregamento_minutos')
  final double? tempoCarregamentoMinutos;
  @JsonKey(name: 'tempo_transito_minutos')
  final double? tempoTransitoMinutos;
  @JsonKey(name: 'tempo_operacao_munck_minutos')
  final double? tempoOperacaoMunckMinutos;
  @JsonKey(name: 'status_notificacao')
  final String? statusNotificacao;
  @JsonKey(name: 'tempo_restante_texto')
  final String? tempoRestanteTexto;
  @JsonKey(name: 'cor_notificacao')
  final String? corNotificacao;

  const FreteEG3({
    required this.id,
    this.numeroNotaFiscal,
    required this.codigoPublico,
    required this.cliente,
    required this.clienteNome,
    this.motorista,
    this.motoristaId,
    this.motoristaNome,
    required this.tipoServico,
    required this.tipoServicoDisplay,
    this.origem,
    this.origemLinkGoogle,
    this.destino,
    this.destinoLinkGoogle,
    this.dataAgendamento,
    this.horaAgendamento,
    this.dataHoraAgendamento,
    required this.tempoEstimadoHoras,
    this.dataLimiteNotificacao,
    required this.statusAtual,
    required this.statusAtualDisplay,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.dataChegadaCd,
    this.dataInicioViagem,
    this.dataChegadaDestino,
    this.dataFinalizacao,
    this.dataInicioOperacaoMunck,
    this.dataFimOperacaoMunck,
    this.observacoes,
    required this.ativo,
    this.materiais,
    this.historicoStatus,
    this.tempoCarregamentoMinutos,
    this.tempoTransitoMinutos,
    this.tempoOperacaoMunckMinutos,
    this.statusNotificacao,
    this.tempoRestanteTexto,
    this.corNotificacao,
  });

  factory FreteEG3.fromJson(Map<String, dynamic> json) => _$FreteEG3FromJson(json);
  Map<String, dynamic> toJson() => _$FreteEG3ToJson(this);

  /// Descrição do frete
  String get descricao {
    final nf = numeroNotaFiscal != null ? 'NF: $numeroNotaFiscal' : '';
    final destinoStr = this.destino != null ? ' → $destino' : '';
    return '$clienteNome$destinoStr $nf'.trim();
  }

  /// Rota formatada
  String get rotaFormatada {
    if (origem != null && destino != null) {
      return '$origem → $destino';
    } else if (destino != null) {
      return '→ $destino';
    } else if (origem != null) {
      return '$origem →';
    }
    return 'Rota não definida';
  }

  /// Data de agendamento formatada
  String get dataAgendamentoFormatada {
    if (dataAgendamento != null) {
      return '${dataAgendamento!.day.toString().padLeft(2, '0')}/'
             '${dataAgendamento!.month.toString().padLeft(2, '0')}/'
             '${dataAgendamento!.year}';
    }
    return 'Não agendado';
  }

  /// Data e hora de agendamento formatada
  String get dataHoraAgendamentoFormatada {
    if (dataHoraAgendamento != null) {
      return '${dataHoraAgendamento!.day.toString().padLeft(2, '0')}/'
             '${dataHoraAgendamento!.month.toString().padLeft(2, '0')}/'
             '${dataHoraAgendamento!.year} '
             '${dataHoraAgendamento!.hour.toString().padLeft(2, '0')}:'
             '${dataHoraAgendamento!.minute.toString().padLeft(2, '0')}';
    }
    return 'Não agendado';
  }

  /// Verifica se é transporte
  bool get isTransporte => tipoServico == 'TRANSPORTE';

  /// Verifica se é Munck de carga
  bool get isMunckCarga => tipoServico == 'MUNCK_CARGA';

  /// Verifica se é Munck de descarga
  bool get isMunckDescarga => tipoServico == 'MUNCK_DESCARGA';

  /// Verifica se está finalizado
  bool get isFinalizado => statusAtual == 'FINALIZADO';

  /// Verifica se está cancelado
  bool get isCancelado => statusAtual == 'CANCELADO';

  /// Verifica se está em andamento
  bool get isEmAndamento => !isFinalizado && !isCancelado && statusAtual != 'NAO_INICIADO';

  /// Próximo status possível
  String? get proximoStatus {
    switch (statusAtual) {
      case 'NAO_INICIADO':
        return isTransporte ? 'AGUARDANDO_CARGA' : 
               isMunckCarga ? 'CARREGAMENTO_NAO_INICIADO' : 
               'DESCARREGAMENTO_NAO_INICIADO';
      case 'AGUARDANDO_CARGA':
        return 'EM_TRANSITO';
      case 'EM_TRANSITO':
        return 'EM_DESCARGA_CLIENTE';
      case 'EM_DESCARGA_CLIENTE':
        return 'FINALIZADO';
      case 'CARREGAMENTO_NAO_INICIADO':
        return 'CARREGAMENTO_INICIADO';
      case 'CARREGAMENTO_INICIADO':
        return 'CARREGAMENTO_CONCLUIDO';
      case 'DESCARREGAMENTO_NAO_INICIADO':
        return 'DESCARREGAMENTO_INICIADO';
      case 'DESCARREGAMENTO_INICIADO':
        return 'DESCARREGAMENTO_CONCLUIDO';
      default:
        return null;
    }
  }

  /// Label do botão de ação
  String? get acaoBotao {
    switch (statusAtual) {
      case 'NAO_INICIADO':
        return isTransporte ? 'Iniciar Carregamento' : 
               isMunckCarga ? 'Iniciar Carregamento' : 
               'Iniciar Descarregamento';
      case 'AGUARDANDO_CARGA':
        return 'Iniciar Viagem';
      case 'EM_TRANSITO':
        return 'Chegou no Destino';
      case 'EM_DESCARGA_CLIENTE':
        return 'Finalizar Entrega';
      case 'CARREGAMENTO_NAO_INICIADO':
        return 'Iniciar Carregamento';
      case 'CARREGAMENTO_INICIADO':
        return 'Finalizar Carregamento';
      case 'DESCARREGAMENTO_NAO_INICIADO':
        return 'Iniciar Descarregamento';
      case 'DESCARREGAMENTO_INICIADO':
        return 'Finalizar Descarregamento';
      default:
        return null;
    }
  }

  /// Cor do status
  String get corStatus {
    switch (statusAtual) {
      case 'NAO_INICIADO':
        return 'gray';
      case 'AGUARDANDO_CARGA':
      case 'CARREGAMENTO_NAO_INICIADO':
      case 'DESCARREGAMENTO_NAO_INICIADO':
        return 'yellow';
      case 'EM_TRANSITO':
      case 'CARREGAMENTO_INICIADO':
      case 'DESCARREGAMENTO_INICIADO':
        return 'blue';
      case 'EM_DESCARGA_CLIENTE':
        return 'orange';
      case 'FINALIZADO':
      case 'CARREGAMENTO_CONCLUIDO':
      case 'DESCARREGAMENTO_CONCLUIDO':
        return 'green';
      case 'CANCELADO':
        return 'red';
      default:
        return 'gray';
    }
  }

  /// Retorna próximo status válido baseado no tipo de serviço
  static String? getProximoStatus(String tipoServico, String statusAtual) {
    switch (tipoServico) {
      case 'TRANSPORTE':
        switch (statusAtual) {
          case 'NAO_INICIADO':
            return 'AGUARDANDO_CARGA';
          case 'AGUARDANDO_CARGA':
            return 'EM_TRANSITO';
          case 'EM_TRANSITO':
            return 'EM_DESCARGA_CLIENTE';
          case 'EM_DESCARGA_CLIENTE':
            return 'FINALIZADO';
          default:
            return null;
        }
      case 'MUNCK_CARGA':
        switch (statusAtual) {
          case 'NAO_INICIADO':
            return 'CARREGAMENTO_INICIADO';
          case 'CARREGAMENTO_INICIADO':
            return 'CARREGAMENTO_CONCLUIDO';
          default:
            return null;
        }
      case 'MUNCK_DESCARGA':
        switch (statusAtual) {
          case 'NAO_INICIADO':
            return 'DESCARREGAMENTO_INICIADO';
          case 'DESCARREGAMENTO_INICIADO':
            return 'DESCARREGAMENTO_CONCLUIDO';
          default:
            return null;
        }
      default:
        return null;
    }
  }

  /// Retorna texto do botão baseado no tipo de serviço e status atual
  static String? getAcaoBotao(String tipoServico, String statusAtual) {
    switch (tipoServico) {
      case 'TRANSPORTE':
        switch (statusAtual) {
          case 'NAO_INICIADO':
            return 'Confirmar Chegada no CD';
          case 'AGUARDANDO_CARGA':
            return 'Iniciar Viagem';
          case 'EM_TRANSITO':
            return 'Chegou no Destino';
          case 'EM_DESCARGA_CLIENTE':
            return 'Finalizar Entrega';
          default:
            return null;
        }
      case 'MUNCK_CARGA':
        switch (statusAtual) {
          case 'NAO_INICIADO':
            return 'Iniciar Carregamento';
          case 'CARREGAMENTO_INICIADO':
            return 'Finalizar Carregamento';
          default:
            return null;
        }
      case 'MUNCK_DESCARGA':
        switch (statusAtual) {
          case 'NAO_INICIADO':
            return 'Iniciar Descarregamento';
          case 'DESCARREGAMENTO_INICIADO':
            return 'Finalizar Descarregamento';
          default:
            return null;
        }
      default:
        return null;
    }
  }

  /// Retorna cor do botão baseado no tipo de serviço
  static String getCorBotao(String tipoServico) {
    switch (tipoServico) {
      case 'TRANSPORTE':
        return 'blue';
      case 'MUNCK_CARGA':
        return 'orange';
      case 'MUNCK_DESCARGA':
        return 'green';
      default:
        return 'gray';
    }
  }

  /// Verifica se é status final (FINALIZADO, *_CONCLUIDO)
  static bool isStatusFinal(String status) {
    return status == 'FINALIZADO' || 
           status == 'CARREGAMENTO_CONCLUIDO' || 
           status == 'DESCARREGAMENTO_CONCLUIDO';
  }

  /// Verifica se status requer rastreamento ativo
  static bool requiresTracking(String status) {
    return status == 'EM_TRANSITO' || 
           status == 'EM_DESCARGA_CLIENTE' ||
           status == 'CARREGAMENTO_INICIADO' ||
           status == 'DESCARREGAMENTO_INICIADO';
  }

  /// Verifica se pode avançar para próximo status
  bool get podeAvancarStatus {
    return getProximoStatus(tipoServico, statusAtual) != null;
  }

  /// Próximo status para este frete específico
  String? get proximoStatusValido {
    return getProximoStatus(tipoServico, statusAtual);
  }

  /// Ação do botão para este frete específico
  String? get acaoBotaoAtual {
    return getAcaoBotao(tipoServico, statusAtual);
  }

  /// Cor do botão para este frete específico
  String get corBotaoAtual {
    return getCorBotao(tipoServico);
  }

  /// Verifica se este frete está em status final
  bool get isStatusFinalAtual {
    return isStatusFinal(statusAtual);
  }

  /// Verifica se este frete requer rastreamento
  bool get requerRastreamento {
    return requiresTracking(statusAtual);
  }

  @override
  String toString() => 'FreteEG3(id: $id, cliente: $clienteNome, status: $statusAtualDisplay)';
}
