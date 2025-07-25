import 'package:hive/hive.dart';
import 'datetime_helper.dart';

part 'resultado_excelencia_hive.g.dart';

@HiveType(typeId: 50)
class ResultadoExcelenciaHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String liderClave;

  @HiveField(2)
  String liderNombre;

  @HiveField(3)
  String liderCorreo;

  @HiveField(4)
  String pais;

  @HiveField(5)
  String ruta;

  @HiveField(6)
  String centroDistribucion;

  @HiveField(7)
  String tipoFormulario;

  @HiveField(8)
  Map<String, dynamic> formularioMaestro;

  @HiveField(9)
  List<RespuestaEvaluacionHive> respuestas;

  @HiveField(10)
  double ponderacionFinal;

  @HiveField(11)
  DateTime fechaCaptura;

  @HiveField(12)
  DateTime fechaHoraInicio;

  @HiveField(13)
  DateTime? fechaHoraFin;

  @HiveField(14)
  String estatus;

  @HiveField(15)
  String? observaciones;

  @HiveField(16)
  String syncStatus;

  @HiveField(17)
  DateTime lastUpdated;

  @HiveField(18)
  Map<String, dynamic>? metadatos;

  ResultadoExcelenciaHive({
    required this.id,
    required this.liderClave,
    required this.liderNombre,
    required this.liderCorreo,
    required this.pais,
    required this.ruta,
    required this.centroDistribucion,
    required this.tipoFormulario,
    required this.formularioMaestro,
    required this.respuestas,
    required this.ponderacionFinal,
    required this.fechaCaptura,
    required this.fechaHoraInicio,
    this.fechaHoraFin,
    required this.estatus,
    this.observaciones,
    this.syncStatus = 'pending',
    DateTime? lastUpdated,
    this.metadatos,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory ResultadoExcelenciaHive.fromJson(Map<String, dynamic> json) {
    return ResultadoExcelenciaHive(
      id: json['id'] ?? '',
      liderClave: json['liderClave'] ?? '',
      liderNombre: json['liderNombre'] ?? '',
      liderCorreo: json['liderCorreo'] ?? '',
      pais: json['pais'] ?? '',
      ruta: json['ruta'] ?? '',
      centroDistribucion: json['centroDistribucion'] ?? '',
      tipoFormulario: json['tipoFormulario'] ?? '',
      formularioMaestro: Map<String, dynamic>.from(json['formularioMaestro'] ?? {}),
      respuestas: (json['respuestas'] as List<dynamic>?)
              ?.map((e) => RespuestaEvaluacionHive.fromJson(e))
              .toList() ??
          [],
      ponderacionFinal: (json['ponderacionFinal'] ?? 0).toDouble(),
      fechaCaptura: DateTimeHelper.parseDateTimeWithFallback(json['fechaCaptura']),
      fechaHoraInicio: DateTimeHelper.parseDateTimeWithFallback(json['fechaHoraInicio']),
      fechaHoraFin: DateTimeHelper.parseDateTime(json['fechaHoraFin']),
      estatus: json['estatus'] ?? 'pendiente',
      observaciones: json['observaciones'],
      syncStatus: json['syncStatus'] ?? 'pending',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      metadatos: json['metadatos'] != null
          ? Map<String, dynamic>.from(json['metadatos'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liderClave': liderClave,
      'liderNombre': liderNombre,
      'liderCorreo': liderCorreo,
      'pais': pais,
      'ruta': ruta,
      'centroDistribucion': centroDistribucion,
      'tipoFormulario': tipoFormulario,
      'formularioMaestro': formularioMaestro,
      'respuestas': respuestas.map((e) => e.toJson()).toList(),
      'ponderacionFinal': ponderacionFinal,
      'fechaCaptura': fechaCaptura.toIso8601String(),
      'fechaHoraInicio': fechaHoraInicio.toIso8601String(),
      'fechaHoraFin': fechaHoraFin?.toIso8601String(),
      'estatus': estatus,
      'observaciones': observaciones,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadatos': metadatos,
    };
  }

  bool get estaCompletada => estatus == 'completada';
  bool get estaPendiente => estatus == 'pendiente';
  bool get requiresSync => syncStatus == 'pending';
  
  double calcularPonderacionTotal() {
    if (respuestas.isEmpty) return 0.0;
    
    double sumaPonderaciones = 0.0;
    int preguntasConPonderacion = 0;
    
    for (var respuesta in respuestas) {
      if (respuesta.ponderacion != null) {
        sumaPonderaciones += respuesta.ponderacion!;
        preguntasConPonderacion++;
      }
    }
    
    return preguntasConPonderacion > 0 
        ? sumaPonderaciones / preguntasConPonderacion 
        : 0.0;
  }
}

@HiveType(typeId: 51)
class RespuestaEvaluacionHive extends HiveObject {
  @HiveField(0)
  String preguntaId;

  @HiveField(1)
  String preguntaTitulo;

  @HiveField(2)
  String? categoria;

  @HiveField(3)
  String tipoPregunta;

  @HiveField(4)
  dynamic respuesta;

  @HiveField(5)
  double? ponderacion;

  @HiveField(6)
  DateTime timestampRespuesta;

  @HiveField(7)
  Map<String, dynamic>? configuracionPregunta;

  RespuestaEvaluacionHive({
    required this.preguntaId,
    required this.preguntaTitulo,
    this.categoria,
    required this.tipoPregunta,
    required this.respuesta,
    this.ponderacion,
    required this.timestampRespuesta,
    this.configuracionPregunta,
  });

  factory RespuestaEvaluacionHive.fromJson(Map<String, dynamic> json) {
    return RespuestaEvaluacionHive(
      preguntaId: json['preguntaId'] ?? '',
      preguntaTitulo: json['preguntaTitulo'] ?? '',
      categoria: json['categoria'],
      tipoPregunta: json['tipoPregunta'] ?? '',
      respuesta: json['respuesta'],
      ponderacion: json['ponderacion']?.toDouble(),
      timestampRespuesta: DateTimeHelper.parseDateTimeWithFallback(json['timestampRespuesta']),
      configuracionPregunta: json['configuracionPregunta'] != null
          ? Map<String, dynamic>.from(json['configuracionPregunta'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preguntaId': preguntaId,
      'preguntaTitulo': preguntaTitulo,
      'categoria': categoria,
      'tipoPregunta': tipoPregunta,
      'respuesta': respuesta,
      'ponderacion': ponderacion,
      'timestampRespuesta': timestampRespuesta.toIso8601String(),
      'configuracionPregunta': configuracionPregunta,
    };
  }

  String get respuestaComoTexto {
    if (respuesta == null) return 'Sin respuesta';
    
    if (respuesta is List) {
      return (respuesta as List).join(', ');
    } else if (respuesta is Map) {
      return respuesta.toString();
    } else {
      return respuesta.toString();
    }
  }
}