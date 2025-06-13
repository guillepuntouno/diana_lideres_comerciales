// lib/modelos/visita_cliente_modelo.dart

/// Modelo principal de la visita al cliente
class VisitaClienteModelo {
  final String visitaId;
  final String liderClave;
  final String clienteId;
  final String clienteNombre;
  final String planId;
  final String dia;
  final DateTime fechaCreacion;
  final CheckInModelo checkIn;
  final CheckOutModelo? checkOut;
  final Map<String, dynamic> formularios;
  final String estatus; // 'en_proceso', 'completada', 'cancelada'
  final DateTime? fechaModificacion;
  final DateTime? fechaFinalizacion;
  final DateTime? fechaCancelacion;
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

  /// Crear desde JSON del servidor
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

  /// Convertir a JSON para envío al servidor
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

  /// Helper para parsear fechas de manera segura
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

  /// Verificar si la visita está en proceso
  bool get estaEnProceso => estatus == 'en_proceso';

  /// Verificar si la visita está completada
  bool get estaCompletada => estatus == 'completada';

  /// Verificar si la visita está cancelada
  bool get estaCancelada => estatus == 'cancelada';

  /// Calcular duración de la visita (si está completada)
  Duration? get duracion {
    if (checkOut == null) return null;
    return checkOut!.timestamp.difference(checkIn.timestamp);
  }

  /// Obtener duración en minutos
  int? get duracionMinutos {
    final d = duracion;
    return d?.inMinutes;
  }

  @override
  String toString() =>
      'VisitaClienteModelo(visitaId: $visitaId, estatus: $estatus)';
}

/// Modelo para el check-in (inicio de visita)
class CheckInModelo {
  final DateTime timestamp;
  final String comentarios;
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

/// Modelo para el check-out (finalización de visita)
class CheckOutModelo {
  final DateTime timestamp;
  final String comentarios;
  final UbicacionModelo ubicacion;
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

/// Modelo para la ubicación GPS
class UbicacionModelo {
  final double latitud;
  final double longitud;
  final double precision;
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

  /// Verificar si la ubicación es válida
  bool get esValida => latitud != 0.0 && longitud != 0.0;

  /// Obtener coordenadas como String
  String get coordenadas =>
      'Lat: ${latitud.toStringAsFixed(6)}, Lng: ${longitud.toStringAsFixed(6)}';

  @override
  String toString() =>
      'UbicacionModelo($coordenadas, precisión: ${precision}m)';
}

/// Clase auxiliar para crear check-in fácilmente
class CheckInBuilder {
  String _comentarios = '';
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

/// Clase auxiliar para crear check-out fácilmente
class CheckOutBuilder {
  String _comentarios = '';
  UbicacionModelo? _ubicacion;
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
