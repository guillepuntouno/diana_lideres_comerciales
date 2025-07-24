import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';

class LiderComercialServicio {
  String get _baseUrl => '${AmbienteConfig.baseUrl}/lideres';
  
  // URLs comentadas para referencia:
  // DEV: http://localhost:60148/api/lideres
  // QA:  https://guillermosofnux-001-site1.stempurl.com/api/lideres

  Future<Map<String, dynamic>?> obtenerPorClave(String clave) async {
    try {
      final url = Uri.parse('$_baseUrl/$clave');

      print('Intentando conectar a: $url'); // Para debug

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers':
                  'Origin, Content-Type, X-Auth-Token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar al servidor');
            },
          );

      print('Status Code: ${response.statusCode}'); // Para debug
      print('Response Body: ${response.body}'); // Para debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('mensaje')) {
          // El backend regresó que no hay data
          return null;
        }

        return data;
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
        return null;
      } else {
        print('Error del servidor: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error en obtenerPorClave: $e');
      rethrow;
    }
  }
}
