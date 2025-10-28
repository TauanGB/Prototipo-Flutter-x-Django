// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Frete _$FreteFromJson(Map<String, dynamic> json) => Frete(
  id: (json['id'] as num).toInt(),
  origem: json['origem'] as String,
  destino: json['destino'] as String,
  status: json['status'] as String,
  descricao: json['descricao'] as String?,
  valor: (json['valor'] as num?)?.toDouble(),
  dataColeta: json['dataColeta'] == null
      ? null
      : DateTime.parse(json['dataColeta'] as String),
  dataEntrega: json['dataEntrega'] == null
      ? null
      : DateTime.parse(json['dataEntrega'] as String),
  cliente: json['cliente'] as String?,
  contato: json['contato'] as String?,
  observacoes: json['observacoes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$FreteToJson(Frete instance) => <String, dynamic>{
  'id': instance.id,
  'origem': instance.origem,
  'destino': instance.destino,
  'status': instance.status,
  'descricao': instance.descricao,
  'valor': instance.valor,
  'dataColeta': instance.dataColeta?.toIso8601String(),
  'dataEntrega': instance.dataEntrega?.toIso8601String(),
  'cliente': instance.cliente,
  'contato': instance.contato,
  'observacoes': instance.observacoes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
