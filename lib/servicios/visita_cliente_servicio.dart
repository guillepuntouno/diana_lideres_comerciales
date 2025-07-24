// lib/servicios/visita_cliente_servicio.dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:diana_lc_front/shared/modelos/visita_cliente_modelo.dart';
import 'package:diana_lc_front/shared/modelos/hive/visita_cliente_hive.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';

class VisitaClienteServicio {
  static final VisitaClienteServicio _instance =
      VisitaClienteServicio._internal();
  factory VisitaClienteServicio() => _instance;
  VisitaClienteServicio._internal();

  // Box de Hive para almacenar visitas localmente
  static const String _boxName = 'visitas_clientes';
  
  // Obtener o abrir el box de visitas
  Future<Box<VisitaClienteHive>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<VisitaClienteHive>(_boxName);
    }
    return Hive.box<VisitaClienteHive>(_boxName);
  }

  /// Crear una nueva visita con check-in inicial (LOCAL)
  Future<VisitaClienteModelo> crearVisitaConCheckIn({
    required String claveVisita,
    required String liderClave,
    required String clienteId,
    required String clienteNombre,
    required String planId,
    required String dia,
    required CheckInModelo checkIn,
  }) async {
    try {
      print('🏁 Creando visita LOCAL con check-in: $claveVisita');

      final box = await _getBox();
      
      // Verificar si ya existe
      if (box.containsKey(claveVisita)) {
        throw Exception('Ya existe una visita con esta clave');
      }

      // Crear la visita modelo
      final visita = VisitaClienteModelo(
        visitaId: claveVisita,
        liderClave: liderClave,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        planId: planId,
        dia: dia,
        checkIn: checkIn,
        checkOut: null,
        formularios: {},
        estatus: 'en_proceso',
        fechaCreacion: DateTime.now(),
      );

      // Convertir a VisitaClienteHive y guardar
      final visitaHive = VisitaClienteHive.fromJson({
        'id': claveVisita,
        'visitaId': visita.visitaId,
        'liderClave': visita.liderClave,
        'clienteId': visita.clienteId,
        'clienteNombre': visita.clienteNombre,
        'planId': visita.planId,
        'dia': visita.dia,
        'fechaCreacion': visita.fechaCreacion.toIso8601String(),
        'checkIn': visita.checkIn.toJson(),
        'checkOut': visita.checkOut?.toJson(),
        'formularios': visita.formularios,
        'estatus': visita.estatus,
        'fechaModificacion': visita.fechaModificacion?.toIso8601String(),
        'fechaFinalizacion': visita.fechaFinalizacion?.toIso8601String(),
        'fechaCancelacion': visita.fechaCancelacion?.toIso8601String(),
        'motivoCancelacion': visita.motivoCancelacion,
        'syncStatus': 'pending',
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      await box.put(claveVisita, visitaHive);
      
      print('✅ Visita creada exitosamente en almacenamiento local');
      return visita;
    } catch (e) {
      print('❌ Error al crear visita local: $e');
      rethrow;
    }
  }

  /// Obtener una visita específica por clave (LOCAL)
  Future<VisitaClienteModelo?> obtenerVisita(String claveVisita) async {
    try {
      print('🔍 Obteniendo visita LOCAL: $claveVisita');

      final box = await _getBox();
      
      if (!box.containsKey(claveVisita)) {
        print('📭 Visita no encontrada localmente');
        return null;
      }
      
      final visitaHive = box.get(claveVisita);
      if (visitaHive == null) return null;
      
      // Convertir de VisitaClienteHive a VisitaClienteModelo
      final visita = VisitaClienteModelo.fromJson(visitaHive.toJson());
      
      print('✅ Visita recuperada del almacenamiento local');
      return visita;
    } catch (e) {
      print('❌ Error al obtener visita local: $e');
      return null;
    }
  }

  /// Actualizar formularios de la visita (LOCAL)
  Future<void> actualizarFormularios(
    String claveVisita,
    Map<String, dynamic> formularios,
  ) async {
    try {
      print('📝 Actualizando formularios LOCAL para: $claveVisita');
      
      final box = await _getBox();
      
      if (!box.containsKey(claveVisita)) {
        throw Exception('Visita no encontrada');
      }
      
      // Obtener visita actual
      final visitaHive = box.get(claveVisita);
      if (visitaHive == null) {
        throw Exception('Visita no encontrada');
      }
      
      // Actualizar formularios
      visitaHive.formularios = formularios;
      visitaHive.fechaModificacion = DateTime.now();
      visitaHive.lastUpdated = DateTime.now();
      
      // Guardar actualización
      await visitaHive.save();
      
      print('✅ Formularios actualizados exitosamente en almacenamiento local');
    } catch (e) {
      print('❌ Error al actualizar formularios localmente: $e');
      rethrow;
    }
  }

  /// Finalizar visita con check-out (LOCAL)
  Future<VisitaClienteModelo> finalizarVisitaConCheckOut(
    String claveVisita,
    CheckOutModelo checkOut,
  ) async {
    try {
      print('🏁 Finalizando visita LOCAL: $claveVisita');

      final box = await _getBox();
      
      print('📦 Total de visitas en box: ${box.length}');
      print('🔑 Claves en box: ${box.keys.toList()}');
      
      // Buscar visitas del mismo cliente
      for (var key in box.keys) {
        final visita = box.get(key);
        if (visita != null && visita.clienteId == claveVisita.split('_').last) {
          print('🔍 Visita encontrada para cliente ${visita.clienteId}:');
          print('   - Clave: $key');
          print('   - VisitaId: ${visita.visitaId}');
          print('   - Estado: ${visita.estatus}');
          print('   - CheckOut: ${visita.checkOut != null ? "SÍ" : "NO"}');
        }
      }
      
      if (!box.containsKey(claveVisita)) {
        print('❌ Clave no encontrada: $claveVisita');
        throw Exception('Visita no encontrada');
      }
      
      // Obtener visita actual
      final visitaHive = box.get(claveVisita);
      if (visitaHive == null) {
        throw Exception('Visita no encontrada');
      }
      
      // Actualizar con checkout
      visitaHive.checkOut = CheckOutHive.fromJson(checkOut.toJson());
      visitaHive.estatus = 'completada';
      visitaHive.fechaModificacion = DateTime.now();
      visitaHive.fechaFinalizacion = DateTime.now();
      visitaHive.lastUpdated = DateTime.now();
      
      // Guardar actualización
      await visitaHive.save();
      
      // Convertir a modelo
      final visita = VisitaClienteModelo.fromJson(visitaHive.toJson());
      
      print('✅ Visita finalizada exitosamente en almacenamiento local');
      print('🕒 Duración: ${checkOut.duracionMinutos} minutos');
      
      return visita;
    } catch (e) {
      print('❌ Error al finalizar visita localmente: $e');
      rethrow;
    }
  }

  /// Cancelar una visita (LOCAL)
  Future<void> cancelarVisita(String claveVisita, String motivo) async {
    try {
      print('❌ Cancelando visita LOCAL: $claveVisita');
      print('📝 Motivo: $motivo');

      final box = await _getBox();
      
      if (!box.containsKey(claveVisita)) {
        throw Exception('Visita no encontrada');
      }
      
      // Obtener visita actual
      final visitaHive = box.get(claveVisita);
      if (visitaHive == null) {
        throw Exception('Visita no encontrada');
      }
      
      // Actualizar estado
      visitaHive.estatus = 'cancelada';
      visitaHive.motivoCancelacion = motivo;
      visitaHive.fechaModificacion = DateTime.now();
      visitaHive.fechaCancelacion = DateTime.now();
      visitaHive.lastUpdated = DateTime.now();
      
      // Guardar actualización
      await visitaHive.save();
      
      print('✅ Visita cancelada exitosamente en almacenamiento local');
    } catch (e) {
      print('❌ Error al cancelar visita localmente: $e');
      rethrow;
    }
  }

  /// Obtener todas las visitas del líder (LOCAL)
  Future<List<VisitaClienteModelo>> obtenerVisitasDelLider(
    String liderClave,
  ) async {
    try {
      print('📋 Obteniendo visitas LOCAL del líder: $liderClave');

      final box = await _getBox();
      final visitas = <VisitaClienteModelo>[];
      
      // Filtrar visitas por líder
      for (var visitaHive in box.values) {
        if (visitaHive.liderClave == liderClave) {
          visitas.add(VisitaClienteModelo.fromJson(visitaHive.toJson()));
        }
      }
      
      print('📊 Total de visitas encontradas: ${visitas.length}');
      return visitas;
    } catch (e) {
      print('❌ Error al obtener visitas del líder: $e');
      return [];
    }
  }

  /// Obtener resumen de visitas por período (LOCAL)
  Future<Map<String, dynamic>> obtenerResumenVisitas({
    required String liderClave,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      print('📊 Obteniendo resumen de visitas LOCAL');

      final visitas = await obtenerVisitasDelLider(liderClave);
      
      // Filtrar por fechas si se proporcionan
      final visitasFiltradas = visitas.where((visita) {
        final fecha = visita.fechaCreacion;
        if (fechaInicio != null && fecha.isBefore(fechaInicio)) return false;
        if (fechaFin != null && fecha.isAfter(fechaFin)) return false;
        return true;
      }).toList();

      // Calcular estadísticas
      final resumen = {
        'totalVisitas': visitasFiltradas.length,
        'visitasCompletadas':
            visitasFiltradas.where((v) => v.estatus == 'completada').length,
        'visitasCanceladas':
            visitasFiltradas.where((v) => v.estatus == 'cancelada').length,
        'visitasActivas':
            visitasFiltradas.where((v) => v.estatus == 'en_proceso').length,
        'duracionPromedio': _calcularDuracionPromedio(visitasFiltradas),
      };

      print('✅ Resumen generado: $resumen');
      return resumen;
    } catch (e) {
      print('❌ Error al generar resumen: $e');
      return {};
    }
  }

  /// Generar clave única para la visita
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

  /// Buscar visita por clienteId y fecha
  Future<VisitaClienteModelo?> buscarVisitaPorClienteYFecha({
    required String clienteId,
    required DateTime fecha,
    required String liderClave,
  }) async {
    try {
      final box = await _getBox();
      print('🔍 Buscando visita para cliente: $clienteId en fecha: ${fecha.toString().split(' ')[0]}');
      
      // Buscar en todos los valores del box
      for (var visita in box.values) {
        if (visita.clienteId == clienteId && 
            visita.liderClave == liderClave &&
            visita.fechaCreacion.year == fecha.year &&
            visita.fechaCreacion.month == fecha.month &&
            visita.fechaCreacion.day == fecha.day) {
          
          print('✅ Visita encontrada:');
          print('   └── VisitaId: ${visita.visitaId}');
          print('   └── Estado: ${visita.estatus}');
          print('   └── CheckOut: ${visita.checkOut != null ? "Sí" : "No"}');
          
          // Convertir directamente desde el modelo Hive
          return VisitaClienteModelo(
            visitaId: visita.visitaId,
            liderClave: visita.liderClave,
            clienteId: visita.clienteId,
            clienteNombre: visita.clienteNombre,
            planId: visita.planId,
            dia: visita.dia,
            fechaCreacion: visita.fechaCreacion,
            checkIn: CheckInModelo(
              timestamp: visita.checkIn.timestamp,
              comentarios: visita.checkIn.comentarios,
              ubicacion: UbicacionModelo(
                latitud: visita.checkIn.ubicacion.latitud,
                longitud: visita.checkIn.ubicacion.longitud,
                precision: visita.checkIn.ubicacion.precision,
                direccion: visita.checkIn.ubicacion.direccion,
              ),
            ),
            checkOut: visita.checkOut != null
                ? CheckOutModelo(
                    timestamp: visita.checkOut!.timestamp,
                    comentarios: visita.checkOut!.comentarios,
                    ubicacion: UbicacionModelo(
                      latitud: visita.checkOut!.ubicacion.latitud,
                      longitud: visita.checkOut!.ubicacion.longitud,
                      precision: visita.checkOut!.ubicacion.precision,
                      direccion: visita.checkOut!.ubicacion.direccion,
                    ),
                    duracionMinutos: visita.checkOut!.duracionMinutos,
                  )
                : null,
            formularios: visita.formularios,
            estatus: visita.estatus,
            fechaModificacion: visita.fechaModificacion,
            fechaFinalizacion: visita.fechaFinalizacion,
            fechaCancelacion: visita.fechaCancelacion,
            motivoCancelacion: visita.motivoCancelacion,
          );
        }
      }
      
      print('❌ No se encontró visita para el cliente $clienteId en la fecha especificada');
      return null;
    } catch (e) {
      print('❌ Error al buscar visita: $e');
      return null;
    }
  }

  /// Crear visita desde una actividad
  Future<VisitaClienteModelo> crearVisitaDesdeActividad({
    required String clienteId,
    required String clienteNombre,
    required String dia,
    required CheckInModelo checkIn,
    required String planId,
  }) async {
    try {
      // Obtener líder actual
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider == null) {
        throw Exception('No hay sesión activa del líder');
      }

      // Generar clave única
      final numeroSemana = _obtenerNumeroSemana();
      final claveVisita = generarClaveVisita(
        liderClave: lider.clave,
        numeroSemana: numeroSemana,
        dia: dia,
        clienteId: clienteId,
      );

      // Crear la visita
      return await crearVisitaConCheckIn(
        claveVisita: claveVisita,
        liderClave: lider.clave,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        planId: planId,
        dia: dia,
        checkIn: checkIn,
      );
    } catch (e) {
      print('❌ Error al crear visita desde actividad: $e');
      rethrow;
    }
  }

  // Métodos auxiliares privados
  int _obtenerNumeroSemana() {
    final ahora = DateTime.now();
    final primerDiaDelAno = DateTime(ahora.year, 1, 1);
    final diferencia = ahora.difference(primerDiaDelAno).inDays;
    return ((diferencia + primerDiaDelAno.weekday) / 7).ceil();
  }

  double _calcularDuracionPromedio(List<VisitaClienteModelo> visitas) {
    final visitasConDuracion = visitas
        .where((v) => v.checkOut != null && v.checkOut!.duracionMinutos > 0)
        .toList();

    if (visitasConDuracion.isEmpty) return 0;

    final sumaDuraciones = visitasConDuracion
        .map((v) => v.checkOut!.duracionMinutos)
        .reduce((a, b) => a + b);

    return sumaDuraciones / visitasConDuracion.length;
  }
}