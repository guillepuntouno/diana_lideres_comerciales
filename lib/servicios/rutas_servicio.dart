import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configuracion/ambiente_config.dart';
import '../modelos/lider_comercial_modelo.dart';
import 'sesion_servicio.dart';

class RutasServicio {
  String get _baseUrl => AmbienteConfig.baseUrl;

  Future<List<Ruta>> obtenerRutasPorDia(String codigoLider, String codigoDiaVisita) async {
    try {
      final url = Uri.parse('$_baseUrl/rutas/$codigoLider/$codigoDiaVisita');
      
      print('🔍 Obteniendo rutas para líder: $codigoLider, día: $codigoDiaVisita');
      print('📡 URL: $url');

      // Obtener token de autenticación
      final token = await SesionServicio.obtenerToken();
      
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: No se pudo conectar al servidor');
        },
      );

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Rutas obtenidas: ${data.length}');
        
        // Agrupar por ruta para obtener rutas únicas
        final Map<String, Map<String, dynamic>> rutasUnicas = {};
        
        for (var item in data) {
          final rutaCodigo = item['RUTA'] ?? '';
          if (rutaCodigo.isNotEmpty && !rutasUnicas.containsKey(rutaCodigo)) {
            rutasUnicas[rutaCodigo] = {
              'RUTA': rutaCodigo,
              'NOMBRE_ASESOR': item['NOMBRE_ASESOR'] ?? '',
              'CODIGO_ASESOR': item['CODIGO_ASESOR'] ?? '',
            };
          }
        }
        
        // Convertir a lista de objetos Ruta
        return rutasUnicas.values.map((rutaData) {
          return Ruta(
            nombre: rutaData['RUTA'],
            asesor: rutaData['NOMBRE_ASESOR'],
            negocios: [], // Los negocios se cargarán después si es necesario
          );
        }).toList();
        
      } else if (response.statusCode == 404) {
        print('⚠️ No se encontraron rutas para el día especificado');
        return [];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener rutas: $e');
      rethrow;
    }
  }

  Future<List<Negocio>> obtenerClientesPorRuta(String codigoLider, String codigoDiaVisita, String ruta) async {
    try {
      final url = Uri.parse('$_baseUrl/rutas/$codigoLider/$codigoDiaVisita/$ruta');
      
      print('🔍 Obteniendo clientes para líder: $codigoLider, día: $codigoDiaVisita, ruta: $ruta');
      print('📡 URL: $url');

      // Obtener token de autenticación
      final token = await SesionServicio.obtenerToken();
      
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: No se pudo conectar al servidor');
        },
      );

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Clientes obtenidos: ${data.length}');
        
        // Convertir a lista de objetos Negocio
        return data.map((clienteData) {
          return Negocio(
            clave: clienteData['CODIGO_CLIENTE'] ?? '',
            nombre: clienteData['NOMBRE_CLIENTE'] ?? '',
            canal: clienteData['CANAL_VENTA'] ?? '',
            clasificacion: clienteData['CLASIFICACION_CLIENTE'] ?? '',
            exhibidor: '', // No viene en el JSON, usando valor por defecto
            direccion: clienteData['DIRECCION CLIENTE'] ?? '', // Campo adicional
            subcanal: clienteData['SUBCANAL_VENTA'] ?? '', // Campo adicional
          );
        }).toList();
        
      } else if (response.statusCode == 404) {
        print('⚠️ No se encontraron clientes para la ruta especificada');
        return [];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      rethrow;
    }
  }
}