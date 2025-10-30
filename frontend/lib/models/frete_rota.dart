import 'package:json_annotation/json_annotation.dart';
import 'frete_eg3.dart';

part 'frete_rota.g.dart';

/// Modelo de frete dentro de uma rota do SistemaEG3
@JsonSerializable()
class FreteRota {
  final int id;
  final int rota;
  final int frete;
  final FreteEG3? freteData;
  @JsonKey(name: 'ordem')
  final int ordem;
  @JsonKey(name: 'status_rota')
  final String statusRota;
  @JsonKey(name: 'status_rota_display')
  final String statusRotaDisplay;
  @JsonKey(name: 'data_inicio')
  final DateTime? dataInicio;
  @JsonKey(name: 'data_conclusao')
  final DateTime? dataConclusao;
  @JsonKey(name: 'observacoes')
  final String? observacoes;
  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;
  @JsonKey(name: 'data_atualizacao')
  final DateTime dataAtualizacao;

  const FreteRota({
    required this.id,
    required this.rota,
    required this.frete,
    this.freteData,
    required this.ordem,
    required this.statusRota,
    required this.statusRotaDisplay,
    this.dataInicio,
    this.dataConclusao,
    this.observacoes,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  factory FreteRota.fromJson(Map<String, dynamic> json) => _$FreteRotaFromJson(json);
  Map<String, dynamic> toJson() => _$FreteRotaToJson(this);

  /// Verifica se o frete está pendente na rota
  bool get isPendente => statusRota == 'PENDENTE';

  /// Verifica se o frete está em execução na rota
  bool get isEmExecucao => statusRota == 'EM_EXECUCAO';

  /// Verifica se o frete está concluído na rota
  bool get isConcluido => statusRota == 'CONCLUIDO';

  /// Verifica se o frete está cancelado na rota
  bool get isCancelado => statusRota == 'CANCELADO';

  /// Data formatada para início
  String? get dataInicioFormatada {
    if (dataInicio != null) {
      return '${dataInicio!.day.toString().padLeft(2, '0')}/${dataInicio!.month.toString().padLeft(2, '0')}/${dataInicio!.year} ${dataInicio!.hour.toString().padLeft(2, '0')}:${dataInicio!.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Data formatada para conclusão
  String? get dataConclusaoFormatada {
    if (dataConclusao != null) {
      return '${dataConclusao!.day.toString().padLeft(2, '0')}/${dataConclusao!.month.toString().padLeft(2, '0')}/${dataConclusao!.year} ${dataConclusao!.hour.toString().padLeft(2, '0')}:${dataConclusao!.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Duração do frete na rota
  Duration? get duracao {
    if (dataInicio != null && dataConclusao != null) {
      return dataConclusao!.difference(dataInicio!);
    }
    return null;
  }

  /// Duração formatada do frete
  String? get duracaoFormatada {
    final duracao = this.duracao;
    if (duracao != null) {
      final horas = duracao.inHours;
      final minutos = duracao.inMinutes % 60;
      
      if (horas > 0) {
        return '${horas}h ${minutos}min';
      } else {
        return '${minutos}min';
      }
    }
    return null;
  }

  /// Descrição resumida do frete na rota
  String get descricaoResumida {
    if (freteData != null) {
      final origem = freteData!.origem ?? 'N/A';
      final destino = freteData!.destino ?? 'N/A';
      return '$origem → $destino';
    }
    return 'Frete #$frete';
  }

  /// Informações completas do frete na rota
  String get informacoesCompletas {
    final info = <String>[];
    
    info.add('Ordem: $ordem');
    info.add('Status: $statusRotaDisplay');
    
    if (freteData != null) {
      info.add('Código: ${freteData!.codigoPublico}');
      info.add('Cliente: ${freteData!.clienteNome}');
      info.add('Serviço: ${freteData!.tipoServicoDisplay}');
    }
    
    if (dataInicio != null) {
      info.add('Início: ${dataInicioFormatada!}');
    }
    
    if (dataConclusao != null) {
      info.add('Conclusão: ${dataConclusaoFormatada!}');
    }
    
    if (duracaoFormatada != null) {
      info.add('Duração: ${duracaoFormatada!}');
    }
    
    return info.join('\n');
  }

  /// Cria uma cópia do FreteRota com campos atualizados
  FreteRota copyWith({
    int? id,
    int? rota,
    int? frete,
    FreteEG3? freteData,
    int? ordem,
    String? statusRota,
    String? statusRotaDisplay,
    DateTime? dataInicio,
    DateTime? dataConclusao,
    String? observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return FreteRota(
      id: id ?? this.id,
      rota: rota ?? this.rota,
      frete: frete ?? this.frete,
      freteData: freteData ?? this.freteData,
      ordem: ordem ?? this.ordem,
      statusRota: statusRota ?? this.statusRota,
      statusRotaDisplay: statusRotaDisplay ?? this.statusRotaDisplay,
      dataInicio: dataInicio ?? this.dataInicio,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  @override
  String toString() => 'FreteRota(id: $id, rota: $rota, frete: $frete, ordem: $ordem, status: $statusRota)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FreteRota && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}