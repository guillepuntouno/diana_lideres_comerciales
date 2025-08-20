import 'package:diana_lc_front/shared/modelos/pregunta_dto.dart';

class FormularioEvaluacionDTO {
  final String id;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final List<String> canales;
  final bool activo;
  final List<PreguntaDTO> preguntas;
  final Map<String, dynamic>? resultadoKPI;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final int? version;

  FormularioEvaluacionDTO({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.tipo,
    this.canales = const [],
    this.activo = true,
    this.preguntas = const [],
    this.resultadoKPI,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.version,
  });

  factory FormularioEvaluacionDTO.fromJson(Map<String, dynamic> json) {
    List<PreguntaDTO> preguntasList = [];
    
    if (json['preguntas'] != null && json['preguntas'] is List) {
      preguntasList = (json['preguntas'] as List)
          .map((pregunta) => PreguntaDTO.fromJson(pregunta))
          .toList();
    }

    List<String> canalesList = [];
    if (json['canales'] != null && json['canales'] is List) {
      canalesList = (json['canales'] as List).map((e) => e.toString()).toList();
    } else if (json['canal'] != null) {
      // Si viene un campo 'canal' en lugar de 'canales', usarlo
      canalesList = [json['canal'].toString()];
    }

    return FormularioEvaluacionDTO(
      id: json['id'] ?? json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      tipo: json['tipo'] ?? '',
      canales: canalesList,
      activo: json['activo'] ?? true,
      preguntas: preguntasList,
      resultadoKPI: json['resultadoKPI'],
      fechaCreacion: json['fechaCreacion'] != null 
          ? DateTime.tryParse(json['fechaCreacion']) 
          : json['createdAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
              : null,
      fechaActualizacion: json['fechaActualizacion'] != null 
          ? DateTime.tryParse(json['fechaActualizacion']) 
          : json['updatedAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
              : null,
      version: json['version'] is String 
          ? int.tryParse(json['version']) 
          : json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'tipo': tipo,
      'canales': canales,
      'activo': activo,
      'preguntas': preguntas.map((e) => e.toJson()).toList(),
      if (resultadoKPI != null) 'resultadoKPI': resultadoKPI,
      if (fechaCreacion != null) 'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null) 'fechaActualizacion': fechaActualizacion!.toIso8601String(),
      if (version != null) 'version': version,
    };
  }

  // Método helper para verificar si el formulario aplica para un canal específico
  bool aplicaParaCanal(String canal) {
    if (canales.isEmpty) return true; // Si no hay canales específicos, aplica para todos
    return canales.any((c) => c.toLowerCase() == canal.toLowerCase());
  }
}