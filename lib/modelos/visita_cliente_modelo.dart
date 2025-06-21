// lib/modelos/visita_cliente_modelo.dart

/// Modelo principal para gestión de visitas a clientes.
/// 
/// Representa una visita completa desde check-in hasta check-out,
/// incluyendo formularios dinámicos y control de estados según
/// reglas de negocio del sistema DIANA.
class VisitaClienteModelo {
  /// Identificador único de la visita generado por el sistema.
  final String visitaId;
  
  /// Clave del líder comercial responsable de la visita.
  final String liderClave;
  
  /// Identificador del cliente visitado según catálogo maestro.
  final String clienteId;
  
  /// Nombre completo del cliente para visualización.
  final String clienteNombre;
  
  /// ID del plan de trabajo al que pertenece esta visita.
  final String planId;
  
  /// Día de la semana asignado (lunes-domingo) según plan.
  final String dia;
  
  /// Timestamp de creación del registro de visita.
  final DateTime fechaCreacion;
  
  /// Datos del check-in obligatorio al iniciar visita.
  final CheckInModelo checkIn;
  
  /// Datos del check-out, null mientras visita esté activa.
  final CheckOutModelo? checkOut;
  
  /// Formularios dinámicos completados durante la visita.
  /// Key: ID formulario, Value: respuestas estructuradas.
  final Map<String, dynamic> formularios;
  
  /// Estado actual: 'en_proceso', 'completada', 'cancelada'.
  /// Define permisos de edición según reglas de negocio.
  final String estatus;
  
  /// Última modificación del registro.
  final DateTime? fechaModificacion;
  
  /// Timestamp cuando se completó la visita.
  final DateTime? fechaFinalizacion;
  
  /// Timestamp de cancelación si aplica.
  final DateTime? fechaCancelacion;
  
  /// Justificación requerida al cancelar visita.
  final String? motivoCancelacion;

  VisitaClienteModelo({
    required this.visitaId,
    required this.liderClave,
    required this.clienteId,
    required this.clienteNombre,
    required this.planId,
    required this.dia,
    required this.fechaCreacion,
    required this.checkIn,
    this.checkOut,
    required this.formularios,
    required this.estatus,
    this.fechaModificacion,
    this.fechaFinalizacion,
    this.fechaCancelacion,
    this.motivoCancelacion,
  });

  /// Constructor desde JSON del backend.
  /// Maneja campos opcionales y validaciones de formato.
  factory VisitaClienteModelo.fromJson(Map<String, dynamic> json) {
    return VisitaClienteModelo(
      visitaId: json['VisitaId'] ?? '',
      liderClave: json['LiderClave'] ?? '',
      clienteId: json['ClienteId'] ?? '',
      clienteNombre: json['ClienteNombre'] ?? '',
      planId: json['PlanId'] ?? '',
      dia: json['Dia'] ?? '',
      fechaCreacion: _parseDateTime(json['FechaCreacion']),
      checkIn: CheckInModelo.fromJson(json['CheckIn'] ?? {}),
      checkOut:
          json['CheckOut'] != null
              ? CheckOutModelo.fromJson(json['CheckOut'])
              : null,
      formularios: Map<String, dynamic>.from(json['Formularios'] ?? {}),
      estatus: json['Estatus'] ?? 'en_proceso',
      fechaModificacion: _parseDateTime(json['FechaModificacion']),
      fechaFinalizacion: _parseDateTime(json['FechaFinalizacion']),
      fechaCancelacion: _parseDateTime(json['FechaCancelacion']),
      motivoCancelacion: json['MotivoCancelacion'],
    );
  }

