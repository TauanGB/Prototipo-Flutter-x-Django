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
  startLatitude: DriverTrip._stringToDouble(json['start_latitude']),
  startLongitude: DriverTrip._stringToDouble(json['start_longitude']),
  endLatitude: DriverTrip._stringToDouble(json['end_latitude']),
  endLongitude: DriverTrip._stringToDouble(json['end_longitude']),
  currentLatitude: DriverTrip._stringToDouble(json['current_latitude']),
  currentLongitude: DriverTrip._stringToDouble(json['current_longitude']),
  status: json['status'] as String? ?? 'started',
  distanceKm: DriverTrip._stringToDouble(json['distance_km']),
  durationMinutes: DriverTrip._stringToInt(json['duration_minutes']),
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

Map<String, dynamic> _$DriverTripToJson(
  DriverTrip instance,
) => <String, dynamic>{
  'id': instance.id,
  'driver': instance.driver,
  'driver_name': instance.driverName,
  'driver_cpf': instance.driverCpf,
  'start_latitude': DriverTrip._doubleToString(instance.startLatitude),
  'start_longitude': DriverTrip._doubleToString(instance.startLongitude),
  'end_latitude': DriverTrip._doubleToString(instance.endLatitude),
  'end_longitude': DriverTrip._doubleToString(instance.endLongitude),
  'current_latitude': DriverTrip._doubleToString(instance.currentLatitude),
  'current_longitude': DriverTrip._doubleToString(instance.currentLongitude),
  'status': instance.status,
  'distance_km': DriverTrip._doubleToString(instance.distanceKm),
  'duration_minutes': DriverTrip._intToString(instance.durationMinutes),
  'started_at': instance.startedAt?.toIso8601String(),
  'completed_at': instance.completedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
