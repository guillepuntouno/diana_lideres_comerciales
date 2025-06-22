import 'package:hive/hive.dart';
import '../lider_comercial_modelo.dart';

part 'lider_comercial_hive.g.dart';

@HiveType(typeId: 1)
class LiderComercialHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String centroDistribucion;

  @HiveField(2)
  String clave;

  @HiveField(3)
  String nombre;

  @HiveField(4)
  String pais;

  @HiveField(5)
  List<RutaHive> rutas;

  @HiveField(6)
  String syncStatus;

  @HiveField(7)
  DateTime lastUpdated;

  LiderComercialHive({
    required this.id,
    required this.centroDistribucion,
    required this.clave,
    required this.nombre,
    required this.pais,
    required this.rutas,
    this.syncStatus = 'synced',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory LiderComercialHive.fromLiderComercial(LiderComercial lider) {
    final rutasHive = lider.rutas
        .map((ruta) => RutaHive.fromRuta(ruta))
        .toList();

    return LiderComercialHive(
      id: lider.clave,
      centroDistribucion: lider.centroDistribucion,
      clave: lider.clave,
      nombre: lider.nombre,
      pais: lider.pais,
      rutas: rutasHive,
      syncStatus: 'synced',
    );
  }

  LiderComercial toLiderComercial() {
    final rutasRegular = rutas
        .map((rutaHive) => rutaHive.toRuta())
        .toList();

    return LiderComercial(
      centroDistribucion: centroDistribucion,
      clave: clave,
      nombre: nombre,
      pais: pais,
      rutas: rutasRegular,
    );
  }

  factory LiderComercialHive.fromJson(Map<String, dynamic> json) {
    List<RutaHive> rutasList = [];
    final rutasData = json['Rutas'] ?? json['rutas'];
    if (rutasData != null && rutasData is List) {
      rutasList = rutasData
          .map<RutaHive>((rutaJson) => RutaHive.fromJson(rutaJson as Map<String, dynamic>))
          .toList();
    }

    return LiderComercialHive(
      id: json['id'] ?? json['Id'] ?? '',
      centroDistribucion: json['CentroDistribucion'] ?? json['centroDistribucion'] ?? '',
      clave: json['Clave'] ?? json['clave'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
      pais: json['Pais'] ?? json['pais'] ?? '',
      rutas: rutasList,
      syncStatus: json['syncStatus'] ?? 'synced',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centroDistribucion': centroDistribucion,
      'clave': clave,
      'nombre': nombre,
      'pais': pais,
      'rutas': rutas.map((ruta) => ruta.toJson()).toList(),
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

@HiveType(typeId: 2)
class RutaHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String asesor;

  @HiveField(2)
  String nombre;

  @HiveField(3)
  List<NegocioHive> negocios;

  @HiveField(4)
  String syncStatus;

  @HiveField(5)
  DateTime lastUpdated;

  RutaHive({
    required this.id,
    required this.asesor,
    required this.nombre,
    required this.negocios,
    this.syncStatus = 'synced',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory RutaHive.fromRuta(Ruta ruta) {
    final negociosHive = ruta.negocios
        .map((negocio) => NegocioHive.fromNegocio(negocio))
        .toList();

    return RutaHive(
      id: '${ruta.nombre}_${DateTime.now().millisecondsSinceEpoch}',
      asesor: ruta.asesor,
      nombre: ruta.nombre,
      negocios: negociosHive,
      syncStatus: 'synced',
    );
  }

  Ruta toRuta() {
    final negociosRegular = negocios
        .map((negocioHive) => negocioHive.toNegocio())
        .toList();

    return Ruta(
      asesor: asesor,
      nombre: nombre,
      negocios: negociosRegular,
    );
  }

  factory RutaHive.fromJson(Map<String, dynamic> json) {
    List<NegocioHive> negociosList = [];
    final negociosData = json['Negocios'] ?? json['negocios'];
    if (negociosData != null && negociosData is List) {
      negociosList = negociosData
          .map<NegocioHive>((negocioJson) => NegocioHive.fromJson(negocioJson as Map<String, dynamic>))
          .toList();
    }

    return RutaHive(
      id: json['id'] ?? json['Id'] ?? '',
      asesor: json['Asesor'] ?? json['asesor'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
      negocios: negociosList,
      syncStatus: json['syncStatus'] ?? 'synced',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asesor': asesor,
      'nombre': nombre,
      'negocios': negocios.map((negocio) => negocio.toJson()).toList(),
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

@HiveType(typeId: 3)
class NegocioHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String canal;

  @HiveField(2)
  String clasificacion;

  @HiveField(3)
  String clave;

  @HiveField(4)
  String exhibidor;

  @HiveField(5)
  String nombre;

  @HiveField(6)
  String syncStatus;

  @HiveField(7)
  DateTime lastUpdated;

  NegocioHive({
    required this.id,
    required this.canal,
    required this.clasificacion,
    required this.clave,
    required this.exhibidor,
    required this.nombre,
    this.syncStatus = 'synced',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory NegocioHive.fromNegocio(Negocio negocio) {
    return NegocioHive(
      id: '${negocio.clave}_${DateTime.now().millisecondsSinceEpoch}',
      canal: negocio.canal,
      clasificacion: negocio.clasificacion,
      clave: negocio.clave,
      exhibidor: negocio.exhibidor,
      nombre: negocio.nombre,
      syncStatus: 'synced',
    );
  }

  Negocio toNegocio() {
    return Negocio(
      canal: canal,
      clasificacion: clasificacion,
      clave: clave,
      exhibidor: exhibidor,
      nombre: nombre,
    );
  }

  factory NegocioHive.fromJson(Map<String, dynamic> json) {
    return NegocioHive(
      id: json['id'] ?? json['Id'] ?? '',
      canal: json['Canal'] ?? json['canal'] ?? '',
      clasificacion: json['Clasificacion'] ?? json['clasificacion'] ?? '',
      clave: json['Clave'] ?? json['clave'] ?? '',
      exhibidor: json['Exhibidor'] ?? json['exhibidor'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
      syncStatus: json['syncStatus'] ?? 'synced',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canal': canal,
      'clasificacion': clasificacion,
      'clave': clave,
      'exhibidor': exhibidor,
      'nombre': nombre,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}