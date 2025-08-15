import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';

/// Helper para agregar y calcular datos del Programa de Excelencia
class ExcelenciaAggregator {
  /// Categorías de evaluación del programa (actualizadas según datos reales)
  static const List<String> categorias = [
    'Pasos de la Venta',
    'Otros Aspectos a Evaluar', 
    'Retroalimentación y Reconocimiento',
  ];
  
  /// Mapeo para mostrar nombres más descriptivos en el reporte
  static const Map<String, String> categoriasDisplay = {
    'Pasos de la Venta': 'Ejecución de Ventas',
    'Otros Aspectos a Evaluar': 'Aspectos Generales',
    'Retroalimentación y Reconocimiento': 'Retroalimentación y Reconocimiento',
  };

  /// Calcula el puntaje promedio de una categoría específica
  static double calcularPuntajeCategoria(
    List<RespuestaEvaluacionHive> respuestas,
    String categoria,
  ) {
    print('🔍 Calculando puntaje para categoría: "$categoria"');
    print('  - Total respuestas disponibles: ${respuestas.length}');
    
    // Debug: mostrar todas las categorías disponibles
    final categoriasDisponibles = respuestas.map((r) => r.categoria).toSet();
    print('  - Categorías disponibles: $categoriasDisponibles');
    
    final respuestasCategoria = respuestas
        .where((r) => r.categoria?.toLowerCase() == categoria.toLowerCase())
        .toList();

    print('  - Respuestas encontradas para "$categoria": ${respuestasCategoria.length}');

    if (respuestasCategoria.isEmpty) {
      print('  - ❌ No hay respuestas para esta categoría');
      return 0.0;
    }

    double sumaPonderaciones = 0.0;
    int preguntasEvaluadas = 0;

    for (var respuesta in respuestasCategoria) {
      print('    * Pregunta: ${respuesta.preguntaTitulo}');
      print('      - Respuesta: ${respuesta.respuesta}');
      print('      - Ponderación original: ${respuesta.ponderacion}');
      
      double puntaje = 0.0;
      
      // Si hay ponderación definida, usarla
      if (respuesta.ponderacion != null) {
        puntaje = respuesta.ponderacion!;
      } 
      // Si no hay ponderación, calcular según la respuesta
      else if (respuesta.respuesta != null) {
        puntaje = _calcularPuntajePorRespuesta(respuesta.respuesta.toString());
      }
      
      print('      - Puntaje asignado: $puntaje');
      
      if (puntaje > 0 || respuesta.respuesta != null) {
        sumaPonderaciones += puntaje;
        preguntasEvaluadas++;
      }
    }

    final promedio = preguntasEvaluadas > 0
        ? sumaPonderaciones / preguntasEvaluadas
        : 0.0;
        
    print('  - ✅ Promedio calculado: $promedio (${preguntasEvaluadas} preguntas evaluadas)');
    return promedio;
  }
  
  /// Calcula puntaje basado en la respuesta cuando no hay ponderación definida
  static double _calcularPuntajePorRespuesta(String respuesta) {
    final respuestaLower = respuesta.toLowerCase().trim();
    
    // Respuestas positivas
    if (respuestaLower == 'sí' || respuestaLower == 'si' || 
        respuestaLower == 'yes' || respuestaLower == 'true' ||
        respuestaLower == 'correcto' || respuestaLower == 'bueno' ||
        respuestaLower == 'excelente') {
      return 100.0;
    }
    
    // Respuestas negativas
    if (respuestaLower == 'no' || respuestaLower == 'false' ||
        respuestaLower == 'incorrecto' || respuestaLower == 'malo') {
      return 0.0;
    }
    
    // Respuestas de texto libre - asignar puntaje medio si tiene contenido
    if (respuesta.isNotEmpty && respuesta.length > 1) {
      return 75.0; // Puntaje por defecto para respuestas con contenido
    }
    
    return 0.0;
  }

  /// Calcula todos los puntajes por categoría
  static Map<String, double> calcularPuntajesPorCategoria(
    List<RespuestaEvaluacionHive> respuestas,
  ) {
    final Map<String, double> puntajes = {};

    for (var categoria in categorias) {
      puntajes[categoria] = calcularPuntajeCategoria(respuestas, categoria);
    }

    return puntajes;
  }

  /// Agrupa los resultados por canal (Detalle/Mayoreo)
  static Map<String, List<ResultadoExcelenciaHive>> agruparPorCanal(
    List<ResultadoExcelenciaHive> resultados,
  ) {
    final Map<String, List<ResultadoExcelenciaHive>> grupos = {};

    for (var resultado in resultados) {
      final canal = resultado.metadatos?['canalVenta'] ?? 'Sin Canal';
      grupos.putIfAbsent(canal, () => []);
      grupos[canal]!.add(resultado);
    }

    return grupos;
  }

  /// Agrupa los resultados por líder
  static Map<String, List<ResultadoExcelenciaHive>> agruparPorLider(
    List<ResultadoExcelenciaHive> resultados,
  ) {
    final Map<String, List<ResultadoExcelenciaHive>> grupos = {};

    for (var resultado in resultados) {
      final liderKey = '${resultado.liderClave}-${resultado.liderNombre}';
      grupos.putIfAbsent(liderKey, () => []);
      grupos[liderKey]!.add(resultado);
    }

    return grupos;
  }

