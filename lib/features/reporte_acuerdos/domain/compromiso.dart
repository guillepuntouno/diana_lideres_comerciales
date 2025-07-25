class Compromiso {
  final String id;
  final String tipo;
  final String detalle;
  final int? cantidad;
  final String fecha;
  final String clienteId;
  final String clienteNombre;
  final String rutaId;
  final String status;
  final String createdAt;
  final String? retroalimentacion;
  final String? reconocimiento;
  final String? visitaId;

  Compromiso({
    required this.id,
    required this.tipo,
    required this.detalle,
    required this.cantidad,
    required this.fecha,
    required this.clienteId,
    required this.clienteNombre,
    required this.rutaId,
    required this.status,
    required this.createdAt,
    this.retroalimentacion,
    this.reconocimiento,
    this.visitaId,
  });

  bool get isPending => status.toUpperCase() == 'PENDIENTE';
  bool get isCompleted => status.toUpperCase() == 'CERRADO' || status.toUpperCase() == 'COMPLETADO';
  bool get isCancelled => status.toUpperCase() == 'CANCELADO';
}