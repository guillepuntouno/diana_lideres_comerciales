import 'package:hive/hive.dart';
import 'datetime_helper.dart';

part 'plan_trabajo_hive.g.dart';

@HiveType(typeId: 8)
class PlanTrabajoHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String liderClave;

  @HiveField(2)
  DateTime fechaPlan;

  @HiveField(3)
  String estatus;

  @HiveField(4)
  List<VisitaPlanificadaHive> visitasPlanificadas;

  @HiveField(5)
  DateTime? fechaInicio;

  @HiveField(6)
  DateTime? fechaFinalizacion;

  @HiveField(7)
  String? observaciones;

  @HiveField(8)
  String syncStatus;

  @HiveField(9)
  DateTime lastUpdated;

  PlanTrabajoHive({
    required this.id,
    required this.liderClave,
    required this.fechaPlan,
    required this.estatus,
    required this.visitasPlanificadas,
    this.fechaInicio,
    this.fechaFinalizacion,
    this.observaciones,
    this.syncStatus = 'pending',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory PlanTrabajoHive.fromJson(Map<String, dynamic> json) {
    List<VisitaPlanificadaHive> visitasList = [];
    final visitasData = json['visitasPlanificadas'] ?? json['VisitasPlanificadas'];
    if (visitasData != null && visitasData is List) {
      visitasList = visitasData
          .map<VisitaPlanificadaHive>((visitaJson) => VisitaPlanificadaHive.fromJson(visitaJson as Map<String, dynamic>))
          .toList();
    }

    return PlanTrabajoHive(
      id: json['id'] ?? json['Id'] ?? '',
      liderClave: json['liderClave'] ?? json['LiderClave'] ?? '',
      fechaPlan: DateTimeHelper.parseDateTimeWithFallback(json['fechaPlan'] ?? json['FechaPlan']),
      estatus: json['estatus'] ?? json['Estatus'] ?? 'pendiente',
      visitasPlanificadas: visitasList,
      fechaInicio: DateTimeHelper.parseDateTime(json['fechaInicio'] ?? json['FechaInicio']),
      fechaFinalizacion: DateTimeHelper.parseDateTime(json['fechaFinalizacion'] ?? json['FechaFinalizacion']),
      observaciones: json['observaciones'] ?? json['Observaciones'],
      syncStatus: json['syncStatus'] ?? 'pending',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liderClave': liderClave,
      'fechaPlan': fechaPlan.toIso8601String(),
      'estatus': estatus,
      'visitasPlanificadas': visitasPlanificadas.map((visita) => visita.toJson()).toList(),
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFinalizacion': fechaFinalizacion?.toIso8601String(),
      'observaciones': observaciones,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }


  bool get estaActivo => estatus == 'activo';
  bool get estaCompletado => estatus == 'completado';
  bool get estaPendiente => estatus == 'pendiente';
  bool get requiresSync => syncStatus == 'pending';

  int get totalVisitas => visitasPlanificadas.length;
  int get visitasCompletadas => visitasPlanificadas.where((v) => v.completada).length;
  double get porcentajeCompletado => totalVisitas > 0 ? (visitasCompletadas / totalVisitas) * 100 : 0.0;
}

@HiveType(typeId: 9)
class VisitaPlanificadaHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String clienteId;

  @HiveField(2)
  String clienteNombre;

  @HiveField(3)
  String clienteDireccion;

  @HiveField(4)
  DateTime horaEstimada;

  @HiveField(5)
  int duracionEstimadaMinutos;

  @HiveField(6)
  String tipoVisita;

  @HiveField(7)
  String prioridad;

  @HiveField(8)
  bool completada;

  @HiveField(9)
  DateTime? horaInicioReal;

  @HiveField(10)
  DateTime? horaFinReal;

  @HiveField(11)
  String? observaciones;

  @HiveField(12)
  String syncStatus;

  @HiveField(13)
  DateTime lastUpdated;

  VisitaPlanificadaHive({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteDireccion,
    required this.horaEstimada,
    required this.duracionEstimadaMinutos,
    required this.tipoVisita,
    required this.prioridad,
    this.completada = false,
    this.horaInicioReal,
    this.horaFinReal,
    this.observaciones,
    this.syncStatus = 'pending',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory VisitaPlanificadaHive.fromJson(Map<String, dynamic> json) {
    return VisitaPlanificadaHive(
      id: json['id'] ?? json['Id'] ?? '',
      clienteId: json['clienteId'] ?? json['ClienteId'] ?? '',
      clienteNombre: json['clienteNombre'] ?? json['ClienteNombre'] ?? '',
      clienteDireccion: json['clienteDireccion'] ?? json['ClienteDireccion'] ?? '',
      horaEstimada: DateTimeHelper.parseDateTimeWithFallback(json['horaEstimada'] ?? json['HoraEstimada']),
      duracionEstimadaMinutos: json['duracionEstimadaMinutos'] ?? json['DuracionEstimadaMinutos'] ?? 30,
      tipoVisita: json['tipoVisita'] ?? json['TipoVisita'] ?? 'rutina',
      prioridad: json['prioridad'] ?? json['Prioridad'] ?? 'media',
      completada: json['completada'] ?? json['Completada'] ?? false,
      horaInicioReal: DateTimeHelper.parseDateTime(json['horaInicioReal'] ?? json['HoraInicioReal']),
      horaFinReal: DateTimeHelper.parseDateTime(json['horaFinReal'] ?? json['HoraFinReal']),
      observaciones: json['observaciones'] ?? json['Observaciones'],
      syncStatus: json['syncStatus'] ?? 'pending',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteDireccion': clienteDireccion,
      'horaEstimada': horaEstimada.toIso8601String(),
      'duracionEstimadaMinutos': duracionEstimadaMinutos,
      'tipoVisita': tipoVisita,
      'prioridad': prioridad,
      'completada': completada,
      'horaInicioReal': horaInicioReal?.toIso8601String(),
      'horaFinReal': horaFinReal?.toIso8601String(),
      'observaciones': observaciones,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }


  bool get requiresSync => syncStatus == 'pending';
  bool get estaRetrasada => DateTime.now().isAfter(horaEstimada) && !completada;
  
  Duration? get duracionReal {
    if (horaInicioReal != null && horaFinReal != null) {
      return horaFinReal!.difference(horaInicioReal!);
    }
    return null;
  }
}