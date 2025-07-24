// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserHiveAdapter extends TypeAdapter<UserHive> {
  @override
  final int typeId = 10;

  @override
  UserHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserHive(
      id: fields[0] as String,
      email: fields[1] as String,
      nombre: fields[2] as String,
      apellido: fields[3] as String,
      rol: fields[4] as String,
      centroDistribucion: fields[5] as String,
      clave: fields[6] as String,
      activo: fields[7] as bool,
      fechaCreacion: fields[8] as DateTime,
      ultimoAcceso: fields[9] as DateTime?,
      permisos: (fields[10] as Map).cast<String, dynamic>(),
      syncStatus: fields[11] as String,
      lastUpdated: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserHive obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.nombre)
      ..writeByte(3)
      ..write(obj.apellido)
      ..writeByte(4)
      ..write(obj.rol)
      ..writeByte(5)
      ..write(obj.centroDistribucion)
      ..writeByte(6)
      ..write(obj.clave)
      ..writeByte(7)
      ..write(obj.activo)
      ..writeByte(8)
      ..write(obj.fechaCreacion)
      ..writeByte(9)
      ..write(obj.ultimoAcceso)
      ..writeByte(10)
      ..write(obj.permisos)
      ..writeByte(11)
      ..write(obj.syncStatus)
      ..writeByte(12)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
