import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';
import 'package:diana_lc_front/shared/modelos/formulario_evaluacion_dto.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';

class FormulariosService {
  static String get baseUrl => AmbienteConfig.baseUrl;
  
  static Future<Map<String, String>> get headers async {
    final token = await SesionServicio.obtenerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener formularios de evaluación de desempeño
  /// GET /api/planes_formularios
  static Future<List<FormularioEvaluacionDTO>> obtenerFormularios() async {
    try {
      final url = Uri.parse('$baseUrl/planes_formularios');
      
      print('🔍 Obteniendo formularios de evaluación');
      print('📡 URL: $url');
      
      final response = await http.get(
        url,
        headers: await headers,
      );
      
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FormularioEvaluacionDTO.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('⚠️ No se encontraron formularios');
        return [];
      } else {
        throw Exception(
          'Error al obtener formularios: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error en obtenerFormularios: $e');
      rethrow;
    }
  }

  /// Filtrar formularios de evaluación de desempeño por canal
  /// Filtros del lado del cliente:
  /// - tipo = "evaluacion_desempeño"
  /// - canal = "detalle" o "mayoreo"
  /// - activo = true
  /// - Selecciona el más reciente si hay múltiples coincidencias
  static Future<FormularioEvaluacionDTO?> obtenerFormularioParaCanal(String canal) async {
    try {
      final formularios = await obtenerFormularios();
      
      print('🔍 Filtrando formularios para canal: $canal');
      print('📊 Total formularios obtenidos: ${formularios.length}');
      
      // Filtrar por tipo, canal y estado activo
      final formulariosFiltrados = formularios.where((formulario) {
        final esEvaluacionDesempeno = formulario.tipo.toLowerCase() == 'evaluacion_desempeño' || 
                                     formulario.tipo.toLowerCase() == 'evaluacion_desempeno' ||
                                     formulario.tipo.toLowerCase() == 'programa_excelencia';
        final aplicaParaCanal = formulario.aplicaParaCanal(canal);
        final estaActivo = formulario.activo;
        
        print('📋 Formulario: ${formulario.nombre}');
        print('  - Tipo: ${formulario.tipo} (¿Es evaluación?: $esEvaluacionDesempeno)');
        print('  - Canales: ${formulario.canales} (¿Aplica para $canal?: $aplicaParaCanal)');
        print('  - Activo: $estaActivo');
        
        return esEvaluacionDesempeno && aplicaParaCanal && estaActivo;
      }).toList();
      
      print('✅ Formularios filtrados: ${formulariosFiltrados.length}');
      
      if (formulariosFiltrados.isEmpty) {
        print('⚠️ No se encontró formulario para el canal: $canal');
        return null;
      }
      
      // Ordenar por fecha de actualización/creación descendente y tomar el más reciente
      formulariosFiltrados.sort((a, b) {
        final fechaA = a.fechaActualizacion ?? a.fechaCreacion ?? DateTime(1970);
        final fechaB = b.fechaActualizacion ?? b.fechaCreacion ?? DateTime(1970);
        return fechaB.compareTo(fechaA);
      });
      
      final formularioSeleccionado = formulariosFiltrados.first;
      print('🎯 Formulario seleccionado: ${formularioSeleccionado.nombre}');
      print('📅 Fecha: ${formularioSeleccionado.fechaActualizacion ?? formularioSeleccionado.fechaCreacion}');
      
      return formularioSeleccionado;
    } catch (e) {
      print('❌ Error en obtenerFormularioParaCanal: $e');
      rethrow;
    }
  }
}