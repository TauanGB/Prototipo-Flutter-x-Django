// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil_usuario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerfilUsuario _$PerfilUsuarioFromJson(Map<String, dynamic> json) =>
    PerfilUsuario(
      id: (json['id'] as num).toInt(),
      tipoUsuario: json['tipo_usuario'] as String,
      tipoUsuarioDisplay: json['tipo_usuario_display'] as String?,
      telefone: json['telefone'] as String?,
      cpf: json['cpf'] as String?,
      dataCriacao: DateTime.parse(json['data_criacao'] as String),
      dataAtualizacao: DateTime.parse(json['data_atualizacao'] as String),
      ativo: json['ativo'] as bool,
    );

Map<String, dynamic> _$PerfilUsuarioToJson(PerfilUsuario instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo_usuario': instance.tipoUsuario,
      'tipo_usuario_display': instance.tipoUsuarioDisplay,
      'telefone': instance.telefone,
      'cpf': instance.cpf,
      'data_criacao': instance.dataCriacao.toIso8601String(),
      'data_atualizacao': instance.dataAtualizacao.toIso8601String(),
      'ativo': instance.ativo,
    };
