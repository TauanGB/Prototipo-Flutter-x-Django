// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frete_rota.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreteRota _$FreteRotaFromJson(Map<String, dynamic> json) => FreteRota(
  id: (json['id'] as num).toInt(),
  rota: (json['rota'] as num).toInt(),
  frete: (json['frete'] as num).toInt(),
  freteData: json['freteData'] == null
      ? null
      : FreteEG3.fromJson(json['freteData'] as Map<String, dynamic>),
  ordem: (json['ordem'] as num).toInt(),
  statusRota: json['status_rota'] as String,
  statusRotaDisplay: json['status_rota_display'] as String,
  dataInicio: json['data_inicio'] == null
      ? null
      : DateTime.parse(json['data_inicio'] as String),
  dataConclusao: json['data_conclusao'] == null
      ? null
      : DateTime.parse(json['data_conclusao'] as String),
  observacoes: json['observacoes'] as String?,
  dataCriacao: DateTime.parse(json['data_criacao'] as String),
  dataAtualizacao: DateTime.parse(json['data_atualizacao'] as String),
);

Map<String, dynamic> _$FreteRotaToJson(FreteRota instance) => <String, dynamic>{
  'id': instance.id,
  'rota': instance.rota,
  'frete': instance.frete,
  'freteData': instance.freteData,
  'ordem': instance.ordem,
  'status_rota': instance.statusRota,
  'status_rota_display': instance.statusRotaDisplay,
  'data_inicio': instance.dataInicio?.toIso8601String(),
  'data_conclusao': instance.dataConclusao?.toIso8601String(),
  'observacoes': instance.observacoes,
  'data_criacao': instance.dataCriacao.toIso8601String(),
  'data_atualizacao': instance.dataAtualizacao.toIso8601String(),
};
