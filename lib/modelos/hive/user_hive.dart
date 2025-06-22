import 'package:hive/hive.dart';
import 'datetime_helper.dart';

part 'user_hive.g.dart';

@HiveType(typeId: 10)
class UserHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String nombre;

  @HiveField(3)
  String apellido;

  @HiveField(4)
  String rol;

  @HiveField(5)
  String centroDistribucion;

  @HiveField(6)
  String clave;

  @HiveField(7)
  bool activo;

  @HiveField(8)
  DateTime fechaCreacion;

  @HiveField(9)
  DateTime? ultimoAcceso;

  @HiveField(10)
  Map<String, dynamic> permisos;

  @HiveField(11)
  String syncStatus;

  @HiveField(12)
  DateTime lastUpdated;

  UserHive({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.centroDistribucion,
    required this.clave,
    this.activo = true,
    required this.fechaCreacion,
    this.ultimoAcceso,
    required this.permisos,
    this.syncStatus = 'synced',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory UserHive.fromJson(Map<String, dynamic> json) {
    return UserHive(
      id: json['id'] ?? json['Id'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      nombre: json['nombre'] ?? json['Nombre'] ?? '',
      apellido: json['apellido'] ?? json['Apellido'] ?? '',
      rol: json['rol'] ?? json['Rol'] ?? '',
      centroDistribucion: json['centroDistribucion'] ?? json['CentroDistribucion'] ?? '',
      clave: json['clave'] ?? json['Clave'] ?? '',
      activo: json['activo'] ?? json['Activo'] ?? true,
      fechaCreacion: DateTimeHelper.parseDateTimeWithFallback(json['fechaCreacion'] ?? json['FechaCreacion']),
      ultimoAcceso: DateTimeHelper.parseDateTime(json['ultimoAcceso'] ?? json['UltimoAcceso']),
      permisos: Map<String, dynamic>.from(json['permisos'] ?? json['Permisos'] ?? {}),
      syncStatus: json['syncStatus'] ?? 'synced',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'rol': rol,
      'centroDistribucion': centroDistribucion,
      'clave': clave,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'ultimoAcceso': ultimoAcceso?.toIso8601String(),
      'permisos': permisos,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }


  String get nombreCompleto => '$nombre $apellido';
  bool get esLiderComercial => rol.toLowerCase() == 'lider_comercial';
  bool get esAdmin => rol.toLowerCase() == 'admin';
  bool get tienePermisoVer => permisos['ver'] ?? false;
  bool get tienePermisoEditar => permisos['editar'] ?? false;
  bool get tienePermisoEliminar => permisos['eliminar'] ?? false;
}