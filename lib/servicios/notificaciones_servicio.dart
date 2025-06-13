// lib/servicios/notificaciones_servicio.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../modelos/notificacion_modelo.dart';

class NotificacionesServicio {
  static final NotificacionesServicio _instance =
      NotificacionesServicio._internal();
  factory NotificacionesServicio() => _instance;
  NotificacionesServicio._internal();

  static bool _inicializado = false;
  static const String _keyNotificaciones = 'notificaciones_persistentes';

  /// Inicializar el servicio de notificaciones
  static Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      print('🔔 Inicializando servicio de notificaciones persistentes...');
      _inicializado = true;
      print('✅ Servicio de notificaciones inicializado');
    } catch (e) {
      print('❌ Error al inicializar notificaciones: $e');
    }
  }

  /// Mostrar notificación de visita completada y guardarla
  static Future<void> mostrarVisitaCompletada({
    required String clienteNombre,
    required String duracion,
    String? payload,
    Map<String, dynamic>? datosAdicionales,
  }) async {
    try {
      await _asegurarInicializado();

      // Crear notificación persistente
      final notificacion = NotificacionModelo(
        id: 'visita_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '✅ Visita Completada',
        mensaje: 'Cliente: $clienteNombre\nDuración: $duracion',
        tipo: 'visita_completada',
        fechaCreacion: DateTime.now(),
        datos: datosAdicionales,
        accionUrl: '/resumen_visita',
      );

      // Guardar notificación
      await _guardarNotificacion(notificacion);

      print('🔔 NOTIFICACIÓN GUARDADA - Visita Completada');
      print('   └── Cliente: $clienteNombre');
      print('   └── Duración: $duracion');
      print('   └── ID: ${notificacion.id}');

      // Vibración (si está disponible)
      try {
        await HapticFeedback.mediumImpact();
      } catch (e) {
        print('⚠️ Vibración no disponible: $e');
      }

      print('✅ Notificación de visita completada guardada');
    } catch (e) {
      print('❌ Error al mostrar/guardar notificación: $e');
    }
  }

  /// Mostrar notificación de compromiso creado y guardarla
  static Future<void> mostrarCompromisoCreado({
    required String clienteNombre,
    required int cantidadCompromisos,
    String? payload,
    Map<String, dynamic>? datosAdicionales,
  }) async {
    try {
      await _asegurarInicializado();

      // Crear notificación persistente
      final notificacion = NotificacionModelo(
        id: 'compromiso_${DateTime.now().millisecondsSinceEpoch}',
        titulo: '📋 Compromisos Asignados',
        mensaje: '$cantidadCompromisos compromiso(s) para $clienteNombre',
        tipo: 'compromisos_creados',
        fechaCreacion: DateTime.now(),
        datos: datosAdicionales,
      );

      // Guardar notificación
      await _guardarNotificacion(notificacion);

      print('🔔 NOTIFICACIÓN GUARDADA - Compromisos Creados');
      print('   └── Cliente: $clienteNombre');
      print('   └── Cantidad: $cantidadCompromisos');
      print('   └── ID: ${notificacion.id}');

      print('✅ Notificación de compromisos guardada');
    } catch (e) {
      print('❌ Error al mostrar/guardar notificación de compromisos: $e');
    }
  }

  /// Mostrar notificación de sincronización y guardarla
  static Future<void> mostrarSincronizacion({
    required String mensaje,
    bool esError = false,
  }) async {
    try {
      await _asegurarInicializado();

      // Solo guardar errores importantes, no sincronizaciones exitosas rutinarias
      if (esError) {
        final notificacion = NotificacionModelo(
          id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
          titulo: '⚠️ Error de Sincronización',
          mensaje: mensaje,
          tipo: 'sincronizacion_error',
          fechaCreacion: DateTime.now(),
        );

        await _guardarNotificacion(notificacion);
      }

      print('🔔 NOTIFICACIÓN SINCRONIZACIÓN');
      print('   └── Mensaje: $mensaje');
      print('   └── Es error: $esError');
    } catch (e) {
      print('❌ Error al mostrar notificación de sincronización: $e');
    }
  }

  /// Solicitar permisos de notificación
  static Future<bool> solicitarPermisos() async {
    try {
      await _asegurarInicializado();
      print('🔔 Permisos de notificación "concedidos"');
      return true;
    } catch (e) {
      print('❌ Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Obtener todas las notificaciones guardadas
  static Future<List<NotificacionModelo>> obtenerNotificaciones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificacionesJson = prefs.getString(_keyNotificaciones);

      if (notificacionesJson == null) return [];

      final List<dynamic> notificacionesList = jsonDecode(notificacionesJson);
      final List<NotificacionModelo> notificaciones =
          notificacionesList
              .map((json) => NotificacionModelo.fromJson(json))
              .toList();

      // Ordenar por fecha (más reciente primero)
      notificaciones.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      return notificaciones;
    } catch (e) {
      print('❌ Error al obtener notificaciones: $e');
      return [];
    }
  }

  /// Obtener notificaciones no leídas
  static Future<List<NotificacionModelo>> obtenerNoLeidas() async {
    final todasLasNotificaciones = await obtenerNotificaciones();
    return todasLasNotificaciones.where((n) => !n.leida).toList();
  }

  /// Obtener cantidad de notificaciones no leídas
  static Future<int> contarNoLeidas() async {
    final noLeidas = await obtenerNoLeidas();
    return noLeidas.length;
  }

  /// Marcar notificación como leída
  static Future<void> marcarComoLeida(String notificacionId) async {
    try {
      final notificaciones = await obtenerNotificaciones();
      final index = notificaciones.indexWhere((n) => n.id == notificacionId);

      if (index != -1) {
        notificaciones[index] = notificaciones[index].marcarComoLeida();
        await _guardarTodasLasNotificaciones(notificaciones);
        print('✅ Notificación $notificacionId marcada como leída');
      }
    } catch (e) {
      print('❌ Error al marcar como leída: $e');
    }
  }

  /// Marcar todas como leídas
  static Future<void> marcarTodasComoLeidas() async {
    try {
      final notificaciones = await obtenerNotificaciones();
      final notificacionesLeidas =
          notificaciones.map((n) => n.copyWith(leida: true)).toList();

      await _guardarTodasLasNotificaciones(notificacionesLeidas);
      print('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      print('❌ Error al marcar todas como leídas: $e');
    }
  }

  /// Eliminar notificación
  static Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      final notificaciones = await obtenerNotificaciones();
      notificaciones.removeWhere((n) => n.id == notificacionId);
      await _guardarTodasLasNotificaciones(notificaciones);
      print('✅ Notificación $notificacionId eliminada');
    } catch (e) {
      print('❌ Error al eliminar notificación: $e');
    }
  }

  /// Limpiar notificaciones antiguas (más de 30 días)
  static Future<void> limpiarNotificacionesAntiguas() async {
    try {
      final notificaciones = await obtenerNotificaciones();
      final fechaLimite = DateTime.now().subtract(const Duration(days: 30));

      final notificacionesRecientes =
          notificaciones
              .where((n) => n.fechaCreacion.isAfter(fechaLimite))
              .toList();

      await _guardarTodasLasNotificaciones(notificacionesRecientes);

      final eliminadas = notificaciones.length - notificacionesRecientes.length;
      if (eliminadas > 0) {
        print('🧹 $eliminadas notificaciones antiguas eliminadas');
      }
    } catch (e) {
      print('❌ Error al limpiar notificaciones: $e');
    }
  }

  /// Cancelar todas las notificaciones (limpiar historial)
  static Future<void> cancelarTodas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyNotificaciones);
      print('🔔 Todas las notificaciones eliminadas');
    } catch (e) {
      print('❌ Error al cancelar notificaciones: $e');
    }
  }

  /// Mostrar notificación visual en la app (alternativa a notificaciones push)
  static void mostrarNotificacionEnApp(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    Color? color,
    VoidCallback? onTap,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mensaje,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: color ?? const Color(0xFFDE1327),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action:
            onTap != null
                ? SnackBarAction(
                  label: 'Ver',
                  textColor: Colors.white,
                  onPressed: onTap,
                )
                : null,
        margin: const EdgeInsets.all(16),
      ),
    );

    // Vibración para feedback
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('⚠️ Vibración no disponible');
    }
  }

  /// Mostrar notificación de visita completada en la app
  static void mostrarVisitaCompletadaEnApp(
    BuildContext context, {
    required String clienteNombre,
    required String duracion,
    VoidCallback? onVerResumen,
  }) {
    mostrarNotificacionEnApp(
      context,
      titulo: '✅ Visita Completada',
      mensaje:
          'Cliente: $clienteNombre\nDuración: $duracion\n(Guardado en notificaciones)',
      color: const Color(0xFF38A169), // Verde
      onTap: onVerResumen,
    );
  }

  /// Mostrar notificación de compromisos en la app
  static void mostrarCompromisosEnApp(
    BuildContext context, {
    required String clienteNombre,
    required int cantidad,
  }) {
    mostrarNotificacionEnApp(
      context,
      titulo: '📋 Compromisos Asignados',
      mensaje:
          '$cantidad compromiso(s) para $clienteNombre\n(Guardado en notificaciones)',
      color: const Color(0xFF38A169), // Verde
    );
  }

  // Métodos privados

  /// Guardar una notificación individual
  static Future<void> _guardarNotificacion(
    NotificacionModelo notificacion,
  ) async {
    try {
      final notificaciones = await obtenerNotificaciones();
      notificaciones.insert(0, notificacion); // Agregar al principio

      // Mantener solo las últimas 100 notificaciones
      if (notificaciones.length > 100) {
        notificaciones.removeRange(100, notificaciones.length);
      }

      await _guardarTodasLasNotificaciones(notificaciones);
    } catch (e) {
      print('❌ Error al guardar notificación individual: $e');
    }
  }

  /// Guardar todas las notificaciones
  static Future<void> _guardarTodasLasNotificaciones(
    List<NotificacionModelo> notificaciones,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificacionesJson = jsonEncode(
        notificaciones.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_keyNotificaciones, notificacionesJson);
    } catch (e) {
      print('❌ Error al guardar todas las notificaciones: $e');
    }
  }

  /// Asegurar que el servicio esté inicializado
  static Future<void> _asegurarInicializado() async {
    if (!_inicializado) {
      await inicializar();
    }
  }
}
