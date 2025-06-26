import 'package:hive/hive.dart';

part 'plan_trabajo_unificado_hive.g.dart';

@HiveType(typeId: 15)
class PlanTrabajoUnificadoHive extends HiveObject {
  @HiveField(0)
  String id; // Format: LIDERCLAVE_SEMXX_YYYY

  @HiveField(1)
  String semana; // Format: "SEMANA XX - YYYY"

  @HiveField(2)
  int numeroSemana;

  @HiveField(3)
  int anio;

  @HiveField(4)
  String liderClave;

  @HiveField(5)
  String liderNombre;

  @HiveField(6)
  String centroDistribucion;

  @HiveField(7)
  String fechaInicio;

  @HiveField(8)
  String fechaFin;

  @HiveField(9)
  String estatus; // 'borrador', 'enviado'

  @HiveField(10)
  DateTime fechaCreacion;

  @HiveField(11)
  DateTime fechaModificacion;

  @HiveField(12)
  bool sincronizado;

  @HiveField(13)
  DateTime? fechaUltimaSincronizacion;

  @HiveField(14)
  Map<String, DiaPlanHive> dias; // Lunes, Martes, etc.

  PlanTrabajoUnificadoHive({
    required this.id,
    required this.semana,
    required this.numeroSemana,
    required this.anio,
    required this.liderClave,
    required this.liderNombre,
    required this.centroDistribucion,
    required this.fechaInicio,
    required this.fechaFin,
    this.estatus = 'borrador',
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    this.sincronizado = false,
    this.fechaUltimaSincronizacion,
    Map<String, DiaPlanHive>? dias,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now(),
        dias = dias ?? {};

  Map<String, dynamic> toJsonCompleto() {
    return {
      'id': id,
      'semana': semana,
      'numeroSemana': numeroSemana,
      'anio': anio,
      'liderClave': liderClave,
      'liderNombre': liderNombre,
      'centroDistribucion': centroDistribucion,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'estatus': estatus,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'sincronizado': sincronizado,
      'fechaUltimaSincronizacion': fechaUltimaSincronizacion?.toIso8601String(),
      'dias': dias.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory PlanTrabajoUnificadoHive.fromJson(Map<String, dynamic> json) {
    return PlanTrabajoUnificadoHive(
      id: json['id'],
      semana: json['semana'],
      numeroSemana: json['numeroSemana'],
      anio: json['anio'],
      liderClave: json['liderClave'],
      liderNombre: json['liderNombre'],
      centroDistribucion: json['centroDistribucion'],
      fechaInicio: json['fechaInicio'],
      fechaFin: json['fechaFin'],
      estatus: json['estatus'] ?? 'borrador',
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
      sincronizado: json['sincronizado'] ?? false,
      fechaUltimaSincronizacion: json['fechaUltimaSincronizacion'] != null
          ? DateTime.parse(json['fechaUltimaSincronizacion'])
          : null,
      dias: (json['dias'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, DiaPlanHive.fromJson(value)),
          ) ?? {},
    );
  }

  // Helper methods
  bool get estaCompleto => dias.length == 6 && dias.values.every((dia) => dia.configurado);

  int get diasConfigurados => dias.values.where((dia) => dia.configurado).length;

  bool puedeEditar() {
    if (estatus != 'enviado') return true;
    final diasTranscurridos = DateTime.now().difference(fechaModificacion).inDays;
    return diasTranscurridos <= 7;
  }

  // Export methods for micro-endpoints
  Map<String, dynamic> toPlanEndpoint() {
    return {
      'id': id,
      'semana': semana,
      'numeroSemana': numeroSemana,
      'anio': anio,
      'liderClave': liderClave,
      'liderNombre': liderNombre,
      'centroDistribucion': centroDistribucion,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'estatus': estatus,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> toPlanDiasEndpoint() {
    return dias.entries.map((entry) {
      final dia = entry.value;
      return {
        'planId': id,
        'dia': dia.dia,
        'tipo': dia.tipo,
        'objetivoId': dia.objetivoId,
        'objetivoNombre': dia.objetivoNombre,
        'rutaId': dia.rutaId,
        'rutaNombre': dia.rutaNombre,
        'tipoActividadAdministrativa': dia.tipoActividadAdministrativa,
      };
    }).toList();
  }

  List<Map<String, dynamic>> toPlanClientesEndpoint() {
    final clientesList = <Map<String, dynamic>>[];
    for (final entry in dias.entries) {
      final dia = entry.value;
      if (dia.tipo == 'gestion_cliente' && dia.clientes.isNotEmpty) {
        for (final cliente in dia.clientes) {
          clientesList.add({
            'planId': id,
            'dia': dia.dia,
            'clienteId': cliente.clienteId,
            'orden': dia.clientes.indexOf(cliente) + 1,
          });
        }
      }
    }
    return clientesList;
  }

  List<Map<String, dynamic>> toVisitasEndpoint() {
    final visitasList = <Map<String, dynamic>>[];
    for (final entry in dias.entries) {
      final dia = entry.value;
      if (dia.tipo == 'gestion_cliente' && dia.clientes.isNotEmpty) {
        for (final visita in dia.clientes) {
          if (visita.horaInicio != null) {
            visitasList.add(visita.toVisitaEndpoint(id, dia.dia));
          }
        }
      }
    }
    return visitasList;
  }

  // Método para serializar el plan completo para sincronización con el servidor
  Map<String, dynamic> toJsonParaSincronizacion() {
    return {
      'id': id,
      'semana': {
        'numero': numeroSemana,
        'estatus': estatus,
      },
      'diasTrabajo': dias.entries.map((entry) {
        final dia = entry.value;
        return {
          'dia': entry.key,
          'tipo': dia.tipo,
          'objetivoId': dia.objetivoId,
          'rutaId': dia.rutaId,
          'clientes': dia.clientes.map((visita) {
            // Buscar formularios de este cliente en este día
            final formulariosCliente = dia.formularios
                .where((f) => f.clienteId == visita.clienteId)
                .map((f) => f.toJson())
                .toList();

            return {
              'clienteId': visita.clienteId,
              'checkIn': visita.horaInicio != null ? {
                'hora': visita.horaInicio,
                'ubicacion': visita.ubicacionInicio?.toJson(),
                'comentarios': visita.comentarioInicio,
              } : null,
              'checkOut': visita.horaFin != null ? {
                'hora': visita.horaFin,
                'duracionMinutos': _calcularDuracionMinutos(visita),
              } : null,
              'formularios': formulariosCliente,
              'cuestionario': visita.cuestionario?.toJson(),
              'compromisos': visita.compromisos.map((c) => c.toJson()).toList(),
              'retroalimentacion': visita.retroalimentacion,
              'reconocimiento': visita.reconocimiento,
              'estatus': visita.estatus,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  int? _calcularDuracionMinutos(VisitaClienteUnificadaHive visita) {
    if (visita.horaInicio == null || visita.horaFin == null) return null;
    try {
      final inicio = DateTime.parse(visita.horaInicio!);
      final fin = DateTime.parse(visita.horaFin!);
      return fin.difference(inicio).inMinutes;
    } catch (e) {
      return null;
    }
  }
}

@HiveType(typeId: 16)
class DiaPlanHive extends HiveObject {
  @HiveField(0)
  String dia; // Lunes, Martes, etc.

  @HiveField(1)
  String tipo; // 'gestion_cliente', 'administrativo', 'abordaje'

  @HiveField(2)
  String? objetivoId;

  @HiveField(3)
  String? objetivoNombre;

  @HiveField(4)
  String? tipoActividadAdministrativa;

  @HiveField(5)
  String? rutaId;

  @HiveField(6)
  String? rutaNombre;

  @HiveField(7)
  List<String> clienteIds;

  @HiveField(8)
  List<VisitaClienteUnificadaHive> clientes;

  @HiveField(9)
  bool configurado;

  @HiveField(10)
  DateTime fechaModificacion;

  @HiveField(11, defaultValue: [])
  List<FormularioDiaHive> formularios;

  DiaPlanHive({
    required this.dia,
    required this.tipo,
    this.objetivoId,
    this.objetivoNombre,
    this.tipoActividadAdministrativa,
    this.rutaId,
    this.rutaNombre,
    List<String>? clienteIds,
    List<VisitaClienteUnificadaHive>? clientes,
    this.configurado = false,
    DateTime? fechaModificacion,
    List<FormularioDiaHive>? formularios,
  })  : clienteIds = clienteIds ?? [],
        clientes = clientes ?? [],
        fechaModificacion = fechaModificacion ?? DateTime.now(),
        formularios = formularios ?? [];

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'tipo': tipo,
      'objetivoId': objetivoId,
      'objetivoNombre': objetivoNombre,
      'tipoActividadAdministrativa': tipoActividadAdministrativa,
      'rutaId': rutaId,
      'rutaNombre': rutaNombre,
      'clienteIds': clienteIds,
      'clientes': clientes.map((c) => c.toJson()).toList(),
      'formularios': formularios.map((f) => f.toJson()).toList(),
    };
  }

  factory DiaPlanHive.fromJson(Map<String, dynamic> json) {
    return DiaPlanHive(
      dia: json['dia'],
      tipo: json['tipo'],
      objetivoId: json['objetivoId'],
      objetivoNombre: json['objetivoNombre'],
      tipoActividadAdministrativa: json['tipoActividadAdministrativa'],
      rutaId: json['rutaId'],
      rutaNombre: json['rutaNombre'],
      clienteIds: (json['clienteIds'] as List<dynamic>?)?.cast<String>() ?? [],
      clientes: (json['clientes'] as List<dynamic>?)
          ?.map((c) => VisitaClienteUnificadaHive.fromJson(c))
          .toList() ?? [],
      configurado: json['configurado'] ?? false,
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : DateTime.now(),
      formularios: (json['formularios'] as List<dynamic>?)
          ?.map((f) => FormularioDiaHive.fromJson(f))
          .toList() ?? [],
    );
  }

  // Convert clienteIds to VisitaCliente objects
  void initializeClientes() {
    if (tipo == 'gestion_cliente' && clienteIds.isNotEmpty && clientes.isEmpty) {
      clientes = clienteIds.map((id) => VisitaClienteUnificadaHive(
        clienteId: id,
      )).toList();
    }
  }
}

@HiveType(typeId: 17)
class VisitaClienteUnificadaHive extends HiveObject {
  @HiveField(0)
  String clienteId;

  @HiveField(1)
  String? horaInicio;

  @HiveField(2)
  String? horaFin;

  @HiveField(3)
  UbicacionUnificadaHive? ubicacionInicio;

  @HiveField(4)
  String? comentarioInicio;

  @HiveField(5)
  CuestionarioHive? cuestionario;

  @HiveField(6)
  List<CompromisoHive> compromisos;

  @HiveField(7)
  String? retroalimentacion;

  @HiveField(8)
  String? reconocimiento;

  @HiveField(9)
  String estatus; // 'pendiente', 'en_proceso', 'completada', 'cancelada'

  @HiveField(10)
  DateTime? fechaModificacion;

  VisitaClienteUnificadaHive({
    required this.clienteId,
    this.horaInicio,
    this.horaFin,
    this.ubicacionInicio,
    this.comentarioInicio,
    this.cuestionario,
    List<CompromisoHive>? compromisos,
    this.retroalimentacion,
    this.reconocimiento,
    this.estatus = 'pendiente',
    this.fechaModificacion,
  }) : compromisos = compromisos ?? [];

  Map<String, dynamic> toJson() {
    return {
      'clienteId': clienteId,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'ubicacionInicio': ubicacionInicio?.toJson(),
      'comentarioInicio': comentarioInicio,
      'cuestionario': cuestionario?.toJson() ?? {},
      'compromisos': compromisos.map((c) => c.toJson()).toList(),
      'retroalimentacion': retroalimentacion,
      'reconocimiento': reconocimiento,
    };
  }

  factory VisitaClienteUnificadaHive.fromJson(Map<String, dynamic> json) {
    return VisitaClienteUnificadaHive(
      clienteId: json['clienteId'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      ubicacionInicio: json['ubicacionInicio'] != null
          ? UbicacionUnificadaHive.fromJson(json['ubicacionInicio'])
          : null,
      comentarioInicio: json['comentarioInicio'],
      cuestionario: json['cuestionario'] != null && (json['cuestionario'] as Map).isNotEmpty
          ? CuestionarioHive.fromJson(json['cuestionario'])
          : null,
      compromisos: (json['compromisos'] as List<dynamic>?)
          ?.map((c) => CompromisoHive.fromJson(c))
          .toList() ?? [],
      retroalimentacion: json['retroalimentacion'],
      reconocimiento: json['reconocimiento'],
      estatus: json['estatus'] ?? 'pendiente',
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : null,
    );
  }

  Map<String, dynamic> toVisitaEndpoint(String planId, String dia) {
    return {
      'planId': planId,
      'dia': dia,
      'clienteId': clienteId,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'ubicacionInicio': ubicacionInicio?.toJson(),
      'comentarioInicio': comentarioInicio,
      'estatus': estatus,
    };
  }

  bool get visitaIniciada => horaInicio != null;
  bool get visitaCompletada => horaFin != null;
}

@HiveType(typeId: 18)
class CuestionarioHive extends HiveObject {
  @HiveField(0)
  TipoExhibidorHive? tipoExhibidor;

  @HiveField(1)
  EstandaresEjecucionHive? estandaresEjecucion;

  @HiveField(2)
  DisponibilidadHive? disponibilidad;

  CuestionarioHive({
    this.tipoExhibidor,
    this.estandaresEjecucion,
    this.disponibilidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipoExhibidor': tipoExhibidor?.toJson(),
      'estandaresEjecucion': estandaresEjecucion?.toJson(),
      'disponibilidad': disponibilidad?.toJson(),
    };
  }

  factory CuestionarioHive.fromJson(Map<String, dynamic> json) {
    return CuestionarioHive(
      tipoExhibidor: json['tipoExhibidor'] != null
          ? TipoExhibidorHive.fromJson(json['tipoExhibidor'])
          : null,
      estandaresEjecucion: json['estandaresEjecucion'] != null
          ? EstandaresEjecucionHive.fromJson(json['estandaresEjecucion'])
          : null,
      disponibilidad: json['disponibilidad'] != null
          ? DisponibilidadHive.fromJson(json['disponibilidad'])
          : null,
    );
  }

  bool get estaCompleto => 
      tipoExhibidor != null && 
      estandaresEjecucion != null && 
      disponibilidad != null;
}

@HiveType(typeId: 19)
class TipoExhibidorHive extends HiveObject {
  @HiveField(0)
  bool poseeAdecuado;

  @HiveField(1)
  String? tipo;

  @HiveField(2)
  String? modelo;

  @HiveField(3)
  int? cantidad;

  TipoExhibidorHive({
    required this.poseeAdecuado,
    this.tipo,
    this.modelo,
    this.cantidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'poseeAdecuado': poseeAdecuado,
      'tipo': tipo,
      'modelo': modelo,
      'cantidad': cantidad,
    };
  }

  factory TipoExhibidorHive.fromJson(Map<String, dynamic> json) {
    return TipoExhibidorHive(
      poseeAdecuado: json['poseeAdecuado'] ?? false,
      tipo: json['tipo'],
      modelo: json['modelo'],
      cantidad: json['cantidad'],
    );
  }
}

@HiveType(typeId: 20)
class EstandaresEjecucionHive extends HiveObject {
  @HiveField(0)
  bool primeraPosicion;

  @HiveField(1)
  bool planograma;

  @HiveField(2)
  bool portafolioFoco;

  @HiveField(3)
  bool anclaje;

  EstandaresEjecucionHive({
    required this.primeraPosicion,
    required this.planograma,
    required this.portafolioFoco,
    required this.anclaje,
  });

  Map<String, dynamic> toJson() {
    return {
      'primeraPosicion': primeraPosicion,
      'planograma': planograma,
      'portafolioFoco': portafolioFoco,
      'anclaje': anclaje,
    };
  }

  factory EstandaresEjecucionHive.fromJson(Map<String, dynamic> json) {
    return EstandaresEjecucionHive(
      primeraPosicion: json['primeraPosicion'] ?? false,
      planograma: json['planograma'] ?? false,
      portafolioFoco: json['portafolioFoco'] ?? false,
      anclaje: json['anclaje'] ?? false,
    );
  }
}

@HiveType(typeId: 21)
class DisponibilidadHive extends HiveObject {
  @HiveField(0)
  bool ristras;

  @HiveField(1)
  bool max;

  @HiveField(2)
  bool familiar;

  @HiveField(3)
  bool dulce;

  @HiveField(4)
  bool galleta;

  DisponibilidadHive({
    required this.ristras,
    required this.max,
    required this.familiar,
    required this.dulce,
    required this.galleta,
  });

  Map<String, dynamic> toJson() {
    return {
      'ristras': ristras,
      'max': max,
      'familiar': familiar,
      'dulce': dulce,
      'galleta': galleta,
    };
  }

  factory DisponibilidadHive.fromJson(Map<String, dynamic> json) {
    return DisponibilidadHive(
      ristras: json['ristras'] ?? false,
      max: json['max'] ?? false,
      familiar: json['familiar'] ?? false,
      dulce: json['dulce'] ?? false,
      galleta: json['galleta'] ?? false,
    );
  }
}

@HiveType(typeId: 22)
class CompromisoHive extends HiveObject {
  @HiveField(0)
  String tipo;

  @HiveField(1)
  String detalle;

  @HiveField(2)
  int cantidad;

  @HiveField(3)
  String fechaPlazo;

  CompromisoHive({
    required this.tipo,
    required this.detalle,
    required this.cantidad,
    required this.fechaPlazo,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'detalle': detalle,
      'cantidad': cantidad,
      'fechaPlazo': fechaPlazo,
    };
  }

  factory CompromisoHive.fromJson(Map<String, dynamic> json) {
    return CompromisoHive(
      tipo: json['tipo'],
      detalle: json['detalle'],
      cantidad: json['cantidad'],
      fechaPlazo: json['fechaPlazo'],
    );
  }
}

@HiveType(typeId: 23)
class UbicacionUnificadaHive extends HiveObject {
  @HiveField(0)
  double lat;

  @HiveField(1)
  double lon;

  UbicacionUnificadaHive({
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }

  factory UbicacionUnificadaHive.fromJson(Map<String, dynamic> json) {
    return UbicacionUnificadaHive(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
    );
  }

  bool get esValida => lat != 0.0 && lon != 0.0;
}

@HiveType(typeId: 40)
class FormularioDiaHive extends HiveObject {
  @HiveField(0)
  String formularioId;

  @HiveField(1)
  String clienteId;

  @HiveField(2)
  Map<String, dynamic> respuestas;

  @HiveField(3)
  DateTime fechaCaptura;

  FormularioDiaHive({
    required this.formularioId,
    required this.clienteId,
    required this.respuestas,
    required this.fechaCaptura,
  });

  Map<String, dynamic> toJson() {
    return {
      'formularioId': formularioId,
      'clienteId': clienteId,
      'respuestas': respuestas,
      'fechaCaptura': fechaCaptura.toIso8601String(),
    };
  }

  factory FormularioDiaHive.fromJson(Map<String, dynamic> json) {
    return FormularioDiaHive(
      formularioId: json['formularioId'],
      clienteId: json['clienteId'],
      respuestas: Map<String, dynamic>.from(json['respuestas'] ?? {}),
      fechaCaptura: json['fechaCaptura'] != null
          ? DateTime.parse(json['fechaCaptura'])
          : DateTime.now(),
    );
  }
}