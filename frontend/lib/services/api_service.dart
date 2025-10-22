import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/driver_location.dart';
import '../models/driver_trip.dart';
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
      final uri = Uri.parse('${config.baseUrl}/drivers/send_location/');
      log('POST para: $uri', name: 'ApiService');
      log('Dados enviados: ${location.toCreateJson()}', name: 'ApiService');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(location.toCreateJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        log('Resposta da API: $data', name: 'ApiService');
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



  /// Inicia uma nova viagem
  static Future<DriverTrip?> startTrip(String cpf, double latitude, double longitude) async {
    try {
      final config = await ConfigService.getApiConfig();
      final uri = Uri.parse('${config.baseUrl}/drivers/start_trip/');
      log('POST para: $uri', name: 'ApiService');
      
      final requestData = {
        'cpf': cpf,
        'start_latitude': latitude,
        'start_longitude': longitude,
      };
      
      log('Dados de início de viagem: $requestData', name: 'ApiService');

      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        log('Viagem iniciada com sucesso: $data', name: 'ApiService');
        return DriverTrip.fromJson(data);
      } else {
        log('Erro ao iniciar viagem: ${response.statusCode}', name: 'ApiService');
        log('Resposta: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e, stackTrace) {
      log('Erro na requisição de início de viagem', name: 'ApiService', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Finaliza uma viagem ativa
  static Future<DriverTrip?> endTrip(String cpf, double latitude, double longitude, {double? distanceKm}) async {
    try {
      final config = await ConfigService.getApiConfig();
      final uri = Uri.parse('${config.baseUrl}/drivers/end_trip/');
      log('POST para: $uri', name: 'ApiService');
      
      final requestData = {
        'cpf': cpf,
        'end_latitude': latitude,
        'end_longitude': longitude,
        if (distanceKm != null) 'distance_km': distanceKm,
      };
      
      log('Dados de fim de viagem: $requestData', name: 'ApiService');

      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Viagem finalizada com sucesso: $data', name: 'ApiService');
        return DriverTrip.fromJson(data);
      } else {
        log('Erro ao finalizar viagem: ${response.statusCode}', name: 'ApiService');
        log('Resposta: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e, stackTrace) {
      log('Erro na requisição de fim de viagem', name: 'ApiService', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Obtém dados completos do motorista
  static Future<Map<String, dynamic>?> getDriverData(String cpf) async {
    try {
      final config = await ConfigService.getApiConfig();
      final uri = Uri.parse('${config.baseUrl}/drivers/get_driver_data/?cpf=$cpf');
      log('GET para: $uri', name: 'ApiService');

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Dados do motorista obtidos: ${data.keys}', name: 'ApiService');
        return data;
      } else {
        log('Erro ao obter dados do motorista: ${response.statusCode}', name: 'ApiService');
        log('Resposta: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e, stackTrace) {
      log('Erro na requisição de dados do motorista', name: 'ApiService', error: e, stackTrace: stackTrace);
      return null;
    }
  }

}
