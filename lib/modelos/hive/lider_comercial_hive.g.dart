// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lider_comercial_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LiderComercialHiveAdapter extends TypeAdapter<LiderComercialHive> {
  @override
  final int typeId = 1;

  @override
  LiderComercialHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LiderComercialHive(
      id: fields[0] as String,
      centroDistribucion: fields[1] as String,
      clave: fields[2] as String,
      nombre: fields[3] as String,
      pais: fields[4] as String,
      rutas: (fields[5] as List).cast<RutaHive>(),
      syncStatus: fields[6] as String,
      lastUpdated: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LiderComercialHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.centroDistribucion)
      ..writeByte(2)
      ..write(obj.clave)
      ..writeByte(3)
      ..write(obj.nombre)
      ..writeByte(4)
      ..write(obj.pais)
      ..writeByte(5)
      ..write(obj.rutas)
      ..writeByte(6)
      ..write(obj.syncStatus)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiderComercialHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RutaHiveAdapter extends TypeAdapter<RutaHive> {
  @override
  final int typeId = 2;

  @override
  RutaHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RutaHive(
      id: fields[0] as String,
      asesor: fields[1] as String,
      nombre: fields[2] as String,
      negocios: (fields[3] as List).cast<NegocioHive>(),
      syncStatus: fields[4] as String,
      lastUpdated: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RutaHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.asesor)
      ..writeByte(2)
      ..write(obj.nombre)
      ..writeByte(3)
      ..write(obj.negocios)
      ..writeByte(4)
      ..write(obj.syncStatus)
      ..writeByte(5)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RutaHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NegocioHiveAdapter extends TypeAdapter<NegocioHive> {
  @override
  final int typeId = 3;

  @override
  NegocioHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NegocioHive(
      id: fields[0] as String,
      canal: fields[1] as String,
      clasificacion: fields[2] as String,
      clave: fields[3] as String,
      exhibidor: fields[4] as String,
      nombre: fields[5] as String,
      syncStatus: fields[6] as String,
      lastUpdated: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NegocioHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.canal)
      ..writeByte(2)
      ..write(obj.clasificacion)
      ..writeByte(3)
      ..write(obj.clave)
      ..writeByte(4)
      ..write(obj.exhibidor)
      ..writeByte(5)
      ..write(obj.nombre)
      ..writeByte(6)
      ..write(obj.syncStatus)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NegocioHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
