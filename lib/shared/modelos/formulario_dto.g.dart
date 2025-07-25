// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formulario_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OpcionDTOAdapter extends TypeAdapter<OpcionDTO> {
  @override
  final int typeId = 32;

  @override
  OpcionDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OpcionDTO(
      valor: fields[0] as String,
      etiqueta: fields[1] as String,
      puntuacion: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OpcionDTO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.valor)
      ..writeByte(1)
      ..write(obj.etiqueta)
      ..writeByte(2)
      ..write(obj.puntuacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpcionDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PreguntaDTOAdapter extends TypeAdapter<PreguntaDTO> {
  @override
  final int typeId = 33;

  @override
  PreguntaDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PreguntaDTO(
      name: fields[0] as String,
      tipoEntrada: fields[1] as String,
      orden: fields[2] as int,
      section: fields[3] as String,
      opciones: (fields[4] as List).cast<OpcionDTO>(),
      etiqueta: fields[6] as String,
      value: fields[5] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, PreguntaDTO obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.tipoEntrada)
      ..writeByte(2)
      ..write(obj.orden)
      ..writeByte(3)
      ..write(obj.section)
      ..writeByte(4)
      ..write(obj.opciones)
      ..writeByte(5)
      ..write(obj.value)
      ..writeByte(6)
      ..write(obj.etiqueta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreguntaDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormularioPlantillaDTOAdapter
    extends TypeAdapter<FormularioPlantillaDTO> {
  @override
  final int typeId = 34;

  @override
  FormularioPlantillaDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormularioPlantillaDTO(
      plantillaId: fields[0] as String,
      nombre: fields[1] as String,
      version: fields[2] as String,
      estatus: fields[3] as FormStatus,
      canal: fields[4] as CanalType,
      questions: (fields[5] as List).cast<PreguntaDTO>(),
      fechaCreacion: fields[6] as DateTime?,
      fechaActualizacion: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FormularioPlantillaDTO obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.plantillaId)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.estatus)
      ..writeByte(4)
      ..write(obj.canal)
      ..writeByte(5)
      ..write(obj.questions)
      ..writeByte(6)
      ..write(obj.fechaCreacion)
      ..writeByte(7)
      ..write(obj.fechaActualizacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormularioPlantillaDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RespuestaPreguntaDTOAdapter extends TypeAdapter<RespuestaPreguntaDTO> {
  @override
  final int typeId = 35;

  @override
  RespuestaPreguntaDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RespuestaPreguntaDTO(
      questionName: fields[0] as String,
      value: fields[1] as dynamic,
      puntuacion: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RespuestaPreguntaDTO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.questionName)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.puntuacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RespuestaPreguntaDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormularioRespuestaDTOAdapter
    extends TypeAdapter<FormularioRespuestaDTO> {
  @override
  final int typeId = 36;

  @override
  FormularioRespuestaDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormularioRespuestaDTO(
      respuestaId: fields[0] as String,
      plantillaId: fields[1] as String,
      planVisitaId: fields[2] as String,
      rutaId: fields[3] as String,
      clientId: fields[4] as String,
      respuestas: (fields[5] as List).cast<RespuestaPreguntaDTO>(),
      puntuacionTotal: fields[6] as int,
      colorKPI: fields[7] as String,
      offline: fields[8] as bool,
      fechaCreacion: fields[9] as DateTime,
      fechaSincronizacion: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FormularioRespuestaDTO obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.respuestaId)
      ..writeByte(1)
      ..write(obj.plantillaId)
      ..writeByte(2)
      ..write(obj.planVisitaId)
      ..writeByte(3)
      ..write(obj.rutaId)
      ..writeByte(4)
      ..write(obj.clientId)
      ..writeByte(5)
      ..write(obj.respuestas)
      ..writeByte(6)
      ..write(obj.puntuacionTotal)
      ..writeByte(7)
      ..write(obj.colorKPI)
      ..writeByte(8)
      ..write(obj.offline)
      ..writeByte(9)
      ..write(obj.fechaCreacion)
      ..writeByte(10)
      ..write(obj.fechaSincronizacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormularioRespuestaDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CanalTypeAdapter extends TypeAdapter<CanalType> {
  @override
  final int typeId = 30;

  @override
  CanalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CanalType.DETALLE;
      case 1:
        return CanalType.MAYOREO;
      case 2:
        return CanalType.EXCELENCIA;
      default:
        return CanalType.DETALLE;
    }
  }

  @override
  void write(BinaryWriter writer, CanalType obj) {
    switch (obj) {
      case CanalType.DETALLE:
        writer.writeByte(0);
        break;
      case CanalType.MAYOREO:
        writer.writeByte(1);
        break;
      case CanalType.EXCELENCIA:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormStatusAdapter extends TypeAdapter<FormStatus> {
  @override
  final int typeId = 31;

  @override
  FormStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FormStatus.ACTIVO;
      case 1:
        return FormStatus.INACTIVO;
      default:
        return FormStatus.ACTIVO;
    }
  }

  @override
  void write(BinaryWriter writer, FormStatus obj) {
    switch (obj) {
      case FormStatus.ACTIVO:
        writer.writeByte(0);
        break;
      case FormStatus.INACTIVO:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
