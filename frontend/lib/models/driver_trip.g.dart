// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverTrip _$DriverTripFromJson(Map<String, dynamic> json) => DriverTrip(
  id: (json['id'] as num?)?.toInt(),
  driver: (json['driver'] as num?)?.toInt(),
  driverName: json['driver_name'] as String?,
  driverCpf: json['driver_cpf'] as String?,
  startLatitude: (json['start_latitude'] as num?)?.toDouble(),
  startLongitude: (json['start_longitude'] as num?)?.toDouble(),
  endLatitude: (json['end_latitude'] as num?)?.toDouble(),
  endLongitude: (json['end_longitude'] as num?)?.toDouble(),
  currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
  currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
  status: json['status'] as String? ?? 'started',
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DriverTripToJson(DriverTrip instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver': instance.driver,
      'driver_name': instance.driverName,
      'driver_cpf': instance.driverCpf,
      'start_latitude': instance.startLatitude,
      'start_longitude': instance.startLongitude,
      'end_latitude': instance.endLatitude,
      'end_longitude': instance.endLongitude,
      'current_latitude': instance.currentLatitude,
      'current_longitude': instance.currentLongitude,
      'status': instance.status,
      'distance_km': instance.distanceKm,
      'duration_minutes': instance.durationMinutes,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
