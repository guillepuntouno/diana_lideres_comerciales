import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';

class FormulariosApiService {
  static final FormulariosApiService _instance = FormulariosApiService._internal();
  factory FormulariosApiService() => _instance;
  FormulariosApiService._internal();

  static String get _baseUrl => '${AmbienteConfig.baseUrl}/planes_formularios';

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener todos los formularios
  /// GET /planes_formularios
  Future<List<Map<String, dynamic>>> obtenerFormularios() async {
    try {
      final headers = await _headers;
      final uri = Uri.parse(_baseUrl);
      
      print('🔍 Obteniendo formularios de: $uri');
      print('🔑 Headers: $headers');
      
      final response = await http.get(uri, headers: headers);
      
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Mapear la estructura del servidor a la estructura esperada
          return data.map((formulario) => _mapearFormularioDesdeServidor(formulario)).toList();
        } else if (data is Map && data['formularios'] is List) {
          // Por si el API devuelve un objeto con la lista dentro
          return (data['formularios'] as List)
              .map((formulario) => _mapearFormularioDesdeServidor(formulario))
              .toList();
        }
        return [];
      } else {
        throw Exception('Error al obtener formularios: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en obtenerFormularios: $e');
      rethrow;
    }
  }

  /// Obtener un formulario específico por ID
  /// GET /planes_formularios/{id}
  Future<Map<String, dynamic>?> obtenerFormularioPorId(String id) async {
    try {
      final headers = await _headers;
      final uri = Uri.parse('$_baseUrl/$id');
      
      print('🔍 Obteniendo formulario: $id');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final formulario = jsonDecode(response.body);
        return _mapearFormularioDesdeServidor(formulario);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener formulario: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerFormularioPorId: $e');
      rethrow;
    }
  }

  /// Crear nuevo formulario
  /// POST /planes_formularios
  Future<Map<String, dynamic>> crearFormulario(Map<String, dynamic> formulario) async {
    try {
      final headers = await _headers;
      
      
      print('📝 Creando formulario: ${formulario['nombre']}');
      print('📦 Body: ${jsonEncode(formulario)}');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(formulario),
      );
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear formulario: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en crearFormulario: $e');
      rethrow;
    }
  }

  /// Actualizar formulario existente
  /// PUT /planes_formularios/{id}
  Future<Map<String, dynamic>> actualizarFormulario(String id, Map<String, dynamic> formulario) async {
    try {
      final headers = await _headers;
      
      print('📝 Actualizando formulario: $id');
      print('📦 Body: ${jsonEncode(formulario)}');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
        body: jsonEncode(formulario),
      );
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al actualizar formulario: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en actualizarFormulario: $e');
      rethrow;
    }
  }

  /// Eliminar formulario (soft delete)
  /// DELETE /planes_formularios/{id}
  Future<bool> eliminarFormulario(String id) async {
    try {
      final headers = await _headers;
      final url = '$_baseUrl/$id';
      
      print('🗑️ Eliminando formulario: $id');
      print('🔗 URL: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );
      
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Error al eliminar formulario: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en eliminarFormulario: $e');
      rethrow;
    }
  }

  /// Activar/Desactivar formulario
  /// PUT /planes_formularios/{id}
  Future<Map<String, dynamic>> cambiarEstadoFormulario(String id, bool activa) async {
    try {
      final headers = await _headers;
      
      print('🔄 Cambiando estado formulario $id a: ${activa ? "activo" : "inactivo"}');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
        body: jsonEncode({'activa': activa}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cambiar estado: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en cambiarEstadoFormulario: $e');
      rethrow;
    }
  }

  /// Duplicar formulario para crear nueva versión
  /// Usa POST con los datos del formulario original modificados
  Future<Map<String, dynamic>> duplicarFormulario(Map<String, dynamic> formularioOriginal, String nuevaVersion) async {
    try {
      // Crear copia del formulario
      final nuevoFormulario = Map<String, dynamic>.from(formularioOriginal);
      
      // Modificar campos para la nueva versión
      nuevoFormulario['id'] = 'pf-${DateTime.now().millisecondsSinceEpoch}';
      nuevoFormulario['version'] = nuevaVersion;
      nuevoFormulario['activa'] = false; // Nueva versión empieza inactiva
      nuevoFormulario['capturado'] = false;
      nuevoFormulario['fechaCreacion'] = DateTime.now().toIso8601String();
      nuevoFormulario['fechaActualizacion'] = DateTime.now().toIso8601String();
      
      // Mantener el nombre con indicador de versión
      nuevoFormulario['nombre'] = '${formularioOriginal['nombre']} - $nuevaVersion';
      
      return await crearFormulario(nuevoFormulario);
    } catch (e) {
      print('❌ Error en duplicarFormulario: $e');
      rethrow;
    }
  }

  /// Mapear formulario desde la estructura del servidor a la estructura esperada
  Map<String, dynamic> _mapearFormularioDesdeServidor(Map<String, dynamic> formularioServidor) {
    // Si tiene la estructura nueva (con preguntas), devolverlo tal cual
    if (formularioServidor.containsKey('preguntas')) {
      return formularioServidor;
    }
    
    // Si tiene la estructura antigua (con questions), mapear
    final formulario = Map<String, dynamic>.from(formularioServidor);
    
    // Mapear questions a preguntas
    if (formulario.containsKey('questions')) {
      formulario['preguntas'] = (formulario['questions'] as List).map((q) {
        // Extraer ponderación/puntuación de las opciones si existe
        double ponderacion = 0;
        if (q['opciones'] != null && (q['opciones'] as List).isNotEmpty) {
          // Tomar la puntuación máxima de las opciones como ponderación
          for (var opcion in q['opciones']) {
            final puntuacion = (opcion['puntuacion'] ?? 0).toDouble();
            if (puntuacion > ponderacion) {
              ponderacion = puntuacion;
            }
          }
        }
        
        return {
          'name': q['name'],
          'etiqueta': q['etiqueta'] ?? _generarEtiquetaDesdeNombre(q['name'] ?? ''),
          'section': q['section'] ?? 'General',
          'orden': q['orden'] ?? 1,
          'tipoEntrada': q['tipoEntrada'] ?? 'text',
          'opciones': q['opciones'] ?? [],
          'obligatorio': q['obligatorio'] ?? false,
          'ponderacion': q['ponderacion'] ?? ponderacion,
          'placeholder': q['placeholder'] ?? '',
          'validacion': q['validacion'] ?? '',
        };
      }).toList();
      formulario.remove('questions');
    }
    
    // Mapear name a nombre si existe
    if (formulario.containsKey('name') && !formulario.containsKey('nombre')) {
      formulario['nombre'] = formulario['name'];
    }
    
    // Mapear tipo si no existe o está en formato diferente
    if (!formulario.containsKey('tipo') || formulario['tipo'] == 'Evaluación') {
      formulario['tipo'] = 'evaluacion';
    }
    
    // Asegurar que tenga los campos requeridos
    formulario['version'] = formulario['version'] ?? 'v1.0';
    formulario['descripcion'] = formulario['descripcion'] ?? '';
    formulario['activa'] = formulario['activa'] ?? true;
    
    return formulario;
  }
  
  /// Generar una etiqueta legible desde el nombre del campo
  String _generarEtiquetaDesdeNombre(String nombre) {
    if (nombre.isEmpty) return '';
    
    // Reemplazar guiones bajos por espacios
    String etiqueta = nombre.replaceAll('_', ' ');
    
    // Capitalizar primera letra
    etiqueta = etiqueta[0].toUpperCase() + etiqueta.substring(1);
    
    // Casos especiales
    final Map<String, String> casos = {
      'pais': 'País',
      'cd': 'Centro de Distribución',
      'canal clientevend': 'Canal Cliente/Vendedor',
      'inactiva': '¿Está inactiva?',
      'observaciones': 'Observaciones',
    };
    
    return casos[nombre.toLowerCase()] ?? etiqueta;
  }

  /// Mapear formulario desde la estructura local a la estructura del servidor
  Map<String, dynamic> _mapearFormularioParaServidor(Map<String, dynamic> formularioLocal) {
    final formulario = Map<String, dynamic>.from(formularioLocal);
    
    // Si el servidor espera questions en lugar de preguntas
    if (formulario.containsKey('preguntas')) {
      formulario['questions'] = formulario['preguntas'];
      // No remover preguntas por si el servidor también lo acepta
    }
    
    return formulario;
  }
}