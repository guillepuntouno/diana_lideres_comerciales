import 'package:hive/hive.dart';
import 'package:diana_lc_front/shared/modelos/formulario_dto.dart';

/// Implementación concreta del servicio de plantillas usando Hive
class PlantillaServiceImpl implements PlantillaService {
  static const String _boxName = 'formularios';
  late Box<FormularioPlantillaDTO> _plantillasBox;
  
  static PlantillaServiceImpl? _instance;
  bool _initialized = false;
  
  // Singleton pattern
  factory PlantillaServiceImpl() {
    _instance ??= PlantillaServiceImpl._internal();
    return _instance!;
  }
  
  PlantillaServiceImpl._internal();
  
  /// Inicializa el servicio abriendo la caja de Hive
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Registrar adapters si no están registrados
      registerFormularioAdapters();
      
      // Abrir la caja
      _plantillasBox = await Hive.openBox<FormularioPlantillaDTO>(_boxName);
      _initialized = true;
      
      print('✅ PlantillaService inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar PlantillaService: $e');
      throw Exception('No se pudo inicializar el servicio de plantillas: $e');
    }
  }
  
  /// Asegura que el servicio esté inicializado
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
  
  @override
  Future<List<FormularioPlantillaDTO>> getAllPlantillas() async {
    await _ensureInitialized();
    
    try {
      final plantillas = _plantillasBox.values.toList();
      print('📋 Total de plantillas obtenidas: ${plantillas.length}');
      return plantillas;
    } catch (e) {
      print('❌ Error al obtener plantillas: $e');
      return [];
    }
  }
  
  @override
  Future<List<FormularioPlantillaDTO>> getPlantillasByCanal(CanalType canal) async {
    await _ensureInitialized();
    
    try {
      // Filtrar plantillas activas por canal
      final plantillas = _plantillasBox.values
          .where((plantilla) => 
              plantilla.estatus == FormStatus.ACTIVO && 
              plantilla.canal == canal)
          .toList();
          
      // Ordenar por fecha de actualización (más recientes primero)
      plantillas.sort((a, b) {
        final fechaA = a.fechaActualizacion ?? a.fechaCreacion ?? DateTime(2000);
        final fechaB = b.fechaActualizacion ?? b.fechaCreacion ?? DateTime(2000);
        return fechaB.compareTo(fechaA);
      });
      
      print('📋 Plantillas activas para canal ${canal.name}: ${plantillas.length}');
      
      return plantillas;
    } catch (e) {
      print('❌ Error al obtener plantillas por canal: $e');
      return [];
    }
  }
  
  @override
  Future<FormularioPlantillaDTO?> getPlantillaById(String plantillaId) async {
    await _ensureInitialized();
    
    try {
      return _plantillasBox.get(plantillaId);
    } catch (e) {
      print('❌ Error al obtener plantilla $plantillaId: $e');
      return null;
    }
  }
  
  @override
  Future<void> savePlantilla(FormularioPlantillaDTO plantilla) async {
    await _ensureInitialized();
    
    try {
      // Usar el plantillaId como key en Hive
      await _plantillasBox.put(plantilla.plantillaId, plantilla);
      
      print('✅ Plantilla guardada: ${plantilla.nombre} (${plantilla.plantillaId})');
    } catch (e) {
      print('❌ Error al guardar plantilla: $e');
      throw Exception('No se pudo guardar la plantilla: $e');
    }
  }
  
  @override
  Future<void> savePlantillas(List<FormularioPlantillaDTO> plantillas) async {
    await _ensureInitialized();
    
    try {
      // Crear un mapa para inserción batch
      final plantillasMap = <String, FormularioPlantillaDTO>{};
      
      for (final plantilla in plantillas) {
        plantillasMap[plantilla.plantillaId] = plantilla;
      }
      
      // Guardar todas las plantillas de una vez
      await _plantillasBox.putAll(plantillasMap);
      
      print('✅ ${plantillas.length} plantillas guardadas correctamente');
    } catch (e) {
      print('❌ Error al guardar plantillas: $e');
      throw Exception('No se pudieron guardar las plantillas: $e');
    }
  }
  
  @override
  Future<void> deletePlantilla(String plantillaId) async {
    await _ensureInitialized();
    
    try {
      await _plantillasBox.delete(plantillaId);
      print('✅ Plantilla eliminada: $plantillaId');
    } catch (e) {
      print('❌ Error al eliminar plantilla: $e');
      throw Exception('No se pudo eliminar la plantilla: $e');
    }
  }
  
  @override
  Future<void> clearAllPlantillas() async {
    await _ensureInitialized();
    
    try {
      await _plantillasBox.clear();
      print('✅ Todas las plantillas han sido eliminadas');
    } catch (e) {
      print('❌ Error al limpiar plantillas: $e');
      throw Exception('No se pudieron eliminar las plantillas: $e');
    }
  }
  
  /// Obtiene estadísticas sobre las plantillas almacenadas
  Future<Map<String, dynamic>> getEstadisticas() async {
    await _ensureInitialized();
    
    try {
      final total = _plantillasBox.length;
      final activas = _plantillasBox.values
          .where((p) => p.estatus == FormStatus.ACTIVO)
          .length;
      final inactivas = total - activas;
      
      final porCanal = <String, int>{};
      for (final canal in CanalType.values) {
        porCanal[canal.name] = _plantillasBox.values
            .where((p) => p.canal == canal && p.estatus == FormStatus.ACTIVO)
            .length;
      }
      
      return {
        'total': total,
        'activas': activas,
        'inactivas': inactivas,
        'porCanal': porCanal,
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }
  
  /// Valida que solo haya un formulario activo por canal
  /// Desactiva todos los formularios del canal especificado excepto el indicado
  /// 
  /// [canal] - El canal del cual se desactivarán los demás formularios
  /// [formularioIdActivar] - El ID del formulario que se activará
  /// 
  /// Retorna true si la operación fue exitosa, false en caso contrario
  Future<bool> validarFormularioUnicoPorCanal(
    CanalType canal, 
    String formularioIdActivar,
  ) async {
    await _ensureInitialized();
    
    try {
      // Obtener todos los formularios del canal
      final formulariosCanal = _plantillasBox.values
          .where((formulario) => formulario.canal == canal)
          .toList();
      
      print('📋 Formularios encontrados para canal ${canal.name}: ${formulariosCanal.length}');
      
      // Verificar que el formulario a activar existe
      final formularioActivar = formulariosCanal
          .firstWhere(
            (f) => f.plantillaId == formularioIdActivar,
            orElse: () => throw Exception('Formulario $formularioIdActivar no encontrado'),
          );
      
      // Actualizar los formularios
      final actualizaciones = <String, FormularioPlantillaDTO>{};
      
      for (final formulario in formulariosCanal) {
        if (formulario.plantillaId == formularioIdActivar) {
          // Activar el formulario especificado
          final formularioActualizado = FormularioPlantillaDTO(
            plantillaId: formulario.plantillaId,
            nombre: formulario.nombre,
            version: formulario.version,
            estatus: FormStatus.ACTIVO,
            canal: formulario.canal,
            questions: formulario.questions,
            fechaCreacion: formulario.fechaCreacion,
            fechaActualizacion: DateTime.now(),
          );
          actualizaciones[formulario.plantillaId] = formularioActualizado;
          print('✅ Activando formulario: ${formulario.nombre}');
        } else if (formulario.estatus == FormStatus.ACTIVO) {
          // Desactivar otros formularios activos del mismo canal
          final formularioActualizado = FormularioPlantillaDTO(
            plantillaId: formulario.plantillaId,
            nombre: formulario.nombre,
            version: formulario.version,
            estatus: FormStatus.INACTIVO,
            canal: formulario.canal,
            questions: formulario.questions,
            fechaCreacion: formulario.fechaCreacion,
            fechaActualizacion: DateTime.now(),
          );
          actualizaciones[formulario.plantillaId] = formularioActualizado;
          print('❌ Desactivando formulario: ${formulario.nombre}');
        }
      }
      
      // Guardar todas las actualizaciones en Hive
      if (actualizaciones.isNotEmpty) {
        await _plantillasBox.putAll(actualizaciones);
        print('✅ Se actualizaron ${actualizaciones.length} formularios para el canal ${canal.name}');
      }
      
      return true;
    } catch (e) {
      print('❌ Error al validar formulario único por canal: $e');
      return false;
    }
  }
  
  /// Cierra la caja de Hive
  Future<void> cerrar() async {
    if (_initialized) {
      await _plantillasBox.close();
      _initialized = false;
    }
  }
}

// Ejemplo de uso:
/*
void ejemploUso() async {
  final plantillaService = PlantillaServiceImpl();
  
  // Inicializar
  await plantillaService.initialize();
  
  // Crear una plantilla de ejemplo
  final plantilla = FormularioPlantillaDTO(
    plantillaId: 'FORM_001',
    nombre: 'Evaluación de Punto de Venta - Detalle',
    version: 'v1.0',
    estatus: FormStatus.ACTIVO,
    canal: CanalType.DETALLE,
    fechaCreacion: DateTime.now(),
    questions: [
      PreguntaDTO(
        name: 'limpieza_local',
        tipoEntrada: 'radio',
        orden: 1,
        section: 'Condiciones del Local',
        opciones: [
          OpcionDTO(valor: 'excelente', etiqueta: 'Excelente', puntuacion: 10),
          OpcionDTO(valor: 'bueno', etiqueta: 'Bueno', puntuacion: 7),
          OpcionDTO(valor: 'regular', etiqueta: 'Regular', puntuacion: 5),
          OpcionDTO(valor: 'malo', etiqueta: 'Malo', puntuacion: 0),
        ],
      ),
      PreguntaDTO(
        name: 'exhibicion_productos',
        tipoEntrada: 'select',
        orden: 2,
        section: 'Exhibición',
        opciones: [
          OpcionDTO(valor: 'completa', etiqueta: 'Completa y ordenada', puntuacion: 10),
          OpcionDTO(valor: 'parcial', etiqueta: 'Parcialmente completa', puntuacion: 5),
          OpcionDTO(valor: 'deficiente', etiqueta: 'Deficiente', puntuacion: 0),
        ],
      ),
    ],
  );
  
  // Guardar plantilla
  await plantillaService.savePlantilla(plantilla);
  
  // Obtener plantillas por canal
  final plantillasDetalle = await plantillaService.getPlantillasByCanal(CanalType.DETALLE);
  print('Plantillas para canal DETALLE: ${plantillasDetalle.length}');
  
  // Obtener estadísticas
  final stats = await plantillaService.getEstadisticas();
  print('Estadísticas: $stats');
}
*/