  /// Serialización a JSON para API REST.
  /// Formato compatible con endpoints de sincronización.
  Map<String, dynamic> toJson() {
    return {
      'VisitaId': visitaId,
      'LiderClave': liderClave,
      'ClienteId': clienteId,
      'ClienteNombre': clienteNombre,
      'PlanId': planId,
      'Dia': dia,
      'FechaCreacion': fechaCreacion.toIso8601String(),
      'CheckIn': checkIn.toJson(),
      'CheckOut': checkOut?.toJson(),
      'Formularios': formularios,
      'Estatus': estatus,
      'FechaModificacion': fechaModificacion?.toIso8601String(),
      'FechaFinalizacion': fechaFinalizacion?.toIso8601String(),
      'FechaCancelacion': fechaCancelacion?.toIso8601String(),
      'MotivoCancelacion': motivoCancelacion,
    };
  }

  /// Parser robusto de fechas desde múltiples formatos.
  /// Retorna DateTime.now() como fallback para evitar nulls.
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (dateValue is DateTime) return dateValue;

    return DateTime.now();
  }

  /// Visita activa, permite edición de formularios.
  bool get estaEnProceso => estatus == 'en_proceso';

  /// Visita finalizada con check-out, solo lectura.
  bool get estaCompletada => estatus == 'completada';

  /// Visita cancelada con justificación, inmutable.
  bool get estaCancelada => estatus == 'cancelada';

  /// Duración total entre check-in y check-out.
  /// Null si visita aún activa.
  Duration? get duracion {
    if (checkOut == null) return null;
    return checkOut!.timestamp.difference(checkIn.timestamp);
  }

  /// Duración en minutos para reportes de productividad.
  int? get duracionMinutos {
    final d = duracion;
    return d?.inMinutes;
  }

  @override
  String toString() =>
      'VisitaClienteModelo(visitaId: $visitaId, estatus: $estatus)';
}

/// Registro de inicio de visita con validación GPS.
/// 
/// Captura ubicación exacta y timestamp para control
/// de asistencia y cumplimiento de rutas.
class CheckInModelo {
  /// Momento exacto del check-in para auditoría.
  final DateTime timestamp;
  
  /// Observaciones del líder al iniciar visita.
  final String comentarios;
  
  /// Coordenadas GPS validadas del punto de check-in.
  final UbicacionModelo ubicacion;

  CheckInModelo({
    required this.timestamp,
    required this.comentarios,
    required this.ubicacion,
  });

