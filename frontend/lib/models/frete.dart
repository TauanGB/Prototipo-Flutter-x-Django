import 'package:json_annotation/json_annotation.dart';

part 'frete.g.dart';

@JsonSerializable()
class Frete {
  final int id;
  final String origem;
  final String destino;
  final String status;
  final String? descricao;
  final double? valor;
  final DateTime? dataColeta;
  final DateTime? dataEntrega;
  final String? cliente;
  final String? contato;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Frete({
    required this.id,
    required this.origem,
    required this.destino,
    required this.status,
    this.descricao,
    this.valor,
    this.dataColeta,
    this.dataEntrega,
    this.cliente,
    this.contato,
    this.observacoes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Frete.fromJson(Map<String, dynamic> json) => _$FreteFromJson(json);
  Map<String, dynamic> toJson() => _$FreteToJson(this);

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'em_andamento':
        return 'Em Andamento';
      case 'coletado':
        return 'Coletado';
      case 'em_transito':
        return 'Em Trânsito';
      case 'entregue':
        return 'Entregue';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String get formattedValor {
    if (valor == null) return 'N/A';
    return 'R\$ ${valor!.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get formattedDataColeta {
    if (dataColeta == null) return 'N/A';
    return '${dataColeta!.day}/${dataColeta!.month}/${dataColeta!.year}';
  }

  String get formattedDataEntrega {
    if (dataEntrega == null) return 'N/A';
    return '${dataEntrega!.day}/${dataEntrega!.month}/${dataEntrega!.year}';
  }

  String get rota {
    return '$origem → $destino';
  }
}
