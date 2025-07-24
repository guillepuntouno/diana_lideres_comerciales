enum ActivityType { admin, visita }

enum ActivityStatus { pendiente, enCurso, completada, postergada }

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String? asesor;
  final String? cliente;
  final String? direccion;
  ActivityStatus status;
  DateTime? horaInicio;
  DateTime? horaFin;
  Map<String, dynamic>? metadata; // Para datos adicionales del plan unificado

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.asesor,
    this.cliente,
    this.direccion,
    this.status = ActivityStatus.pendiente,
    this.horaInicio,
    this.horaFin,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'asesor': asesor,
    'cliente': cliente,
    'direccion': direccion,
    'status': status.name,
    'horaInicio': horaInicio?.millisecondsSinceEpoch,
    'horaFin': horaFin?.millisecondsSinceEpoch,
    'metadata': metadata,
  };

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id: json['id'],
    type: ActivityType.values.firstWhere((e) => e.name == json['type']),
    title: json['title'],
    asesor: json['asesor'],
    cliente: json['cliente'],
    direccion: json['direccion'],
    status: ActivityStatus.values.firstWhere((e) => e.name == json['status']),
    horaInicio:
        json['horaInicio'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['horaInicio'])
            : null,
    horaFin:
        json['horaFin'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['horaFin'])
            : null,
    metadata: json['metadata'],
  );
}
