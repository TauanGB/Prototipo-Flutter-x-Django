import 'package:json_annotation/json_annotation.dart';

part 'status_history.g.dart';

/// Modelo de histórico de status do frete
@JsonSerializable()
class StatusHistory {
  final int id;
  @JsonKey(name: 'status_anterior')
  final String? statusAnterior;
  @JsonKey(name: 'status_anterior_display')
  final String? statusAnteriorDisplay;
  @JsonKey(name: 'status_novo')
  final String statusNovo;
  @JsonKey(name: 'status_novo_display')
  final String statusNovoDisplay;
  final int? usuario;
  @JsonKey(name: 'usuario_nome')
  final String? usuarioNome;
  @JsonKey(name: 'data_alteracao')
  final DateTime dataAlteracao;
  final String? observacoes;

  const StatusHistory({
    required this.id,
    this.statusAnterior,
    this.statusAnteriorDisplay,
    required this.statusNovo,
    required this.statusNovoDisplay,
    this.usuario,
    this.usuarioNome,
    required this.dataAlteracao,
    this.observacoes,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) => _$StatusHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$StatusHistoryToJson(this);

  /// Descrição da mudança de status
  String get descricaoMudanca {
    if (statusAnterior != null) {
      return '${statusAnteriorDisplay ?? statusAnterior} → ${statusNovoDisplay}';
    }
    return statusNovoDisplay;
  }

  /// Data formatada
  String get dataFormatada {
    return '${dataAlteracao.day.toString().padLeft(2, '0')}/'
           '${dataAlteracao.month.toString().padLeft(2, '0')}/'
           '${dataAlteracao.year} '
           '${dataAlteracao.hour.toString().padLeft(2, '0')}:'
           '${dataAlteracao.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'StatusHistory(id: $id, mudanca: $descricaoMudanca, data: $dataFormatada)';
}
