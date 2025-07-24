import 'package:diana_lc_front/shared/modelos/formulario_dto.dart';
import 'plantilla_service_impl.dart';
import 'captura_formulario_service_impl.dart';

/// Helper para facilitar el trabajo con formularios dinámicos
class FormularioHelper {
  static final PlantillaServiceImpl _plantillaService = PlantillaServiceImpl();
  static final CapturaFormularioServiceImpl _capturaService = CapturaFormularioServiceImpl();
  
  /// Inicializa los servicios de formularios
  static Future<void> inicializar() async {
    await _plantillaService.initialize();
    await _capturaService.initialize();
    print('✅ Servicios de formularios inicializados');
  }
  
  /// Importa un formulario desde JSON
  static FormularioPlantillaDTO importarFormularioDesdeJson({
    required String plantillaId,
    required String nombre,
    required String version,
    required CanalType canal,
    required List<dynamic> preguntasJson,
  }) {
    final preguntas = preguntasJson.map((p) => PreguntaDTO.fromJson(p)).toList();
    
    return FormularioPlantillaDTO(
      plantillaId: plantillaId,
      nombre: nombre,
      version: version,
      estatus: FormStatus.ACTIVO,
      canal: canal,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
      questions: preguntas,
    );
  }

  /// Crea datos de ejemplo para desarrollo/testing
  static Future<void> crearDatosEjemplo() async {
    // Ejemplo real de formulario de evaluación de ventas
    final preguntasVentasJson = [
      {
        "name": "paso_1",
        "tipoEntrada": "radio",
        "orden": 1,
        "section": "Pasos de la Venta",
        "etiqueta": "Paso 1: Preparación de la Visita. El Asesor de Ventas realiza la preparación de la visita en base a los indicadores.",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "paso_2",
        "tipoEntrada": "radio",
        "orden": 2,
        "section": "Pasos de la Venta",
        "etiqueta": "Paso 2: Saludo y Revisión de Inventario. El Asesor de Ventas saluda al cliente por su nombre y realiza validación de inventario en los exhibidores.",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "paso_3",
        "tipoEntrada": "radio",
        "orden": 3,
        "section": "Pasos de la Venta",
        "etiqueta": "Paso 3: Negociación del Pedido. El Asesor de Ventas realiza negociación del pedido en base al portafolio foco, promociones y necesidades del cliente.",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "paso_4",
        "tipoEntrada": "radio",
        "orden": 4,
        "section": "Pasos de la Venta",
        "etiqueta": "Paso 4: Ejecución de la FOE. El Asesor de Ventas ejecuta Foto de Éxito en el PDV.",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "exhibidor_posicion",
        "tipoEntrada": "radio",
        "orden": 5,
        "section": "Pasos de la Venta",
        "etiqueta": "¿El exhibidor está en primera posición?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "portafolio_foco",
        "tipoEntrada": "radio",
        "orden": 6,
        "section": "Pasos de la Venta",
        "etiqueta": "¿Promueve el portafolio foco?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "ejecucion_foto_exito",
        "tipoEntrada": "radio",
        "orden": 7,
        "section": "Pasos de la Venta",
        "etiqueta": "¿Ejecuta la foto de éxito en el PDV?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "negociacion_pdv",
        "tipoEntrada": "radio",
        "orden": 8,
        "section": "Pasos de la Venta",
        "etiqueta": "¿Realiza negociación en el PDV?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "respeta_transito",
        "tipoEntrada": "radio",
        "orden": 9,
        "section": "Otros Aspectos a Evaluar",
        "etiqueta": "¿Conduce correctamente y respeta el reglamento de tránsito y a los peatones?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "plan_visita_actualizado",
        "tipoEntrada": "radio",
        "orden": 10,
        "section": "Otros Aspectos a Evaluar",
        "etiqueta": "¿El asesor mantiene su Plan de Visita actualizado?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      },
      {
        "name": "orden_piking",
        "tipoEntrada": "radio",
        "orden": 11,
        "section": "Otros Aspectos a Evaluar",
        "etiqueta": "¿El asesor mantiene su camioneta ordenada, garantizando la calidad del producto y eficiencia en el Piking?",
        "opciones": [
          { "valor": "SI", "etiqueta": "Sí", "puntuacion": 1 },
          { "valor": "NO", "etiqueta": "No", "puntuacion": 0 }
        ]
      }
    ];
    
    // Crear formulario de evaluación de ventas
    final formularioVentas = importarFormularioDesdeJson(
      plantillaId: 'FORM_EVAL_VENTAS_001',
      nombre: 'Evaluación de Proceso de Ventas',
      version: 'v1.0',
      canal: CanalType.DETALLE,
      preguntasJson: preguntasVentasJson,
    );
    
    // Plantilla para canal DETALLE (punto de venta)
    final plantillaDetalle = FormularioPlantillaDTO(
      plantillaId: 'FORM_DETALLE_002',
      nombre: 'Evaluación Punto de Venta - Detalle',
      version: 'v1.0',
      estatus: FormStatus.ACTIVO,
      canal: CanalType.DETALLE,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
      questions: [
        PreguntaDTO(
          name: 'limpieza_local',
          tipoEntrada: 'radio',
          orden: 1,
          section: 'Condiciones del Local',
          etiqueta: 'Limpieza general del local',
          opciones: [
            OpcionDTO(valor: 'excelente', etiqueta: 'Excelente', puntuacion: 10),
            OpcionDTO(valor: 'bueno', etiqueta: 'Bueno', puntuacion: 7),
            OpcionDTO(valor: 'regular', etiqueta: 'Regular', puntuacion: 5),
            OpcionDTO(valor: 'malo', etiqueta: 'Malo', puntuacion: 0),
          ],
        ),
        PreguntaDTO(
          name: 'exhibicion_productos',
          tipoEntrada: 'select',
          orden: 2,
          section: 'Exhibición',
          etiqueta: 'Estado de la exhibición de productos',
          opciones: [
            OpcionDTO(valor: 'completa', etiqueta: 'Completa y ordenada', puntuacion: 10),
            OpcionDTO(valor: 'parcial', etiqueta: 'Parcialmente completa', puntuacion: 5),
            OpcionDTO(valor: 'deficiente', etiqueta: 'Deficiente', puntuacion: 0),
          ],
        ),
        PreguntaDTO(
          name: 'atencion_cliente',
          tipoEntrada: 'radio',
          orden: 3,
          section: 'Servicio',
          etiqueta: 'Calidad de atención al cliente',
          opciones: [
            OpcionDTO(valor: 'excelente', etiqueta: 'Excelente', puntuacion: 10),
            OpcionDTO(valor: 'buena', etiqueta: 'Buena', puntuacion: 7),
            OpcionDTO(valor: 'regular', etiqueta: 'Regular', puntuacion: 5),
            OpcionDTO(valor: 'mala', etiqueta: 'Mala', puntuacion: 0),
          ],
        ),
        PreguntaDTO(
          name: 'comentarios',
          tipoEntrada: 'text',
          orden: 4,
          section: 'Observaciones',
          etiqueta: 'Comentarios adicionales',
          opciones: [],
        ),
      ],
    );
    
    // Plantilla para canal MAYOREO
    final plantillaMayoreo = FormularioPlantillaDTO(
      plantillaId: 'FORM_MAYOREO_001',
      nombre: 'Evaluación Cliente Mayorista',
      version: 'v1.0',
      estatus: FormStatus.ACTIVO,
      canal: CanalType.MAYOREO,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
      questions: [
        PreguntaDTO(
          name: 'volumen_compra',
          tipoEntrada: 'select',
          orden: 1,
          section: 'Volumen de Negocio',
          etiqueta: 'Volumen promedio de compra mensual',
          opciones: [
            OpcionDTO(valor: 'alto', etiqueta: 'Alto (>1000 unidades)', puntuacion: 10),
            OpcionDTO(valor: 'medio', etiqueta: 'Medio (500-1000)', puntuacion: 7),
            OpcionDTO(valor: 'bajo', etiqueta: 'Bajo (<500)', puntuacion: 3),
          ],
        ),
        PreguntaDTO(
          name: 'frecuencia_pedidos',
          tipoEntrada: 'radio',
          orden: 2,
          section: 'Frecuencia',
          etiqueta: 'Frecuencia de realización de pedidos',
          opciones: [
            OpcionDTO(valor: 'semanal', etiqueta: 'Semanal', puntuacion: 10),
            OpcionDTO(valor: 'quincenal', etiqueta: 'Quincenal', puntuacion: 7),
            OpcionDTO(valor: 'mensual', etiqueta: 'Mensual', puntuacion: 5),
            OpcionDTO(valor: 'esporadico', etiqueta: 'Esporádico', puntuacion: 2),
          ],
        ),
        PreguntaDTO(
          name: 'pago_puntual',
          tipoEntrada: 'radio',
          orden: 3,
          section: 'Comportamiento de Pago',
          etiqueta: 'Puntualidad en el pago de facturas',
          opciones: [
            OpcionDTO(valor: 'si', etiqueta: 'Siempre puntual', puntuacion: 10),
            OpcionDTO(valor: 'ocasional', etiqueta: 'Ocasionalmente tardío', puntuacion: 5),
            OpcionDTO(valor: 'no', etiqueta: 'Frecuentemente tardío', puntuacion: 0),
          ],
        ),
      ],
    );
    
    // Plantilla para programa EXCELENCIA
    final plantillaExcelencia = FormularioPlantillaDTO(
      plantillaId: 'FORM_EXCELENCIA_001',
      nombre: 'Evaluación Programa Excelencia',
      version: 'v1.0',
      estatus: FormStatus.ACTIVO,
      canal: CanalType.EXCELENCIA,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
      questions: [
        PreguntaDTO(
          name: 'cumplimiento_metas',
          tipoEntrada: 'select',
          orden: 1,
          section: 'Desempeño',
          etiqueta: 'Nivel de cumplimiento de metas asignadas',
          opciones: [
            OpcionDTO(valor: 'supera', etiqueta: 'Supera metas (>110%)', puntuacion: 15),
            OpcionDTO(valor: 'cumple', etiqueta: 'Cumple metas (90-110%)', puntuacion: 10),
            OpcionDTO(valor: 'parcial', etiqueta: 'Cumplimiento parcial (70-90%)', puntuacion: 5),
            OpcionDTO(valor: 'bajo', etiqueta: 'Bajo cumplimiento (<70%)', puntuacion: 0),
          ],
        ),
        PreguntaDTO(
          name: 'innovacion',
          tipoEntrada: 'radio',
          orden: 2,
          section: 'Innovación',
          etiqueta: 'Capacidad de innovación y propuesta de mejoras',
          opciones: [
            OpcionDTO(valor: 'alta', etiqueta: 'Altamente innovador', puntuacion: 10),
            OpcionDTO(valor: 'media', etiqueta: 'Medianamente innovador', puntuacion: 6),
            OpcionDTO(valor: 'baja', etiqueta: 'Poco innovador', puntuacion: 2),
          ],
        ),
        PreguntaDTO(
          name: 'liderazgo',
          tipoEntrada: 'checkbox',
          orden: 3,
          section: 'Competencias',
          etiqueta: 'Competencias de liderazgo demostradas',
          opciones: [
            OpcionDTO(valor: 'comunicacion', etiqueta: 'Comunicación efectiva', puntuacion: 5),
            OpcionDTO(valor: 'trabajo_equipo', etiqueta: 'Trabajo en equipo', puntuacion: 5),
            OpcionDTO(valor: 'orientacion_resultados', etiqueta: 'Orientación a resultados', puntuacion: 5),
            OpcionDTO(valor: 'adaptabilidad', etiqueta: 'Adaptabilidad', puntuacion: 5),
          ],
        ),
      ],
    );
    
    // Guardar plantillas
    await _plantillaService.savePlantillas([
      formularioVentas,
      plantillaDetalle,
      plantillaMayoreo,
      plantillaExcelencia,
    ]);
    
    print('✅ Plantillas de ejemplo creadas');
    print('   └── Evaluación de Proceso de Ventas (11 preguntas)');
    print('   └── Evaluación Punto de Venta - Detalle');
    print('   └── Evaluación Cliente Mayorista');
    print('   └── Evaluación Programa Excelencia');
  }
  
  /// Calcula la puntuación máxima posible de una plantilla
  static int calcularPuntuacionMaxima(FormularioPlantillaDTO plantilla) {
    int maxima = 0;
    
    for (final pregunta in plantilla.questions) {
      if (pregunta.tipoEntrada == 'checkbox') {
        // Para checkbox, suma todas las opciones
        maxima += pregunta.opciones
            .map((o) => o.puntuacion)
            .reduce((a, b) => a + b);
      } else if (pregunta.opciones.isNotEmpty) {
        // Para otros tipos, toma la puntuación máxima
        maxima += pregunta.opciones
            .map((o) => o.puntuacion)
            .reduce((a, b) => a > b ? a : b);
      }
    }
    
    return maxima;
  }
  
  /// Calcula el porcentaje de cumplimiento
  static double calcularPorcentajeCumplimiento(
    int puntuacionObtenida, 
    int puntuacionMaxima
  ) {
    if (puntuacionMaxima == 0) return 0;
    return (puntuacionObtenida / puntuacionMaxima) * 100;
  }
  
  /// Obtiene el resumen de respuestas de un cliente
  static Future<Map<String, dynamic>> obtenerResumenCliente(String clientId) async {
    final respuestas = await _capturaService.getRespuestasPorCliente(clientId);
    
    if (respuestas.isEmpty) {
      return {
        'totalFormularios': 0,
        'promedioGeneral': 0.0,
        'ultimaVisita': null,
      };
    }
    
    // Calcular promedios por tipo
    final promediosPorCanal = <String, List<double>>{};
    
    for (final respuesta in respuestas) {
      final plantilla = await _plantillaService.getPlantillaById(respuesta.plantillaId);
      if (plantilla != null) {
        final canal = plantilla.canal.name;
        final maxima = calcularPuntuacionMaxima(plantilla);
        final porcentaje = calcularPorcentajeCumplimiento(
          respuesta.puntuacionTotal, 
          maxima
        );
        
        promediosPorCanal[canal] = (promediosPorCanal[canal] ?? [])..add(porcentaje);
      }
    }
    
    // Calcular promedios finales
    final promediosFinales = <String, double>{};
    promediosPorCanal.forEach((canal, porcentajes) {
      if (porcentajes.isNotEmpty) {
        promediosFinales[canal] = 
            porcentajes.reduce((a, b) => a + b) / porcentajes.length;
      }
    });
    
    // Promedio general
    double promedioGeneral = 0;
    if (respuestas.isNotEmpty) {
      final todosPromedios = promediosPorCanal.values
          .expand((list) => list)
          .toList();
      promedioGeneral = todosPromedios.reduce((a, b) => a + b) / todosPromedios.length;
    }
    
    return {
      'totalFormularios': respuestas.length,
      'promedioGeneral': promedioGeneral,
      'promediosPorCanal': promediosFinales,
      'ultimaVisita': respuestas.first.fechaCreacion,
      'respuestas': respuestas.map((r) => {
        'fecha': r.fechaCreacion,
        'puntuacion': r.puntuacionTotal,
        'color': r.colorKPI,
        'sincronizado': !r.offline,
      }).toList(),
    };
  }
  
  /// Obtiene estadísticas generales del sistema
  static Future<Map<String, dynamic>> obtenerEstadisticasGenerales() async {
    final statsPlantillas = await _plantillaService.getEstadisticas();
    final statsRespuestas = await _capturaService.getEstadisticas();
    
    return {
      'plantillas': statsPlantillas,
      'respuestas': statsRespuestas,
      'fecha': DateTime.now().toIso8601String(),
    };
  }
}

// Ejemplo de uso completo:
/*
void ejemploCompleto() async {
  // Inicializar
  await FormularioHelper.inicializar();
  
  // Crear datos de ejemplo
  await FormularioHelper.crearDatosEjemplo();
  
  // Obtener plantillas para canal DETALLE
  final plantillaService = PlantillaServiceImpl();
  final plantillasDetalle = await plantillaService.getPlantillasByCanal(CanalType.DETALLE);
  
  if (plantillasDetalle.isNotEmpty) {
    final plantilla = plantillasDetalle.first;
    print('Usando plantilla: ${plantilla.nombre}');
    
    // Simular captura de respuestas
    final capturaService = CapturaFormularioServiceImpl();
    
    final respuesta = FormularioRespuestaDTO(
      respuestaId: '',
      plantillaId: plantilla.plantillaId,
      planVisitaId: 'PLAN_2024_W45',
      rutaId: 'RUTA_CENTRO',
      clientId: 'CLI_001',
      respuestas: [
        RespuestaPreguntaDTO(
          questionName: 'limpieza_local',
          value: 'excelente',
          puntuacion: 10,
        ),
        RespuestaPreguntaDTO(
          questionName: 'exhibicion_productos',
          value: 'completa',
          puntuacion: 10,
        ),
        RespuestaPreguntaDTO(
          questionName: 'atencion_cliente',
          value: 'buena',
          puntuacion: 7,
        ),
        RespuestaPreguntaDTO(
          questionName: 'comentarios',
          value: 'Excelente servicio y presentación del local',
          puntuacion: 0,
        ),
      ],
      puntuacionTotal: 27,
      colorKPI: '',
      offline: true,
      fechaCreacion: DateTime.now(),
    );
    
    await capturaService.saveRespuesta(respuesta);
    
    // Ver resumen del cliente
    final resumen = await FormularioHelper.obtenerResumenCliente('CLI_001');
    print('Resumen del cliente: $resumen');
    
    // Ver estadísticas generales
    final stats = await FormularioHelper.obtenerEstadisticasGenerales();
    print('Estadísticas del sistema: $stats');
  }
}
*/