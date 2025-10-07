// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverLocation _$DriverLocationFromJson(Map<String, dynamic> json) =>
    DriverLocation(
      id: (json['id'] as num?)?.toInt(),
      driver: (json['driver'] as num?)?.toInt(),
      driverName: json['driver_name'] as String?,
      driverUsername: json['driver_username'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      accuracy: _parseDoubleNullable(json['accuracy']),
      speed: _parseDoubleNullable(json['speed']),
      heading: _parseDoubleNullable(json['heading']),
      altitude: _parseDoubleNullable(json['altitude']),
      status: json['status'] as String? ?? 'online',
      batteryLevel: (json['battery_level'] as num?)?.toInt(),
      isGpsEnabled: json['is_gps_enabled'] as bool? ?? true,
      deviceId: json['device_id'] as String?,
      appVersion: json['app_version'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw ArgumentError('Cannot parse $value to double');
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw ArgumentError('Cannot parse $value to double');
}

Map<String, dynamic> _$DriverLocationToJson(DriverLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver': instance.driver,
      'driver_name': instance.driverName,
      'driver_username': instance.driverUsername,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'heading': instance.heading,
      'altitude': instance.altitude,
      'status': instance.status,
      'battery_level': instance.batteryLevel,
      'is_gps_enabled': instance.isGpsEnabled,
      'device_id': instance.deviceId,
      'app_version': instance.appVersion,
      'timestamp': instance.timestamp?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
