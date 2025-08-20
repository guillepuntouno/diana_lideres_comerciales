class OpcionDTO {
  final String valor;
  final String? etiqueta;
  final double? puntuacion;
  final int? orden;

  OpcionDTO({
    required this.valor,
    this.etiqueta,
    this.puntuacion,
    this.orden,
  });

  factory OpcionDTO.fromJson(Map<String, dynamic> json) {
    return OpcionDTO(
      valor: json['valor'] ?? '',
      etiqueta: json['etiqueta'],
      puntuacion: json['puntuacion'] != null 
          ? (json['puntuacion'] is int 
              ? (json['puntuacion'] as int).toDouble() 
              : json['puntuacion'] as double)
          : null,
      orden: json['orden'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valor': valor,
      if (etiqueta != null) 'etiqueta': etiqueta,
      if (puntuacion != null) 'puntuacion': puntuacion,
      if (orden != null) 'orden': orden,
    };
  }
}