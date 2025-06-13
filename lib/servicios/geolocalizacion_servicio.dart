// lib/servicios/geolocalizacion_servicio.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeolocalizacionServicio {
  static final GeolocalizacionServicio _instance =
      GeolocalizacionServicio._internal();
  factory GeolocalizacionServicio() => _instance;
  GeolocalizacionServicio._internal();

  /// Obtener ubicación de manera universal (Web + Móvil)
  Future<GeolocalizacionResultado> obtenerUbicacion() async {
    try {
      print('🌐 Plataforma: ${kIsWeb ? "WEB" : "MÓVIL"}');

      if (kIsWeb) {
        return await _obtenerUbicacionWeb();
      } else {
        return await _obtenerUbicacionMovil();
      }
    } catch (e) {
      print('❌ Error general en geolocalización: $e');
      return GeolocalizacionResultado.error('Error inesperado: $e');
    }
  }

  /// Geolocalización específica para WEB
  Future<GeolocalizacionResultado> _obtenerUbicacionWeb() async {
    try {
      print('🌐 Iniciando geolocalización WEB...');

      // En web, verificar si el servicio está disponible
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return GeolocalizacionResultado.error(
          'La geolocalización no está disponible en este navegador',
        );
      }

      // En web, la verificación de permisos es más simple
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('🔐 Solicitando permisos en web...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeolocalizacionResultado.error(
            'Permisos de ubicación denegados. Habilítelos en la configuración del navegador.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeolocalizacionResultado.error(
          'Los permisos de ubicación están bloqueados. Habilítelos en la configuración del navegador.',
        );
      }

      // Obtener posición con configuración compatible
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 20), // Más tiempo para web
        onTimeout: () {
          throw Exception(
            'Timeout - El navegador no pudo obtener la ubicación',
          );
        },
      );

      print('✅ Ubicación obtenida en WEB:');
      print('   └── Lat: ${position.latitude}');
      print('   └── Lng: ${position.longitude}');
      print('   └── Precisión: ${position.accuracy} metros');

      return GeolocalizacionResultado.exitoso(
        latitud: position.latitude,
        longitud: position.longitude,
        precision: position.accuracy,
        direccion:
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      print('❌ Error en geolocalización WEB: $e');

      String mensajeUsuario;
      if (e.toString().contains('Timeout')) {
        mensajeUsuario =
            'El navegador no pudo obtener la ubicación. Intente nuevamente.';
      } else if (e.toString().contains('permission')) {
        mensajeUsuario =
            'Permisos de ubicación requeridos. Habilítelos en su navegador.';
      } else {
        mensajeUsuario = 'Error de geolocalización en el navegador.';
      }

      return GeolocalizacionResultado.error(mensajeUsuario);
    }
  }

  /// Geolocalización específica para MÓVIL (Android/iOS)
  Future<GeolocalizacionResultado> _obtenerUbicacionMovil() async {
    try {
      print('📱 Iniciando geolocalización MÓVIL...');

      // Verificar servicio de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return GeolocalizacionResultado.errorConAccion(
          'El servicio de ubicación está deshabilitado',
          accion: AccionRequerida.abrirConfiguracion,
        );
      }

      // Verificar y solicitar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeolocalizacionResultado.errorConAccion(
            'Permisos de ubicación denegados',
            accion: AccionRequerida.solicitarPermisos,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeolocalizacionResultado.errorConAccion(
          'Los permisos están bloqueados permanentemente',
          accion: AccionRequerida.abrirConfiguracionApp,
        );
      }

      // Obtener posición con API compatible
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout al obtener ubicación GPS');
        },
      );

      print('✅ Ubicación obtenida en MÓVIL:');
      print('   └── Lat: ${position.latitude}');
      print('   └── Lng: ${position.longitude}');
      print('   └── Precisión: ${position.accuracy} metros');

      return GeolocalizacionResultado.exitoso(
        latitud: position.latitude,
        longitud: position.longitude,
        precision: position.accuracy,
        direccion:
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      print('❌ Error en geolocalización MÓVIL: $e');

      String mensajeUsuario;
      if (e.toString().contains('Timeout')) {
        mensajeUsuario =
            'No se pudo obtener la ubicación GPS. Verifique su señal.';
      } else {
        mensajeUsuario = 'Error al obtener ubicación.';
      }

      return GeolocalizacionResultado.error(mensajeUsuario);
    }
  }

  /// Abrir configuración según la plataforma
  Future<void> abrirConfiguracion(AccionRequerida accion) async {
    try {
      if (kIsWeb) {
        // En web no podemos abrir configuración, solo mostrar mensaje
        print('ℹ️ En web: mostrar instrucciones al usuario');
        return;
      }

      // Solo importar permission_handler en móvil
      switch (accion) {
        case AccionRequerida.abrirConfiguracion:
          await Geolocator.openLocationSettings();
          break;
        case AccionRequerida.abrirConfiguracionApp:
          // Importación condicional para móvil
          if (!kIsWeb) {
            final permissionHandler = await import(
              'package:permission_handler/permission_handler.dart',
            );
            await permissionHandler.openAppSettings();
          }
          break;
        case AccionRequerida.solicitarPermisos:
          // Ya se maneja en el flujo principal
          break;
      }
    } catch (e) {
      print('Error al abrir configuración: $e');
    }
  }
}

/// Resultado de la geolocalización
class GeolocalizacionResultado {
  final bool exitoso;
  final double? latitud;
  final double? longitud;
  final double? precision;
  final String? direccion;
  final String? mensajeError;
  final AccionRequerida? accionRequerida;

  GeolocalizacionResultado._({
    required this.exitoso,
    this.latitud,
    this.longitud,
    this.precision,
    this.direccion,
    this.mensajeError,
    this.accionRequerida,
  });

  factory GeolocalizacionResultado.exitoso({
    required double latitud,
    required double longitud,
    required double precision,
    required String direccion,
  }) {
    return GeolocalizacionResultado._(
      exitoso: true,
      latitud: latitud,
      longitud: longitud,
      precision: precision,
      direccion: direccion,
    );
  }

  factory GeolocalizacionResultado.error(String mensaje) {
    return GeolocalizacionResultado._(exitoso: false, mensajeError: mensaje);
  }

  factory GeolocalizacionResultado.errorConAccion(
    String mensaje, {
    required AccionRequerida accion,
  }) {
    return GeolocalizacionResultado._(
      exitoso: false,
      mensajeError: mensaje,
      accionRequerida: accion,
    );
  }
}

/// Acciones que puede requerir el usuario
enum AccionRequerida {
  abrirConfiguracion,
  abrirConfiguracionApp,
  solicitarPermisos,
}

/// Función auxiliar para importación condicional
Future<dynamic> import(String package) async {
  // Esto es un placeholder - Flutter maneja las importaciones en compilación
  return {};
}
