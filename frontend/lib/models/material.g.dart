// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
  id: (json['id'] as num).toInt(),
  nome: json['nome'] as String,
  descricao: json['descricao'] as String?,
  unidade: json['unidade'] as String?,
  quantidade: (json['quantidade'] as num?)?.toDouble(),
  peso: (json['peso'] as num?)?.toDouble(),
  observacoes: json['observacoes'] as String?,
  dataCriacao: DateTime.parse(json['data_criacao'] as String),
  dataAtualizacao: DateTime.parse(json['data_atualizacao'] as String),
  ativo: json['ativo'] as bool,
);

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'descricao': instance.descricao,
  'unidade': instance.unidade,
  'quantidade': instance.quantidade,
  'peso': instance.peso,
  'observacoes': instance.observacoes,
  'data_criacao': instance.dataCriacao.toIso8601String(),
  'data_atualizacao': instance.dataAtualizacao.toIso8601String(),
  'ativo': instance.ativo,
};
