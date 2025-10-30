// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frete_eg3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreteEG3 _$FreteEG3FromJson(Map<String, dynamic> json) => FreteEG3(
  id: (json['id'] as num).toInt(),
  numeroNotaFiscal: json['numero_nota_fiscal'] as String?,
  codigoPublico: json['codigo_publico'] as String,
  cliente: (json['cliente'] as num).toInt(),
  clienteNome: json['cliente_nome'] as String,
  motorista: (json['motorista'] as num?)?.toInt(),
  motoristaId: (json['motorista_id'] as num?)?.toInt(),
  motoristaNome: json['motorista_nome'] as String?,
  tipoServico: json['tipo_servico'] as String,
  tipoServicoDisplay: json['tipo_servico_display'] as String,
  origem: json['origem'] as String?,
  origemLinkGoogle: json['origem_link_google'] as String?,
  destino: json['destino'] as String?,
  destinoLinkGoogle: json['destino_link_google'] as String?,
  dataAgendamento: json['data_agendamento'] == null
      ? null
      : DateTime.parse(json['data_agendamento'] as String),
  horaAgendamento: json['hora_agendamento'] as String?,
  dataHoraAgendamento: json['data_hora_agendamento'] == null
      ? null
      : DateTime.parse(json['data_hora_agendamento'] as String),
  tempoEstimadoHoras: (json['tempo_estimado_horas'] as num).toInt(),
  dataLimiteNotificacao: json['data_limite_notificacao'] == null
      ? null
      : DateTime.parse(json['data_limite_notificacao'] as String),
  statusAtual: json['status_atual'] as String,
  statusAtualDisplay: json['status_atual_display'] as String,
  dataCriacao: DateTime.parse(json['data_criacao'] as String),
  dataAtualizacao: DateTime.parse(json['data_atualizacao'] as String),
  dataChegadaCd: json['data_chegada_cd'] == null
      ? null
      : DateTime.parse(json['data_chegada_cd'] as String),
  dataInicioViagem: json['data_inicio_viagem'] == null
      ? null
      : DateTime.parse(json['data_inicio_viagem'] as String),
  dataChegadaDestino: json['data_chegada_destino'] == null
      ? null
      : DateTime.parse(json['data_chegada_destino'] as String),
  dataFinalizacao: json['data_finalizacao'] == null
      ? null
      : DateTime.parse(json['data_finalizacao'] as String),
  dataInicioOperacaoMunck: json['data_inicio_operacao_munck'] == null
      ? null
      : DateTime.parse(json['data_inicio_operacao_munck'] as String),
  dataFimOperacaoMunck: json['data_fim_operacao_munck'] == null
      ? null
      : DateTime.parse(json['data_fim_operacao_munck'] as String),
  observacoes: json['observacoes'] as String?,
  ativo: json['ativo'] as bool,
  tempoCarregamentoMinutos: (json['tempo_carregamento_minutos'] as num?)
      ?.toDouble(),
  tempoTransitoMinutos: (json['tempo_transito_minutos'] as num?)?.toDouble(),
  tempoOperacaoMunckMinutos: (json['tempo_operacao_munck_minutos'] as num?)
      ?.toDouble(),
  statusNotificacao: json['status_notificacao'] as String?,
  tempoRestanteTexto: json['tempo_restante_texto'] as String?,
  corNotificacao: json['cor_notificacao'] as String?,
);

Map<String, dynamic> _$FreteEG3ToJson(FreteEG3 instance) => <String, dynamic>{
  'id': instance.id,
  'numero_nota_fiscal': instance.numeroNotaFiscal,
  'codigo_publico': instance.codigoPublico,
  'cliente': instance.cliente,
  'cliente_nome': instance.clienteNome,
  'motorista': instance.motorista,
  'motorista_id': instance.motoristaId,
  'motorista_nome': instance.motoristaNome,
  'tipo_servico': instance.tipoServico,
  'tipo_servico_display': instance.tipoServicoDisplay,
  'origem': instance.origem,
  'origem_link_google': instance.origemLinkGoogle,
  'destino': instance.destino,
  'destino_link_google': instance.destinoLinkGoogle,
  'data_agendamento': instance.dataAgendamento?.toIso8601String(),
  'hora_agendamento': instance.horaAgendamento,
  'data_hora_agendamento': instance.dataHoraAgendamento?.toIso8601String(),
  'tempo_estimado_horas': instance.tempoEstimadoHoras,
  'data_limite_notificacao': instance.dataLimiteNotificacao?.toIso8601String(),
  'status_atual': instance.statusAtual,
  'status_atual_display': instance.statusAtualDisplay,
  'data_criacao': instance.dataCriacao.toIso8601String(),
  'data_atualizacao': instance.dataAtualizacao.toIso8601String(),
  'data_chegada_cd': instance.dataChegadaCd?.toIso8601String(),
  'data_inicio_viagem': instance.dataInicioViagem?.toIso8601String(),
  'data_chegada_destino': instance.dataChegadaDestino?.toIso8601String(),
  'data_finalizacao': instance.dataFinalizacao?.toIso8601String(),
  'data_inicio_operacao_munck': instance.dataInicioOperacaoMunck
      ?.toIso8601String(),
  'data_fim_operacao_munck': instance.dataFimOperacaoMunck?.toIso8601String(),
  'observacoes': instance.observacoes,
  'ativo': instance.ativo,
  'tempo_carregamento_minutos': instance.tempoCarregamentoMinutos,
  'tempo_transito_minutos': instance.tempoTransitoMinutos,
  'tempo_operacao_munck_minutos': instance.tempoOperacaoMunckMinutos,
  'status_notificacao': instance.statusNotificacao,
  'tempo_restante_texto': instance.tempoRestanteTexto,
  'cor_notificacao': instance.corNotificacao,
};
