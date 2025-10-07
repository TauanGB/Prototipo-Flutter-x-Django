import 'package:json_annotation/json_annotation.dart';

part 'driver_location.g.dart';

@JsonSerializable()
class DriverLocation {
  final int? id;
  final int? driver;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  @JsonKey(name: 'driver_username')
  final String? driverUsername;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final String status;
  @JsonKey(name: 'battery_level')
  final int? batteryLevel;
  @JsonKey(name: 'is_gps_enabled')
  final bool isGpsEnabled;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  @JsonKey(name: 'app_version')
  final String? appVersion;
  final DateTime? timestamp;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  DriverLocation({
    this.id,
    this.driver,
    this.driverName,
    this.driverUsername,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.status = 'online',
    this.batteryLevel,
    this.isGpsEnabled = true,
    this.deviceId,
    this.appVersion,
    this.timestamp,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationFromJson(json);

  Map<String, dynamic> toJson() => _$DriverLocationToJson(this);

  // Método para criar dados de envio (sem campos de resposta)
  Map<String, dynamic> toCreateJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'status': status,
      'battery_level': batteryLevel,
      'is_gps_enabled': isGpsEnabled,
      'device_id': deviceId,
      'app_version': appVersion,
    };
  }
}
