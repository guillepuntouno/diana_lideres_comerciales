import 'package:diana_lc_front/shared/modelos/opcion_dto.dart';

class PreguntaDTO {
  final String id;
  final String name;
  final String etiqueta;
  final String tipoEntrada;
  final bool obligatorio;
  final String? placeholder;
  final List<OpcionDTO> opciones;
  final String? seccion;
  final int? orden;
  final Map<String, dynamic>? validaciones;

  PreguntaDTO({
    required this.id,
    required this.name,
    required this.etiqueta,
    required this.tipoEntrada,
    this.obligatorio = false,
    this.placeholder,
    this.opciones = const [],
    this.seccion,
    this.orden,
    this.validaciones,
  });

  factory PreguntaDTO.fromJson(Map<String, dynamic> json) {
    List<OpcionDTO> opcionesList = [];
    
    if (json['opciones'] != null && json['opciones'] is List) {
      opcionesList = (json['opciones'] as List)
          .map((opcion) => OpcionDTO.fromJson(opcion))
          .toList();
    }

    return PreguntaDTO(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? '',
      etiqueta: json['etiqueta'] ?? json['label'] ?? '',
      tipoEntrada: json['tipoEntrada'] ?? json['type'] ?? 'text',
      obligatorio: json['obligatorio'] ?? json['required'] ?? false,
      placeholder: json['placeholder'],
      opciones: opcionesList,
      seccion: json['section'] ?? json['seccion'],
      orden: json['orden'],
      validaciones: json['validaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'etiqueta': etiqueta,
      'tipoEntrada': tipoEntrada,
      'obligatorio': obligatorio,
      if (placeholder != null) 'placeholder': placeholder,
      'opciones': opciones.map((e) => e.toJson()).toList(),
      if (seccion != null) 'seccion': seccion,
      if (orden != null) 'orden': orden,
      if (validaciones != null) 'validaciones': validaciones,
    };
  }
}