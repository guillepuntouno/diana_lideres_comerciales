import 'package:hive/hive.dart';
import 'dia_trabajo_hive.dart';

part 'plan_trabajo_semanal_hive.g.dart';

@HiveType(typeId: 13)
class PlanTrabajoSemanalHive extends HiveObject {
  @HiveField(0)
  String id; // Format: LIDERCLAVE_SEMXX_YYYY

  @HiveField(1)
  String semana; // Format: "SEMANA XX - YYYY"

  @HiveField(2)
  String liderClave;

  @HiveField(3)
  String liderNombre;

  @HiveField(4)
  String centroDistribucion;

  @HiveField(5)
  String fechaInicio;

  @HiveField(6)
  String fechaFin;

  @HiveField(7)
  Map<String, DiaTrabajoHive> dias; // Lunes, Martes, etc.

  @HiveField(8)
  String estatus; // 'borrador', 'enviado'

  @HiveField(9)
  DateTime fechaCreacion;

  @HiveField(10)
  DateTime fechaModificacion;

  @HiveField(11)
  bool sincronizado;

  @HiveField(12)
  DateTime? fechaUltimaSincronizacion;

  @HiveField(13)
  int? numeroSemana;

  @HiveField(14)
  int? anio;

  PlanTrabajoSemanalHive({
    required this.id,
    required this.semana,
    required this.liderClave,
    required this.liderNombre,
    required this.centroDistribucion,
    required this.fechaInicio,
    required this.fechaFin,
    Map<String, DiaTrabajoHive>? dias,
    this.estatus = 'borrador',
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    this.sincronizado = false,
    this.fechaUltimaSincronizacion,
    this.numeroSemana,
    this.anio,
  })  : dias = dias ?? {},
        fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semana': semana,
      'liderClave': liderClave,
      'liderNombre': liderNombre,
      'centroDistribucion': centroDistribucion,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'dias': dias.map((key, value) => MapEntry(key, value.toJson())),
      'estatus': estatus,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'sincronizado': sincronizado,
      'fechaUltimaSincronizacion': fechaUltimaSincronizacion?.toIso8601String(),
      'numeroSemana': numeroSemana,
      'anio': anio,
    };
  }

  factory PlanTrabajoSemanalHive.fromJson(Map<String, dynamic> json) {
    return PlanTrabajoSemanalHive(
      id: json['id'] ?? '',
      semana: json['semana'] ?? '',
      liderClave: json['liderClave'] ?? '',
      liderNombre: json['liderNombre'] ?? '',
      centroDistribucion: json['centroDistribucion'] ?? '',
      fechaInicio: json['fechaInicio'] ?? '',
      fechaFin: json['fechaFin'] ?? '',
      dias: (json['dias'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, DiaTrabajoHive.fromJson(value)),
          ) ??
          {},
      estatus: json['estatus'] ?? 'borrador',
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
      sincronizado: json['sincronizado'] ?? false,
      fechaUltimaSincronizacion: json['fechaUltimaSincronizacion'] != null
          ? DateTime.parse(json['fechaUltimaSincronizacion'])
          : null,
      numeroSemana: json['numeroSemana'],
      anio: json['anio'],
    );
  }

  // Helper methods
  bool get estaCompleto => dias.length == 6 && dias.values.every((dia) => dia.objetivoId != null);

  int get diasConfigurados => dias.values.where((dia) => dia.objetivoId != null).length;

  bool puedeEditar() {
    if (estatus != 'enviado') return true;
    final diasTranscurridos = DateTime.now().difference(fechaModificacion).inDays;
    return diasTranscurridos <= 7;
  }
}