import '../modelos/visita_cliente_modelo.dart';
import '../modelos/hive/visita_cliente_hive.dart';
import '../servicios/hive_service.dart';
import '../servicios/sesion_servicio.dart';
import 'package:uuid/uuid.dart';

class VisitaClienteOfflineService {
  static final VisitaClienteOfflineService _instance = VisitaClienteOfflineService._internal();
  factory VisitaClienteOfflineService() => _instance;
  VisitaClienteOfflineService._internal();

  final HiveService _hiveService = HiveService();
  final _uuid = const Uuid();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Asegurar que HiveService esté inicializado
    if (!_hiveService.isInitialized) {
      await _hiveService.initialize();
    }
    
    _isInitialized = true;
  }

  /// Crear una nueva visita con check-in inicial
  Future<VisitaClienteModelo> crearVisitaConCheckIn({
    required String claveVisita,
    required String liderClave,
    required String clienteId,
    required String clienteNombre,
    required String planId,
    required String dia,
    required CheckInModelo checkIn,
  }) async {
    await initialize();
    
    try {
      print('🏁 Creando visita offline con check-in: $claveVisita');

      // Generar un ID único para la visita
      final visitaId = _uuid.v4();
      
      // Crear el modelo de visita
      final visita = VisitaClienteModelo(
        visitaId: visitaId,
        liderClave: liderClave,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        planId: planId,
        dia: dia,
        estatus: 'en_progreso',
        checkIn: checkIn,
        formularios: {},
        fechaCreacion: DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      // Convertir a modelo Hive
      final visitaHive = _convertirAHive(visita);
      
      // Guardar en Hive
      await _hiveService.visitasClientes.put(visitaId, visitaHive);
      
      print('✅ Visita creada exitosamente offline');
      print('   └── Visita ID: ${visita.visitaId}');
      print('   └── Estatus: ${visita.estatus}');
      
      return visita;
    } catch (e) {
      print('❌ Error al crear visita offline: $e');
      rethrow;
    }
  }

  /// Obtener una visita específica por ID
  Future<VisitaClienteModelo?> obtenerVisita(String visitaId) async {
    await initialize();
    
    try {
      final visitaHive = _hiveService.visitasClientes.get(visitaId);
      if (visitaHive != null) {
        return _convertirDesdeHive(visitaHive);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener visita: $e');
      return null;
    }
  }

  /// Actualizar formularios de la visita
  Future<void> actualizarFormularios(
    String visitaId,
    Map<String, dynamic> formularios,
  ) async {
    await initialize();
    
    try {
      print('📝 Actualizando formularios para: $visitaId');
      
      final visitaHive = _hiveService.visitasClientes.get(visitaId);
      if (visitaHive == null) {
        throw Exception('Visita no encontrada');
      }
      
      // Actualizar formularios
      visitaHive.formularios = formularios;
      visitaHive.fechaModificacion = DateTime.now();
      visitaHive.syncStatus = 'pending';
      
      // Guardar cambios
      await visitaHive.save();
      
      print('✅ Formularios actualizados exitosamente');
    } catch (e) {
      print('❌ Error al actualizar formularios: $e');
      rethrow;
    }
  }

  /// Finalizar visita con check-out
  Future<VisitaClienteModelo> finalizarVisitaConCheckOut(
    String visitaId,
    CheckOutModelo checkOut,
  ) async {
    await initialize();
    
    try {
      print('🏁 Finalizando visita offline: $visitaId');
      
      final visitaHive = _hiveService.visitasClientes.get(visitaId);
      if (visitaHive == null) {
        throw Exception('Visita no encontrada');
      }
      
      // Actualizar con check-out
      visitaHive.checkOut = CheckOutHive(
        timestamp: checkOut.timestamp,
        ubicacion: UbicacionHive(
          latitud: checkOut.ubicacion.latitud,
          longitud: checkOut.ubicacion.longitud,
          precision: checkOut.ubicacion.precision,
          direccion: checkOut.ubicacion.direccion,
        ),
        comentarios: checkOut.comentarios,
        duracionMinutos: checkOut.duracionMinutos,
      );
      visitaHive.estatus = 'completada';
      visitaHive.fechaModificacion = DateTime.now();
      visitaHive.syncStatus = 'pending';
      
      // Guardar cambios
      await visitaHive.save();
      
      print('✅ Visita finalizada exitosamente');
      
      return _convertirDesdeHive(visitaHive);
    } catch (e) {
      print('❌ Error al finalizar visita: $e');
      rethrow;
    }
  }

  /// Obtener todas las visitas de un líder
  Future<List<VisitaClienteModelo>> obtenerVisitasPorLider(
    String liderClave,
  ) async {
    await initialize();
    
    try {
      final visitas = _hiveService.visitasClientes.values
          .where((v) => v.liderClave == liderClave)
          .map((v) => _convertirDesdeHive(v))
          .toList();
      
      // Ordenar por fecha de creación descendente
      visitas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      
      return visitas;
    } catch (e) {
      print('❌ Error al obtener visitas: $e');
      return [];
    }
  }

  /// Obtener visitas por día específico
  Future<List<VisitaClienteModelo>> obtenerVisitasPorDia(
    String liderClave,
    String dia,
  ) async {
    await initialize();
    
    try {
      final visitas = _hiveService.visitasClientes.values
          .where((v) => v.liderClave == liderClave && v.dia == dia)
          .map((v) => _convertirDesdeHive(v))
          .toList();
      
      return visitas;
    } catch (e) {
      print('❌ Error al obtener visitas del día: $e');
      return [];
    }
  }

  /// Generar clave de visita automáticamente
  String generarClaveVisita({
    required String liderClave,
    required int numeroSemana,
    required String dia,
    required String clienteId,
  }) {
    final clave = '${liderClave}_${numeroSemana}_${dia.toLowerCase()}_$clienteId';
    print('🔑 Clave generada: $clave');
    return clave;
  }

  /// Método de conveniencia para crear visita con datos actuales
  Future<VisitaClienteModelo> crearVisitaDesdeActividad({
    required String clienteId,
    required String clienteNombre,
    required String dia,
    required CheckInModelo checkIn,
    String? planId,
  }) async {
    try {
      // Obtener datos de la sesión
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider == null) {
        throw Exception('No hay sesión activa del líder');
      }

      // Generar clave de visita
      final claveVisita = generarClaveVisita(
        liderClave: lider.clave,
        numeroSemana: _obtenerSemanaActual(),
        dia: dia,
        clienteId: clienteId,
      );

      // Crear visita
      return await crearVisitaConCheckIn(
        claveVisita: claveVisita,
        liderClave: lider.clave,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        planId: planId ?? 'SIN_PLAN',
        dia: dia,
        checkIn: checkIn,
      );
    } catch (e) {
      print('❌ Error al crear visita desde actividad: $e');
      rethrow;
    }
  }

  /// Obtener visitas pendientes de sincronizar
  Future<List<VisitaClienteModelo>> obtenerVisitasPendientesSincronizar() async {
    await initialize();
    
    try {
      final visitas = _hiveService.visitasClientes.values
          .where((v) => v.syncStatus == 'pending')
          .map((v) => _convertirDesdeHive(v))
          .toList();
      
      return visitas;
    } catch (e) {
      print('❌ Error al obtener visitas pendientes: $e');
      return [];
    }
  }

  /// Marcar visita como sincronizada
  Future<void> marcarComoSincronizada(String visitaId) async {
    await initialize();
    
    try {
      final visitaHive = _hiveService.visitasClientes.get(visitaId);
      if (visitaHive != null) {
        visitaHive.syncStatus = 'synced';
        await visitaHive.save();
      }
    } catch (e) {
      print('❌ Error al marcar visita como sincronizada: $e');
    }
  }

  // === MÉTODOS AUXILIARES ===

  int _obtenerSemanaActual() {
    final ahora = DateTime.now();
    final primerDiaAno = DateTime(ahora.year, 1, 1);
    final diasDesdeInicio = ahora.difference(primerDiaAno).inDays;
    return ((diasDesdeInicio + primerDiaAno.weekday - 1) / 7).ceil();
  }

  /// Convertir de modelo de negocio a Hive
  VisitaClienteHive _convertirAHive(VisitaClienteModelo visita) {
    return VisitaClienteHive(
      id: visita.visitaId, // Usar visitaId como id único
      visitaId: visita.visitaId,
      liderClave: visita.liderClave,
      clienteId: visita.clienteId,
      clienteNombre: visita.clienteNombre,
      planId: visita.planId,
      dia: visita.dia,
      estatus: visita.estatus,
      checkIn: CheckInHive(
        timestamp: visita.checkIn.timestamp,
        ubicacion: UbicacionHive(
          latitud: visita.checkIn.ubicacion.latitud,
          longitud: visita.checkIn.ubicacion.longitud,
          precision: visita.checkIn.ubicacion.precision,
          direccion: visita.checkIn.ubicacion.direccion,
        ),
        comentarios: visita.checkIn.comentarios,
      ),
      checkOut: visita.checkOut != null
          ? CheckOutHive(
              timestamp: visita.checkOut!.timestamp,
              ubicacion: UbicacionHive(
                latitud: visita.checkOut!.ubicacion.latitud,
                longitud: visita.checkOut!.ubicacion.longitud,
                precision: visita.checkOut!.ubicacion.precision,
                direccion: visita.checkOut!.ubicacion.direccion,
              ),
              comentarios: visita.checkOut!.comentarios,
              duracionMinutos: visita.checkOut!.duracionMinutos,
            )
          : null,
      formularios: visita.formularios,
      fechaCreacion: visita.fechaCreacion,
      fechaModificacion: visita.fechaModificacion ?? DateTime.now(),
      syncStatus: 'pending',
    );
  }

  /// Convertir de Hive a modelo de negocio
  VisitaClienteModelo _convertirDesdeHive(VisitaClienteHive visitaHive) {
    return VisitaClienteModelo(
      visitaId: visitaHive.visitaId,
      liderClave: visitaHive.liderClave,
      clienteId: visitaHive.clienteId,
      clienteNombre: visitaHive.clienteNombre,
      planId: visitaHive.planId,
      dia: visitaHive.dia,
      estatus: visitaHive.estatus,
      checkIn: CheckInModelo(
        timestamp: visitaHive.checkIn.timestamp,
        ubicacion: UbicacionModelo(
          latitud: visitaHive.checkIn.ubicacion.latitud,
          longitud: visitaHive.checkIn.ubicacion.longitud,
          precision: visitaHive.checkIn.ubicacion.precision,
          direccion: visitaHive.checkIn.ubicacion.direccion,
        ),
        comentarios: visitaHive.checkIn.comentarios,
      ),
      checkOut: visitaHive.checkOut != null
          ? CheckOutModelo(
              timestamp: visitaHive.checkOut!.timestamp,
              ubicacion: UbicacionModelo(
                latitud: visitaHive.checkOut!.ubicacion.latitud,
                longitud: visitaHive.checkOut!.ubicacion.longitud,
                precision: visitaHive.checkOut!.ubicacion.precision,
                direccion: visitaHive.checkOut!.ubicacion.direccion,
              ),
              duracionMinutos: _calcularDuracionMinutos(
                visitaHive.checkIn.timestamp,
                visitaHive.checkOut!.timestamp,
              ),
              comentarios: visitaHive.checkOut!.comentarios,
            )
          : null,
      formularios: visitaHive.formularios,
      fechaCreacion: visitaHive.fechaCreacion,
      fechaModificacion: visitaHive.fechaModificacion,
    );
  }

  int _calcularDuracionMinutos(DateTime inicio, DateTime fin) {
    return fin.difference(inicio).inMinutes;
  }
}