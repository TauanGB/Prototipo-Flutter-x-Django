import 'package:json_annotation/json_annotation.dart';

part 'frete_ativo.g.dart';

/// Modelo simplificado para fretes ativos da API SistemaEG3
/// Compatível com a estrutura atual retornada pela API
@JsonSerializable()
class FreteAtivo {
  final int id;
  @JsonKey(name: 'nome_frete')
  final String? nomeFrete;
  @JsonKey(name: 'numero_nota_fiscal')
  final String? numeroNotaFiscal;
  @JsonKey(name: 'codigo_publico')
  final String? codigoPublico;
  @JsonKey(name: 'status_atual')
  final String? statusAtual;
  final String? origem;
  final String? destino;
  @JsonKey(name: 'data_agendamento')
  final String? dataAgendamento;
  final String? observacoes;
  @JsonKey(name: 'cliente_nome')
  final String? clienteNome;

  const FreteAtivo({
    required this.id,
    this.nomeFrete,
    this.numeroNotaFiscal,
    this.codigoPublico,
    this.statusAtual,
    this.origem,
    this.destino,
    this.dataAgendamento,
    this.observacoes,
    this.clienteNome,
  });

  factory FreteAtivo.fromJson(Map<String, dynamic> json) => _$FreteAtivoFromJson(json);
  Map<String, dynamic> toJson() => _$FreteAtivoToJson(this);

  /// Descrição do frete para exibição
  String get descricao {
    final nome = nomeFrete ?? 'Frete ${id}';
    final nf = numeroNotaFiscal != null ? ' (NF: $numeroNotaFiscal)' : '';
    return '$nome$nf';
  }

  /// Descrição da rota
  String get rota {
    if (origem != null && destino != null) {
      return '$origem → $destino';
    } else if (origem != null) {
      return origem!;
    } else if (destino != null) {
      return destino!;
    }
    return 'Rota não informada';
  }

  /// Status formatado para exibição
  String get statusFormatado {
    if (statusAtual == null) return 'Status não informado';
    
    switch (statusAtual!.toUpperCase()) {
      case 'AGUARDANDO_CARGA':
        return 'Aguardando Carga';
      case 'EM_TRANSITO':
        return 'Em Trânsito';
      case 'EM_DESCARGA_CLIENTE':
        return 'Em Descarga';
      case 'CARREGAMENTO_NAO_INICIADO':
        return 'Carregamento Pendente';
      case 'CARREGAMENTO_INICIADO':
        return 'Carregando';
      case 'DESCARREGAMENTO_NAO_INICIADO':
        return 'Descarga Pendente';
      case 'DESCARREGAMENTO_INICIADO':
        return 'Descarregando';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return statusAtual!;
    }
  }

  /// Cor do status para UI
  String get corStatus {
    if (statusAtual == null) return '#666666';
    
    switch (statusAtual!.toUpperCase()) {
      case 'AGUARDANDO_CARGA':
      case 'CARREGAMENTO_NAO_INICIADO':
        return '#FFA500'; // Laranja
      case 'EM_TRANSITO':
      case 'CARREGAMENTO_INICIADO':
        return '#2196F3'; // Azul
      case 'EM_DESCARGA_CLIENTE':
      case 'DESCARREGAMENTO_INICIADO':
        return '#4CAF50'; // Verde
      case 'FINALIZADO':
        return '#4CAF50'; // Verde
      case 'CANCELADO':
        return '#F44336'; // Vermelho
      default:
        return '#666666'; // Cinza
    }
  }

  @override
  String toString() {
    return 'FreteAtivo(id: $id, nome: $nomeFrete, status: $statusAtual)';
  }
}



