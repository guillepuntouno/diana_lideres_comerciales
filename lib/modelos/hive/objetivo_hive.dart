import 'package:hive/hive.dart';

part 'objetivo_hive.g.dart';

@HiveType(typeId: 11)
class ObjetivoHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String tipo; // 'gestion_cliente' o 'administrativo'

  @HiveField(3)
  bool activo;

  @HiveField(4)
  int orden;

  @HiveField(5)
  DateTime fechaModificacion;

  ObjetivoHive({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.activo = true,
    this.orden = 0,
    DateTime? fechaModificacion,
  }) : fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'activo': activo,
      'orden': orden,
      'fechaModificacion': fechaModificacion.toIso8601String(),
    };
  }

  factory ObjetivoHive.fromJson(Map<String, dynamic> json) {
    return ObjetivoHive(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'gestion_cliente',
      activo: json['activo'] ?? true,
      orden: json['orden'] ?? 0,
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
    );
  }
}