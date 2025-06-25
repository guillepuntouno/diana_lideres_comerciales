import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/configuracion/ambiente_config.dart';

class ClientesServicio {
  //static const String _baseUrl = 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev';
  static String get _baseUrl => AmbienteConfig.baseUrl;

  /// Obtiene todos los clientes disponibles
  Future<List<Map<String, dynamic>>?> obtenerTodosLosClientes() async {
    try {
      // Obtener token de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token');

      if (token == null || token.isEmpty) {
        print('❌ No hay token de autenticación');
        return null;
      }

      print('🔍 Obteniendo todos los clientes...');

      final response = await http.get(
        Uri.parse('$_baseUrl/clientes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Clientes obtenidos: ${data.length} registros');

        // Retornar la lista de clientes
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map && data.containsKey('clientes')) {
          return (data['clientes'] as List).cast<Map<String, dynamic>>();
        }

        return [];
      } else {
        print('❌ Error al obtener clientes: ${response.statusCode}');
        print('   Respuesta: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      return null;
    }
  }

  /// Obtiene clientes por ruta específica
  Future<List<Map<String, dynamic>>?> obtenerClientesPorRuta({
    required String dia,
    required String lider,
    required String ruta,
  }) async {
    try {
      // Obtener token de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token');

      if (token == null || token.isEmpty) {
        print('❌ No hay token de autenticación');
        return null;
      }

      print(
        '🔍 Obteniendo clientes para ruta: $ruta, día: $dia, líder: $lider',
      );
      print(
        '🔑 Token JWT: ${token.substring(0, 20)}...',
      ); // Mostrar solo el inicio del token

      final uri = Uri.parse('$_baseUrl/clientes');

      print('📡 URL: $uri');
      print('📤 Enviando como POST con body');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'dia': dia, 'lider': lider, 'ruta': ruta}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Respuesta exitosa del servidor');

        // Retornar la lista de clientes
        if (data is List) {
          print('📊 Datos recibidos: ${data.length} clientes');
          if (data.isNotEmpty) {
            print('🔍 Ejemplo de cliente recibido:');
            print('   - Cliente_ID: ${data[0]['Cliente_ID']}');
            print('   - Negocio: ${data[0]['Negocio']}');
            print('   - Clasificación: ${data[0]['Clasificación']}');
            print('   - Tipovendedor: ${data[0]['Tipovendedor']}');
            print('   - Exhibidor: ${data[0]['Exhibidor']}');
          }
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map && data.containsKey('clientes')) {
          final clientesList = (data['clientes'] as List);
          print(
            '📊 Datos recibidos (en objeto): ${clientesList.length} clientes',
          );
          return clientesList.cast<Map<String, dynamic>>();
        }

        print('⚠️ Formato de respuesta no reconocido');
        return [];
      } else {
        print('❌ Error al obtener clientes: ${response.statusCode}');
        print('   Respuesta: ${response.body}');
        print('   Headers enviados: ${response.request?.headers}');

        // Si es error 401, verificar el token
        if (response.statusCode == 401) {
          print('⚠️ Error de autenticación. Verificando token...');
          print('   Token guardado: ${token.substring(0, 20)}...');
        }

        return null;
      }
    } catch (e) {
      print('❌ Error al obtener clientes por ruta: $e');
      return null;
    }
  }

  /// Convierte los datos del cliente del formato AWS al formato esperado
  static Negocio convertirClienteANegocio(Map<String, dynamic> clienteData) {
    // Mapeo actualizado para la nueva estructura de AWS
    return Negocio(
      clave:
          clienteData['Cliente_ID'] ??
          clienteData['clave'] ??
          clienteData['id'] ??
          '',
      nombre:
          clienteData['Negocio'] ??
          clienteData['nombre'] ??
          clienteData['razonSocial'] ??
          '',
      canal:
          clienteData['Tipovendedor'] ??
          clienteData['canal'] ??
          clienteData['tipoNegocio'] ??
          '',
      clasificacion:
          clienteData['Clasificación'] ??
          clienteData['clasificacion'] ??
          clienteData['segmento'] ??
          '',
      exhibidor: clienteData['Exhibidor'] ?? clienteData['exhibidor'] ?? 'NO',
    );
  }
}
