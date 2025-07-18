import 'package:hive/hive.dart';
import '../modelos/formulario_dto.dart';
import 'package:uuid/uuid.dart';

/// Implementación concreta del servicio de captura de formularios usando Hive
class CapturaFormularioServiceImpl implements CapturaFormularioService {
  static const String _boxName = 'respuestas';
  late Box<FormularioRespuestaDTO> _respuestasBox;
  
  static CapturaFormularioServiceImpl? _instance;
  bool _initialized = false;
  final _uuid = const Uuid();
  
  // Singleton pattern
  factory CapturaFormularioServiceImpl() {
    _instance ??= CapturaFormularioServiceImpl._internal();
    return _instance!;
  }
  
  CapturaFormularioServiceImpl._internal();
  
  /// Inicializa el servicio abriendo la caja de Hive
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Registrar adapters si no están registrados
      registerFormularioAdapters();
      
      // Abrir la caja
      _respuestasBox = await Hive.openBox<FormularioRespuestaDTO>(_boxName);
      _initialized = true;
      
      print('✅ CapturaFormularioService inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar CapturaFormularioService: $e');
      throw Exception('No se pudo inicializar el servicio de captura: $e');
    }
  }
  
  /// Asegura que el servicio esté inicializado
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
  
  @override
  Future<void> saveRespuesta(FormularioRespuestaDTO respuesta) async {
    await _ensureInitialized();
    
    try {
      // Si no tiene ID, generar uno
      if (respuesta.respuestaId.isEmpty) {
        respuesta.respuestaId = _uuid.v4();
      }
      
      // Asegurar que esté marcada como offline si es nueva
      if (respuesta.offline != false) {
        respuesta.offline = true;
      }
      
      // Calcular el color KPI basado en la puntuación
      respuesta.colorKPI = _calcularColorKPI(respuesta.puntuacionTotal);
      
      // Guardar usando el respuestaId como key
      await _respuestasBox.put(respuesta.respuestaId, respuesta);
      
      print('✅ Respuesta guardada: ${respuesta.respuestaId} para cliente ${respuesta.clientId}');
      print('   └── Puntuación: ${respuesta.puntuacionTotal} (${respuesta.colorKPI})');
      print('   └── Offline: ${respuesta.offline}');
    } catch (e) {
      print('❌ Error al guardar respuesta: $e');
      throw Exception('No se pudo guardar la respuesta: $e');
    }
  }
  
  @override
  Future<FormularioRespuestaDTO?> getRespuestaById(String respuestaId) async {
    await _ensureInitialized();
    
    try {
      return _respuestasBox.get(respuestaId);
    } catch (e) {
      print('❌ Error al obtener respuesta $respuestaId: $e');
      return null;
    }
  }
  
  @override
  Future<List<FormularioRespuestaDTO>> getRespuestasPorCliente(String clientId) async {
    await _ensureInitialized();
    
    try {
      // Filtrar respuestas por cliente
      final respuestas = _respuestasBox.values
          .where((respuesta) => respuesta.clientId == clientId)
          .toList();
          
      // Ordenar por fecha (más recientes primero)
      respuestas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      
      print('📋 Respuestas encontradas para cliente $clientId: ${respuestas.length}');
      
      return respuestas;
    } catch (e) {
      print('❌ Error al obtener respuestas por cliente: $e');
      return [];
    }
  }
  
  @override
  Future<List<FormularioRespuestaDTO>> getRespuestasPorPlantilla(String plantillaId) async {
    await _ensureInitialized();
    
    try {
      // Filtrar respuestas por plantilla
      final respuestas = _respuestasBox.values
          .where((respuesta) => respuesta.plantillaId == plantillaId)
          .toList();
          
      // Ordenar por fecha (más recientes primero)
      respuestas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      
      print('📋 Respuestas encontradas para plantilla $plantillaId: ${respuestas.length}');
      
      return respuestas;
    } catch (e) {
      print('❌ Error al obtener respuestas por plantilla: $e');
      return [];
    }
  }
  
  @override
  Future<List<FormularioRespuestaDTO>> getRespuestasPendientes() async {
    await _ensureInitialized();
    
    try {
      // Filtrar respuestas offline
      final pendientes = _respuestasBox.values
          .where((respuesta) => respuesta.offline == true)
          .toList();
          
      // Ordenar por fecha (más antiguas primero para sincronizar en orden)
      pendientes.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
      
      print('📤 Respuestas pendientes de sincronizar: ${pendientes.length}');
      
      return pendientes;
    } catch (e) {
      print('❌ Error al obtener respuestas pendientes: $e');
      return [];
    }
  }
  
  @override
  Future<void> marcarComoSincronizada(String respuestaId) async {
    await _ensureInitialized();
    
    try {
      final respuesta = await getRespuestaById(respuestaId);
      
      if (respuesta != null) {
        respuesta.offline = false;
        respuesta.fechaSincronizacion = DateTime.now();
        
        await _respuestasBox.put(respuestaId, respuesta);
        
        print('✅ Respuesta marcada como sincronizada: $respuestaId');
      } else {
        print('⚠️ No se encontró la respuesta $respuestaId para marcar como sincronizada');
      }
    } catch (e) {
      print('❌ Error al marcar respuesta como sincronizada: $e');
      throw Exception('No se pudo marcar la respuesta como sincronizada: $e');
    }
  }
  
  @override
  Future<void> syncRespuestasPendientes() async {
    await _ensureInitialized();
    
    try {
      final pendientes = await getRespuestasPendientes();
      
      if (pendientes.isEmpty) {
        print('✅ No hay respuestas pendientes de sincronizar');
        return;
      }
      
      print('🔄 Iniciando sincronización de ${pendientes.length} respuestas...');
      
      int sincronizadas = 0;
      int errores = 0;
      
      for (final respuesta in pendientes) {
        try {
          // Simular sincronización con delay
          await Future.delayed(const Duration(milliseconds: 500));
          
          // En una implementación real, aquí se haría la llamada al API
          // await apiService.enviarRespuesta(respuesta);
          
          // Marcar como sincronizada
          await marcarComoSincronizada(respuesta.respuestaId);
          sincronizadas++;
          
          print('   ✅ Sincronizada: ${respuesta.respuestaId}');
        } catch (e) {
          errores++;
          print('   ❌ Error al sincronizar ${respuesta.respuestaId}: $e');
        }
      }
      
      print('📊 Sincronización completada:');
      print('   └── Sincronizadas: $sincronizadas');
      print('   └── Errores: $errores');
      
    } catch (e) {
      print('❌ Error durante sincronización: $e');
      throw Exception('Error durante el proceso de sincronización: $e');
    }
  }
  
  @override
  Future<void> deleteRespuesta(String respuestaId) async {
    await _ensureInitialized();
    
    try {
      await _respuestasBox.delete(respuestaId);
      print('✅ Respuesta eliminada: $respuestaId');
    } catch (e) {
      print('❌ Error al eliminar respuesta: $e');
      throw Exception('No se pudo eliminar la respuesta: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getEstadisticas() async {
    await _ensureInitialized();
    
    try {
      final total = _respuestasBox.length;
      final pendientes = _respuestasBox.values
          .where((r) => r.offline == true)
          .length;
      final sincronizadas = total - pendientes;
      
      // Estadísticas por color KPI
      final porColorKPI = <String, int>{
        'verde': 0,
        'amarillo': 0,
        'rojo': 0,
      };
      
      // Estadísticas por cliente (top 5)
      final porCliente = <String, int>{};
      
      for (final respuesta in _respuestasBox.values) {
        // Contar por color KPI
        porColorKPI[respuesta.colorKPI] = (porColorKPI[respuesta.colorKPI] ?? 0) + 1;
        
        // Contar por cliente
        porCliente[respuesta.clientId] = (porCliente[respuesta.clientId] ?? 0) + 1;
      }
      
      // Obtener top 5 clientes con más respuestas
      final topClientes = porCliente.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5Clientes = Map.fromEntries(topClientes.take(5));
      
      // Calcular promedio de puntuación
      double promedioPuntuacion = 0;
      if (total > 0) {
        final sumaPuntuaciones = _respuestasBox.values
            .map((r) => r.puntuacionTotal)
            .reduce((a, b) => a + b);
        promedioPuntuacion = sumaPuntuaciones / total;
      }
      
      return {
        'total': total,
        'sincronizadas': sincronizadas,
        'pendientes': pendientes,
        'porColorKPI': porColorKPI,
        'top5Clientes': top5Clientes,
        'promedioPuntuacion': promedioPuntuacion.toStringAsFixed(2),
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }
  
  /// Calcula el color KPI basado en la puntuación total
  String _calcularColorKPI(int puntuacion) {
    // Estos umbrales pueden ajustarse según las reglas del negocio
    if (puntuacion >= 80) {
      return 'verde';
    } else if (puntuacion >= 60) {
      return 'amarillo';
    } else {
      return 'rojo';
    }
  }
  
  /// Limpia todas las respuestas
  Future<void> clearAllRespuestas() async {
    await _ensureInitialized();
    
    try {
      await _respuestasBox.clear();
      print('✅ Todas las respuestas han sido eliminadas');
    } catch (e) {
      print('❌ Error al limpiar respuestas: $e');
      throw Exception('No se pudieron eliminar las respuestas: $e');
    }
  }
  
  /// Cierra la caja de Hive
  Future<void> cerrar() async {
    if (_initialized) {
      await _respuestasBox.close();
      _initialized = false;
    }
  }
}

// Ejemplo de uso:
/*
void ejemploCaptura() async {
  final capturaService = CapturaFormularioServiceImpl();
  
  // Inicializar
  await capturaService.initialize();
  
  // Crear una respuesta de ejemplo
  final respuesta = FormularioRespuestaDTO(
    respuestaId: '', // Se generará automáticamente
    plantillaId: 'FORM_001',
    planVisitaId: 'PLAN_2024_W45',
    rutaId: 'RUTA_CENTRO_01',
    clientId: 'CLI_12345',
    respuestas: [
      RespuestaPreguntaDTO(
        questionName: 'limpieza_local',
        value: 'excelente',
        puntuacion: 10,
      ),
      RespuestaPreguntaDTO(
        questionName: 'exhibicion_productos',
        value: 'completa',
        puntuacion: 10,
      ),
    ],
    puntuacionTotal: 20,
    colorKPI: '', // Se calculará automáticamente
    offline: true,
    fechaCreacion: DateTime.now(),
  );
  
  // Guardar respuesta
  await capturaService.saveRespuesta(respuesta);
  
  // Obtener respuestas del cliente
  final respuestasCliente = await capturaService.getRespuestasPorCliente('CLI_12345');
  print('Respuestas del cliente: ${respuestasCliente.length}');
  
  // Obtener respuestas pendientes
  final pendientes = await capturaService.getRespuestasPendientes();
  print('Respuestas pendientes de sincronizar: ${pendientes.length}');
  
  // Simular sincronización
  await capturaService.syncRespuestasPendientes();
  
  // Obtener estadísticas
  final stats = await capturaService.getEstadisticas();
  print('Estadísticas: $stats');
}
*/