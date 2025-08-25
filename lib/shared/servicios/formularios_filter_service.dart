import 'package:diana_lc_front/shared/modelos/formulario_evaluacion_dto.dart';

class FormulariosFilterService {
  
  /// Mapeo de país UI a país WS
  static const Map<String, String> paisUIaWS = {
    'SV': 'salvador',
    'GT': 'guatemala', 
    'HN': 'honduras',
    'NI': 'nicaragua',
    'CR': 'costa_rica',
    'PA': 'panama',
  };
  
  /// Normalizar texto para comparaciones robustas
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ñ', 'n')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }
  
  /// Mapear país de UI a WS
  static String mapPaisUIaWS(String paisUI) {
    final mapped = paisUIaWS[paisUI.toUpperCase()];
    if (mapped == null) {
      print('⚠️ País no mapeado: $paisUI, usando como está');
      return paisUI.toLowerCase();
    }
    return mapped;
  }
  
  /// Verificar si un formulario es de evaluación de desempeño
  static bool esEvaluacionDesempeno(FormularioEvaluacionDTO formulario) {
    final tipoNorm = normalize(formulario.tipo);
    return tipoNorm == normalize('evaluacion_desempeño') || 
           tipoNorm == normalize('evaluacion_desempeno');
  }
  
  /// Verificar si un formulario aplica para el país
  static bool aplicaParaPais(FormularioEvaluacionDTO formulario, String paisWS) {
    // Si el formulario no especifica países, aplica para todos
    if (formulario.paises == null || formulario.paises!.isEmpty) {
      return true;
    }
    
    final paisNorm = normalize(paisWS);
    return formulario.paises!.any((pais) => normalize(pais) == paisNorm);
  }
  
  /// Filtrar formularios de evaluación de desempeño
  static List<FormularioEvaluacionDTO> filtrarFormulariosEvaluacion({
    required List<FormularioEvaluacionDTO> formularios,
    required String canal,
    required String paisUI,
  }) {
    final paisWS = mapPaisUIaWS(paisUI);
    final canalNorm = normalize(canal);
    
    print('🔍 === FILTRADO DE FORMULARIOS ===');
    print('📊 Total formularios recibidos: ${formularios.length}');
    print('🎯 Filtros aplicados:');
    print('  - País UI: $paisUI → WS: $paisWS');
    print('  - Canal: $canal (normalizado: $canalNorm)');
    print('  - Tipo: evaluacion_desempeño (excluyendo programa_excelencia)');
    
    int contadorTipo = 0;
    int contadorCanal = 0; 
    int contadorPais = 0;
    int contadorActivo = 0;
    
    final resultado = formularios.where((formulario) {
      // 1. Verificar tipo (EXCLUIR programa_excelencia)
      final esEvalDesempeno = esEvaluacionDesempeno(formulario);
      if (esEvalDesempeno) contadorTipo++;
      
      // 2. Verificar canal
      final aplicaCanal = formulario.aplicaParaCanal(canal);
      if (esEvalDesempeno && aplicaCanal) contadorCanal++;
      
      // 3. Verificar país
      final aplicaPais = aplicaParaPais(formulario, paisWS);
      if (esEvalDesempeno && aplicaCanal && aplicaPais) contadorPais++;
      
      // 4. Verificar activo
      final estaActivo = formulario.activo;
      if (esEvalDesempeno && aplicaCanal && aplicaPais && estaActivo) contadorActivo++;
      
      print('📋 Formulario: ${formulario.nombre}');
      print('  - ID: ${formulario.id}');
      print('  - Tipo: ${formulario.tipo} → ¿Es eval. desempeño?: $esEvalDesempeno');
      print('  - Canales: ${formulario.canales} → ¿Aplica para $canal?: $aplicaCanal');
      print('  - Países: ${formulario.paises} → ¿Aplica para $paisWS?: $aplicaPais');
      print('  - Activo: $estaActivo');
      print('  - ¿Cumple todos los filtros?: ${esEvalDesempeno && aplicaCanal && aplicaPais && estaActivo}');
      print('');
      
      return esEvalDesempeno && aplicaCanal && aplicaPais && estaActivo;
    }).toList();
    
    print('📊 === RESULTADOS DEL FILTRADO ===');
    print('  - Por tipo (evaluacion_desempeño): $contadorTipo');
    print('  - Por canal ($canal): $contadorCanal');
    print('  - Por país ($paisWS): $contadorPais');
    print('  - Activos: $contadorActivo');
    print('  - 🎯 TOTAL FILTRADOS: ${resultado.length}');
    
    // Ordenar por fecha más reciente
    resultado.sort((a, b) {
      final fechaA = a.fechaActualizacion ?? a.fechaCreacion ?? DateTime(1970);
      final fechaB = b.fechaActualizacion ?? b.fechaCreacion ?? DateTime(1970);
      return fechaB.compareTo(fechaA);
    });
    
    if (resultado.isNotEmpty) {
      final seleccionado = resultado.first;
      print('✅ Formulario seleccionado: ${seleccionado.nombre} (ID: ${seleccionado.id})');
      print('📅 Fecha: ${seleccionado.fechaActualizacion ?? seleccionado.fechaCreacion}');
    }
    
    return resultado;
  }
}