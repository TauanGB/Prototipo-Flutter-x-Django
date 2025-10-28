// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rota.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rota _$RotaFromJson(Map<String, dynamic> json) => Rota(
  id: (json['id'] as num).toInt(),
  nome: json['nome'] as String,
  motorista: (json['motorista'] as num?)?.toInt(),
  motoristaNome: json['motorista_nome'] as String?,
  motoristaUsername: json['motorista_username'] as String?,
  dataCriacao: DateTime.parse(json['data_criacao'] as String),
  dataInicio: json['data_inicio'] == null
      ? null
      : DateTime.parse(json['data_inicio'] as String),
  dataConclusao: json['data_conclusao'] == null
      ? null
      : DateTime.parse(json['data_conclusao'] as String),
  status: json['status'] as String,
  observacoes: json['observacoes'] as String?,
  ativo: json['ativo'] as bool,
  fretesRota: (json['fretes_rota'] as List<dynamic>?)
      ?.map((e) => FreteRota.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalFretes: (json['total_fretes'] as num).toInt(),
  fretesConcluidos: (json['fretes_concluidos'] as num).toInt(),
  progressoPercentual: (json['progresso_percentual'] as num).toDouble(),
);

Map<String, dynamic> _$RotaToJson(Rota instance) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'motorista': instance.motorista,
  'motorista_nome': instance.motoristaNome,
  'motorista_username': instance.motoristaUsername,
  'data_criacao': instance.dataCriacao.toIso8601String(),
  'data_inicio': instance.dataInicio?.toIso8601String(),
  'data_conclusao': instance.dataConclusao?.toIso8601String(),
  'status': instance.status,
  'observacoes': instance.observacoes,
  'ativo': instance.ativo,
  'fretes_rota': instance.fretesRota,
  'total_fretes': instance.totalFretes,
  'fretes_concluidos': instance.fretesConcluidos,
  'progresso_percentual': instance.progressoPercentual,
};
