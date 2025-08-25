import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';

class ProgramaExcelenciaLocalRepository {
  static final ProgramaExcelenciaLocalRepository _instance = 
      ProgramaExcelenciaLocalRepository._internal();
  
  factory ProgramaExcelenciaLocalRepository() => _instance;
  
  ProgramaExcelenciaLocalRepository._internal();
  
  final HiveService _hiveService = HiveService();
  
  // Obtener la caja de programa de excelencia
  Box<ResultadoExcelenciaHive> get _box => 
      _hiveService.resultadosExcelenciaBox;
  
  // Obtener caja de media para capturas
  Box<Map> get _mediaBox {
    const String boxName = 'box_programa_excelencia_media';
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('La caja de media no está abierta');
    }
    return Hive.box<Map>(boxName);
  }
  
  // Abrir caja de media si no existe
  Future<void> initializeMediaBox() async {
    const String boxName = 'box_programa_excelencia_media';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
  }
  
  // Guardar evaluación
  Future<void> guardarEvaluacion(ResultadoExcelenciaHive evaluacion) async {
    try {
      print('🔄 Intentando guardar evaluación: ${evaluacion.id}');
      print('📦 Caja abierta: ${_box.isOpen}');
      print('📊 Items en caja antes: ${_box.length}');
      
      await _box.put(evaluacion.id, evaluacion);
      
      print('📊 Items en caja después: ${_box.length}');
      print('✅ Evaluación guardada: ${evaluacion.id}');
      print('🎯 Metadatos guardados: ${evaluacion.metadatos}');
    } catch (e) {
      print('❌ Error guardando evaluación: $e');
      rethrow;
    }
  }
  
  // Obtener todas las evaluaciones
  List<ResultadoExcelenciaHive> obtenerTodasEvaluaciones() {
    try {
      print('🔍 Obteniendo todas las evaluaciones...');
      print('📦 Caja abierta: ${_box.isOpen}');
      print('📊 Items en caja: ${_box.length}');
      
      final evaluaciones = _box.values.toList()
        ..sort((a, b) => b.fechaCaptura.compareTo(a.fechaCaptura));
      
      print('📋 Evaluaciones encontradas: ${evaluaciones.length}');
      for (var eval in evaluaciones) {
        print('  - ID: ${eval.id}, Fecha: ${eval.fechaCaptura}, Líder: ${eval.liderClave}');
      }
      
      return evaluaciones;
    } catch (e) {
      print('❌ Error obteniendo evaluaciones: $e');
      return [];
    }
  }
  
  // Obtener evaluaciones filtradas
  List<ResultadoExcelenciaHive> obtenerEvaluacionesFiltradas({
    String? canal,
    String? asesorCodigo,
    String? liderClave,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    try {
      print('🔍 Obteniendo evaluaciones filtradas...');
      print('📊 Total items en caja: ${_box.length}');
      print('🎯 Filtros aplicados:');
      print('  - Canal: $canal');
      print('  - Asesor: $asesorCodigo');
      print('  - Líder: $liderClave');
      
      var evaluaciones = _box.values.where((evaluacion) {
        bool cumpleFiltros = true;
        
        // Filtrar por líder
        if (liderClave != null && liderClave.isNotEmpty) {
          cumpleFiltros = cumpleFiltros && evaluacion.liderClave == liderClave;
        }
        
        // Filtrar por canal (desde metadatos)
        if (canal != null && canal.isNotEmpty) {
          final metadatos = evaluacion.metadatos;
          if (metadatos != null && metadatos['canal'] != null) {
            cumpleFiltros = cumpleFiltros && metadatos['canal'] == canal;
          }
        }
        
        // Filtrar por asesor (desde metadatos)
        if (asesorCodigo != null && asesorCodigo.isNotEmpty) {
          final metadatos = evaluacion.metadatos;
          if (metadatos != null && metadatos['asesorCodigo'] != null) {
            cumpleFiltros = cumpleFiltros && metadatos['asesorCodigo'] == asesorCodigo;
          }
        }
        
        // Filtrar por rango de fechas
        if (fechaInicio != null) {
          cumpleFiltros = cumpleFiltros && 
              evaluacion.fechaCaptura.isAfter(fechaInicio.subtract(const Duration(days: 1)));
        }
        
        if (fechaFin != null) {
          cumpleFiltros = cumpleFiltros && 
              evaluacion.fechaCaptura.isBefore(fechaFin.add(const Duration(days: 1)));
        }
        
        return cumpleFiltros;
      }).toList();
      
      // Ordenar por fecha de captura (más reciente primero)
      evaluaciones.sort((a, b) => b.fechaCaptura.compareTo(a.fechaCaptura));
      
      print('📋 Evaluaciones filtradas encontradas: ${evaluaciones.length}');
      for (var eval in evaluaciones) {
        print('  - ID: ${eval.id}, Canal: ${eval.metadatos?['canal']}, Asesor: ${eval.metadatos?['asesorCodigo']}, Líder: ${eval.liderClave}');
      }
      
      return evaluaciones;
    } catch (e) {
      print('❌ Error obteniendo evaluaciones filtradas: $e');
      return [];
    }
  }
  
  // Obtener evaluación por ID
  ResultadoExcelenciaHive? obtenerEvaluacionPorId(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      print('❌ Error obteniendo evaluación por ID: $e');
      return null;
    }
  }
  
  // Actualizar evaluación
  Future<void> actualizarEvaluacion(ResultadoExcelenciaHive evaluacion) async {
    try {
      evaluacion.lastUpdated = DateTime.now();
      await evaluacion.save();
      print('✅ Evaluación actualizada: ${evaluacion.id}');
    } catch (e) {
      print('❌ Error actualizando evaluación: $e');
      rethrow;
    }
  }
  
  // Eliminar evaluación
  Future<void> eliminarEvaluacion(String id) async {
    try {
      await _box.delete(id);
      print('✅ Evaluación eliminada: $id');
    } catch (e) {
      print('❌ Error eliminando evaluación: $e');
      rethrow;
    }
  }
  
  // Obtener evaluaciones pendientes de sincronización
  List<ResultadoExcelenciaHive> obtenerEvaluacionesPendientesSync() {
    try {
      return _box.values
          .where((evaluacion) => evaluacion.syncStatus == 'pending')
          .toList();
    } catch (e) {
      print('❌ Error obteniendo evaluaciones pendientes: $e');
      return [];
    }
  }
  
  // Marcar evaluación como sincronizada
  Future<void> marcarComoSincronizada(String id) async {
    try {
      final evaluacion = _box.get(id);
      if (evaluacion != null) {
        evaluacion.syncStatus = 'synced';
        evaluacion.lastUpdated = DateTime.now();
        await evaluacion.save();
        print('✅ Evaluación marcada como sincronizada: $id');
      }
    } catch (e) {
      print('❌ Error marcando evaluación como sincronizada: $e');
      rethrow;
    }
  }
  
  // Marcar evaluación como fallida
  Future<void> marcarComoFallida(String id, String? error) async {
    try {
      final evaluacion = _box.get(id);
      if (evaluacion != null) {
        evaluacion.syncStatus = 'failed';
        evaluacion.lastUpdated = DateTime.now();
        if (error != null) {
          evaluacion.metadatos ??= {};
          evaluacion.metadatos!['syncError'] = error;
        }
        await evaluacion.save();
        print('❌ Evaluación marcada como fallida: $id');
      }
    } catch (e) {
      print('❌ Error marcando evaluación como fallida: $e');
      rethrow;
    }
  }
  
  // Guardar media/capturas
  Future<void> guardarMedia(String evaluacionId, List<Map<String, dynamic>> mediaItems) async {
    try {
      await initializeMediaBox();
      await _mediaBox.put(evaluacionId, {
        'evaluacionId': evaluacionId,
        'items': mediaItems,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('✅ Media guardada para evaluación: $evaluacionId');
    } catch (e) {
      print('❌ Error guardando media: $e');
      rethrow;
    }
  }
  
  // Obtener media/capturas de una evaluación
  List<Map<String, dynamic>> obtenerMedia(String evaluacionId) {
    try {
      final mediaData = _mediaBox.get(evaluacionId);
      if (mediaData != null && mediaData['items'] != null) {
        return List<Map<String, dynamic>>.from(mediaData['items']);
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo media: $e');
      return [];
    }
  }
  
  // Eliminar media de una evaluación
  Future<void> eliminarMedia(String evaluacionId) async {
    try {
      await _mediaBox.delete(evaluacionId);
      print('✅ Media eliminada para evaluación: $evaluacionId');
    } catch (e) {
      print('❌ Error eliminando media: $e');
      rethrow;
    }
  }
  
  // Obtener estadísticas
  Map<String, dynamic> obtenerEstadisticas({String? liderClave}) {
    try {
      var evaluaciones = _box.values.toList();
      
      if (liderClave != null) {
        evaluaciones = evaluaciones
            .where((e) => e.liderClave == liderClave)
            .toList();
      }
      
      return {
        'total': evaluaciones.length,
        'completadas': evaluaciones.where((e) => e.estaCompletada).length,
        'pendientes': evaluaciones.where((e) => e.estaPendiente).length,
        'sincronizadas': evaluaciones.where((e) => e.syncStatus == 'synced').length,
        'pendientesSync': evaluaciones.where((e) => e.syncStatus == 'pending').length,
        'fallidas': evaluaciones.where((e) => e.syncStatus == 'failed').length,
        'promedioGeneral': _calcularPromedioGeneral(evaluaciones),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }
  
  double _calcularPromedioGeneral(List<ResultadoExcelenciaHive> evaluaciones) {
    if (evaluaciones.isEmpty) return 0.0;
    
    final evaluacionesCompletadas = evaluaciones.where((e) => e.estaCompletada);
    if (evaluacionesCompletadas.isEmpty) return 0.0;
    
    double suma = 0.0;
    for (var evaluacion in evaluacionesCompletadas) {
      suma += evaluacion.ponderacionFinal;
    }
    
    return suma / evaluacionesCompletadas.length;
  }
  
  // Limpiar todas las evaluaciones
  Future<void> limpiarTodo() async {
    try {
      await _box.clear();
      await _mediaBox.clear();
      print('✅ Todas las evaluaciones y media han sido eliminadas');
    } catch (e) {
      print('❌ Error limpiando evaluaciones: $e');
      rethrow;
    }
  }
  
  // ValueListenable para escuchar cambios en tiempo real
  ValueListenable<Box<ResultadoExcelenciaHive>> get listenable => _box.listenable();
}