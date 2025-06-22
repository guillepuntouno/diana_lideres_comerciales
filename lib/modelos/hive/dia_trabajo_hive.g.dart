// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dia_trabajo_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiaTrabajoHiveAdapter extends TypeAdapter<DiaTrabajoHive> {
  @override
  final int typeId = 14;

  @override
  DiaTrabajoHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiaTrabajoHive(
      dia: fields[0] as String,
      objetivoId: fields[1] as String?,
      objetivoNombre: fields[2] as String?,
      tipo: fields[3] as String?,
      clienteIds: (fields[4] as List?)?.cast<String>(),
      rutaId: fields[5] as String?,
      rutaNombre: fields[6] as String?,
      tipoActividadAdministrativa: fields[7] as String?,
      objetivoAbordaje: fields[8] as String?,
      fechaModificacion: fields[9] as DateTime?,
      configurado: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DiaTrabajoHive obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.dia)
      ..writeByte(1)
      ..write(obj.objetivoId)
      ..writeByte(2)
      ..write(obj.objetivoNombre)
      ..writeByte(3)
      ..write(obj.tipo)
      ..writeByte(4)
      ..write(obj.clienteIds)
      ..writeByte(5)
      ..write(obj.rutaId)
      ..writeByte(6)
      ..write(obj.rutaNombre)
      ..writeByte(7)
      ..write(obj.tipoActividadAdministrativa)
      ..writeByte(8)
      ..write(obj.objetivoAbordaje)
      ..writeByte(9)
      ..write(obj.fechaModificacion)
      ..writeByte(10)
      ..write(obj.configurado);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaTrabajoHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}