// lib/modelos/plan_trabajo_modelo.dart

class PlanTrabajoModelo {
  final String semana;
  final String fechaInicio;
  final String fechaFin;
  final String liderId;
  final String liderNombre;
  final String centroDistribucion;
  String estatus; // 'borrador', 'programado', 'en_ejecucion', 'finalizado'
  final Map<String, DiaTrabajoModelo> dias;
  final DateTime fechaCreacion;
  DateTime fechaModificacion;
  bool sincronizado;

  PlanTrabajoModelo({
    required this.semana,
    required this.fechaInicio,
    required this.fechaFin,
    required this.liderId,
    required this.liderNombre,
    required this.centroDistribucion,
    this.estatus = 'borrador',
    Map<String, DiaTrabajoModelo>? dias,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    this.sincronizado = false,
  }) : dias = dias ?? {},
       fechaCreacion = fechaCreacion ?? DateTime.now(),
       fechaModificacion = fechaModificacion ?? DateTime.now();

  factory PlanTrabajoModelo.fromJson(Map<String, dynamic> json) {
    return PlanTrabajoModelo(
      semana: json['semana'],
      fechaInicio: json['fechaInicio'],
      fechaFin: json['fechaFin'],
      liderId: json['liderId'],
      liderNombre: json['liderNombre'],
      centroDistribucion: json['centroDistribucion'],
      estatus: json['estatus'],
      dias: (json['dias'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, DiaTrabajoModelo.fromJson(value)),
      ),
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaModificacion: DateTime.parse(json['fechaModificacion']),
      sincronizado: json['sincronizado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semana': semana,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'liderId': liderId,
      'liderNombre': liderNombre,
      'centroDistribucion': centroDistribucion,
      'estatus': estatus,
      'dias': dias.map((key, value) => MapEntry(key, value.toJson())),
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'sincronizado': sincronizado,
    };
  }
}

class DiaTrabajoModelo {
  final String dia;
  final String? objetivo;
  final String? tipo; // 'administrativo' o 'gestion_cliente'
  final String? centroDistribucion;
  final String? rutaId;
  final String? rutaNombre;
  final String? tipoActividad; // NUEVO CAMPO - Para actividades administrativas
  final String? comentario; // NUEVO CAMPO - Comentarios opcionales
  final List<ClienteAsignadoModelo> clientesAsignados;
  bool completado;

  DiaTrabajoModelo({
    required this.dia,
    this.objetivo,
    this.tipo,
    this.centroDistribucion,
    this.rutaId,
    this.rutaNombre,
    this.tipoActividad, // NUEVO PARÁMETRO
    this.comentario, // NUEVO PARÁMETRO
    List<ClienteAsignadoModelo>? clientesAsignados,
    this.completado = false,
  }) : clientesAsignados = clientesAsignados ?? [];

  factory DiaTrabajoModelo.fromJson(Map<String, dynamic> json) {
    return DiaTrabajoModelo(
      dia: json['dia'],
      objetivo: json['objetivo'],
      tipo: json['tipo'],
      centroDistribucion: json['centroDistribucion'],
      rutaId: json['rutaId'],
      rutaNombre: json['rutaNombre'],
      tipoActividad: json['tipoActividad'], // NUEVO CAMPO fromJson
      comentario: json['comentario'], // NUEVO CAMPO fromJson
      clientesAsignados:
          (json['clientesAsignados'] as List<dynamic>?)
              ?.map((c) => ClienteAsignadoModelo.fromJson(c))
              .toList() ??
          [],
      completado: json['completado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'objetivo': objetivo,
      'tipo': tipo,
      'centroDistribucion': centroDistribucion,
      'rutaId': rutaId,
      'rutaNombre': rutaNombre,
      'tipoActividad': tipoActividad, // NUEVO CAMPO toJson
      'comentario': comentario, // NUEVO CAMPO toJson
      'clientesAsignados': clientesAsignados.map((c) => c.toJson()).toList(),
      'completado': completado,
    };
  }
}

class ClienteAsignadoModelo {
  final String clienteId;
  final String clienteNombre;
  final String clienteDireccion;
  final String clienteTipo; // 'detalle' o 'mayoreo'
  bool visitado;
  DateTime? fechaVisita;

  ClienteAsignadoModelo({
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteDireccion,
    required this.clienteTipo,
    this.visitado = false,
    this.fechaVisita,
  });

  factory ClienteAsignadoModelo.fromJson(Map<String, dynamic> json) {
    return ClienteAsignadoModelo(
      clienteId: json['clienteId'],
      clienteNombre: json['clienteNombre'],
      clienteDireccion: json['clienteDireccion'],
      clienteTipo: json['clienteTipo'],
      visitado: json['visitado'] ?? false,
      fechaVisita:
          json['fechaVisita'] != null
              ? DateTime.parse(json['fechaVisita'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteDireccion': clienteDireccion,
      'clienteTipo': clienteTipo,
      'visitado': visitado,
      'fechaVisita': fechaVisita?.toIso8601String(),
    };
  }
}
