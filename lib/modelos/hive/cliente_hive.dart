import 'package:hive/hive.dart';

part 'cliente_hive.g.dart';

@HiveType(typeId: 12)
class ClienteHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String direccion;

  @HiveField(3)
  String? telefono;

  @HiveField(4)
  String rutaId;

  @HiveField(5)
  String rutaNombre;

  @HiveField(6)
  String? asesorId;

  @HiveField(7)
  String? asesorNombre;

  @HiveField(8)
  double? latitud;

  @HiveField(9)
  double? longitud;

  @HiveField(10)
  bool activo;

  @HiveField(11)
  DateTime fechaModificacion;

  @HiveField(12)
  String? tipoNegocio;

  @HiveField(13)
  String? segmento;

  ClienteHive({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.telefono,
    required this.rutaId,
    required this.rutaNombre,
    this.asesorId,
    this.asesorNombre,
    this.latitud,
    this.longitud,
    this.activo = true,
    DateTime? fechaModificacion,
    this.tipoNegocio,
    this.segmento,
  }) : fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'rutaId': rutaId,
      'rutaNombre': rutaNombre,
      'asesorId': asesorId,
      'asesorNombre': asesorNombre,
      'latitud': latitud,
      'longitud': longitud,
      'activo': activo,
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'tipoNegocio': tipoNegocio,
      'segmento': segmento,
    };
  }

  factory ClienteHive.fromJson(Map<String, dynamic> json) {
    return ClienteHive(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'],
      rutaId: json['rutaId'] ?? '',
      rutaNombre: json['rutaNombre'] ?? '',
      asesorId: json['asesorId'],
      asesorNombre: json['asesorNombre'],
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      activo: json['activo'] ?? true,
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
      tipoNegocio: json['tipoNegocio'],
      segmento: json['segmento'],
    );
  }
}