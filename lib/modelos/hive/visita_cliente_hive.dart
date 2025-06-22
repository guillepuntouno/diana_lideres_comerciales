import 'package:hive/hive.dart';
import 'datetime_helper.dart';

part 'visita_cliente_hive.g.dart';

@HiveType(typeId: 4)
class VisitaClienteHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String visitaId;

  @HiveField(2)
  String liderClave;

  @HiveField(3)
  String clienteId;

  @HiveField(4)
  String clienteNombre;

  @HiveField(5)
  String planId;

  @HiveField(6)
  String dia;

  @HiveField(7)
  DateTime fechaCreacion;

  @HiveField(8)
  CheckInHive checkIn;

  @HiveField(9)
  CheckOutHive? checkOut;

  @HiveField(10)
  Map<String, dynamic> formularios;

  @HiveField(11)
  String estatus;

  @HiveField(12)
  DateTime? fechaModificacion;

  @HiveField(13)
  DateTime? fechaFinalizacion;

  @HiveField(14)
  DateTime? fechaCancelacion;

  @HiveField(15)
  String? motivoCancelacion;

  @HiveField(16)
  String syncStatus;

  @HiveField(17)
  DateTime lastUpdated;

  VisitaClienteHive({
    required this.id,
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
    this.syncStatus = 'pending',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory VisitaClienteHive.fromJson(Map<String, dynamic> json) {
    return VisitaClienteHive(
      id: json['id'] ?? json['Id'] ?? '',
      visitaId: json['VisitaId'] ?? json['visitaId'] ?? '',
      liderClave: json['LiderClave'] ?? json['liderClave'] ?? '',
      clienteId: json['ClienteId'] ?? json['clienteId'] ?? '',
      clienteNombre: json['ClienteNombre'] ?? json['clienteNombre'] ?? '',
      planId: json['PlanId'] ?? json['planId'] ?? '',
      dia: json['Dia'] ?? json['dia'] ?? '',
      fechaCreacion: DateTimeHelper.parseDateTimeWithFallback(json['FechaCreacion'] ?? json['fechaCreacion']),
      checkIn: CheckInHive.fromJson(json['CheckIn'] ?? json['checkIn'] ?? {}),
      checkOut: json['CheckOut'] != null || json['checkOut'] != null
          ? CheckOutHive.fromJson(json['CheckOut'] ?? json['checkOut'])
          : null,
      formularios: Map<String, dynamic>.from(json['Formularios'] ?? json['formularios'] ?? {}),
      estatus: json['Estatus'] ?? json['estatus'] ?? 'en_proceso',
      fechaModificacion: DateTimeHelper.parseDateTime(json['FechaModificacion'] ?? json['fechaModificacion']),
      fechaFinalizacion: DateTimeHelper.parseDateTime(json['FechaFinalizacion'] ?? json['fechaFinalizacion']),
      fechaCancelacion: DateTimeHelper.parseDateTime(json['FechaCancelacion'] ?? json['fechaCancelacion']),
      motivoCancelacion: json['MotivoCancelacion'] ?? json['motivoCancelacion'],
      syncStatus: json['syncStatus'] ?? 'pending',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitaId': visitaId,
      'liderClave': liderClave,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'planId': planId,
      'dia': dia,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'checkIn': checkIn.toJson(),
      'checkOut': checkOut?.toJson(),
      'formularios': formularios,
      'estatus': estatus,
      'fechaModificacion': fechaModificacion?.toIso8601String(),
      'fechaFinalizacion': fechaFinalizacion?.toIso8601String(),
      'fechaCancelacion': fechaCancelacion?.toIso8601String(),
      'motivoCancelacion': motivoCancelacion,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }


  bool get estaEnProceso => estatus == 'en_proceso';
  bool get estaCompletada => estatus == 'completada';
  bool get estaCancelada => estatus == 'cancelada';
  bool get requiresSync => syncStatus == 'pending';
}

@HiveType(typeId: 5)
class CheckInHive extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String comentarios;

  @HiveField(2)
  UbicacionHive ubicacion;

  CheckInHive({
    required this.timestamp,
    required this.comentarios,
    required this.ubicacion,
  });

  factory CheckInHive.fromJson(Map<String, dynamic> json) {
    return CheckInHive(
      timestamp: DateTimeHelper.parseDateTimeWithFallback(json['Timestamp'] ?? json['timestamp']),
      comentarios: json['Comentarios'] ?? json['comentarios'] ?? '',
      ubicacion: UbicacionHive.fromJson(json['Ubicacion'] ?? json['ubicacion'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'comentarios': comentarios,
      'ubicacion': ubicacion.toJson(),
    };
  }

}

@HiveType(typeId: 6)
class CheckOutHive extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String comentarios;

  @HiveField(2)
  UbicacionHive ubicacion;

  @HiveField(3)
  int duracionMinutos;

  CheckOutHive({
    required this.timestamp,
    required this.comentarios,
    required this.ubicacion,
    required this.duracionMinutos,
  });

  factory CheckOutHive.fromJson(Map<String, dynamic> json) {
    return CheckOutHive(
      timestamp: DateTimeHelper.parseDateTimeWithFallback(json['Timestamp'] ?? json['timestamp']),
      comentarios: json['Comentarios'] ?? json['comentarios'] ?? '',
      ubicacion: UbicacionHive.fromJson(json['Ubicacion'] ?? json['ubicacion'] ?? {}),
      duracionMinutos: json['DuracionMinutos'] ?? json['duracionMinutos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'comentarios': comentarios,
      'ubicacion': ubicacion.toJson(),
      'duracionMinutos': duracionMinutos,
    };
  }

}

@HiveType(typeId: 7)
class UbicacionHive extends HiveObject {
  @HiveField(0)
  double latitud;

  @HiveField(1)
  double longitud;

  @HiveField(2)
  double precision;

  @HiveField(3)
  String direccion;

  UbicacionHive({
    required this.latitud,
    required this.longitud,
    required this.precision,
    required this.direccion,
  });

  factory UbicacionHive.fromJson(Map<String, dynamic> json) {
    return UbicacionHive(
      latitud: _parseDouble(json['Latitud'] ?? json['latitud']),
      longitud: _parseDouble(json['Longitud'] ?? json['longitud']),
      precision: _parseDouble(json['Precision'] ?? json['precision']),
      direccion: json['Direccion'] ?? json['direccion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'precision': precision,
      'direccion': direccion,
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

  bool get esValida => latitud != 0.0 && longitud != 0.0;
  String get coordenadas => 'Lat: ${latitud.toStringAsFixed(6)}, Lng: ${longitud.toStringAsFixed(6)}';
}