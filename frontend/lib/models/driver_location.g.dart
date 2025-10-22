// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverLocation _$DriverLocationFromJson(Map<String, dynamic> json) =>
    DriverLocation(
      id: (json['id'] as num?)?.toInt(),
      driver: (json['driver'] as num?)?.toInt(),
      cpf: json['cpf'] as String?,
      driverName: json['driver_name'] as String?,
      driverCpf: json['driver_cpf'] as String?,
      driverUsername: json['driver_username'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
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

Map<String, dynamic> _$DriverLocationToJson(DriverLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver': instance.driver,
      'cpf': instance.cpf,
      'driver_name': instance.driverName,
      'driver_cpf': instance.driverCpf,
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
