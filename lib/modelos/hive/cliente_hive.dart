import 'package:hive/hive.dart';

part 'cliente_hive.g.dart';

@HiveType(typeId: 12)
class ClienteHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String direccion;

  @HiveField(3)
  String? telefono;

  @HiveField(4)
  String rutaId;

  @HiveField(5)
  String rutaNombre;

  @HiveField(6)
  String? asesorId;

  @HiveField(7)
  String? asesorNombre;

  @HiveField(8)
  double? latitud;

  @HiveField(9)
  double? longitud;

  @HiveField(10)
  bool activo;

  @HiveField(11)
  DateTime fechaModificacion;

  @HiveField(12)
  String? tipoNegocio;

  @HiveField(13)
  String? segmento;

  @HiveField(14)
  String? pais;

  @HiveField(15)
  String? centroDistribucion;

  @HiveField(16)
  String? codigoLider;

  @HiveField(17)
  String? nombreLider;

  @HiveField(18)
  String? emailLider;

  @HiveField(19)
  String? canalVenta;

  @HiveField(20)
  String? subcanalVenta;

  @HiveField(21)
  String? estadoRuta;

  @HiveField(22)
  String? estadoCliente;

  @HiveField(23)
  String? clasificacionCliente;

  @HiveField(24)
  String? diaVisita;

  @HiveField(25)
  String? diaVisitaCod;

  ClienteHive({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.telefono,
    required this.rutaId,
    required this.rutaNombre,
    this.asesorId,
    this.asesorNombre,
    this.latitud,
    this.longitud,
    this.activo = true,
    DateTime? fechaModificacion,
    this.tipoNegocio,
    this.segmento,
    this.pais,
    this.centroDistribucion,
    this.codigoLider,
    this.nombreLider,
    this.emailLider,
    this.canalVenta,
    this.subcanalVenta,
    this.estadoRuta,
    this.estadoCliente,
    this.clasificacionCliente,
    this.diaVisita,
    this.diaVisitaCod,
  }) : fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'rutaId': rutaId,
      'rutaNombre': rutaNombre,
      'asesorId': asesorId,
      'asesorNombre': asesorNombre,
      'latitud': latitud,
      'longitud': longitud,
      'activo': activo,
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'tipoNegocio': tipoNegocio,
      'segmento': segmento,
      'pais': pais,
      'centroDistribucion': centroDistribucion,
      'codigoLider': codigoLider,
      'nombreLider': nombreLider,
      'emailLider': emailLider,
      'canalVenta': canalVenta,
      'subcanalVenta': subcanalVenta,
      'estadoRuta': estadoRuta,
      'estadoCliente': estadoCliente,
      'clasificacionCliente': clasificacionCliente,
      'diaVisita': diaVisita,
      'diaVisitaCod': diaVisitaCod,
    };
  }

  factory ClienteHive.fromJson(Map<String, dynamic> json) {
    return ClienteHive(
      id: json['id'] ?? json['CODIGO_CLIENTE'] ?? '',
      nombre: json['nombre'] ?? json['NOMBRE_CLIENTE'] ?? '',
      direccion: json['direccion'] ?? json['DIRECCION CLIENTE'] ?? '',
      telefono: json['telefono'],
      rutaId: json['rutaId'] ?? json['RUTA'] ?? '',
      rutaNombre: json['rutaNombre'] ?? json['RUTA'] ?? '',
      asesorId: json['asesorId'] ?? json['CODIGO_ASESOR'],
      asesorNombre: json['asesorNombre'] ?? json['NOMBRE_ASESOR'],
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      activo: json['activo'] ?? (json['ESTADO_CLIENTE'] == 'Activo'),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
      tipoNegocio: json['tipoNegocio'],
      segmento: json['segmento'],
      pais: json['pais'] ?? json['PAIS'],
      centroDistribucion: json['centroDistribucion'] ?? json['CD'],
      codigoLider: json['codigoLider'] ?? json['CODIGO_LIDER'],
      nombreLider: json['nombreLider'] ?? json['NOMBRE_LIDER'],
      emailLider: json['emailLider'] ?? json['EMAIL_LIDER'],
      canalVenta: json['canalVenta'] ?? json['CANAL_VENTA'],
      subcanalVenta: json['subcanalVenta'] ?? json['SUBCANAL_VENTA'],
      estadoRuta: json['estadoRuta'] ?? json['ESTADO_RUTA'],
      estadoCliente: json['estadoCliente'] ?? json['ESTADO_CLIENTE'],
      clasificacionCliente: json['clasificacionCliente'] ?? json['CLASIFICACION_CLIENTE'],
      diaVisita: json['diaVisita'] ?? json['DIA_VISITA'],
      diaVisitaCod: json['diaVisitaCod'] ?? json['DIA_VISITA_COD'],
    );
  }

  // Método para crear ClienteHive desde un Negocio y datos adicionales del contexto
  factory ClienteHive.fromNegocio(Map<String, dynamic> negocioJson, {
    String? rutaId,
    String? rutaNombre,
    String? asesorId,
    String? asesorNombre,
    String? codigoLider,
    String? nombreLider,
    String? emailLider,
    String? centroDistribucion,
  }) {
    return ClienteHive(
      id: negocioJson['CODIGO_CLIENTE'] ?? '',
      nombre: negocioJson['NOMBRE_CLIENTE'] ?? '',
      direccion: negocioJson['DIRECCION CLIENTE'] ?? '',
      telefono: null, // No viene en el JSON
      rutaId: rutaId ?? negocioJson['RUTA'] ?? '',
      rutaNombre: rutaNombre ?? negocioJson['RUTA'] ?? '',
      asesorId: asesorId ?? negocioJson['CODIGO_ASESOR']?.toString(),
      asesorNombre: asesorNombre ?? negocioJson['NOMBRE_ASESOR'],
      latitud: null, // Se puede actualizar después
      longitud: null, // Se puede actualizar después
      activo: negocioJson['ESTADO_CLIENTE'] == 'Activo',
      tipoNegocio: null, // No viene en el JSON
      segmento: null, // No viene en el JSON
      pais: negocioJson['PAIS'],
      centroDistribucion: centroDistribucion ?? negocioJson['CD'],
      codigoLider: codigoLider ?? negocioJson['CODIGO_LIDER']?.toString(),
      nombreLider: nombreLider ?? negocioJson['NOMBRE_LIDER'],
      emailLider: emailLider ?? negocioJson['EMAIL_LIDER'],
      canalVenta: negocioJson['CANAL_VENTA'],
      subcanalVenta: negocioJson['SUBCANAL_VENTA'],
      estadoRuta: negocioJson['ESTADO_RUTA'],
      estadoCliente: negocioJson['ESTADO_CLIENTE'],
      clasificacionCliente: negocioJson['CLASIFICACION_CLIENTE'],
      diaVisita: negocioJson['DIA_VISITA'],
      diaVisitaCod: negocioJson['DIA_VISITA_COD'],
    );
  }
}