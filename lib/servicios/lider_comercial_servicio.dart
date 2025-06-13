import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LiderComercialServicio {
  final String _baseUrl =
      kIsWeb
          ? 'http://localhost:60148/api/lideres' // Para web
          : 'http://10.0.2.2:60148/api/lideres'; // Para Android emulator

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
            const Duration(seconds: 10),
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
