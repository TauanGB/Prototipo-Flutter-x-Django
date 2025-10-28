// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusHistory _$StatusHistoryFromJson(Map<String, dynamic> json) =>
    StatusHistory(
      id: (json['id'] as num).toInt(),
      statusAnterior: json['status_anterior'] as String?,
      statusAnteriorDisplay: json['status_anterior_display'] as String?,
      statusNovo: json['status_novo'] as String,
      statusNovoDisplay: json['status_novo_display'] as String,
      usuario: (json['usuario'] as num?)?.toInt(),
      usuarioNome: json['usuario_nome'] as String?,
      dataAlteracao: DateTime.parse(json['data_alteracao'] as String),
      observacoes: json['observacoes'] as String?,
    );

Map<String, dynamic> _$StatusHistoryToJson(StatusHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status_anterior': instance.statusAnterior,
      'status_anterior_display': instance.statusAnteriorDisplay,
      'status_novo': instance.statusNovo,
      'status_novo_display': instance.statusNovoDisplay,
      'usuario': instance.usuario,
      'usuario_nome': instance.usuarioNome,
      'data_alteracao': instance.dataAlteracao.toIso8601String(),
      'observacoes': instance.observacoes,
    };
