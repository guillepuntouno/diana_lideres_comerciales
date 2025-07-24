// lib/modelos/indicador_gestion_modelo.dart

class IndicadorGestionModelo {
  final String id;
  final String nombre;
  final String descripcion;
  final String tipoResultado; // 'numero' o 'porcentaje'
  final bool activo;
  final int orden;

  IndicadorGestionModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoResultado,
    this.activo = true,
    this.orden = 0,
  });

  factory IndicadorGestionModelo.fromJson(Map<String, dynamic> json) {
    return IndicadorGestionModelo(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tipoResultado: json['tipoResultado'] ?? 'numero',
      activo: json['activo'] ?? true,
      orden: json['orden'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipoResultado': tipoResultado,
      'activo': activo,
      'orden': orden,
    };
  }
}

class ClienteIndicadorModelo {
  final String planVisitaId;
  final String rutaId;
  final String clienteId;
  final String clienteNombre;
  final List<String> indicadorIds;
  final Map<String, String> resultados; // Mapa de indicadorId -> resultado
  final String? comentario;
  final String userId;
  final DateTime timestamp;
  bool completado;

  ClienteIndicadorModelo({
    required this.planVisitaId,
    required this.rutaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.indicadorIds,
    Map<String, String>? resultados,
    this.comentario,
    required this.userId,
    required this.timestamp,
    this.completado = false,
  }) : resultados = resultados ?? {};

  factory ClienteIndicadorModelo.fromJson(Map<String, dynamic> json) {
    return ClienteIndicadorModelo(
      planVisitaId: json['planVisitaId'],
      rutaId: json['rutaId'],
      clienteId: json['clienteId'],
      clienteNombre: json['clienteNombre'],
      indicadorIds: List<String>.from(json['indicadorIds'] ?? []),
      resultados: Map<String, String>.from(json['resultados'] ?? {}),
      comentario: json['comentario'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      completado: json['completado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planVisitaId': planVisitaId,
      'rutaId': rutaId,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'indicadorIds': indicadorIds,
      'resultados': resultados,
      'comentario': comentario,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'completado': completado,
    };
  }
}

// Catálogo inicial de indicadores
class CatalogoIndicadores {
  static List<IndicadorGestionModelo> get indicadoresIniciales => [
    IndicadorGestionModelo(
      id: '1',
      nombre: 'Venta actual',
      descripcion: 'Ventas del período actual',
      tipoResultado: 'numero',
      orden: 1,
    ),
    IndicadorGestionModelo(
      id: '2',
      nombre: 'Venta AA',
      descripcion: 'Ventas del año anterior',
      tipoResultado: 'numero',
      orden: 2,
    ),
    IndicadorGestionModelo(
      id: '3',
      nombre: '% Crec. vs AA',
      descripcion: 'Porcentaje de crecimiento vs año anterior',
      tipoResultado: 'porcentaje',
      orden: 3,
    ),
    IndicadorGestionModelo(
      id: '4',
      nombre: 'Decrecimiento 2 meses sin compra',
      descripcion: 'Cliente sin compras en los últimos 2 meses',
      tipoResultado: 'numero',
      orden: 4,
    ),
    IndicadorGestionModelo(
      id: '5',
      nombre: 'Mix de productos',
      descripcion: 'Variedad de productos comprados',
      tipoResultado: 'numero',
      orden: 5,
    ),
    IndicadorGestionModelo(
      id: '6',
      nombre: 'Frecuencia de visita',
      descripcion: 'Frecuencia de visitas al cliente',
      tipoResultado: 'numero',
      orden: 6,
    ),
    IndicadorGestionModelo(
      id: '7',
      nombre: 'Ticket promedio',
      descripcion: 'Valor promedio de compra',
      tipoResultado: 'numero',
      orden: 7,
    ),
    IndicadorGestionModelo(
      id: '8',
      nombre: 'Productos nuevos',
      descripcion: 'Introducción de productos nuevos',
      tipoResultado: 'numero',
      orden: 8,
    ),
    IndicadorGestionModelo(
      id: '9',
      nombre: 'Cumplimiento de cuota',
      descripcion: 'Porcentaje de cumplimiento de cuota asignada',
      tipoResultado: 'porcentaje',
      orden: 9,
    ),
    IndicadorGestionModelo(
      id: '10',
      nombre: 'Estatus de crédito',
      descripcion: 'Situación crediticia del cliente',
      tipoResultado: 'porcentaje',
      orden: 10,
    ),
    IndicadorGestionModelo(
      id: '11',
      nombre: 'Punto de equilibrio',
      descripcion: 'Punto de equilibrio del cliente',
      tipoResultado: 'porcentaje',
      orden: 11,
    ),
  ];
}