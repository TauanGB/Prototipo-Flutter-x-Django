/// Evento pendente de atualização de status na fila de envio
/// 
/// Representa uma mudança de status que o app já aplicou localmente,
/// mas que ainda não foi confirmada pelo backend via sync
class SyncEvent {
  final int freteId;
  final String statusNovo;
  final String? observacoes;
  final String timestamp; // ISO8601 string

  const SyncEvent({
    required this.freteId,
    required this.statusNovo,
    this.observacoes,
    required this.timestamp,
  });

  /// Cria SyncEvent a partir de JSON
  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      freteId: json['frete_id'] as int,
      statusNovo: json['status_novo'] as String,
      observacoes: json['observacoes'] as String?,
      timestamp: json['timestamp'] as String,
    );
  }

  /// Converte SyncEvent para JSON (formato do backend para sync)
  Map<String, dynamic> toJson() {
    return {
      'frete_id': freteId,
      'status_novo': statusNovo,
      if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
      'timestamp': timestamp,
    };
  }

  /// Cria SyncEvent com timestamp atual
  factory SyncEvent.now({
    required int freteId,
    required String statusNovo,
    String? observacoes,
  }) {
    return SyncEvent(
      freteId: freteId,
      statusNovo: statusNovo,
      observacoes: observacoes,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncEvent &&
        other.freteId == freteId &&
        other.statusNovo == statusNovo &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(freteId, statusNovo, timestamp);
  }

  @override
  String toString() {
    return 'SyncEvent(freteId: $freteId, statusNovo: $statusNovo, timestamp: $timestamp)';
  }
}

