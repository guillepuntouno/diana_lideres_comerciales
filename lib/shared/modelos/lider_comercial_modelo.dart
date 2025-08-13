class LiderComercial {
  final String centroDistribucion;
  final String clave;
  final String nombre;
  final String pais;
  final List<Ruta> rutas;

  LiderComercial({
    required this.centroDistribucion,
    required this.clave,
    required this.nombre,
    required this.pais,
    required this.rutas,
  });

  factory LiderComercial.fromJson(Map<String, dynamic> json) {
    print('Parseando JSON: $json'); // Debug

    // Obtener rutas de manera más segura - adaptado para nueva estructura AWS
    List<Ruta> rutasList = [];
    final rutasData = json['Rutas'] ?? json['rutas'];
    if (rutasData != null && rutasData is List) {
      rutasList =
          rutasData
              .map<Ruta>(
                (rutaJson) => Ruta.fromJson(rutaJson as Map<String, dynamic>),
              )
              .toList();
    }

    // Adaptación para manejar ambas estructuras (anterior y nueva de AWS)
    return LiderComercial(
      centroDistribucion:
          json['CD'] ?? json['CentroDistribucion'] ?? json['centroDistribucion'] ?? '',
      clave: json['clave'] ?? json['Clave'] ?? json['CoSEupervisor']?.toString() ?? '',
      nombre: json['nombre'] ?? json['Nombre'] ?? json['idLider'] ?? json['Supervisor'] ?? '',
      pais: json['pais'] ?? json['Pais'] ?? '',
      rutas: rutasList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centroDistribucion': centroDistribucion,
      'clave': clave,
      'nombre': nombre,
      'pais': pais,
      'rutas': rutas.map((ruta) => ruta.toJson()).toList(),
    };
  }
}

class Ruta {
  final String asesor;
  final String nombre;
  final List<Negocio> negocios;
  final String diaVisitaCod; // Nuevo campo para DIA_VISITA_COD

  Ruta({
    required this.asesor, 
    required this.nombre, 
    required this.negocios,
    this.diaVisitaCod = '', // Valor por defecto
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    // Obtener negocios de manera más segura
    List<Negocio> negociosList = [];
    final negociosData = json['Negocios'] ?? json['negocios'];
    if (negociosData != null && negociosData is List) {
      negociosList =
          negociosData
              .map<Negocio>(
                (negocioJson) =>
                    Negocio.fromJson(negocioJson as Map<String, dynamic>),
              )
              .toList();
    }

    // Adaptación para nueva estructura AWS
    return Ruta(
      asesor: json['Asesor'] ?? json['asesor'] ?? json['Canal_clientevend'] ?? '',
      nombre: json['Ruta'] ?? json['idRuta'] ?? json['Nombre'] ?? json['nombre'] ?? '',
      negocios: negociosList,
      diaVisitaCod: json['DIA_VISITA_COD'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asesor': asesor,
      'nombre': nombre,
      'negocios': negocios.map((negocio) => negocio.toJson()).toList(),
      'diaVisitaCod': diaVisitaCod,
    };
  }
}

class Negocio {
  final String canal;
  final String clasificacion;
  final String clave;
  final String exhibidor;
  final String nombre;
  final String direccion;
  final String subcanal;

  Negocio({
    required this.canal,
    required this.clasificacion,
    required this.clave,
    required this.exhibidor,
    required this.nombre,
    this.direccion = '',
    this.subcanal = '',
  });

  factory Negocio.fromJson(Map<String, dynamic> json) {
    return Negocio(
      canal: json['Canal'] ?? json['canal'] ?? json['CANAL_VENTA'] ?? '',
      clasificacion: json['Clasificacion'] ?? json['clasificacion'] ?? json['CLASIFICACION_CLIENTE'] ?? '',
      clave: json['Clave'] ?? json['clave'] ?? json['CODIGO_CLIENTE'] ?? '',
      exhibidor: json['Exhibidor'] ?? json['exhibidor'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? json['NOMBRE_CLIENTE'] ?? '',
      direccion: json['direccion'] ?? json['DIRECCION CLIENTE'] ?? '',
      subcanal: json['subcanal'] ?? json['SUBCANAL_VENTA'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canal': canal,
      'clasificacion': clasificacion,
      'clave': clave,
      'exhibidor': exhibidor,
      'nombre': nombre,
      'direccion': direccion,
      'subcanal': subcanal,
    };
  }
}
