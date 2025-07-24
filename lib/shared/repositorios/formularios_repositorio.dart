import 'package:hive/hive.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';

class FormulariosRepositorio {
  static final FormulariosRepositorio _instance = FormulariosRepositorio._internal();
  factory FormulariosRepositorio() => _instance;
  FormulariosRepositorio._internal();

  static const String _boxName = HiveService.formulariosPlantillasBox;
  final HiveService _hiveService = HiveService();

  /// Obtener la caja de formularios plantillas
  Box<dynamic> get _box => Hive.box(_boxName);

  /// Inicializar el repositorio y abrir la caja si es necesario
  Future<void> inicializar() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  /// Guardar formulario plantilla
  Future<void> guardarFormulario(Map<String, dynamic> formulario) async {
    try {
      await _box.put(formulario['id'], formulario);
      print('✅ Formulario guardado localmente: ${formulario['id']}');
    } catch (e) {
      print('❌ Error al guardar formulario: $e');
      rethrow;
    }
  }

  /// Obtener todos los formularios plantilla
  Future<List<Map<String, dynamic>>> obtenerTodos() async {
    try {
      final formularios = _box.values
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      
      // Ordenar por fecha de actualización descendente
      formularios.sort((a, b) {
        final fechaA = DateTime.tryParse(a['fechaActualizacion'] ?? '') ?? DateTime(2000);
        final fechaB = DateTime.tryParse(b['fechaActualizacion'] ?? '') ?? DateTime(2000);
        return fechaB.compareTo(fechaA);
      });
      
      return formularios;
    } catch (e) {
      print('❌ Error al obtener formularios: $e');
      return [];
    }
  }

  /// Obtener formulario por ID
  Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final formulario = _box.get(id);
      if (formulario != null && formulario is Map) {
        return Map<String, dynamic>.from(formulario);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener formulario por ID: $e');
      return null;
    }
  }

  /// Actualizar formulario
  Future<void> actualizarFormulario(String id, Map<String, dynamic> formulario) async {
    try {
      formulario['fechaActualizacion'] = DateTime.now().toIso8601String();
      await _box.put(id, formulario);
      print('✅ Formulario actualizado: $id');
    } catch (e) {
      print('❌ Error al actualizar formulario: $e');
      rethrow;
    }
  }

  /// Eliminar formulario
  Future<void> eliminarFormulario(String id) async {
    try {
      await _box.delete(id);
      print('✅ Formulario eliminado: $id');
    } catch (e) {
      print('❌ Error al eliminar formulario: $e');
      rethrow;
    }
  }

  /// Guardar múltiples formularios (para sincronización)
  Future<void> guardarMultiples(List<Map<String, dynamic>> formularios) async {
    try {
      final Map<dynamic, dynamic> formulariosMap = {};
      for (final formulario in formularios) {
        formulariosMap[formulario['id']] = formulario;
      }
      await _box.putAll(formulariosMap);
      print('✅ ${formularios.length} formularios guardados');
    } catch (e) {
      print('❌ Error al guardar múltiples formularios: $e');
      rethrow;
    }
  }

  /// Limpiar todos los formularios locales
  Future<void> limpiarTodo() async {
    try {
      await _box.clear();
      print('✅ Todos los formularios eliminados');
    } catch (e) {
      print('❌ Error al limpiar formularios: $e');
      rethrow;
    }
  }

  /// Buscar formularios por criterios
  Future<List<Map<String, dynamic>>> buscar({
    String? nombre,
    bool? activa,
    String? version,
  }) async {
    try {
      var formularios = await obtenerTodos();
      
      if (nombre != null && nombre.isNotEmpty) {
        formularios = formularios.where((f) => 
          f['nombre'].toString().toLowerCase().contains(nombre.toLowerCase())
        ).toList();
      }
      
      if (activa != null) {
        formularios = formularios.where((f) => f['activa'] == activa).toList();
      }
      
      if (version != null && version.isNotEmpty) {
        formularios = formularios.where((f) => f['version'] == version).toList();
      }
      
      return formularios;
    } catch (e) {
      print('❌ Error al buscar formularios: $e');
      return [];
    }
  }

  /// Obtener formularios pendientes de sincronización
  Future<List<Map<String, dynamic>>> obtenerPendientesSincronizacion() async {
    try {
      final formularios = await obtenerTodos();
      return formularios.where((f) => f['syncStatus'] == 'pending').toList();
    } catch (e) {
      print('❌ Error al obtener pendientes: $e');
      return [];
    }
  }

  /// Marcar formulario como sincronizado
  Future<void> marcarComoSincronizado(String id) async {
    try {
      final formulario = await obtenerPorId(id);
      if (formulario != null) {
        formulario['syncStatus'] = 'synced';
        await actualizarFormulario(id, formulario);
      }
    } catch (e) {
      print('❌ Error al marcar como sincronizado: $e');
    }
  }

  /// Verificar si un formulario tiene capturas
  Future<bool> tieneCapturasFormulario(String formularioId) async {
    try {
      // Buscar en la caja de planes de trabajo unificados
      if (!Hive.isBoxOpen(HiveService.planTrabajoUnificadoBox)) {
        return false;
      }
      
      final planesBox = Hive.box(HiveService.planTrabajoUnificadoBox);
      
      // Buscar si algún plan tiene formularios capturados con este ID
      for (final plan in planesBox.values) {
        if (plan != null && plan is Map) {
          final dias = plan['dias'] as Map<String, dynamic>?;
          if (dias != null) {
            for (final dia in dias.values) {
              if (dia is Map) {
                final formularios = dia['formularios'] as List?;
                if (formularios != null) {
                  for (final form in formularios) {
                    if (form is Map && form['formularioId'] == formularioId) {
                      return true; // Encontró una captura
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error al verificar capturas: $e');
      return true; // Por seguridad, asumimos que tiene capturas
    }
  }
}