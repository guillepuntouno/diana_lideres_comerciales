import '../modelos/hive/visita_cliente_hive.dart';
import '../servicios/hive_service.dart';

class VisitaClienteRepository {
  static final VisitaClienteRepository _instance = VisitaClienteRepository._internal();
  factory VisitaClienteRepository() => _instance;
  VisitaClienteRepository._internal();

  final HiveService _hiveService = HiveService();

  /// Guarda o actualiza una visita
  Future<void> save(VisitaClienteHive visita) async {
    try {
      visita.lastUpdated = DateTime.now();
      visita.syncStatus = 'pending';
      await _hiveService.visitasClientes.put(visita.id, visita);
      print('✅ Visita guardada: ${visita.visitaId}');
    } catch (e) {
      print('❌ Error guardando visita: $e');
      rethrow;
    }
  }

  /// Obtiene una visita por ID
  VisitaClienteHive? getById(String id) {
    try {
      return _hiveService.visitasClientes.get(id);
    } catch (e) {
      print('❌ Error obteniendo visita: $e');
      return null;
    }
  }

  /// Obtiene todas las visitas
  List<VisitaClienteHive> getAll() {
    try {
      return _hiveService.visitasClientes.values.toList();
    } catch (e) {
      print('❌ Error obteniendo todas las visitas: $e');
      return [];
    }
  }

  /// Obtiene visitas por líder comercial
  List<VisitaClienteHive> getByLider(String liderClave) {
    try {
      return _hiveService.visitasClientes.values
          .where((visita) => visita.liderClave == liderClave)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo visitas por líder: $e');
      return [];
    }
  }

  /// Obtiene visitas por fecha
  List<VisitaClienteHive> getByFecha(DateTime fecha) {
    try {
      final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
      final fechaFin = fechaInicio.add(const Duration(days: 1));
      
      return _hiveService.visitasClientes.values
          .where((visita) => 
              visita.fechaCreacion.isAfter(fechaInicio) && 
              visita.fechaCreacion.isBefore(fechaFin))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo visitas por fecha: $e');
      return [];
    }
  }

  /// Obtiene visitas por estado
  List<VisitaClienteHive> getByEstatus(String estatus) {
    try {
      return _hiveService.visitasClientes.values
          .where((visita) => visita.estatus == estatus)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo visitas por estatus: $e');
      return [];
    }
  }

  /// Obtiene visitas pendientes de sincronización
  List<VisitaClienteHive> getPendingSync() {
    try {
      return _hiveService.visitasClientes.values
          .where((visita) => visita.syncStatus == 'pending')
          .toList();
    } catch (e) {
      print('❌ Error obteniendo visitas pendientes: $e');
      return [];
    }
  }

  /// Obtiene visitas activas (en proceso)
  List<VisitaClienteHive> getVisitasActivas() {
    try {
      return _hiveService.visitasClientes.values
          .where((visita) => visita.estaEnProceso)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo visitas activas: $e');
      return [];
    }
  }

  /// Inicia una visita (check-in)
  Future<void> iniciarVisita(String visitaId, CheckInHive checkIn) async {
    try {
      final visita = getById(visitaId);
      if (visita != null) {
        visita.checkIn = checkIn;
        visita.estatus = 'en_proceso';
        visita.fechaModificacion = DateTime.now();
        await save(visita);
        print('✅ Visita iniciada: $visitaId');
      } else {
        throw Exception('Visita no encontrada: $visitaId');
      }
    } catch (e) {
      print('❌ Error iniciando visita: $e');
      rethrow;
    }
  }

  /// Finaliza una visita (check-out)
  Future<void> finalizarVisita(String visitaId, CheckOutHive checkOut) async {
    try {
      final visita = getById(visitaId);
      if (visita != null) {
        visita.checkOut = checkOut;
        visita.estatus = 'completada';
        visita.fechaFinalizacion = DateTime.now();
        visita.fechaModificacion = DateTime.now();
        await save(visita);
        print('✅ Visita finalizada: $visitaId');
      } else {
        throw Exception('Visita no encontrada: $visitaId');
      }
    } catch (e) {
      print('❌ Error finalizando visita: $e');
      rethrow;
    }
  }

