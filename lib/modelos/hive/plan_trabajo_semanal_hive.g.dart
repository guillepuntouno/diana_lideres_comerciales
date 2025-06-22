// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_trabajo_semanal_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanTrabajoSemanalHiveAdapter extends TypeAdapter<PlanTrabajoSemanalHive> {
  @override
  final int typeId = 13;

  @override
  PlanTrabajoSemanalHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanTrabajoSemanalHive(
      id: fields[0] as String,
      semana: fields[1] as String,
      liderClave: fields[2] as String,
      liderNombre: fields[3] as String,
      centroDistribucion: fields[4] as String,
      fechaInicio: fields[5] as String,
      fechaFin: fields[6] as String,
      dias: (fields[7] as Map?)?.cast<String, DiaTrabajoHive>(),
      estatus: fields[8] as String,
      fechaCreacion: fields[9] as DateTime?,
      fechaModificacion: fields[10] as DateTime?,
      sincronizado: fields[11] as bool,
      fechaUltimaSincronizacion: fields[12] as DateTime?,
      numeroSemana: fields[13] as int?,
      anio: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanTrabajoSemanalHive obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.semana)
      ..writeByte(2)
      ..write(obj.liderClave)
      ..writeByte(3)
      ..write(obj.liderNombre)
      ..writeByte(4)
      ..write(obj.centroDistribucion)
      ..writeByte(5)
      ..write(obj.fechaInicio)
      ..writeByte(6)
      ..write(obj.fechaFin)
      ..writeByte(7)
      ..write(obj.dias)
      ..writeByte(8)
      ..write(obj.estatus)
      ..writeByte(9)
      ..write(obj.fechaCreacion)
      ..writeByte(10)
      ..write(obj.fechaModificacion)
      ..writeByte(11)
      ..write(obj.sincronizado)
      ..writeByte(12)
      ..write(obj.fechaUltimaSincronizacion)
      ..writeByte(13)
      ..write(obj.numeroSemana)
      ..writeByte(14)
      ..write(obj.anio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanTrabajoSemanalHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}