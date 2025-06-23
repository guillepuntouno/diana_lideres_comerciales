import 'package:hive/hive.dart';
import '../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../servicios/hive_service.dart';

class PlanTrabajoUnificadoRepository {
  final HiveService _hiveService = HiveService();
  
  Box<PlanTrabajoUnificadoHive> get _box => _hiveService.planesTrabajoUnificadosBox;

  // Crear nuevo plan
  Future<void> crearPlan(PlanTrabajoUnificadoHive plan) async {
    try {
      await _box.put(plan.id, plan);
      print('✅ Plan creado: ${plan.id}');
    } catch (e) {
      print('❌ Error creando plan: $e');
      rethrow;
    }
  }

  // Obtener plan por ID
  PlanTrabajoUnificadoHive? obtenerPlan(String planId) {
    try {
      return _box.get(planId);
    } catch (e) {
      print('❌ Error obteniendo plan: $e');
      return null;
    }
  }

  // Obtener plan actual de la semana
  PlanTrabajoUnificadoHive? obtenerPlanActual(String liderClave) {
    try {
      final ahora = DateTime.now();
      final planes = _box.values.where((plan) => 
        plan.liderClave == liderClave &&
        plan.anio == ahora.year &&
        _esSemanaActual(plan, ahora)
      ).toList();
      
      if (planes.isEmpty) return null;
      
      // Ordenar por fecha de modificación descendente
      planes.sort((a, b) => b.fechaModificacion.compareTo(a.fechaModificacion));
      return planes.first;
    } catch (e) {
      print('❌ Error obteniendo plan actual: $e');
      return null;
    }
  }

  // Obtener todos los planes del líder
  List<PlanTrabajoUnificadoHive> obtenerPlanesDelLider(String liderClave) {
    try {
      return _box.values
          .where((plan) => plan.liderClave == liderClave)
          .toList()
        ..sort((a, b) => b.fechaModificacion.compareTo(a.fechaModificacion));
    } catch (e) {
      print('❌ Error obteniendo planes del líder: $e');
      return [];
    }
  }

  // Actualizar plan
  Future<void> actualizarPlan(PlanTrabajoUnificadoHive plan) async {
    try {
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      await plan.save();
      print('✅ Plan actualizado: ${plan.id}');
    } catch (e) {
      print('❌ Error actualizando plan: $e');
      rethrow;
    }
  }

