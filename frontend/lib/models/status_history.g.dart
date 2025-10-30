// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusHistory _$StatusHistoryFromJson(Map<String, dynamic> json) =>
    StatusHistory(
      id: (json['id'] as num).toInt(),
      frete: (json['frete'] as num).toInt(),
      status: json['status'] as String,
      statusDisplay: json['status_display'] as String,
      dataMudanca: DateTime.parse(json['data_mudanca'] as String),
      usuario: json['usuario'] as String?,
      observacoes: json['observacoes'] as String?,
      dataCriacao: DateTime.parse(json['data_criacao'] as String),
    );

Map<String, dynamic> _$StatusHistoryToJson(StatusHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'frete': instance.frete,
      'status': instance.status,
      'status_display': instance.statusDisplay,
      'data_mudanca': instance.dataMudanca.toIso8601String(),
      'usuario': instance.usuario,
      'observacoes': instance.observacoes,
      'data_criacao': instance.dataCriacao.toIso8601String(),
    };
