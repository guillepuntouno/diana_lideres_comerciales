// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visita_cliente_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisitaClienteHiveAdapter extends TypeAdapter<VisitaClienteHive> {
  @override
  final int typeId = 4;

  @override
  VisitaClienteHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitaClienteHive(
      id: fields[0] as String,
      visitaId: fields[1] as String,
      liderClave: fields[2] as String,
      clienteId: fields[3] as String,
      clienteNombre: fields[4] as String,
      planId: fields[5] as String,
      dia: fields[6] as String,
      fechaCreacion: fields[7] as DateTime,
      checkIn: fields[8] as CheckInHive,
      checkOut: fields[9] as CheckOutHive?,
      formularios: (fields[10] as Map).cast<String, dynamic>(),
      estatus: fields[11] as String,
      fechaModificacion: fields[12] as DateTime?,
      fechaFinalizacion: fields[13] as DateTime?,
      fechaCancelacion: fields[14] as DateTime?,
      motivoCancelacion: fields[15] as String?,
      syncStatus: fields[16] as String,
      lastUpdated: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VisitaClienteHive obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.visitaId)
      ..writeByte(2)
      ..write(obj.liderClave)
      ..writeByte(3)
      ..write(obj.clienteId)
      ..writeByte(4)
      ..write(obj.clienteNombre)
      ..writeByte(5)
      ..write(obj.planId)
      ..writeByte(6)
      ..write(obj.dia)
      ..writeByte(7)
      ..write(obj.fechaCreacion)
      ..writeByte(8)
      ..write(obj.checkIn)
      ..writeByte(9)
      ..write(obj.checkOut)
      ..writeByte(10)
      ..write(obj.formularios)
      ..writeByte(11)
      ..write(obj.estatus)
      ..writeByte(12)
      ..write(obj.fechaModificacion)
      ..writeByte(13)
      ..write(obj.fechaFinalizacion)
      ..writeByte(14)
      ..write(obj.fechaCancelacion)
      ..writeByte(15)
      ..write(obj.motivoCancelacion)
      ..writeByte(16)
      ..write(obj.syncStatus)
      ..writeByte(17)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitaClienteHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CheckInHiveAdapter extends TypeAdapter<CheckInHive> {
  @override
  final int typeId = 5;

  @override
  CheckInHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckInHive(
      timestamp: fields[0] as DateTime,
      comentarios: fields[1] as String,
      ubicacion: fields[2] as UbicacionHive,
    );
  }

  @override
  void write(BinaryWriter writer, CheckInHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.comentarios)
      ..writeByte(2)
      ..write(obj.ubicacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CheckOutHiveAdapter extends TypeAdapter<CheckOutHive> {
  @override
  final int typeId = 6;

  @override
  CheckOutHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckOutHive(
      timestamp: fields[0] as DateTime,
      comentarios: fields[1] as String,
      ubicacion: fields[2] as UbicacionHive,
      duracionMinutos: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CheckOutHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.comentarios)
      ..writeByte(2)
      ..write(obj.ubicacion)
      ..writeByte(3)
      ..write(obj.duracionMinutos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckOutHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UbicacionHiveAdapter extends TypeAdapter<UbicacionHive> {
  @override
  final int typeId = 7;

  @override
  UbicacionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UbicacionHive(
      latitud: fields[0] as double,
      longitud: fields[1] as double,
      precision: fields[2] as double,
      direccion: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UbicacionHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.latitud)
      ..writeByte(1)
      ..write(obj.longitud)
      ..writeByte(2)
      ..write(obj.precision)
      ..writeByte(3)
      ..write(obj.direccion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UbicacionHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
