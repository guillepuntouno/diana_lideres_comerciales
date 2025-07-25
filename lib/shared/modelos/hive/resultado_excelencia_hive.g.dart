// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultado_excelencia_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResultadoExcelenciaHiveAdapter
    extends TypeAdapter<ResultadoExcelenciaHive> {
  @override
  final int typeId = 50;

  @override
  ResultadoExcelenciaHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResultadoExcelenciaHive(
      id: fields[0] as String,
      liderClave: fields[1] as String,
      liderNombre: fields[2] as String,
      liderCorreo: fields[3] as String,
      pais: fields[4] as String,
      ruta: fields[5] as String,
      centroDistribucion: fields[6] as String,
      tipoFormulario: fields[7] as String,
      formularioMaestro: (fields[8] as Map).cast<String, dynamic>(),
      respuestas: (fields[9] as List).cast<RespuestaEvaluacionHive>(),
      ponderacionFinal: fields[10] as double,
      fechaCaptura: fields[11] as DateTime,
      fechaHoraInicio: fields[12] as DateTime,
      fechaHoraFin: fields[13] as DateTime?,
      estatus: fields[14] as String,
      observaciones: fields[15] as String?,
      syncStatus: fields[16] as String,
      lastUpdated: fields[17] as DateTime?,
      metadatos: (fields[18] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ResultadoExcelenciaHive obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.liderClave)
      ..writeByte(2)
      ..write(obj.liderNombre)
      ..writeByte(3)
      ..write(obj.liderCorreo)
      ..writeByte(4)
      ..write(obj.pais)
      ..writeByte(5)
      ..write(obj.ruta)
      ..writeByte(6)
      ..write(obj.centroDistribucion)
      ..writeByte(7)
      ..write(obj.tipoFormulario)
      ..writeByte(8)
      ..write(obj.formularioMaestro)
      ..writeByte(9)
      ..write(obj.respuestas)
      ..writeByte(10)
      ..write(obj.ponderacionFinal)
      ..writeByte(11)
      ..write(obj.fechaCaptura)
      ..writeByte(12)
      ..write(obj.fechaHoraInicio)
      ..writeByte(13)
      ..write(obj.fechaHoraFin)
      ..writeByte(14)
      ..write(obj.estatus)
      ..writeByte(15)
      ..write(obj.observaciones)
      ..writeByte(16)
      ..write(obj.syncStatus)
      ..writeByte(17)
      ..write(obj.lastUpdated)
      ..writeByte(18)
      ..write(obj.metadatos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultadoExcelenciaHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RespuestaEvaluacionHiveAdapter
    extends TypeAdapter<RespuestaEvaluacionHive> {
  @override
  final int typeId = 51;

  @override
  RespuestaEvaluacionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RespuestaEvaluacionHive(
      preguntaId: fields[0] as String,
      preguntaTitulo: fields[1] as String,
      categoria: fields[2] as String?,
      tipoPregunta: fields[3] as String,
      respuesta: fields[4] as dynamic,
      ponderacion: fields[5] as double?,
      timestampRespuesta: fields[6] as DateTime,
      configuracionPregunta: (fields[7] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, RespuestaEvaluacionHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.preguntaId)
      ..writeByte(1)
      ..write(obj.preguntaTitulo)
      ..writeByte(2)
      ..write(obj.categoria)
      ..writeByte(3)
      ..write(obj.tipoPregunta)
      ..writeByte(4)
      ..write(obj.respuesta)
      ..writeByte(5)
      ..write(obj.ponderacion)
      ..writeByte(6)
      ..write(obj.timestampRespuesta)
      ..writeByte(7)
      ..write(obj.configuracionPregunta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RespuestaEvaluacionHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
