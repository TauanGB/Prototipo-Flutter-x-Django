import 'package:json_annotation/json_annotation.dart';
import 'frete_eg3.dart';

part 'frete_rota.g.dart';

/// Modelo de relacionamento frete-rota
@JsonSerializable()
class FreteRota {
  final int id;
  final int ordem;
  @JsonKey(name: 'status_rota')
  final String statusRota;
  @JsonKey(name: 'data_inicio_execucao')
  final DateTime? dataInicioExecucao;
  @JsonKey(name: 'data_conclusao_execucao')
  final DateTime? dataConclusaoExecucao;
  @JsonKey(name: 'frete')
  final FreteEG3 frete;

  const FreteRota({
    required this.id,
    required this.ordem,
    required this.statusRota,
    this.dataInicioExecucao,
    this.dataConclusaoExecucao,
    required this.frete,
  });

  factory FreteRota.fromJson(Map<String, dynamic> json) => _$FreteRotaFromJson(json);
  Map<String, dynamic> toJson() => _$FreteRotaToJson(this);

  /// Verifica se está pendente
  bool get isPendente => statusRota == 'PENDENTE';

  /// Verifica se está em execução
  bool get isEmExecucao => statusRota == 'EM_EXECUCAO';

  /// Verifica se está concluído
  bool get isConcluido => statusRota == 'CONCLUIDO';

  /// Cor do status da rota
  String get corStatus {
    switch (statusRota) {
      case 'PENDENTE':
        return 'gray';
      case 'EM_EXECUCAO':
        return 'blue';
      case 'CONCLUIDO':
        return 'green';
      default:
        return 'gray';
    }
  }

  @override
  String toString() => 'FreteRota(id: $id, ordem: $ordem, status: $statusRota)';
}
