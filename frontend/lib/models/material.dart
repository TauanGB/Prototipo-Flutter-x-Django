import 'package:json_annotation/json_annotation.dart';

part 'material.g.dart';

/// Modelo de material do SistemaEG3
@JsonSerializable()
class Material {
  final int id;
  final String nome;
  final String? descricao;
  final String? unidade;
  final double? quantidade;
  final double? peso;
  final String? observacoes;
  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;
  @JsonKey(name: 'data_atualizacao')
  final DateTime dataAtualizacao;
  final bool ativo;

  const Material({
    required this.id,
    required this.nome,
    this.descricao,
    this.unidade,
    this.quantidade,
    this.peso,
    this.observacoes,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.ativo,
  });

  factory Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);
  Map<String, dynamic> toJson() => _$MaterialToJson(this);

  /// Descrição completa do material
  String get descricaoCompleta {
    final desc = descricao != null ? ' - $descricao' : '';
    final qtd = quantidade != null ? ' (${quantidade!.toStringAsFixed(2)} ${unidade ?? 'un'})' : '';
    return '$nome$desc$qtd';
  }

  /// Peso formatado
  String? get pesoFormatado {
    if (peso != null) {
      return '${peso!.toStringAsFixed(2)} kg';
    }
    return null;
  }

  /// Quantidade formatada
  String? get quantidadeFormatada {
    if (quantidade != null) {
      return '${quantidade!.toStringAsFixed(2)} ${unidade ?? 'un'}';
    }
    return null;
  }

  @override
  String toString() => 'Material(id: $id, nome: $nome)';
}







