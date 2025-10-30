import 'package:json_annotation/json_annotation.dart';

part 'frete_ativo.g.dart';

/// Modelo de frete ativo do SistemaEG3
@JsonSerializable()
class FreteAtivo {
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
  @JsonKey(name: 'latitude_atual')
  final double? latitudeAtual;
  @JsonKey(name: 'longitude_atual')
  final double? longitudeAtual;
  @JsonKey(name: 'endereco_atual')
  final String? enderecoAtual;
  @JsonKey(name: 'ultima_atualizacao_localizacao')
  final DateTime? ultimaAtualizacaoLocalizacao;

  const FreteAtivo({
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
    this.tempoCarregamentoMinutos,
    this.tempoTransitoMinutos,
    this.tempoOperacaoMunckMinutos,
    this.statusNotificacao,
    this.tempoRestanteTexto,
    this.corNotificacao,
    this.latitudeAtual,
    this.longitudeAtual,
    this.enderecoAtual,
    this.ultimaAtualizacaoLocalizacao,
  });

  factory FreteAtivo.fromJson(Map<String, dynamic> json) => _$FreteAtivoFromJson(json);
  Map<String, dynamic> toJson() => _$FreteAtivoToJson(this);

  /// Descrição do frete
  String get descricao {
    final nf = numeroNotaFiscal != null ? 'NF: $numeroNotaFiscal' : '';
    final destinoStr = destino != null ? ' → $destino' : '';
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

  /// Verifica se tem localização atual
  bool get temLocalizacaoAtual => latitudeAtual != null && longitudeAtual != null;

  /// Coordenadas atuais formatadas
  String? get coordenadasAtuaisFormatadas {
    if (temLocalizacaoAtual) {
      return '${latitudeAtual!.toStringAsFixed(6)}, ${longitudeAtual!.toStringAsFixed(6)}';
    }
    return null;
  }

  /// Tempo desde última atualização de localização
  Duration? get tempoUltimaLocalizacao {
    if (ultimaAtualizacaoLocalizacao != null) {
      return DateTime.now().difference(ultimaAtualizacaoLocalizacao!);
    }
    return null;
  }

  /// Tempo desde última localização formatado
  String? get tempoUltimaLocalizacaoFormatado {
    final duration = tempoUltimaLocalizacao;
    if (duration != null) {
      if (duration.inMinutes < 1) {
        return 'Agora';
      } else if (duration.inMinutes < 60) {
        return '${duration.inMinutes}m atrás';
      } else if (duration.inHours < 24) {
        return '${duration.inHours}h atrás';
      } else {
        return '${duration.inDays}d atrás';
      }
    }
    return null;
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

  @override
  String toString() => 'FreteAtivo(id: $id, cliente: $clienteNome, status: $statusAtualDisplay)';
}