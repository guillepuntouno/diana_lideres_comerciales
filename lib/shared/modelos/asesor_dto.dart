class AsesorDTO {
  final String codigo;
  final String nombre;
  final String pais;
  final String canal;
  final String? codigoLider;
  final bool activo;

  AsesorDTO({
    required this.codigo,
    required this.nombre,
    required this.pais,
    required this.canal,
    this.codigoLider,
    this.activo = true,
  });

  factory AsesorDTO.fromJson(Map<String, dynamic> json) {
    return AsesorDTO(
      codigo: json['CODIGO_ASESOR'] ?? json['codigo'] ?? '',
      nombre: json['NOMBRE_ASESOR'] ?? json['nombre'] ?? '',
      pais: json['PAIS'] ?? json['pais'] ?? '',
      canal: json['canal'] ?? '', // No viene en la respuesta actual
      codigoLider: json['CODIGO_LIDER'] ?? json['codigoLider'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'pais': pais,
      'canal': canal,
      'codigoLider': codigoLider,
      'activo': activo,
    };
  }

  @override
  String toString() {
    return 'AsesorDTO(codigo: $codigo, nombre: $nombre, pais: $pais, canal: $canal)';
  }
}