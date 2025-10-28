// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
  id: (json['id'] as num).toInt(),
  nome: json['nome'] as String,
  quantidade: (json['quantidade'] as num).toDouble(),
  unidadeMedida: json['unidade_medida'] as String,
);

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'quantidade': instance.quantidade,
  'unidade_medida': instance.unidadeMedida,
};
