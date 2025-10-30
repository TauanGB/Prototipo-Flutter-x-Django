import 'sync_frete.dart';
import 'sync_event.dart';

/// Estado operacional atual do motorista no dispositivo
/// 
/// Representa tudo que a UI vai mostrar e tudo que o serviço de background
/// vai enviar para o backend no POST /api/fretes/motorista/sync/
/// 
/// Baseado no README_API_ENDPOINTS.md seção "📱 ESPECIFICAÇÃO PARA APP FLUTTER"
class SyncState {
  final int motoristaId;
  final int? rotaId;
  final bool rotaAtiva;
  final String ultimaAtualizacao; // ISO8601 string
  final LocalizacaoAtual localizacaoAtual;
  final List<SyncFrete> fretes;
  final List<SyncEvent> filaEnvioPendente;

  const SyncState({
    required this.motoristaId,
    this.rotaId,
    required this.rotaAtiva,
    required this.ultimaAtualizacao,
    required this.localizacaoAtual,
    required this.fretes,
    required this.filaEnvioPendente,
  });

  /// Cria SyncState vazio/limpo para um motorista
  factory SyncState.empty({required int motoristaId}) {
    return SyncState(
      motoristaId: motoristaId,
      rotaId: null,
      rotaAtiva: false,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
      localizacaoAtual: const LocalizacaoAtual(latitude: 0.0, longitude: 0.0),
      fretes: [],
      filaEnvioPendente: [],
    );
  }

  /// Cria SyncState a partir da resposta do endpoint GET /api/fretes/motorista/rota-atual/
  /// 
  /// Response do backend:
  /// {
  ///   "rota_id": 5,
  ///   "nome_rota": "Rota SP-RJ",
  ///   "status": "EM_ANDAMENTO",
  ///   "fretes_rota": [
  ///     {
  ///       "id": 11,
  ///       "ordem": 2,
  ///       "status_rota": "EM_EXECUCAO",
  ///       "frete_info": { ... }
  ///     }
  ///   ]
  /// }
  factory SyncState.fromApiRotaAtual({
    required int motoristaId,
    required Map<String, dynamic> apiResponse,
    LocalizacaoAtual? localizacaoAtual,
    List<SyncEvent>? filaEnvioPendente,
  }) {
    final rotaId = apiResponse['rota_id'] as int?;
    final status = apiResponse['status'] as String?;
    final rotaAtiva = status == 'EM_ANDAMENTO';

    // Mapear fretes da rota
    final fretesJson = apiResponse['fretes_rota'] as List<dynamic>? ?? [];
    final fretes = fretesJson
        .map((f) => SyncFrete.fromApiRotaAtual(f as Map<String, dynamic>))
        .toList();

    return SyncState(
      motoristaId: motoristaId,
      rotaId: rotaId,
      rotaAtiva: rotaAtiva,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
      localizacaoAtual: localizacaoAtual ?? 
          const LocalizacaoAtual(latitude: 0.0, longitude: 0.0),
      fretes: fretes,
      filaEnvioPendente: filaEnvioPendente ?? [],
    );
  }

  /// Cria SyncState quando não há rota ativa
  factory SyncState.semRota({
    required int motoristaId,
    LocalizacaoAtual? localizacaoAtual,
    List<SyncEvent>? filaEnvioPendente,
  }) {
    return SyncState(
      motoristaId: motoristaId,
      rotaId: null,
      rotaAtiva: false,
      ultimaAtualizacao: DateTime.now().toIso8601String(),
      localizacaoAtual: localizacaoAtual ?? 
          const LocalizacaoAtual(latitude: 0.0, longitude: 0.0),
      fretes: [],
      filaEnvioPendente: filaEnvioPendente ?? [],
    );
  }

  /// Cria SyncState a partir de JSON armazenado localmente
  factory SyncState.fromJson(Map<String, dynamic> json) {
    final fretesJson = json['fretes'] as List<dynamic>? ?? [];
    final eventosJson = json['fila_envio_pendente'] as List<dynamic>? ?? [];
    final localizacaoJson = json['localizacao_atual'] as Map<String, dynamic>? ?? {};

    return SyncState(
      motoristaId: json['motorista_id'] as int,
      rotaId: json['rota_id'] as int?,
      rotaAtiva: json['rota_ativa'] as bool? ?? false,
      ultimaAtualizacao: json['ultima_atualizacao'] as String,
      localizacaoAtual: LocalizacaoAtual.fromJson(localizacaoJson),
      fretes: fretesJson
          .map((f) => SyncFrete.fromJson(f as Map<String, dynamic>))
          .toList(),
      filaEnvioPendente: eventosJson
          .map((e) => SyncEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converte SyncState para JSON (para armazenamento local)
  Map<String, dynamic> toJson() {
    return {
      'motorista_id': motoristaId,
      'rota_id': rotaId,
      'rota_ativa': rotaAtiva,
      'ultima_atualizacao': ultimaAtualizacao,
      'localizacao_atual': localizacaoAtual.toJson(),
      'fretes': fretes.map((f) => f.toJson()).toList(),
      'fila_envio_pendente': filaEnvioPendente.map((e) => e.toJson()).toList(),
    };
  }

  /// Cria cópia do SyncState com campos atualizados
  SyncState copyWith({
    int? motoristaId,
    int? rotaId,
    bool? rotaAtiva,
    String? ultimaAtualizacao,
    LocalizacaoAtual? localizacaoAtual,
    List<SyncFrete>? fretes,
    List<SyncEvent>? filaEnvioPendente,
  }) {
    return SyncState(
      motoristaId: motoristaId ?? this.motoristaId,
      rotaId: rotaId ?? this.rotaId,
      rotaAtiva: rotaAtiva ?? this.rotaAtiva,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      localizacaoAtual: localizacaoAtual ?? this.localizacaoAtual,
      fretes: fretes ?? this.fretes,
      filaEnvioPendente: filaEnvioPendente ?? this.filaEnvioPendente,
    );
  }

  /// Obtém o frete atual (status_rota == EM_EXECUCAO)
  SyncFrete? get freteAtual {
    try {
      return fretes.firstWhere((f) => f.statusRota == 'EM_EXECUCAO');
    } catch (e) {
      return null;
    }
  }

  /// Obtém o próximo frete pendente
  SyncFrete? get proximoFretePendente {
    try {
      return fretes.firstWhere((f) => f.statusRota == 'PENDENTE');
    } catch (e) {
      return null;
    }
  }

  /// Verifica se há rota ativa com fretes
  bool get temRotaAtiva => rotaAtiva && rotaId != null && fretes.isNotEmpty;

  @override
  String toString() {
    return 'SyncState(motoristaId: $motoristaId, rotaId: $rotaId, rotaAtiva: $rotaAtiva, fretes: ${fretes.length}, eventos: ${filaEnvioPendente.length})';
  }
}

/// Localização atual do motorista
class LocalizacaoAtual {
  final double latitude;
  final double longitude;

  const LocalizacaoAtual({
    required this.latitude,
    required this.longitude,
  });

  factory LocalizacaoAtual.fromJson(Map<String, dynamic> json) {
    return LocalizacaoAtual(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Verifica se a localização é válida (diferente de 0,0)
  bool get isValid => latitude != 0.0 || longitude != 0.0;

  @override
  String toString() {
    return 'LocalizacaoAtual(lat: $latitude, lon: $longitude)';
  }
}

