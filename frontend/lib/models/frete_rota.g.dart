// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frete_rota.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreteRota _$FreteRotaFromJson(Map<String, dynamic> json) => FreteRota(
  id: (json['id'] as num).toInt(),
  ordem: (json['ordem'] as num).toInt(),
  statusRota: json['status_rota'] as String,
  dataInicioExecucao: json['data_inicio_execucao'] == null
      ? null
      : DateTime.parse(json['data_inicio_execucao'] as String),
  dataConclusaoExecucao: json['data_conclusao_execucao'] == null
      ? null
      : DateTime.parse(json['data_conclusao_execucao'] as String),
  frete: FreteEG3.fromJson(json['frete'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FreteRotaToJson(FreteRota instance) => <String, dynamic>{
  'id': instance.id,
  'ordem': instance.ordem,
  'status_rota': instance.statusRota,
  'data_inicio_execucao': instance.dataInicioExecucao?.toIso8601String(),
  'data_conclusao_execucao': instance.dataConclusaoExecucao?.toIso8601String(),
  'frete': instance.frete,
};
