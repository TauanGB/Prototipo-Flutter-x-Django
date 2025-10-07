import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/driver_location.dart';
import '../config/app_config.dart';
import 'config_service.dart';

class ApiService {
  // Obtém a URL base dinamicamente
  static Future<String> get baseUrl async => await AppConfig.apiBaseUrl;
  
  // Headers padrão para as requisições
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Envia dados de localização do motorista para a API
  static Future<DriverLocation?> sendDriverLocation(DriverLocation location) async {
    try {
      final config = await ConfigService.getApiConfig();
      final uri = Uri.parse('${config.baseUrl}/driver-locations/send_location/');
      log('POST para: $uri', name: 'ApiService');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(location.toCreateJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return DriverLocation.fromJson(data);
      } else {
        log('Erro ao enviar localização: ${response.statusCode}', name: 'ApiService');
        log('Resposta: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e, stackTrace) {
      log('Erro na requisição', name: 'ApiService', error: e, stackTrace: stackTrace);
      return null;
    }
  }


  /// Obtém a localização atual do motorista
  static Future<DriverLocation?> getCurrentLocation() async {
    try {
      final currentBaseUrl = await baseUrl;
      final uri = Uri.parse('$currentBaseUrl/driver-locations/current_location/');
      log('GET para: $uri', name: 'ApiService');

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverLocation.fromJson(data);
      } else {
        log('Erro ao obter localização atual: ${response.statusCode}', name: 'ApiService');
        return null;
      }
    } catch (e, stackTrace) {
      log('Erro na requisição', name: 'ApiService', error: e, stackTrace: stackTrace);
      return null;
    }
  }



  /// Atualiza o status do motorista
  static Future<DriverLocation?> updateDriverStatus(String status) async {
    try {
      final currentBaseUrl = await baseUrl;
      final uri = Uri.parse('$currentBaseUrl/driver-locations/update_status/');
      log('POST para: $uri', name: 'ApiService');

      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverLocation.fromJson(data);
      } else {
        log('Erro ao atualizar status: ${response.statusCode}', name: 'ApiService');
        log('Resposta: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e, stackTrace) {
      log('Erro na requisição', name: 'ApiService', error: e, stackTrace: stackTrace);
      return null;
    }
  }

}
