import 'package:json_annotation/json_annotation.dart';

part 'driver_trip.g.dart';

@JsonSerializable()
class DriverTrip {
  final int? id;
  final int? driver;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  @JsonKey(name: 'driver_cpf')
  final String? driverCpf;
  @JsonKey(name: 'start_latitude')
  final double? startLatitude;
  @JsonKey(name: 'start_longitude')
  final double? startLongitude;
  @JsonKey(name: 'end_latitude')
  final double? endLatitude;
  @JsonKey(name: 'end_longitude')
  final double? endLongitude;
  @JsonKey(name: 'current_latitude')
  final double? currentLatitude;
  @JsonKey(name: 'current_longitude')
  final double? currentLongitude;
  final String status;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  DriverTrip({
    this.id,
    this.driver,
    this.driverName,
    this.driverCpf,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.currentLatitude,
    this.currentLongitude,
    this.status = 'started',
    this.distanceKm,
    this.durationMinutes,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> json) =>
      _$DriverTripFromJson(json);

  Map<String, dynamic> toJson() => _$DriverTripToJson(this);

  // Método para criar dados de início de viagem
  Map<String, dynamic> toStartTripJson() {
    return {
      'cpf': driverCpf,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
    };
  }

  // Método para criar dados de fim de viagem
  Map<String, dynamic> toEndTripJson() {
    return {
      'cpf': driverCpf,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      if (distanceKm != null) 'distance_km': distanceKm,
    };
  }

  // Getters para status
  bool get isStarted => status == 'started';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Getter para duração formatada
  String get formattedDuration {
    if (durationMinutes == null) return 'N/A';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  // Getter para distância formatada
  String get formattedDistance {
    if (distanceKm == null) return 'N/A';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}

