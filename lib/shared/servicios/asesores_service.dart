import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';
import 'package:diana_lc_front/shared/modelos/asesor_dto.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';

class AsesoresService {
  static String get baseUrl => AmbienteConfig.baseUrl;
  
  static Future<Map<String, String>> get headers async {
    final token = await SesionServicio.obtenerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener asesores por líder y país
  /// GET /api/asesores/{codigoLider}?pais={PAIS}
  static Future<List<AsesorDTO>> obtenerAsesoresPorLider({
    required String codigoLider,
    required String pais,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/asesores/$codigoLider?pais=$pais');
      
      print('🔍 Obteniendo asesores para líder: $codigoLider, país: $pais');
      print('📡 URL: $url');
      
      final response = await http.get(
        url,
        headers: await headers,
      );
      
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Verificar si la respuesta tiene la estructura esperada
        if (responseData['success'] == true && responseData.containsKey('asesores')) {
          final List<dynamic> asesoresList = responseData['asesores'];
          return asesoresList.map((json) => AsesorDTO.fromJson(json)).toList();
        } else {
          print('⚠️ Respuesta inesperada del servidor');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('⚠️ No se encontraron asesores para el líder $codigoLider');
        return [];
      } else {
        throw Exception(
          'Error al obtener asesores: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en obtenerAsesoresPorLider: $e');
      rethrow;
    }
  }

  /// Obtener todos los asesores (si se necesita en el futuro)
  /// GET /api/asesores
  static Future<List<AsesorDTO>> obtenerTodosLosAsesores() async {
    try {
      final url = Uri.parse('$baseUrl/asesores');
      
      print('🔍 Obteniendo todos los asesores');
      
      final response = await http.get(
        url,
        headers: await headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AsesorDTO.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener asesores: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en obtenerTodosLosAsesores: $e');
      rethrow;
    }
  }
}