  // Actualizar día específico
  Future<void> actualizarDia(String planId, String dia, DiaPlanHive diaActualizado) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      plan.dias[dia] = diaActualizado;
      await actualizarPlan(plan);
      print('✅ Día actualizado: $dia en plan ${plan.id}');
    } catch (e) {
      print('❌ Error actualizando día: $e');
      rethrow;
    }
  }

  // Actualizar visita de cliente
  Future<void> actualizarVisitaCliente(
    String planId, 
    String dia, 
    String clienteId,
    VisitaClienteUnificadaHive visitaActualizada
  ) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      final diaPlan = plan.dias[dia];
      if (diaPlan == null) throw Exception('Día no encontrado en el plan');
      
      final index = diaPlan.clientes.indexWhere((v) => v.clienteId == clienteId);
      if (index == -1) throw Exception('Cliente no encontrado en el día');
      
      visitaActualizada.fechaModificacion = DateTime.now();
      diaPlan.clientes[index] = visitaActualizada;
      
      await actualizarPlan(plan);
      print('✅ Visita actualizada: Cliente $clienteId en día $dia');
    } catch (e) {
      print('❌ Error actualizando visita: $e');
      rethrow;
    }
  }

  // Iniciar check-in de visita
  Future<void> iniciarCheckIn(
    String planId,
    String dia,
    String clienteId,
    String horaInicio,
    UbicacionUnificadaHive ubicacion,
    String? comentario,
  ) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      final diaPlan = plan.dias[dia];
      if (diaPlan == null) throw Exception('Día no encontrado');
      
      final visitaIndex = diaPlan.clientes.indexWhere((v) => v.clienteId == clienteId);
      if (visitaIndex == -1) throw Exception('Cliente no encontrado');
      
      final visita = diaPlan.clientes[visitaIndex];
      visita.horaInicio = horaInicio;
      visita.ubicacionInicio = ubicacion;
      visita.comentarioInicio = comentario;
      visita.estatus = 'en_proceso';
      visita.fechaModificacion = DateTime.now();
      
      await actualizarPlan(plan);
      print('✅ Check-in iniciado para cliente $clienteId');
    } catch (e) {
      print('❌ Error en check-in: $e');
      rethrow;
    }
  }

  // Completar visita
  Future<void> completarVisita(
    String planId,
    String dia,
    String clienteId,
    String horaFin,
    CuestionarioHive cuestionario,
    List<CompromisoHive> compromisos,
    String? retroalimentacion,
    String? reconocimiento,
  ) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      final diaPlan = plan.dias[dia];
      if (diaPlan == null) throw Exception('Día no encontrado');
      
      final visitaIndex = diaPlan.clientes.indexWhere((v) => v.clienteId == clienteId);
      if (visitaIndex == -1) throw Exception('Cliente no encontrado');
      
      final visita = diaPlan.clientes[visitaIndex];
      visita.horaFin = horaFin;
      visita.cuestionario = cuestionario;
      visita.compromisos = compromisos;
      visita.retroalimentacion = retroalimentacion;
      visita.reconocimiento = reconocimiento;
      visita.estatus = 'completada';
      visita.fechaModificacion = DateTime.now();
      
      await actualizarPlan(plan);
      print('✅ Visita completada para cliente $clienteId');
    } catch (e) {
      print('❌ Error completando visita: $e');
      rethrow;
    }
  }

  // Cambiar estado del plan
  Future<void> cambiarEstadoPlan(String planId, String nuevoEstado) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      plan.estatus = nuevoEstado;
      await actualizarPlan(plan);
      print('✅ Estado del plan cambiado a: $nuevoEstado');
    } catch (e) {
      print('❌ Error cambiando estado del plan: $e');
      rethrow;
    }
  }

  // Obtener planes pendientes de sincronización
  List<PlanTrabajoUnificadoHive> obtenerPlanesPendientesSync() {
    try {
      return _box.values
          .where((plan) => !plan.sincronizado)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo planes pendientes: $e');
      return [];
    }
  }

  // Marcar plan como sincronizado
  Future<void> marcarComoSincronizado(String planId) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      plan.sincronizado = true;
      plan.fechaUltimaSincronizacion = DateTime.now();
      await plan.save();
      print('✅ Plan marcado como sincronizado: $planId');
    } catch (e) {
      print('❌ Error marcando plan como sincronizado: $e');
      rethrow;
    }
  }

  // Eliminar plan
  Future<void> eliminarPlan(String planId) async {
    try {
      await _box.delete(planId);
      print('✅ Plan eliminado: $planId');
    } catch (e) {
      print('❌ Error eliminando plan: $e');
      rethrow;
    }
  }

  // Limpiar todos los planes
  Future<void> limpiarTodo() async {
    try {
      await _box.clear();
      print('✅ Todos los planes eliminados');
    } catch (e) {
      print('❌ Error limpiando planes: $e');
      rethrow;
    }
  }

  // Helpers privados
  bool _esSemanaActual(PlanTrabajoUnificadoHive plan, DateTime fecha) {
    final inicioSemana = DateTime.parse(plan.fechaInicio);
    final finSemana = DateTime.parse(plan.fechaFin);
    return fecha.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
           fecha.isBefore(finSemana.add(const Duration(days: 1)));
  }

  // Obtener progreso del plan
  Map<String, dynamic> obtenerProgresoPlan(String planId) {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) return {};
      
      int totalVisitas = 0;
      int visitasCompletadas = 0;
      int visitasEnProceso = 0;
      int visitasPendientes = 0;
      
      for (final dia in plan.dias.values) {
        if (dia.tipo == 'gestion_cliente') {
          totalVisitas += dia.clientes.length;
          visitasCompletadas += dia.clientes.where((v) => v.estatus == 'completada').length;
          visitasEnProceso += dia.clientes.where((v) => v.estatus == 'en_proceso').length;
          visitasPendientes += dia.clientes.where((v) => v.estatus == 'pendiente').length;
        }
      }
      
      return {
        'totalVisitas': totalVisitas,
        'visitasCompletadas': visitasCompletadas,
        'visitasEnProceso': visitasEnProceso,
        'visitasPendientes': visitasPendientes,
        'porcentajeCompletado': totalVisitas > 0 
            ? ((visitasCompletadas / totalVisitas) * 100).round() 
            : 0,
      };
    } catch (e) {
      print('❌ Error obteniendo progreso: $e');
      return {};
    }
  }

  // Inicializar clientes del día (convertir clienteIds a objetos VisitaCliente)
  Future<void> inicializarClientesDelDia(String planId, String dia) async {
    try {
      final plan = obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');
      
      final diaPlan = plan.dias[dia];
      if (diaPlan == null) throw Exception('Día no encontrado');
      
      diaPlan.initializeClientes();
      await actualizarPlan(plan);
      print('✅ Clientes inicializados para el día $dia');
    } catch (e) {
      print('❌ Error inicializando clientes: $e');
      rethrow;
    }
  }
}