  factory CheckInModelo.fromJson(Map<String, dynamic> json) {
    return CheckInModelo(
      timestamp: _parseDateTime(json['Timestamp']),
      comentarios: json['Comentarios'] ?? '',
      ubicacion: UbicacionModelo.fromJson(json['Ubicacion'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Timestamp': timestamp.toIso8601String(),
      'Comentarios': comentarios,
      'Ubicacion': ubicacion.toJson(),
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return dateValue is DateTime ? dateValue : DateTime.now();
  }

  @override
  String toString() => 'CheckInModelo(timestamp: $timestamp)';
}

/// Registro de finalización de visita.
/// 
/// Cierra el ciclo de visita calculando duración
/// y validando ubicación de salida.
class CheckOutModelo {
  /// Momento exacto del check-out.
  final DateTime timestamp;
  
  /// Resumen o conclusiones de la visita.
  final String comentarios;
  
  /// Coordenadas GPS del punto de salida.
  final UbicacionModelo ubicacion;
  
  /// Duración calculada automáticamente en minutos.
  final int duracionMinutos;

  CheckOutModelo({
    required this.timestamp,
    required this.comentarios,
    required this.ubicacion,
    required this.duracionMinutos,
  });

  factory CheckOutModelo.fromJson(Map<String, dynamic> json) {
    return CheckOutModelo(
      timestamp: _parseDateTime(json['Timestamp']),
      comentarios: json['Comentarios'] ?? '',
      ubicacion: UbicacionModelo.fromJson(json['Ubicacion'] ?? {}),
      duracionMinutos: json['DuracionMinutos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Timestamp': timestamp.toIso8601String(),
      'Comentarios': comentarios,
      'Ubicacion': ubicacion.toJson(),
      'DuracionMinutos': duracionMinutos,
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return dateValue is DateTime ? dateValue : DateTime.now();
  }

  @override
  String toString() =>
      'CheckOutModelo(timestamp: $timestamp, duracion: ${duracionMinutos}min)';
}

/// Datos de geolocalización para trazabilidad.
/// 
/// Valida coordenadas y precisión según políticas
/// de verificación de asistencia en campo.
class UbicacionModelo {
  /// Latitud en grados decimales WGS84.
  final double latitud;
  
  /// Longitud en grados decimales WGS84.
  final double longitud;
  
  /// Precisión del GPS en metros.
  final double precision;
  
  /// Dirección geocodificada para referencia.
  final String direccion;

  UbicacionModelo({
    required this.latitud,
    required this.longitud,
    required this.precision,
    required this.direccion,
  });

  factory UbicacionModelo.fromJson(Map<String, dynamic> json) {
    return UbicacionModelo(
      latitud: _parseDouble(json['Latitud']),
      longitud: _parseDouble(json['Longitud']),
      precision: _parseDouble(json['Precision']),
      direccion: json['Direccion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Latitud': latitud,
      'Longitud': longitud,
      'Precision': precision,
      'Direccion': direccion,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }

    return 0.0;
  }

  /// Valida coordenadas no-cero para control de calidad.
  bool get esValida => latitud != 0.0 && longitud != 0.0;

  /// Formato legible de coordenadas para UI.
  String get coordenadas =>
      'Lat: ${latitud.toStringAsFixed(6)}, Lng: ${longitud.toStringAsFixed(6)}';

  @override
  String toString() =>
      'UbicacionModelo($coordenadas, precisión: ${precision}m)';
}

/// Builder pattern para construcción de check-in.
/// 
/// Facilita creación con validaciones requeridas
/// según reglas de negocio.
class CheckInBuilder {
  /// Comentarios opcionales del check-in.
  String _comentarios = '';
  
  /// Ubicación requerida para validar presencia.
  UbicacionModelo? _ubicacion;

  CheckInBuilder comentarios(String comentarios) {
    _comentarios = comentarios;
    return this;
  }

  CheckInBuilder ubicacion({
    required double latitud,
    required double longitud,
    required double precision,
    required String direccion,
  }) {
    _ubicacion = UbicacionModelo(
      latitud: latitud,
      longitud: longitud,
      precision: precision,
      direccion: direccion,
    );
    return this;
  }

  CheckInModelo build() {
    if (_ubicacion == null) {
      throw Exception('La ubicación es requerida para el check-in');
    }

    return CheckInModelo(
      timestamp: DateTime.now(),
      comentarios: _comentarios,
      ubicacion: _ubicacion!,
    );
  }
}

/// Builder pattern para construcción de check-out.
/// 
/// Calcula duración automáticamente basado en
/// timestamp de inicio proporcionado.
class CheckOutBuilder {
  /// Resumen o conclusiones de la visita.
  String _comentarios = '';
  
  /// Ubicación de salida requerida.
  UbicacionModelo? _ubicacion;
  
  /// Timestamp del check-in para cálculo de duración.
  DateTime? _inicioVisita;

  CheckOutBuilder comentarios(String comentarios) {
    _comentarios = comentarios;
    return this;
  }

  CheckOutBuilder ubicacion({
    required double latitud,
    required double longitud,
    required double precision,
    required String direccion,
  }) {
    _ubicacion = UbicacionModelo(
      latitud: latitud,
      longitud: longitud,
      precision: precision,
      direccion: direccion,
    );
    return this;
  }

  CheckOutBuilder inicioVisita(DateTime inicio) {
    _inicioVisita = inicio;
    return this;
  }

  CheckOutModelo build() {
    if (_ubicacion == null) {
      throw Exception('La ubicación es requerida para el check-out');
    }

    final ahora = DateTime.now();
    final duracion =
        _inicioVisita != null ? ahora.difference(_inicioVisita!).inMinutes : 0;

    return CheckOutModelo(
      timestamp: ahora,
      comentarios: _comentarios,
      ubicacion: _ubicacion!,
      duracionMinutos: duracion,
    );
  }
}
