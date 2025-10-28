import 'package:json_annotation/json_annotation.dart';
import 'frete_rota.dart';

part 'rota.g.dart';

/// Modelo de rota do SistemaEG3
@JsonSerializable()
class Rota {
  final int id;
  final String nome;
  final int? motorista;
  @JsonKey(name: 'motorista_nome')
  final String? motoristaNome;
  @JsonKey(name: 'motorista_username')
  final String? motoristaUsername;
  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;
  @JsonKey(name: 'data_inicio')
  final DateTime? dataInicio;
  @JsonKey(name: 'data_conclusao')
  final DateTime? dataConclusao;
  final String status;
  final String? observacoes;
  final bool ativo;
  @JsonKey(name: 'fretes_rota')
  final List<FreteRota>? fretesRota;
  @JsonKey(name: 'total_fretes')
  final int totalFretes;
  @JsonKey(name: 'fretes_concluidos')
  final int fretesConcluidos;
  @JsonKey(name: 'progresso_percentual')
  final double progressoPercentual;

  const Rota({
    required this.id,
    required this.nome,
    this.motorista,
    this.motoristaNome,
    this.motoristaUsername,
    required this.dataCriacao,
    this.dataInicio,
    this.dataConclusao,
    required this.status,
    this.observacoes,
    required this.ativo,
    this.fretesRota,
    required this.totalFretes,
    required this.fretesConcluidos,
    required this.progressoPercentual,
  });

  factory Rota.fromJson(Map<String, dynamic> json) => _$RotaFromJson(json);
  Map<String, dynamic> toJson() => _$RotaToJson(this);

  /// Verifica se está planejada
  bool get isPlanejada => status == 'PLANEJADA';

  /// Verifica se está em andamento
  bool get isEmAndamento => status == 'EM_ANDAMENTO';

  /// Verifica se está concluída
  bool get isConcluida => status == 'CONCLUIDA';

  /// Verifica se está cancelada
  bool get isCancelada => status == 'CANCELADA';

  /// Cor do status da rota
  String get corStatus {
    switch (status) {
      case 'PLANEJADA':
        return 'gray';
      case 'EM_ANDAMENTO':
        return 'blue';
      case 'CONCLUIDA':
        return 'green';
      case 'CANCELADA':
        return 'red';
      default:
        return 'gray';
    }
  }

  /// Data de criação formatada
  String get dataCriacaoFormatada {
    return '${dataCriacao.day.toString().padLeft(2, '0')}/'
           '${dataCriacao.month.toString().padLeft(2, '0')}/'
           '${dataCriacao.year}';
  }

  /// Data de início formatada
  String? get dataInicioFormatada {
    if (dataInicio != null) {
      return '${dataInicio!.day.toString().padLeft(2, '0')}/'
             '${dataInicio!.month.toString().padLeft(2, '0')}/'
             '${dataInicio!.year} '
             '${dataInicio!.hour.toString().padLeft(2, '0')}:'
             '${dataInicio!.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Data de conclusão formatada
  String? get dataConclusaoFormatada {
    if (dataConclusao != null) {
      return '${dataConclusao!.day.toString().padLeft(2, '0')}/'
             '${dataConclusao!.month.toString().padLeft(2, '0')}/'
             '${dataConclusao!.year} '
             '${dataConclusao!.hour.toString().padLeft(2, '0')}:'
             '${dataConclusao!.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Descrição da rota
  String get descricao {
    final motorista = motoristaNome ?? 'Sem motorista';
    final fretes = '$totalFretes frete${totalFretes != 1 ? 's' : ''}';
    return '$nome - $motorista ($fretes)';
  }

  /// Fretes pendentes
  List<FreteRota> get fretesPendentes {
    return fretesRota?.where((f) => f.isPendente).toList() ?? [];
  }

  /// Fretes em execução
  List<FreteRota> get fretesEmExecucao {
    return fretesRota?.where((f) => f.isEmExecucao).toList() ?? [];
  }

  /// Fretes concluídos
  List<FreteRota> get fretesConcluidosList {
    return fretesRota?.where((f) => f.isConcluido).toList() ?? [];
  }

  /// Próximo frete a ser executado
  FreteRota? get proximoFrete {
    final pendentes = fretesPendentes;
    if (pendentes.isNotEmpty) {
      pendentes.sort((a, b) => a.ordem.compareTo(b.ordem));
      return pendentes.first;
    }
    return null;
  }

  /// Frete atual em execução
  FreteRota? get freteAtual {
    final emExecucao = fretesEmExecucao;
    return emExecucao.isNotEmpty ? emExecucao.first : null;
  }

  @override
  String toString() => 'Rota(id: $id, nome: $nome, status: $status, progresso: ${progressoPercentual.toStringAsFixed(1)}%)';
}
