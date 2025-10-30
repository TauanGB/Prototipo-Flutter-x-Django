import 'package:json_annotation/json_annotation.dart';

part 'status_history.g.dart';

/// Modelo de histórico de status do SistemaEG3
@JsonSerializable()
class StatusHistory {
  final int id;
  final int frete;
  final String status;
  @JsonKey(name: 'status_display')
  final String statusDisplay;
  @JsonKey(name: 'data_mudanca')
  final DateTime dataMudanca;
  @JsonKey(name: 'usuario')
  final String? usuario;
  @JsonKey(name: 'observacoes')
  final String? observacoes;
  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;

  const StatusHistory({
    required this.id,
    required this.frete,
    required this.status,
    required this.statusDisplay,
    required this.dataMudanca,
    this.usuario,
    this.observacoes,
    required this.dataCriacao,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) => _$StatusHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$StatusHistoryToJson(this);

  /// Data formatada da mudança de status
  String get dataMudancaFormatada {
    return '${dataMudanca.day.toString().padLeft(2, '0')}/${dataMudanca.month.toString().padLeft(2, '0')}/${dataMudanca.year} ${dataMudanca.hour.toString().padLeft(2, '0')}:${dataMudanca.minute.toString().padLeft(2, '0')}';
  }

  /// Data formatada da criação
  String get dataCriacaoFormatada {
    return '${dataCriacao.day.toString().padLeft(2, '0')}/${dataCriacao.month.toString().padLeft(2, '0')}/${dataCriacao.year} ${dataCriacao.hour.toString().padLeft(2, '0')}:${dataCriacao.minute.toString().padLeft(2, '0')}';
  }

  /// Descrição resumida do histórico
  String get descricaoResumida {
    final usuario = this.usuario ?? 'Sistema';
    return '$statusDisplay por $usuario';
  }

  /// Informações completas do histórico
  String get informacoesCompletas {
    final info = <String>[];
    
    info.add('Status: $statusDisplay');
    info.add('Data: $dataMudancaFormatada');
    
    if (usuario != null) {
      info.add('Usuário: $usuario');
    }
    
    if (observacoes != null && observacoes!.isNotEmpty) {
      info.add('Observações: $observacoes');
    }
    
    return info.join('\n');
  }

  /// Cria uma cópia do StatusHistory com campos atualizados
  StatusHistory copyWith({
    int? id,
    int? frete,
    String? status,
    String? statusDisplay,
    DateTime? dataMudanca,
    String? usuario,
    String? observacoes,
    DateTime? dataCriacao,
  }) {
    return StatusHistory(
      id: id ?? this.id,
      frete: frete ?? this.frete,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      dataMudanca: dataMudanca ?? this.dataMudanca,
      usuario: usuario ?? this.usuario,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  String toString() => 'StatusHistory(id: $id, frete: $frete, status: $status, data: $dataMudancaFormatada)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}