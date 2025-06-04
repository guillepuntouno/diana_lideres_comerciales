// modelos/user_dto.dart
import 'base_entity.dart';

class UsuarioDto extends BaseEntity {
  String nombre;
  String correo;
  String rol; // "admin" | "asesor" | "lider"
  String estado; // "activo" | "inactivo"
  String centroDistribucion;

  UsuarioDto({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.createdBy,
    required super.updatedBy,
    required super.deletedBy,
    required super.isDeleted,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.estado,
    required this.centroDistribucion,
  });

  factory UsuarioDto.fromJson(Map<String, dynamic> json) => UsuarioDto(
    id: json['id'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    deletedAt: json['deletedAt'],
    createdBy: json['createdBy'],
    updatedBy: json['updatedBy'],
    deletedBy: json['deletedBy'],
    isDeleted: json['isDeleted'],
    nombre: json['nombre'],
    correo: json['correo'],
    rol: json['rol'],
    estado: json['estado'],
    centroDistribucion: json['centroDistribucion'],
  );

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'nombre': nombre,
    'correo': correo,
    'rol': rol,
    'estado': estado,
    'centroDistribucion': centroDistribucion,
  };
}
