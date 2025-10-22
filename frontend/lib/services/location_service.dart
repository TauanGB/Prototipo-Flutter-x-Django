import 'dart:io';
import 'package:geolocator/geolocator.dart';

class LocationService {

  /// Solicita permissão de localização
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Verifica se tem permissão de localização
  static Future<bool> hasPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Verifica se o serviço de localização está habilitado
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verifica a permissão atual de localização
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Obtém a localização atual
  static Future<Position?> getCurrentPosition() async {
    try {
      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Serviço de localização desabilitado');
        return null;
      }

      // Verifica permissões
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permissão de localização negada');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permissão de localização negada permanentemente');
        return null;
      }

      // Obtém a posição atual com configurações específicas de plataforma
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isIOS 
          ? AppleSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            )
          : AndroidSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            ),
      );

      return position;
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }


}
