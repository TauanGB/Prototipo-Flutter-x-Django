import 'package:json_annotation/json_annotation.dart';

part 'material.g.dart';

/// Modelo de material transportado no frete
@JsonSerializable()
class Material {
  final int id;
  final String nome;
  final double quantidade;
  @JsonKey(name: 'unidade_medida')
  final String unidadeMedida;

  const Material({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidadeMedida,
  });

  factory Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);
  Map<String, dynamic> toJson() => _$MaterialToJson(this);

  /// Descrição formatada do material
  String get descricaoFormatada => '$quantidade $unidadeMedida de $nome';

  @override
  String toString() => 'Material(id: $id, nome: $nome, quantidade: $quantidade $unidadeMedida)';
}
