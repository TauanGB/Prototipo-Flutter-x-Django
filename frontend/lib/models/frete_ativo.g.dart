// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frete_ativo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreteAtivo _$FreteAtivoFromJson(Map<String, dynamic> json) => FreteAtivo(
  id: (json['id'] as num).toInt(),
  nomeFrete: json['nome_frete'] as String?,
  numeroNotaFiscal: json['numero_nota_fiscal'] as String?,
  codigoPublico: json['codigo_publico'] as String?,
  statusAtual: json['status_atual'] as String?,
  origem: json['origem'] as String?,
  destino: json['destino'] as String?,
  dataAgendamento: json['data_agendamento'] as String?,
  observacoes: json['observacoes'] as String?,
  clienteNome: json['cliente_nome'] as String?,
);

Map<String, dynamic> _$FreteAtivoToJson(FreteAtivo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome_frete': instance.nomeFrete,
      'numero_nota_fiscal': instance.numeroNotaFiscal,
      'codigo_publico': instance.codigoPublico,
      'status_atual': instance.statusAtual,
      'origem': instance.origem,
      'destino': instance.destino,
      'data_agendamento': instance.dataAgendamento,
      'observacoes': instance.observacoes,
      'cliente_nome': instance.clienteNome,
    };
