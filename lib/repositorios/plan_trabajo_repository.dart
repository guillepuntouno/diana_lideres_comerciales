import 'package:hive/hive.dart';
import '../modelos/hive/plan_trabajo_semanal_hive.dart';
import '../modelos/hive/dia_trabajo_hive.dart';

class PlanTrabajoRepository {
  static const String _boxName = 'planes_trabajo_semanal';
  late Box<PlanTrabajoSemanalHive> _box;

  Future<void> init() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<PlanTrabajoSemanalHive>(_boxName);
      } else {
        _box = await Hive.openBox<PlanTrabajoSemanalHive>(_boxName);
      }
    } catch (e) {
      print('❌ Error abriendo caja $_boxName: $e');
      
      // Si hay error por typeId desconocido, intentar limpiar y recrear
      if (e.toString().contains('unknown typeId')) {
        print('🔄 Intentando limpiar y recrear la caja $_boxName...');
        
        try {
          // Cerrar la caja si está abierta
          if (Hive.isBoxOpen(_boxName)) {
            await Hive.box(_boxName).close();
          }
          
          // Eliminar la caja corrupta
          await Hive.deleteBoxFromDisk(_boxName);
          print('🗑️ Caja corrupta eliminada');
          
          // Crear nueva caja limpia
          _box = await Hive.openBox<PlanTrabajoSemanalHive>(_boxName);
          print('✅ Nueva caja creada exitosamente');
        } catch (cleanupError) {
          print('❌ Error al limpiar caja: $cleanupError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  // Generar ID único para el plan
  String generarId(String liderClave, String semana) {
    // Extraer número de semana y año
    final regex = RegExp(r'SEMANA (\d+) - (\d+)');
    final match = regex.firstMatch(semana);
    if (match != null) {
      final numeroSemana = match.group(1);
      final anio = match.group(2);
      return '${liderClave}_SEM${numeroSemana}_$anio';
    }
    return '${liderClave}_${semana.replaceAll(' ', '_')}';
  }

  // Guardar plan
  Future<void> guardarPlan(PlanTrabajoSemanalHive plan) async {
    plan.fechaModificacion = DateTime.now();
    await _box.put(plan.id, plan);
  }

  // Obtener plan por semana
  PlanTrabajoSemanalHive? obtenerPlanPorSemana(String liderClave, String semana) {
    final id = generarId(liderClave, semana);
    return _box.get(id);
  }

  // Obtener todos los planes de un líder
  List<PlanTrabajoSemanalHive> obtenerPlanesPorLider(String liderClave) {
    return _box.values
        .where((plan) => plan.liderClave == liderClave)
        .toList()
      ..sort((a, b) => b.fechaModificacion.compareTo(a.fechaModificacion));
  }

  // Obtener planes pendientes de sincronizar
  List<PlanTrabajoSemanalHive> obtenerPlanesPendientesSincronizar() {
    return _box.values.where((plan) => !plan.sincronizado).toList();
  }

  // Actualizar día en el plan
  Future<void> actualizarDia(
    String liderClave,
    String semana,
    DiaTrabajoHive dia,
  ) async {
    print('[PlanTrabajoRepository] Actualizando día: ${dia.dia}');
    print('  - Líder: $liderClave');
    print('  - Semana: $semana');
    print('  - Configurado: ${dia.configurado}');
    print('  - Objetivo: ${dia.objetivoNombre}');
    
    final plan = obtenerPlanPorSemana(liderClave, semana);
    if (plan != null) {
      print('  - Plan encontrado, actualizando...');
      plan.dias[dia.dia] = dia;
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      await guardarPlan(plan);
      print('  - Día actualizado exitosamente');
      
      // Verificar que se guardó correctamente
      final planVerificacion = obtenerPlanPorSemana(liderClave, semana);
      if (planVerificacion != null && planVerificacion.dias.containsKey(dia.dia)) {
        print('  - Verificación: Día ${dia.dia} guardado con objetivo: ${planVerificacion.dias[dia.dia]!.objetivoNombre}');
      }
    } else {
      print('  - ERROR: Plan no encontrado');
    }
  }

  // Marcar plan como sincronizado
  Future<void> marcarComoSincronizado(String planId) async {
    final plan = _box.get(planId);
    if (plan != null) {
      plan.sincronizado = true;
      plan.fechaUltimaSincronizacion = DateTime.now();
      await guardarPlan(plan);
    }
  }

  // Cambiar estatus del plan
  Future<void> cambiarEstatus(String planId, String nuevoEstatus) async {
    final plan = _box.get(planId);
    if (plan != null) {
      plan.estatus = nuevoEstatus;
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      await guardarPlan(plan);
    }
  }

  // Verificar si existe un plan enviado para la semana actual
  bool existePlanEnviadoSemanaActual(String liderClave) {
    final ahora = DateTime.now();
    final numeroSemana = _calcularNumeroSemana(ahora);
    final anio = ahora.year;
    final semanaActual = 'SEMANA $numeroSemana - $anio';
    
    final plan = obtenerPlanPorSemana(liderClave, semanaActual);
    return plan != null && plan.estatus == 'enviado';
  }

  // Calcular número de semana
  int _calcularNumeroSemana(DateTime fecha) {
    final inicioAno = DateTime(fecha.year, 1, 1);
    final primerLunes = inicioAno.add(
      Duration(days: (8 - inicioAno.weekday) % 7),
    );
    
    if (fecha.isBefore(primerLunes)) {
      return _calcularNumeroSemana(
        DateTime(fecha.year - 1, 12, 31),
      );
    }
    
    return ((fecha.difference(primerLunes).inDays) / 7).floor() + 1;
  }

  // Eliminar planes antiguos (más de 30 días)
  Future<void> limpiarPlanesAntiguos() async {
    final hace30Dias = DateTime.now().subtract(Duration(days: 30));
    final planesAEliminar = _box.values
        .where((plan) => 
            plan.fechaModificacion.isBefore(hace30Dias) && 
            plan.sincronizado)
        .map((plan) => plan.id)
        .toList();
    
    await _box.deleteAll(planesAEliminar);
  }

  // Obtener estadísticas
  Map<String, dynamic> obtenerEstadisticas(String liderClave) {
    final planes = obtenerPlanesPorLider(liderClave);
    
    return {
      'totalPlanes': planes.length,
      'borradores': planes.where((p) => p.estatus == 'borrador').length,
      'enviados': planes.where((p) => p.estatus == 'enviado').length,
      'pendientesSincronizar': planes.where((p) => !p.sincronizado).length,
      'planesCompletos': planes.where((p) => p.estaCompleto).length,
    };
  }
}