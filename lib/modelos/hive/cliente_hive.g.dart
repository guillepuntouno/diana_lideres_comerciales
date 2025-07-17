// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClienteHiveAdapter extends TypeAdapter<ClienteHive> {
  @override
  final int typeId = 12;

  @override
  ClienteHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClienteHive(
      id: fields[0] as String,
      nombre: fields[1] as String,
      direccion: fields[2] as String,
      telefono: fields[3] as String?,
      rutaId: fields[4] as String,
      rutaNombre: fields[5] as String,
      asesorId: fields[6] as String?,
      asesorNombre: fields[7] as String?,
      latitud: fields[8] as double?,
      longitud: fields[9] as double?,
      activo: fields[10] as bool,
      fechaModificacion: fields[11] as DateTime?,
      tipoNegocio: fields[12] as String?,
      segmento: fields[13] as String?,
      pais: fields[14] as String?,
      centroDistribucion: fields[15] as String?,
      codigoLider: fields[16] as String?,
      nombreLider: fields[17] as String?,
      emailLider: fields[18] as String?,
      canalVenta: fields[19] as String?,
      subcanalVenta: fields[20] as String?,
      estadoRuta: fields[21] as String?,
      estadoCliente: fields[22] as String?,
      clasificacionCliente: fields[23] as String?,
      diaVisita: fields[24] as String?,
      diaVisitaCod: fields[25] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClienteHive obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.direccion)
      ..writeByte(3)
      ..write(obj.telefono)
      ..writeByte(4)
      ..write(obj.rutaId)
      ..writeByte(5)
      ..write(obj.rutaNombre)
      ..writeByte(6)
      ..write(obj.asesorId)
      ..writeByte(7)
      ..write(obj.asesorNombre)
      ..writeByte(8)
      ..write(obj.latitud)
      ..writeByte(9)
      ..write(obj.longitud)
      ..writeByte(10)
      ..write(obj.activo)
      ..writeByte(11)
      ..write(obj.fechaModificacion)
      ..writeByte(12)
      ..write(obj.tipoNegocio)
      ..writeByte(13)
      ..write(obj.segmento)
      ..writeByte(14)
      ..write(obj.pais)
      ..writeByte(15)
      ..write(obj.centroDistribucion)
      ..writeByte(16)
      ..write(obj.codigoLider)
      ..writeByte(17)
      ..write(obj.nombreLider)
      ..writeByte(18)
      ..write(obj.emailLider)
      ..writeByte(19)
      ..write(obj.canalVenta)
      ..writeByte(20)
      ..write(obj.subcanalVenta)
      ..writeByte(21)
      ..write(obj.estadoRuta)
      ..writeByte(22)
      ..write(obj.estadoCliente)
      ..writeByte(23)
      ..write(obj.clasificacionCliente)
      ..writeByte(24)
      ..write(obj.diaVisita)
      ..writeByte(25)
      ..write(obj.diaVisitaCod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClienteHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
