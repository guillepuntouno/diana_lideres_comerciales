import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'sesion_servicio.dart';

class RutasServicio {
  String get _baseUrl => AmbienteConfig.baseUrl;

  Future<List<Ruta>> obtenerRutasPorDia(
    String codigoLider,
    String codigoDiaVisita,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/rutas/$codigoLider/$codigoDiaVisita');

      print(
        '🔍 Obteniendo rutas para líder: $codigoLider, día: $codigoDiaVisita',
      );
      print('📡 URL: $url');
      debugPrint('URL de rutas: $url');

      // Obtener token de autenticación
      final token = await SesionServicio.obtenerToken();

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(url, headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar al servidor');
            },
          );

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Rutas obtenidas del API: ${data.length}');

        // Crear un mapa para agrupar por combinación única de RUTA + CODIGO_ASESOR
        final Map<String, Map<String, dynamic>> rutasUnicas = {};
        
        for (var item in data) {
          final rutaCodigo = item['RUTA'] ?? '';
          final codigoAsesor = item['CODIGO_ASESOR'] ?? '';
          final nombreAsesor = item['NOMBRE_ASESOR'] ?? '';
          final diaVisitaCod = item['DIA_VISITA_COD'] ?? '';
          
          // Crear una clave única combinando ruta y código de asesor
          final claveUnica = '${rutaCodigo}_${codigoAsesor}';
          
          if (rutaCodigo.isNotEmpty && !rutasUnicas.containsKey(claveUnica)) {
            rutasUnicas[claveUnica] = {
              'RUTA': rutaCodigo,
              'NOMBRE_ASESOR': nombreAsesor,
              'CODIGO_ASESOR': codigoAsesor,
              'DIA_VISITA_COD': diaVisitaCod,
            };
          }
        }

        print('📊 Rutas únicas procesadas: ${rutasUnicas.length}');
        
        // Log detallado de las rutas
        rutasUnicas.forEach((key, value) {
          print('  - Ruta: ${value['RUTA']} | Asesor: ${value['NOMBRE_ASESOR']} (${value['CODIGO_ASESOR']}) | DIA_VISITA_COD: ${value['DIA_VISITA_COD']}');
        });

        // Convertir a lista de objetos Ruta
        return rutasUnicas.values.map((rutaData) {
          return Ruta(
            nombre: rutaData['RUTA'],
            asesor: rutaData['NOMBRE_ASESOR'],
            negocios: [], // Los negocios se cargarán después si es necesario
            diaVisitaCod: rutaData['DIA_VISITA_COD'] ?? '',
          );
        }).toList();
      } else if (response.statusCode == 404) {
        print('⚠️ No se encontraron rutas para el día especificado');
        return [];
      } else if (response.statusCode == 400) {
        print('❌ Error 400: Formato de fecha inválido o parámetros incorrectos');
        throw Exception('El formato de fecha debe ser DD-MM-YYYY');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener rutas: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('No se pudo conectar al servidor. Verifique su conexión a internet.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('La solicitud tardó demasiado. Intente nuevamente.');
      }
      rethrow;
    }
  }

  // Retorna tanto la lista de Negocio como el JSON original
  Future<Map<String, dynamic>> obtenerClientesPorRutaConJson(
    String codigoLider,
    String codigoDiaVisita,
    String ruta,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rutas/$codigoLider/$codigoDiaVisita/$ruta',
      );

      print(
        '🔍 Obteniendo clientes para líder: $codigoLider, día: $codigoDiaVisita, ruta: $ruta',
      );
      print('📡 URL construida: $url');
      print('✅ Formato esperado: /rutas/{liderId}/{codigoDiaVisita}/{rutaId}');
      debugPrint('URL final de clientes: $url');

      // Obtener token de autenticación
      final token = await SesionServicio.obtenerToken();

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(url, headers: headers)
          .timeout(
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
        final negocios =
            data.map((clienteData) {
              return Negocio(
                clave: clienteData['CODIGO_CLIENTE'] ?? '',
                nombre: clienteData['NOMBRE_CLIENTE'] ?? '',
                canal: clienteData['CANAL_VENTA'] ?? '',
                clasificacion: clienteData['CLASIFICACION_CLIENTE'] ?? '',
                exhibidor: '', // No viene en el JSON, usando valor por defecto
                direccion:
                    clienteData['DIRECCION CLIENTE'] ?? '', // Campo adicional
                subcanal:
                    clienteData['SUBCANAL_VENTA'] ?? '', // Campo adicional
              );
            }).toList();

        // Retornar tanto los negocios como el JSON original
        return {
          'negocios': negocios,
          'jsonData': data.cast<Map<String, dynamic>>(),
        };
      } else if (response.statusCode == 404) {
        print('⚠️ No se encontraron clientes para la ruta especificada');
        return {'negocios': <Negocio>[], 'jsonData': <Map<String, dynamic>>[]};
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      rethrow;
    }
  }

  // Método original mantenido para compatibilidad
  Future<List<Negocio>> obtenerClientesPorRuta(
    String codigoLider,
    String codigoDiaVisita,
    String ruta,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/rutas/$codigoLider/$codigoDiaVisita/$ruta',
      );

      print(
        '🔍 Obteniendo clientes para líder: $codigoLider, día: $codigoDiaVisita, ruta: $ruta',
      );
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

      final response = await http
          .get(url, headers: headers)
          .timeout(
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
            direccion:
                clienteData['DIRECCION CLIENTE'] ?? '', // Campo adicional
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
