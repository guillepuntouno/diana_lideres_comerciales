import 'package:flutter/foundation.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/shared/helpers/excelencia_aggregator.dart';

/// ViewModel para el reporte del Programa de Excelencia
class ReporteProgramaExcelenciaVM extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  
  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  // Datos
  List<ResultadoExcelenciaHive> _todosLosResultados = [];
  Map<String, dynamic> _reporteData = {};
  Map<String, dynamic> get reporteData => _reporteData;
  
  // Filtros
  String? _filtroPais;
  String? get filtroPais => _filtroPais;
  
  String? _filtroCentroDistribucion;
  String? get filtroCentroDistribucion => _filtroCentroDistribucion;
  
  String? _filtroLider;
  String? get filtroLider => _filtroLider;
  
  String? _filtroCanal;
  String? get filtroCanal => _filtroCanal;
  
  // Listas para dropdowns
  List<String> _paisesDisponibles = [];
  List<String> get paisesDisponibles => _paisesDisponibles;
  
  List<String> _centrosDisponibles = [];
  List<String> get centrosDisponibles => _centrosDisponibles;
  
  List<String> _lideresDisponibles = [];
  List<String> get lideresDisponibles => _lideresDisponibles;
  
  List<String> _canalesDisponibles = [];
  List<String> get canalesDisponibles => _canalesDisponibles;
  
  /// Constructor
  ReporteProgramaExcelenciaVM() {
    cargarDatos();
  }
  
  /// Carga los datos desde HIVE
  Future<void> cargarDatos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('🔄 Iniciando carga de datos del reporte...');
      
      // Verificar que HIVE esté inicializado
      if (!_hiveService.isInitialized) {
        print('⚙️ Inicializando HiveService...');
        await _hiveService.initialize();
      }
      
      // Obtener todos los resultados
      final box = _hiveService.resultadosExcelenciaBox;
      _todosLosResultados = box.values.toList();
      
      print('📦 Total resultados cargados desde Hive: ${_todosLosResultados.length}');
      
      // Debug: Mostrar algunos datos de muestra
      if (_todosLosResultados.isNotEmpty) {
        final primer = _todosLosResultados.first;
        print('📋 Ejemplo de resultado:');
        print('  - ID: ${primer.id}');
        print('  - Líder: ${primer.liderNombre}');
        print('  - País: ${primer.pais}');
        print('  - Canal: ${primer.metadatos?['canalVenta']}');
        print('  - Respuestas: ${primer.respuestas.length}');
      }
      
      // Extraer valores únicos para filtros
      _extraerValoresUnicos();
      
      // Generar reporte inicial (sin filtros)
      _generarReporte();
      
      print('✅ Datos cargados exitosamente');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar datos: $e');
      _error = 'Error al cargar datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Extrae valores únicos para los filtros
  void _extraerValoresUnicos() {
    final Set<String> paises = {};
    final Set<String> centros = {};
    final Set<String> lideres = {};
    final Set<String> canales = {};
    
    for (var resultado in _todosLosResultados) {
      if (resultado.pais.isNotEmpty) paises.add(resultado.pais);
      if (resultado.centroDistribucion.isNotEmpty) centros.add(resultado.centroDistribucion);
      if (resultado.liderNombre.isNotEmpty) {
        lideres.add('${resultado.liderClave}-${resultado.liderNombre}');
      }
      
      final canal = resultado.metadatos?['canalVenta']?.toString();
      if (canal != null && canal.isNotEmpty) canales.add(canal);
    }
    
    _paisesDisponibles = paises.toList()..sort();
    _centrosDisponibles = centros.toList()..sort();
    _lideresDisponibles = lideres.toList()..sort();
    _canalesDisponibles = canales.toList()..sort();
  }
  
  /// Genera el reporte con los filtros actuales
  void _generarReporte() {
    print('📊 Generando reporte...');
    print('  - Total resultados disponibles: ${_todosLosResultados.length}');
    print('  - Filtros aplicados:');
    print('    * País: $_filtroPais');
    print('    * Centro: $_filtroCentroDistribucion');
    print('    * Líder: $_filtroLider');
    print('    * Canal: $_filtroCanal');
    
    _reporteData = ExcelenciaAggregator.generarReporte(
      _todosLosResultados,
      filtroCanal: _filtroCanal,
      filtroLider: _filtroLider?.split('-').first, // Extraer solo la clave
      filtroPais: _filtroPais,
      filtroCentroDistribucion: _filtroCentroDistribucion,
    );
    
    print('  - Resultados después de filtros: ${_reporteData['totalResultados']}');
    print('  - Canales encontrados: ${_reporteData['porCanal']?.keys.toList()}');
  }
  
  /// Actualiza el filtro de país
  void setFiltroPais(String? valor) {
    _filtroPais = valor;
    _generarReporte();
    notifyListeners();
  }
  
  /// Actualiza el filtro de centro de distribución
  void setFiltroCentroDistribucion(String? valor) {
    _filtroCentroDistribucion = valor;
    _generarReporte();
    notifyListeners();
  }
  
  /// Actualiza el filtro de líder
  void setFiltroLider(String? valor) {
    _filtroLider = valor;
    _generarReporte();
    notifyListeners();
  }
  
  /// Actualiza el filtro de canal
  void setFiltroCanal(String? valor) {
    _filtroCanal = valor;
    _generarReporte();
    notifyListeners();
  }
  
  /// Limpia todos los filtros
  void limpiarFiltros() {
    _filtroPais = null;
    _filtroCentroDistribucion = null;
    _filtroLider = null;
    _filtroCanal = null;
    _generarReporte();
    notifyListeners();
  }
  
  /// Obtiene los datos para la tabla
  List<Map<String, dynamic>> obtenerDatosTabla() {
    print('📋 Generando datos para tabla...');
    final List<Map<String, dynamic>> filas = [];
    
    if (_reporteData.isEmpty || _reporteData['porCanal'] == null) {
      print('❌ No hay datos del reporte o porCanal es null');
      print('  - _reporteData.isEmpty: ${_reporteData.isEmpty}');
      print('  - _reporteData.keys: ${_reporteData.keys.toList()}');
      return filas;
    }
    
    final porCanal = _reporteData['porCanal'] as Map<String, dynamic>;
    
    for (var entradaCanal in porCanal.entries) {
      final canal = entradaCanal.key;
      final datosCanal = entradaCanal.value as Map<String, dynamic>;
      final porLider = datosCanal['porLider'] as Map<String, dynamic>;
      
      for (var entradaLider in porLider.entries) {
        final liderInfo = entradaLider.key.split('-');
        final liderClave = liderInfo.isNotEmpty ? liderInfo[0] : '';
        final liderNombre = liderInfo.length > 1 ? liderInfo[1] : '';
        
        final datosLider = entradaLider.value as Map<String, dynamic>;
        final detalle = datosLider['detalle'] as Map<String, dynamic>;
        final puntajesPorCategoria = detalle['puntajesPorCategoria'] as Map<String, double>;
        final puntajePromedio = detalle['puntajePromedio'] as double;
        
        // Obtener equipo del primer resultado
        final resultados = datosLider['resultados'] as List<ResultadoExcelenciaHive>;
        final equipo = resultados.isNotEmpty ? resultados.first.ruta : '';
        
        filas.add({
          'canal': canal,
          'lider': liderNombre,
          'equipo': equipo,
          'alineacionObjetivos': puntajesPorCategoria['Alineación de Objetivos'] ?? 0.0,
          'planeacion': puntajesPorCategoria['Planeación'] ?? 0.0,
          'organizacion': puntajesPorCategoria['Organización'] ?? 0.0,
          'ejecucion': puntajesPorCategoria['Ejecución'] ?? 0.0,
          'retroalimentacion': puntajesPorCategoria['Retroalimentación y Reconocimiento'] ?? 0.0,
          'logroObjetivos': puntajesPorCategoria['Logro de Objetivos de Venta'] ?? 0.0,
          'puntajeFinal': puntajePromedio,
          'color': ExcelenciaAggregator.obtenerColorPuntaje(puntajePromedio),
        });
      }
    }
    
    // Ordenar por canal y luego por líder
    filas.sort((a, b) {
      final canalComp = a['canal'].toString().compareTo(b['canal'].toString());
      if (canalComp != 0) return canalComp;
      return a['lider'].toString().compareTo(b['lider'].toString());
    });
    
    print('✅ Tabla generada con ${filas.length} filas');
    if (filas.isNotEmpty) {
      print('📋 Primera fila de ejemplo: ${filas.first}');
    }
    
    return filas;
  }
  
  /// Obtiene los totales por canal
  Map<String, Map<String, double>> obtenerTotalesPorCanal() {
    final Map<String, Map<String, double>> totales = {};
    
    if (_reporteData.isEmpty || _reporteData['porCanal'] == null) {
      return totales;
    }
    
    final porCanal = _reporteData['porCanal'] as Map<String, dynamic>;
    
    for (var entrada in porCanal.entries) {
      final canal = entrada.key;
      final datosCanal = entrada.value as Map<String, dynamic>;
      final resumen = datosCanal['resumen'] as Map<String, dynamic>;
      final puntajesPorCategoria = resumen['puntajesPorCategoria'] as Map<String, double>;
      
      totales[canal] = {
        'alineacionObjetivos': puntajesPorCategoria['Alineación de Objetivos'] ?? 0.0,
        'planeacion': puntajesPorCategoria['Planeación'] ?? 0.0,
        'organizacion': puntajesPorCategoria['Organización'] ?? 0.0,
        'ejecucion': puntajesPorCategoria['Ejecución'] ?? 0.0,
        'retroalimentacion': puntajesPorCategoria['Retroalimentación y Reconocimiento'] ?? 0.0,
        'logroObjetivos': puntajesPorCategoria['Logro de Objetivos de Venta'] ?? 0.0,
        'puntajeFinal': resumen['puntajePromedio'] ?? 0.0,
      };
    }
    
    return totales;
  }
  
  /// Obtiene el total general
  Map<String, double> obtenerTotalGeneral() {
    if (_reporteData.isEmpty || _reporteData['resumenGeneral'] == null) {
      return {};
    }
    
    final resumen = _reporteData['resumenGeneral'] as Map<String, dynamic>;
    final puntajesPorCategoria = resumen['puntajesPorCategoria'] as Map<String, double>;
    
    return {
      'alineacionObjetivos': puntajesPorCategoria['Alineación de Objetivos'] ?? 0.0,
      'planeacion': puntajesPorCategoria['Planeación'] ?? 0.0,
      'organizacion': puntajesPorCategoria['Organización'] ?? 0.0,
      'ejecucion': puntajesPorCategoria['Ejecución'] ?? 0.0,
      'retroalimentacion': puntajesPorCategoria['Retroalimentación y Reconocimiento'] ?? 0.0,
      'logroObjetivos': puntajesPorCategoria['Logro de Objetivos de Venta'] ?? 0.0,
      'puntajeFinal': resumen['puntajePromedio'] ?? 0.0,
    };
  }
}