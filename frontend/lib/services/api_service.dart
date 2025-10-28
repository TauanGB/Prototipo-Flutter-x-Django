import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/driver_location.dart';
import '../models/driver_trip.dart';
import '../config/app_config.dart';
import '../models/api_config.dart';

class ApiService {
  // Obtém a URL base dinamicamente
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Headers padrão para as requisições
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Envia dados de localização do motorista para a API
  static Future<Map<String, dynamic>> sendDriverLocation(DriverLocation location) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/drivers/send_location/');
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
        return {
          'success': true,
          'data': DriverLocation.fromJson(data),
          'error': null,
          'statusCode': response.statusCode,
        };
      } else {
        log('❌ ERRO API: Falha ao enviar localização - Status: ${response.statusCode}', name: 'ApiService');
        log('❌ Resposta da API: ${response.body}', name: 'ApiService');
        log('❌ Verifique configurações da API e conexão com internet', name: 'ApiService');
        return {
          'success': false,
          'data': null,
          'error': 'Status ${response.statusCode}: ${response.body}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      log('❌ ERRO CRÍTICO: Falha na requisição de localização', name: 'ApiService', error: e, stackTrace: stackTrace);
      log('❌ Verifique conexão com internet e configurações da API', name: 'ApiService');
      return {
        'success': false,
        'data': null,
        'error': 'Erro de conexão: $e',
        'statusCode': null,
      };
    }
  }


  /// Obtém a localização atual do motorista
  static Future<DriverLocation?> getCurrentLocation() async {
    try {
      final currentBaseUrl = baseUrl;
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
      log('❌ ERRO CRÍTICO: Falha na requisição de localização', name: 'ApiService', error: e, stackTrace: stackTrace);
      log('❌ Verifique conexão com internet e configurações da API', name: 'ApiService');
      return null;
    }
  }



  /// Inicia uma nova viagem
  static Future<Map<String, dynamic>> startTrip(String cpf, double latitude, double longitude) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/drivers/start_trip/');
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
        return {
          'success': true,
          'data': DriverTrip.fromJson(data),
          'error': null,
          'responseBody': response.body,
          'statusCode': response.statusCode,
        };
      } else {
        log('❌ ERRO API: Falha ao iniciar viagem - Status: ${response.statusCode}', name: 'ApiService');
        log('❌ Resposta da API: ${response.body}', name: 'ApiService');
        log('❌ Verifique configurações da API e conexão com internet', name: 'ApiService');
        return {
          'success': false,
          'data': null,
          'error': 'Status ${response.statusCode}: ${response.body}',
          'responseBody': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      log('❌ ERRO CRÍTICO: Falha na requisição de início de viagem', name: 'ApiService', error: e, stackTrace: stackTrace);
      log('❌ Verifique conexão com internet e configurações da API', name: 'ApiService');
      return {
        'success': false,
        'data': null,
        'error': 'Erro de conexão: $e',
        'responseBody': null,
        'statusCode': null,
      };
    }
  }

  /// Finaliza uma viagem ativa
  static Future<Map<String, dynamic>> endTrip(String cpf, double latitude, double longitude, {double? distanceKm}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/drivers/end_trip/');
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
        return {
          'success': true,
          'data': DriverTrip.fromJson(data),
          'error': null,
          'responseBody': response.body,
          'statusCode': response.statusCode,
        };
      } else {
        log('❌ ERRO API: Falha ao finalizar viagem - Status: ${response.statusCode}', name: 'ApiService');
        log('❌ Resposta da API: ${response.body}', name: 'ApiService');
        log('❌ Verifique configurações da API e conexão com internet', name: 'ApiService');
        return {
          'success': false,
          'data': null,
          'error': 'Status ${response.statusCode}: ${response.body}',
          'responseBody': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      log('❌ ERRO CRÍTICO: Falha na requisição de fim de viagem', name: 'ApiService', error: e, stackTrace: stackTrace);
      log('❌ Verifique conexão com internet e configurações da API', name: 'ApiService');
      return {
        'success': false,
        'data': null,
        'error': 'Erro de conexão: $e',
        'responseBody': null,
        'statusCode': null,
      };
    }
  }

  /// Obtém dados completos do motorista
  static Future<Map<String, dynamic>?> getDriverData(String cpf) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/drivers/get_driver_data/?cpf=$cpf');
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
              log('❌ ERRO API: Falha ao obter dados do motorista - Status: ${response.statusCode}', name: 'ApiService');
              log('❌ Resposta da API: ${response.body}', name: 'ApiService');
              log('❌ Verifique configurações da API e conexão com internet', name: 'ApiService');
              return null;
            }
    } catch (e, stackTrace) {
      log('❌ ERRO CRÍTICO: Falha na requisição de dados do motorista', name: 'ApiService', error: e, stackTrace: stackTrace);
      log('❌ Verifique conexão com internet e configurações da API', name: 'ApiService');
      return null;
    }
  }

}
