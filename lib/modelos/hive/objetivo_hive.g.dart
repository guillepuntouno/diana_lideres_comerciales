// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objetivo_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ObjetivoHiveAdapter extends TypeAdapter<ObjetivoHive> {
  @override
  final int typeId = 11;

  @override
  ObjetivoHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObjetivoHive(
      id: fields[0] as String,
      nombre: fields[1] as String,
      tipo: fields[2] as String,
      activo: fields[3] as bool,
      orden: fields[4] as int,
      fechaModificacion: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ObjetivoHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.activo)
      ..writeByte(4)
      ..write(obj.orden)
      ..writeByte(5)
      ..write(obj.fechaModificacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObjetivoHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
