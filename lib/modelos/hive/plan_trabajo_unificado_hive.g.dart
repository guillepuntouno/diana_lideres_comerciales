// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_trabajo_unificado_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanTrabajoUnificadoHiveAdapter extends TypeAdapter<PlanTrabajoUnificadoHive> {
  @override
  final int typeId = 15;

  @override
  PlanTrabajoUnificadoHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanTrabajoUnificadoHive(
      id: fields[0] as String,
      semana: fields[1] as String,
      numeroSemana: fields[2] as int,
      anio: fields[3] as int,
      liderClave: fields[4] as String,
      liderNombre: fields[5] as String,
      centroDistribucion: fields[6] as String,
      fechaInicio: fields[7] as String,
      fechaFin: fields[8] as String,
      estatus: fields[9] as String,
      fechaCreacion: fields[10] as DateTime?,
      fechaModificacion: fields[11] as DateTime?,
      sincronizado: fields[12] as bool,
      fechaUltimaSincronizacion: fields[13] as DateTime?,
      dias: (fields[14] as Map?)?.cast<String, DiaPlanHive>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlanTrabajoUnificadoHive obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.semana)
      ..writeByte(2)
      ..write(obj.numeroSemana)
      ..writeByte(3)
      ..write(obj.anio)
      ..writeByte(4)
      ..write(obj.liderClave)
      ..writeByte(5)
      ..write(obj.liderNombre)
      ..writeByte(6)
      ..write(obj.centroDistribucion)
      ..writeByte(7)
      ..write(obj.fechaInicio)
      ..writeByte(8)
      ..write(obj.fechaFin)
      ..writeByte(9)
      ..write(obj.estatus)
      ..writeByte(10)
      ..write(obj.fechaCreacion)
      ..writeByte(11)
      ..write(obj.fechaModificacion)
      ..writeByte(12)
      ..write(obj.sincronizado)
      ..writeByte(13)
      ..write(obj.fechaUltimaSincronizacion)
      ..writeByte(14)
      ..write(obj.dias);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanTrabajoUnificadoHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiaPlanHiveAdapter extends TypeAdapter<DiaPlanHive> {
  @override
  final int typeId = 16;

  @override
  DiaPlanHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiaPlanHive(
      dia: fields[0] as String,
      tipo: fields[1] as String,
      objetivoId: fields[2] as String?,
      objetivoNombre: fields[3] as String?,
      tipoActividadAdministrativa: fields[4] as String?,
      rutaId: fields[5] as String?,
      rutaNombre: fields[6] as String?,
      clienteIds: (fields[7] as List?)?.cast<String>(),
      clientes: (fields[8] as List?)?.cast<VisitaClienteUnificadaHive>(),
      configurado: fields[9] as bool,
      fechaModificacion: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DiaPlanHive obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.dia)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.objetivoId)
      ..writeByte(3)
      ..write(obj.objetivoNombre)
      ..writeByte(4)
      ..write(obj.tipoActividadAdministrativa)
      ..writeByte(5)
      ..write(obj.rutaId)
      ..writeByte(6)
      ..write(obj.rutaNombre)
      ..writeByte(7)
      ..write(obj.clienteIds)
      ..writeByte(8)
      ..write(obj.clientes)
      ..writeByte(9)
      ..write(obj.configurado)
      ..writeByte(10)
      ..write(obj.fechaModificacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaPlanHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VisitaClienteUnificadaHiveAdapter extends TypeAdapter<VisitaClienteUnificadaHive> {
  @override
  final int typeId = 17;

  @override
  VisitaClienteUnificadaHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitaClienteUnificadaHive(
      clienteId: fields[0] as String,
      horaInicio: fields[1] as String?,
      horaFin: fields[2] as String?,
      ubicacionInicio: fields[3] as UbicacionUnificadaHive?,
      comentarioInicio: fields[4] as String?,
      cuestionario: fields[5] as CuestionarioHive?,
      compromisos: (fields[6] as List?)?.cast<CompromisoHive>(),
      retroalimentacion: fields[7] as String?,
      reconocimiento: fields[8] as String?,
      estatus: fields[9] as String,
      fechaModificacion: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VisitaClienteUnificadaHive obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.clienteId)
      ..writeByte(1)
      ..write(obj.horaInicio)
      ..writeByte(2)
      ..write(obj.horaFin)
      ..writeByte(3)
      ..write(obj.ubicacionInicio)
      ..writeByte(4)
      ..write(obj.comentarioInicio)
      ..writeByte(5)
      ..write(obj.cuestionario)
      ..writeByte(6)
      ..write(obj.compromisos)
      ..writeByte(7)
      ..write(obj.retroalimentacion)
      ..writeByte(8)
      ..write(obj.reconocimiento)
      ..writeByte(9)
      ..write(obj.estatus)
      ..writeByte(10)
      ..write(obj.fechaModificacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitaClienteUnificadaHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CuestionarioHiveAdapter extends TypeAdapter<CuestionarioHive> {
  @override
  final int typeId = 18;

  @override
  CuestionarioHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CuestionarioHive(
      tipoExhibidor: fields[0] as TipoExhibidorHive?,
      estandaresEjecucion: fields[1] as EstandaresEjecucionHive?,
      disponibilidad: fields[2] as DisponibilidadHive?,
    );
  }

  @override
  void write(BinaryWriter writer, CuestionarioHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.tipoExhibidor)
      ..writeByte(1)
      ..write(obj.estandaresEjecucion)
      ..writeByte(2)
      ..write(obj.disponibilidad);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CuestionarioHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoExhibidorHiveAdapter extends TypeAdapter<TipoExhibidorHive> {
  @override
  final int typeId = 19;

  @override
  TipoExhibidorHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TipoExhibidorHive(
      poseeAdecuado: fields[0] as bool,
      tipo: fields[1] as String?,
      modelo: fields[2] as String?,
      cantidad: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TipoExhibidorHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.poseeAdecuado)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.modelo)
      ..writeByte(3)
      ..write(obj.cantidad);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoExhibidorHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EstandaresEjecucionHiveAdapter extends TypeAdapter<EstandaresEjecucionHive> {
  @override
  final int typeId = 20;

  @override
  EstandaresEjecucionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EstandaresEjecucionHive(
      primeraPosicion: fields[0] as bool,
      planograma: fields[1] as bool,
      portafolioFoco: fields[2] as bool,
      anclaje: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EstandaresEjecucionHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.primeraPosicion)
      ..writeByte(1)
      ..write(obj.planograma)
      ..writeByte(2)
      ..write(obj.portafolioFoco)
      ..writeByte(3)
      ..write(obj.anclaje);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstandaresEjecucionHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DisponibilidadHiveAdapter extends TypeAdapter<DisponibilidadHive> {
  @override
  final int typeId = 21;

  @override
  DisponibilidadHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DisponibilidadHive(
      ristras: fields[0] as bool,
      max: fields[1] as bool,
      familiar: fields[2] as bool,
      dulce: fields[3] as bool,
      galleta: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DisponibilidadHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.ristras)
      ..writeByte(1)
      ..write(obj.max)
      ..writeByte(2)
      ..write(obj.familiar)
      ..writeByte(3)
      ..write(obj.dulce)
      ..writeByte(4)
      ..write(obj.galleta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisponibilidadHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CompromisoHiveAdapter extends TypeAdapter<CompromisoHive> {
  @override
  final int typeId = 22;

  @override
  CompromisoHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompromisoHive(
      tipo: fields[0] as String,
      detalle: fields[1] as String,
      cantidad: fields[2] as int,
      fechaPlazo: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompromisoHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tipo)
      ..writeByte(1)
      ..write(obj.detalle)
      ..writeByte(2)
      ..write(obj.cantidad)
      ..writeByte(3)
      ..write(obj.fechaPlazo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompromisoHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UbicacionUnificadaHiveAdapter extends TypeAdapter<UbicacionUnificadaHive> {
  @override
  final int typeId = 23;

  @override
  UbicacionUnificadaHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UbicacionUnificadaHive(
      lat: fields[0] as double,
      lon: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, UbicacionUnificadaHive obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.lon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UbicacionUnificadaHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}