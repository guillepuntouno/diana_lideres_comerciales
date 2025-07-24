// lib/modelos/notificacion_modelo.dart
class NotificacionModelo {
  final String id;
  final String titulo;
  final String mensaje;
  final String
  tipo; // 'visita_completada', 'compromisos_creados', 'sincronizacion'
  final DateTime fechaCreacion;
  final bool leida;
  final Map<String, dynamic>? datos; // Datos adicionales para navegación
  final String? iconoUrl;
  final String? accionUrl; // Ruta para navegar al tocar

  NotificacionModelo({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fechaCreacion,
    this.leida = false,
    this.datos,
    this.iconoUrl,
    this.accionUrl,
  });

  /// Crear desde JSON
  factory NotificacionModelo.fromJson(Map<String, dynamic> json) {
    return NotificacionModelo(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? '',
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
        json['fechaCreacion'] ?? 0,
      ),
      leida: json['leida'] ?? false,
      datos:
          json['datos'] != null
              ? Map<String, dynamic>.from(json['datos'])
              : null,
      iconoUrl: json['iconoUrl'],
      accionUrl: json['accionUrl'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
      'leida': leida,
      'datos': datos,
      'iconoUrl': iconoUrl,
      'accionUrl': accionUrl,
    };
  }

  /// Crear copia con cambios
  NotificacionModelo copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    String? tipo,
    DateTime? fechaCreacion,
    bool? leida,
    Map<String, dynamic>? datos,
    String? iconoUrl,
    String? accionUrl,
  }) {
    return NotificacionModelo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      leida: leida ?? this.leida,
      datos: datos ?? this.datos,
      iconoUrl: iconoUrl ?? this.iconoUrl,
      accionUrl: accionUrl ?? this.accionUrl,
    );
  }

  /// Marcar como leída
  NotificacionModelo marcarComoLeida() {
    return copyWith(leida: true);
  }

  /// Verificar si es de hoy
  bool get esDeHoy {
    final ahora = DateTime.now();
    return fechaCreacion.year == ahora.year &&
        fechaCreacion.month == ahora.month &&
        fechaCreacion.day == ahora.day;
  }

  /// Obtener tiempo relativo
  String get tiempoRelativo {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaCreacion);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inHours < 1) {
      return '${diferencia.inMinutes}min';
    } else if (diferencia.inDays < 1) {
      return '${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays}d';
    } else {
      return '${fechaCreacion.day}/${fechaCreacion.month}';
    }
  }

  @override
  String toString() =>
      'NotificacionModelo(id: $id, titulo: $titulo, tipo: $tipo)';
}
