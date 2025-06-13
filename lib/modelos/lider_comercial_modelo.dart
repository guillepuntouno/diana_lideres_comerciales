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

    // Obtener rutas de manera más segura
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

    return LiderComercial(
      centroDistribucion:
          json['CentroDistribucion'] ?? json['centroDistribucion'] ?? '',
      clave: json['Clave'] ?? json['clave'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
      pais: json['Pais'] ?? json['pais'] ?? '',
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

  Ruta({required this.asesor, required this.nombre, required this.negocios});

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

    return Ruta(
      asesor: json['Asesor'] ?? json['asesor'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
      negocios: negociosList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asesor': asesor,
      'nombre': nombre,
      'negocios': negocios.map((negocio) => negocio.toJson()).toList(),
    };
  }
}

class Negocio {
  final String canal;
  final String clasificacion;
  final String clave;
  final String exhibidor;
  final String nombre;

  Negocio({
    required this.canal,
    required this.clasificacion,
    required this.clave,
    required this.exhibidor,
    required this.nombre,
  });

  factory Negocio.fromJson(Map<String, dynamic> json) {
    return Negocio(
      canal: json['Canal'] ?? json['canal'] ?? '',
      clasificacion: json['Clasificacion'] ?? json['clasificacion'] ?? '',
      clave: json['Clave'] ?? json['clave'] ?? '',
      exhibidor: json['Exhibidor'] ?? json['exhibidor'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canal': canal,
      'clasificacion': clasificacion,
      'clave': clave,
      'exhibidor': exhibidor,
      'nombre': nombre,
    };
  }
}
