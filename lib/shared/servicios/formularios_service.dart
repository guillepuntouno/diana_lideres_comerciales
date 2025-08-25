import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';
import 'package:diana_lc_front/shared/modelos/formulario_evaluacion_dto.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/formularios_filter_service.dart';

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

  /// Filtrar formularios de evaluación de desempeño por canal y país
  /// Filtros del lado del cliente:
  /// - tipo = "evaluacion_desempeño" (EXCLUYE programa_excelencia)
  /// - canal = "detalle" o "mayoreo" 
  /// - país = país mapeado (SV → salvador)
  /// - activo = true
  /// - Selecciona el más reciente si hay múltiples coincidencias
  static Future<FormularioEvaluacionDTO?> obtenerFormularioParaCanal(
    String canal, {
    String? paisUI,
  }) async {
    try {
      final formularios = await obtenerFormularios();
      
      // Usar país por defecto si no se proporciona
      final pais = paisUI ?? 'SV'; // Default a El Salvador
      
      print('🔍 === BÚSQUEDA DE FORMULARIO EVALUACIÓN DESEMPEÑO ===');
      print('📊 Total formularios obtenidos del WS: ${formularios.length}');
      print('🎯 Buscando para: Canal=$canal, País=$pais');
      
      // Usar el servicio de filtrado robusto
      final formulariosFiltrados = FormulariosFilterService.filtrarFormulariosEvaluacion(
        formularios: formularios,
        canal: canal,
        paisUI: pais,
      );
      
      if (formulariosFiltrados.isEmpty) {
        print('❌ No hay formularios activos de Evaluación de Desempeño para el canal $canal en $pais');
        return null;
      }
      
      final formularioSeleccionado = formulariosFiltrados.first;
      print('✅ === FORMULARIO SELECCIONADO ===');
      print('📋 Nombre: ${formularioSeleccionado.nombre}');
      print('🆔 ID: ${formularioSeleccionado.id}');
      print('🏷️ Tipo: ${formularioSeleccionado.tipo}');
      print('📅 Fecha: ${formularioSeleccionado.fechaActualizacion ?? formularioSeleccionado.fechaCreacion}');
      
      return formularioSeleccionado;
    } catch (e) {
      print('❌ Error en obtenerFormularioParaCanal: $e');
      rethrow;
    }
  }
}