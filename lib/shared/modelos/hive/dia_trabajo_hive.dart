import 'package:hive/hive.dart';

part 'dia_trabajo_hive.g.dart';

@HiveType(typeId: 14)
class DiaTrabajoHive extends HiveObject {
  @HiveField(0)
  String dia; // Lunes, Martes, etc.

  @HiveField(1)
  String? objetivoId;

  @HiveField(2)
  String? objetivoNombre;

  @HiveField(3)
  String? tipo; // 'gestion_cliente' o 'administrativo'

  @HiveField(4)
  List<String> clienteIds;

  @HiveField(5)
  String? rutaId;

  @HiveField(6)
  String? rutaNombre;

  @HiveField(7)
  String? tipoActividadAdministrativa;

  @HiveField(8)
  String? objetivoAbordaje;

  @HiveField(9)
  DateTime fechaModificacion;

  @HiveField(10)
  bool configurado;

  DiaTrabajoHive({
    required this.dia,
    this.objetivoId,
    this.objetivoNombre,
    this.tipo,
    List<String>? clienteIds,
    this.rutaId,
    this.rutaNombre,
    this.tipoActividadAdministrativa,
    this.objetivoAbordaje,
    DateTime? fechaModificacion,
    this.configurado = false,
  })  : clienteIds = clienteIds ?? [],
        fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'objetivoId': objetivoId,
      'objetivoNombre': objetivoNombre,
      'tipo': tipo,
      'clienteIds': clienteIds,
      'rutaId': rutaId,
      'rutaNombre': rutaNombre,
      'tipoActividadAdministrativa': tipoActividadAdministrativa,
      'objetivoAbordaje': objetivoAbordaje,
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'configurado': configurado,
    };
  }

  factory DiaTrabajoHive.fromJson(Map<String, dynamic> json) {
    return DiaTrabajoHive(
      dia: json['dia'] ?? '',
      objetivoId: json['objetivoId'],
      objetivoNombre: json['objetivoNombre'],
      tipo: json['tipo'],
      clienteIds: (json['clienteIds'] as List<dynamic>?)?.cast<String>() ?? [],
      rutaId: json['rutaId'],
      rutaNombre: json['rutaNombre'],
      tipoActividadAdministrativa: json['tipoActividadAdministrativa'],
      objetivoAbordaje: json['objetivoAbordaje'],
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
      configurado: json['configurado'] ?? false,
    );
  }
}