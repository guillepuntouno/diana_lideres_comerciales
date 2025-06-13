// lib/servicios/visitas_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class VisitasApiService {
  static const String baseUrl = 'http://localhost:60148/api';

  // Headers comunes para las peticiones
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Crear una nueva visita con check-in inicial
  /// POST /api/visitas
  static Future<Map<String, dynamic>> crearVisita({
    required String claveVisita,
    required String liderClave,
    required String clienteId,
    required String clienteNombre,
    String? planId,
    String? dia,
    Map<String, dynamic>? checkIn,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/visitas');

      final body = {
        'claveVisita': claveVisita,
        'liderClave': liderClave,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'planId': planId,
        'dia': dia,
        'checkIn':
            checkIn ??
            {
              'timestamp': DateTime.now().toIso8601String(),
              'comentarios': '',
              'ubicacion': {
                'latitud': 0.0,
                'longitud': 0.0,
                'precision': 0.0,
                'direccion': '',
              },
            },
      };

      print('🚀 Creando visita: $claveVisita');
      print('📡 URL: $url');
      print('📦 Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Error al crear visita: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en crearVisita: $e');
      rethrow;
    }
  }

  /// Obtener una visita específica por clave
  /// GET /api/visitas/{claveVisita}
  static Future<Map<String, dynamic>?> obtenerVisita(String claveVisita) async {
    try {
      final url = Uri.parse('$baseUrl/visitas/$claveVisita');

      print('🔍 Obteniendo visita: $claveVisita');

      final response = await http.get(url, headers: headers);

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('mensaje')) {
          // No existe la visita
          return null;
        }
        return data;
      } else {
        throw Exception('Error al obtener visita: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerVisita: $e');
      return null;
    }
  }

  /// Actualizar visita con formularios dinámicos
  /// PUT /api/visitas/{claveVisita}/formularios
  static Future<Map<String, dynamic>> actualizarFormularios({
    required String claveVisita,
    required Map<String, dynamic> formularios,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/visitas/$claveVisita/formularios');

      final body = {'formularios': formularios};

      print('💾 Actualizando formularios para visita: $claveVisita');
      print('📦 Formularios: ${jsonEncode(formularios)}');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Error al actualizar formularios: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en actualizarFormularios: $e');
      rethrow;
    }
  }

  /// Finalizar visita con check-out
  /// PUT /api/visitas/{claveVisita}/checkout
  static Future<Map<String, dynamic>> finalizarVisita({
    required String claveVisita,
    String? comentarios,
    Map<String, dynamic>? ubicacion,
    int? duracionMinutos,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/visitas/$claveVisita/checkout');

      final body = {
        'timestamp': DateTime.now().toIso8601String(),
        'comentarios': comentarios ?? '',
        'ubicacion':
            ubicacion ??
            {
              'latitud': 0.0,
              'longitud': 0.0,
              'precision': 0.0,
              'direccion': '',
            },
        'duracionMinutos': duracionMinutos ?? 0,
      };

      print('🏁 Finalizando visita: $claveVisita');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Error al finalizar visita: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en finalizarVisita: $e');
      rethrow;
    }
  }

  /// Cancelar una visita
  /// PUT /api/visitas/{claveVisita}/cancelar
  static Future<Map<String, dynamic>> cancelarVisita({
    required String claveVisita,
    required String motivo,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/visitas/$claveVisita/cancelar');

      final body = {'motivo': motivo};

      print('❌ Cancelando visita: $claveVisita');
      print('📝 Motivo: $motivo');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cancelar visita: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en cancelarVisita: $e');
      rethrow;
    }
  }
}
