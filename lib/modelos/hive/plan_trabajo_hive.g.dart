// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_trabajo_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanTrabajoHiveAdapter extends TypeAdapter<PlanTrabajoHive> {
  @override
  final int typeId = 8;

  @override
  PlanTrabajoHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanTrabajoHive(
      id: fields[0] as String,
      liderClave: fields[1] as String,
      fechaPlan: fields[2] as DateTime,
      estatus: fields[3] as String,
      visitasPlanificadas: (fields[4] as List).cast<VisitaPlanificadaHive>(),
      fechaInicio: fields[5] as DateTime?,
      fechaFinalizacion: fields[6] as DateTime?,
      observaciones: fields[7] as String?,
      syncStatus: fields[8] as String,
      lastUpdated: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanTrabajoHive obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.liderClave)
      ..writeByte(2)
      ..write(obj.fechaPlan)
      ..writeByte(3)
      ..write(obj.estatus)
      ..writeByte(4)
      ..write(obj.visitasPlanificadas)
      ..writeByte(5)
      ..write(obj.fechaInicio)
      ..writeByte(6)
      ..write(obj.fechaFinalizacion)
      ..writeByte(7)
      ..write(obj.observaciones)
      ..writeByte(8)
      ..write(obj.syncStatus)
      ..writeByte(9)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanTrabajoHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VisitaPlanificadaHiveAdapter extends TypeAdapter<VisitaPlanificadaHive> {
  @override
  final int typeId = 9;

  @override
  VisitaPlanificadaHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitaPlanificadaHive(
      id: fields[0] as String,
      clienteId: fields[1] as String,
      clienteNombre: fields[2] as String,
      clienteDireccion: fields[3] as String,
      horaEstimada: fields[4] as DateTime,
      duracionEstimadaMinutos: fields[5] as int,
      tipoVisita: fields[6] as String,
      prioridad: fields[7] as String,
      completada: fields[8] as bool,
      horaInicioReal: fields[9] as DateTime?,
      horaFinReal: fields[10] as DateTime?,
      observaciones: fields[11] as String?,
      syncStatus: fields[12] as String,
      lastUpdated: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VisitaPlanificadaHive obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clienteId)
      ..writeByte(2)
      ..write(obj.clienteNombre)
      ..writeByte(3)
      ..write(obj.clienteDireccion)
      ..writeByte(4)
      ..write(obj.horaEstimada)
      ..writeByte(5)
      ..write(obj.duracionEstimadaMinutos)
      ..writeByte(6)
      ..write(obj.tipoVisita)
      ..writeByte(7)
      ..write(obj.prioridad)
      ..writeByte(8)
      ..write(obj.completada)
      ..writeByte(9)
      ..write(obj.horaInicioReal)
      ..writeByte(10)
      ..write(obj.horaFinReal)
      ..writeByte(11)
      ..write(obj.observaciones)
      ..writeByte(12)
      ..write(obj.syncStatus)
      ..writeByte(13)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitaPlanificadaHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