  /// Cancela una visita
  Future<void> cancelarVisita(String visitaId, String motivo) async {
    try {
      final visita = getById(visitaId);
      if (visita != null) {
        visita.estatus = 'cancelada';
        visita.motivoCancelacion = motivo;
        visita.fechaCancelacion = DateTime.now();
        visita.fechaModificacion = DateTime.now();
        await save(visita);
        print('✅ Visita cancelada: $visitaId');
      } else {
        throw Exception('Visita no encontrada: $visitaId');
      }
    } catch (e) {
      print('❌ Error cancelando visita: $e');
      rethrow;
    }
  }

  /// Actualiza formularios de una visita
  Future<void> actualizarFormularios(String visitaId, Map<String, dynamic> formularios) async {
    try {
      final visita = getById(visitaId);
      if (visita != null) {
        visita.formularios.addAll(formularios);
        visita.fechaModificacion = DateTime.now();
        await save(visita);
        print('✅ Formularios actualizados para visita: $visitaId');
      } else {
        throw Exception('Visita no encontrada: $visitaId');
      }
    } catch (e) {
      print('❌ Error actualizando formularios: $e');
      rethrow;
    }
  }

  /// Elimina una visita
  Future<void> delete(String id) async {
    try {
      await _hiveService.visitasClientes.delete(id);
      print('✅ Visita eliminada: $id');
    } catch (e) {
      print('❌ Error eliminando visita: $e');
      rethrow;
    }
  }

  /// Elimina todas las visitas
  Future<void> deleteAll() async {
    try {
      await _hiveService.visitasClientes.clear();
      print('✅ Todas las visitas eliminadas');
    } catch (e) {
      print('❌ Error eliminando todas las visitas: $e');
      rethrow;
    }
  }

  /// Marca una visita como sincronizada
  Future<void> markAsSynced(String id) async {
    try {
      final visita = getById(id);
      if (visita != null) {
        visita.syncStatus = 'synced';
        visita.lastUpdated = DateTime.now();
        await visita.save();
        print('✅ Visita marcada como sincronizada: $id');
      }
    } catch (e) {
      print('❌ Error marcando visita como sincronizada: $e');
      rethrow;
    }
  }

  /// Obtiene estadísticas de visitas
  Map<String, int> getEstadisticas() {
    try {
      final todasLasVisitas = getAll();
      
      return {
        'total': todasLasVisitas.length,
        'en_proceso': todasLasVisitas.where((v) => v.estaEnProceso).length,
        'completadas': todasLasVisitas.where((v) => v.estaCompletada).length,
        'canceladas': todasLasVisitas.where((v) => v.estaCancelada).length,
        'pendientes_sync': todasLasVisitas.where((v) => v.syncStatus == 'pending').length,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Busca visitas por cliente
  List<VisitaClienteHive> searchByCliente(String query) {
    try {
      final queryLower = query.toLowerCase();
      return _hiveService.visitasClientes.values
          .where((visita) => 
              visita.clienteNombre.toLowerCase().contains(queryLower) ||
              visita.clienteId.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      print('❌ Error buscando visitas por cliente: $e');
      return [];
    }
  }

  /// Obtiene visitas del día actual
  List<VisitaClienteHive> getVisitasHoy() {
    return getByFecha(DateTime.now());
  }

  /// Obtiene visitas de la semana actual
  List<VisitaClienteHive> getVisitasSemana() {
    try {
      final ahora = DateTime.now();
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 7));
      
      return _hiveService.visitasClientes.values
          .where((visita) => 
              visita.fechaCreacion.isAfter(inicioSemana) && 
              visita.fechaCreacion.isBefore(finSemana))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo visitas de la semana: $e');
      return [];
    }
  }
}