  /// Calcula el resumen agregado para un grupo de resultados
  static Map<String, dynamic> calcularResumenGrupo(
    List<ResultadoExcelenciaHive> resultados,
  ) {
    if (resultados.isEmpty) {
      return {
        'totalEvaluaciones': 0,
        'puntajePromedio': 0.0,
        'puntajesPorCategoria': Map.fromIterables(categorias, List.filled(categorias.length, 0.0)),
      };
    }

    // Calcular puntajes por categoría para cada resultado
    final List<Map<String, double>> todosLosPuntajes = [];
    
    for (var resultado in resultados) {
      final puntajes = calcularPuntajesPorCategoria(resultado.respuestas);
      todosLosPuntajes.add(puntajes);
    }

    // Promediar puntajes por categoría
    final Map<String, double> puntajesPromedio = {};
    
    for (var categoria in categorias) {
      double suma = 0.0;
      int contador = 0;
      
      for (var puntajes in todosLosPuntajes) {
        if (puntajes.containsKey(categoria) && puntajes[categoria]! > 0) {
          suma += puntajes[categoria]!;
          contador++;
        }
      }
      
      puntajesPromedio[categoria] = contador > 0 ? suma / contador : 0.0;
    }

    // Calcular puntaje final promedio
    final double puntajeFinal = puntajesPromedio.values.isNotEmpty
        ? puntajesPromedio.values.reduce((a, b) => a + b) / puntajesPromedio.length
        : 0.0;

    return {
      'totalEvaluaciones': resultados.length,
      'puntajePromedio': puntajeFinal,
      'puntajesPorCategoria': puntajesPromedio,
    };
  }

  /// Genera el reporte completo con agregaciones
  static Map<String, dynamic> generarReporte(
    List<ResultadoExcelenciaHive> resultados, {
    String? filtroCanal,
    String? filtroLider,
    String? filtroPais,
    String? filtroCentroDistribucion,
  }) {
    print('🔧 ExcelenciaAggregator.generarReporte');
    print('  - Resultados recibidos: ${resultados.length}');
    
    // Aplicar filtros
    var resultadosFiltrados = resultados.where((r) {
      if (filtroCanal != null && filtroCanal.isNotEmpty && r.metadatos?['canalVenta'] != filtroCanal) return false;
      if (filtroLider != null && filtroLider.isNotEmpty && r.liderClave != filtroLider) return false;
      if (filtroPais != null && filtroPais.isNotEmpty && r.pais != filtroPais) return false;
      if (filtroCentroDistribucion != null && filtroCentroDistribucion.isNotEmpty && r.centroDistribucion != filtroCentroDistribucion) return false;
      return true;
    }).toList();
    
    print('  - Resultados después de filtros: ${resultadosFiltrados.length}');

    // Agrupar por canal
    final porCanal = agruparPorCanal(resultadosFiltrados);
    final Map<String, dynamic> resumenPorCanal = {};
    
    for (var entrada in porCanal.entries) {
      final canal = entrada.key;
      final resultadosCanal = entrada.value;
      
      // Agrupar por líder dentro del canal
      final porLider = agruparPorLider(resultadosCanal);
      final Map<String, dynamic> resumenPorLider = {};
      
      for (var entradaLider in porLider.entries) {
        final lider = entradaLider.key;
        final resultadosLider = entradaLider.value;
        
        resumenPorLider[lider] = {
          'detalle': calcularResumenGrupo(resultadosLider),
          'resultados': resultadosLider,
        };
      }
      
      resumenPorCanal[canal] = {
        'resumen': calcularResumenGrupo(resultadosCanal),
        'porLider': resumenPorLider,
      };
    }

    // Resumen general
    final resumenGeneral = calcularResumenGrupo(resultadosFiltrados);

    return {
      'resumenGeneral': resumenGeneral,
      'porCanal': resumenPorCanal,
      'totalResultados': resultadosFiltrados.length,
      'fechaReporte': DateTime.now().toIso8601String(),
    };
  }

  /// Obtiene el color según el puntaje
  static String obtenerColorPuntaje(double puntaje) {
    if (puntaje >= 85) return 'verde';
    if (puntaje >= 60) return 'amarillo';
    return 'rojo';
  }

  /// DEBUG: Obtiene todas las categorías reales de los datos
  static Set<String> obtenerCategoriasReales(List<ResultadoExcelenciaHive> resultados) {
    final Set<String> categorias = {};
    
    for (var resultado in resultados) {
      for (var respuesta in resultado.respuestas) {
        if (respuesta.categoria != null && respuesta.categoria!.isNotEmpty) {
          categorias.add(respuesta.categoria!);
        }
      }
    }
    
    print('🏷️ Categorías reales encontradas en los datos:');
    for (var categoria in categorias) {
      print('  - "$categoria"');
    }
    
    return categorias;
  }
}