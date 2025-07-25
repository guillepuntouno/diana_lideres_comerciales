// lib/web/vistas/administracion/pantalla_administracion.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/user_dto.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/formulario_list_page.dart';
import 'package:diana_lc_front/web/vistas/evaluacion_desempeno/pantalla_evaluacion_desempeno.dart';
import 'package:diana_lc_front/web/vistas/evaluacion_desempeno/pantalla_resumen_evaluacion.dart';
import 'package:diana_lc_front/shared/servicios/formularios_api_service.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/visita_cliente_hive.dart';
import 'package:diana_lc_front/shared/servicios/resultados_dia_service.dart';
import 'package:diana_lc_front/shared/servicios/offline_sync_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

/// Colores corporativos
class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

/// Enum para las plantillas/rutinas disponibles
enum TipoRutina {
  todas('Todas las actividades', 'todas'),
  visitasClientes('Visitas a Clientes', 'visitas'),
  administrativas('Actividades Administrativas', 'administrativas'),
  formularios('Formularios Capturados', 'formularios');

  final String titulo;
  final String plantillaId;
  
  const TipoRutina(this.titulo, this.plantillaId);
}

class PantallaAdministracion extends StatefulWidget {
  const PantallaAdministracion({Key? key}) : super(key: key);

  @override
  State<PantallaAdministracion> createState() => _PantallaAdministracionState();
}

class _PantallaAdministracionState extends State<PantallaAdministracion> {
  final SesionServicio _sesionServicio = SesionServicio();
  final FormulariosApiService _formulariosApiService = FormulariosApiService();
  final HiveService _hiveService = HiveService();
  final ResultadosDiaService _resultadosService = ResultadosDiaService();
  
  String _vistaSeleccionada = 'dashboard';
  List<UsuarioDto> _usuarios = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permisos = [];
  bool _isLoading = false;
  String _busqueda = '';
  
  // Variables para el dashboard de rutinas
  String? _liderClave;
  String _diaSeleccionado = '';
  TipoRutina _rutinaSeleccionada = TipoRutina.todas;
  String? _rutaFiltro;
  String? _clienteFiltro;
  
  List<PlanTrabajoUnificadoHive> _planesDisponibles = [];
  PlanTrabajoUnificadoHive? _planSeleccionado;
  DiaPlanHive? _diaPlan;
  Map<String, dynamic> _kpis = {};
  
  bool _cargandoRutinas = true;
  bool _isOffline = false;
  String? _errorRutinas;
  
  // Variables para filtros del Programa de Excelencia
  String? _selectedPais;
  String? _selectedCentro;
  String? _selectedRuta;
  Map<String, dynamic>? _selectedRutaData;
  
  // Variables para formularios
  List<Map<String, dynamic>> _formulariosProgramaExcelencia = [];
  String? _selectedFormulario;
  bool _isLoadingFormularios = false;
  
  // Variables para evaluaciones realizadas (mockup para HIVE)
  List<Map<String, dynamic>> _evaluacionesRealizadas = [];
  
  // Datos hardcoded para los filtros en cascada
  final List<Map<String, dynamic>> _paisesData = [
    {
      "id": "ssv01",
      "nombre": "El Salvador",
      "centrosDistribucion": [
        {
          "id": "CD01",
          "nombre": "Centro de Servicio",
          "rutas": [
            {
              "id": "MORD10",
              "nombre": "MORD10",
              "canalVenta": "Tradicional",
              "subcanalVenta": "Detalle",
              "estadoRuta": "Activo",
              "lider": {
                "id": "230",
                "nombre": "LIDER MER03 - GRUPO 3",
                "correo": "felix.hernandez@diana.com.sv"
              }
            }
          ]
        }
      ]
    }
  ];
  
  // Listas dinámicas que se actualizan según la selección
  List<Map<String, dynamic>> _centrosDisponibles = [];
  List<Map<String, dynamic>> _rutasDisponibles = [];
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarEvaluacionesMockup();
    _inicializarRutinas();
    _checkConnectivity();
  }
  
  // Método para cargar evaluaciones desde HIVE
  void _cargarEvaluacionesMockup() {
    _cargarEvaluacionesDesdeHive();
  }
  
  void _cargarEvaluacionesDesdeHive() {
    try {
      final box = _hiveService.resultadosExcelenciaBox;
      final evaluaciones = box.values.toList();
      
      print('📦 Total evaluaciones en Hive: ${evaluaciones.length}');
      
      // Filtrar evaluaciones según la ruta seleccionada si aplica
      List<ResultadoExcelenciaHive> evaluacionesFiltradas;
      if (_selectedRutaData != null) {
        evaluacionesFiltradas = evaluaciones.where((e) => 
          e.ruta == _selectedRutaData!['nombre'] &&
          e.liderClave == _selectedRutaData!['lider']['id']
        ).toList();
        print('🔍 Evaluaciones filtradas para ruta ${_selectedRutaData!['nombre']}: ${evaluacionesFiltradas.length}');
      } else {
        evaluacionesFiltradas = evaluaciones;
      }
      
      // Convertir a formato esperado por la UI
      _evaluacionesRealizadas = evaluacionesFiltradas.map((e) {
        dynamic puntuacionMaxima = 10; // Valor por defecto
        
        // Intentar obtener puntuación máxima del formulario
        try {
          if (e.formularioMaestro.containsKey('resultadoKPI')) {
            puntuacionMaxima = e.formularioMaestro['resultadoKPI']['puntuacionMaxima'] ?? 10;
          }
        } catch (err) {
          print('⚠️ Error obteniendo puntuación máxima: $err');
        }
        
        return {
          'id': e.id,
          'fecha': e.fechaCaptura,
          'evaluador': 'Administrador', // Por ahora hardcoded
          'lider': e.liderNombre,
          'formulario': e.tipoFormulario,
          'puntuacion': e.ponderacionFinal,
          'puntuacionMaxima': puntuacionMaxima is int ? puntuacionMaxima.toDouble() : puntuacionMaxima,
          'estado': e.estatus,
          'enviada': e.syncStatus == 'synced',
          'pais': e.pais,
          'centroDistribucion': e.centroDistribucion,
          'ruta': e.ruta,
          'datosCompletos': e, // Guardamos el objeto completo para poder acceder después
        };
      }).toList();
      
      // Ordenar por fecha más reciente
      _evaluacionesRealizadas.sort((a, b) => 
        (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
      
      setState(() {});
      
      print('📊 Evaluaciones cargadas desde Hive: ${_evaluacionesRealizadas.length}');
      if (_evaluacionesRealizadas.isNotEmpty) {
        print('📌 Primera evaluación: ${_evaluacionesRealizadas.first['formulario']} - ${_evaluacionesRealizadas.first['puntuacion']}/${_evaluacionesRealizadas.first['puntuacionMaxima']}');
      }
    } catch (e) {
      print('❌ Error al cargar evaluaciones desde Hive: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _evaluacionesRealizadas = [];
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      switch (_vistaSeleccionada) {
        case 'dashboard':
          // Dashboard no requiere cargar datos específicos por ahora
          break;
        case 'formularios':
          // Los formularios se manejan en su propio componente
          break;
        case 'programa_excelencia':
          // Programa de excelencia no requiere cargar datos específicos por ahora
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Métodos para el dashboard de rutinas
  Future<void> _inicializarRutinas() async {
    try {
      print('🚀 Iniciando dashboard de rutinas...');
      
      // Obtener líder actual
      final lider = await SesionServicio.obtenerLiderComercial();
      print('👤 Líder obtenido: ${lider?.nombre} - ${lider?.clave}');
      
      if (lider == null) {
        setState(() {
          _errorRutinas = 'No hay sesión activa';
          _cargandoRutinas = false;
        });
        return;
      }
      
      _liderClave = lider.clave;
      
      // Seleccionar día actual por defecto
      _diaSeleccionado = _resultadosService.obtenerNombreDia(DateTime.now());
      print('📅 Día seleccionado: $_diaSeleccionado');
      
      // Cargar datos
      await _cargarDatosRutinas();
    } catch (e) {
      print('❌ Error al inicializar rutinas: $e');
      setState(() {
        _errorRutinas = 'Error al inicializar: $e';
        _cargandoRutinas = false;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
    
    // Listener para cambios de conectividad
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
      });
    });
  }

  Future<void> _cargarDatosRutinas() async {
    if (_liderClave == null) return;
    
    setState(() => _cargandoRutinas = true);
    
    try {
      print('📦 Cargando datos de rutinas...');
      
      // Si hay conexión, sincronizar primero
      if (!_isOffline) {
        print('🔄 Sincronizando datos...');
        final syncManager = OfflineSyncManager();
        await syncManager.performFullSync();
      }
      
      // Cargar todos los planes del líder
      print('📂 Abriendo box de planes_trabajo_unificado...');
      final box = await Hive.openBox<PlanTrabajoUnificadoHive>('planes_trabajo_unificado');
      print('📊 Total planes en box: ${box.values.length}');
      
      _planesDisponibles = box.values
          .where((plan) => plan.liderClave == _liderClave)
          .toList()
          ..sort((a, b) => b.numeroSemana.compareTo(a.numeroSemana));
      
      print('📋 Planes del líder $_liderClave: ${_planesDisponibles.length}');
      for (var plan in _planesDisponibles) {
        print('  - ${plan.semana} (Semana ${plan.numeroSemana}) - ${plan.estatus}');
      }
      
      if (_planesDisponibles.isEmpty) {
        setState(() {
          _errorRutinas = 'No Existen Datos Disponibles para el líder $_liderClave';
          _cargandoRutinas = false;
        });
        return;
      }
      
      // Si no hay plan seleccionado, usar el más reciente
      if (_planSeleccionado == null) {
        _planSeleccionado = _planesDisponibles.first;
      }
      
      // Si hay un día seleccionado, cargar su información
      if (_diaSeleccionado.isNotEmpty && _planSeleccionado!.dias.containsKey(_diaSeleccionado)) {
        _diaPlan = _planSeleccionado!.dias[_diaSeleccionado];
      } else {
        // Seleccionar el primer día con actividades
        final diasConActividades = _planSeleccionado!.dias.entries
            .where((entry) => entry.value.configurado)
            .toList();
        if (diasConActividades.isNotEmpty) {
          _diaSeleccionado = diasConActividades.first.key;
          _diaPlan = diasConActividades.first.value;
        }
      }
      
      // Sincronizar estados de visitas reales con el plan
      await _sincronizarEstadosVisitas();
      
      _kpis = _calcularKPIsRutina();
      
      setState(() {
        _cargandoRutinas = false;
        _errorRutinas = null;
      });
    } catch (e) {
      setState(() {
        _errorRutinas = 'Error al cargar datos: $e';
        _cargandoRutinas = false;
      });
    }
  }

  Future<void> _sincronizarEstadosVisitas() async {
    if (_diaPlan == null || _diaPlan!.tipo != 'gestion_cliente' || _liderClave == null) return;
    
    try {
      // Abrir el box de visitas
      final visitasBox = await Hive.openBox<VisitaClienteHive>('visitas_clientes');
      
      // Obtener la fecha del día seleccionado
      final fechaDia = _obtenerFechaDelDia(_diaSeleccionado);
      
      // Iterar sobre cada cliente del día
      for (var cliente in _diaPlan!.clientes) {
        // Buscar visitas de este cliente en la fecha específica
        for (var visita in visitasBox.values) {
          if (visita.clienteId == cliente.clienteId && 
              visita.liderClave == _liderClave &&
              visita.fechaCreacion.year == fechaDia.year &&
              visita.fechaCreacion.month == fechaDia.month &&
              visita.fechaCreacion.day == fechaDia.day) {
            
            // Actualizar el estado del cliente en el plan
            if (visita.estatus == 'completada' || visita.checkOut != null) {
              cliente.estatus = 'completada';
              cliente.horaInicio = visita.checkIn.timestamp.toIso8601String();
              if (visita.checkOut != null) {
                cliente.horaFin = visita.checkOut!.timestamp.toIso8601String();
              }
              cliente.comentarioInicio = visita.checkIn.comentarios;
            } else if (visita.estatus == 'en_proceso') {
              cliente.estatus = 'en_proceso';
              cliente.horaInicio = visita.checkIn.timestamp.toIso8601String();
              cliente.comentarioInicio = visita.checkIn.comentarios;
            }
            
            // Sincronizar formularios capturados
            if (visita.formularios.isNotEmpty) {
              for (var formularioEntry in visita.formularios.entries) {
                final formularioId = formularioEntry.key;
                final formularioData = formularioEntry.value;
                
                // Verificar si ya existe el formulario en el día del plan
                bool formularioExiste = _diaPlan!.formularios.any((f) => 
                  f.clienteId == cliente.clienteId && 
                  f.formularioId == formularioId
                );
                
                if (!formularioExiste) {
                  // Crear un formulario del día para agregarlo al plan
                  final nuevoFormulario = FormularioDiaHive(
                    formularioId: formularioId,
                    clienteId: cliente.clienteId,
                    respuestas: formularioData is Map<String, dynamic> ? formularioData : {},
                    fechaCaptura: visita.fechaCreacion,
                  );
                  
                  _diaPlan!.formularios.add(nuevoFormulario);
                }
              }
            }
            
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error al sincronizar estados de visitas: $e');
    }
  }
  
  DateTime _obtenerFechaDelDia(String nombreDia) {
    final ahora = DateTime.now();
    final diasSemana = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    final diaIndex = diasSemana.indexOf(nombreDia.toLowerCase());
    final diaActualIndex = ahora.weekday - 1;
    
    var diferenciaDias = diaIndex - diaActualIndex;
    
    // Ajustar a la misma semana
    if (diferenciaDias < -3) {
      diferenciaDias += 7;
    } else if (diferenciaDias > 3) {
      diferenciaDias -= 7;
    }
    
    return ahora.add(Duration(days: diferenciaDias));
  }

  Map<String, dynamic> _calcularKPIsRutina() {
    if (_diaPlan == null || _diaPlan!.tipo != 'gestion_cliente') {
      return {
        'clientesPlanificados': 0,
        'visitados': 0,
        'porcentajeCumplimiento': 0,
        'duracionPromedio': 0,
      };
    }
    
    // Filtrar actividades según la rutina seleccionada
    final actividadesFiltradas = _obtenerActividadesFiltradas();
    
    final clientesPlanificados = actividadesFiltradas.length;
    final visitados = actividadesFiltradas.where((v) {
      // Verificar si tiene el formulario correspondiente
      if (_rutinaSeleccionada == TipoRutina.todas) {
        return v.estatus == 'completada';
      }
      
      // Para otras rutinas, verificar si tiene el formulario correspondiente
      final tieneFormulario = _tieneFormularioRutina(v);
      return tieneFormulario;
    }).length;
    
    final porcentajeCumplimiento = clientesPlanificados > 0 
        ? (visitados / clientesPlanificados * 100).round() 
        : 0;
    
    // Calcular duración promedio
    final duraciones = <int>[];
    for (final visita in actividadesFiltradas) {
      if (visita.horaInicio != null && visita.horaFin != null) {
        try {
          final inicio = DateTime.parse(visita.horaInicio!);
          final fin = DateTime.parse(visita.horaFin!);
          final duracion = fin.difference(inicio).inMinutes;
          if (duracion > 0) duraciones.add(duracion);
        } catch (_) {}
      }
    }
    
    final duracionPromedio = duraciones.isNotEmpty
        ? (duraciones.reduce((a, b) => a + b) / duraciones.length).round()
        : 0;
    
    return {
      'clientesPlanificados': clientesPlanificados,
      'visitados': visitados,
      'porcentajeCumplimiento': porcentajeCumplimiento,
      'duracionPromedio': duracionPromedio,
    };
  }

  List<VisitaClienteUnificadaHive> _obtenerActividadesFiltradas() {
    if (_diaPlan == null) return [];
    
    // Si es día administrativo - COMENTADO TEMPORALMENTE
    // if (_diaPlan!.tipo == 'administrativo' && 
    //     (_rutinaSeleccionada == TipoRutina.administrativas || 
    //      _rutinaSeleccionada == TipoRutina.todas)) {
    //   return []; // Las actividades administrativas se muestran diferente
    // }
    
    var actividades = _diaPlan!.clientes;
    
    // Filtrar por tipo de rutina seleccionada
    switch (_rutinaSeleccionada) {
      case TipoRutina.visitasClientes:
        // Mostrar todas las visitas programadas
        break;
      case TipoRutina.formularios:
        // Solo mostrar clientes con formularios capturados
        actividades = actividades.where((a) => 
          _diaPlan!.formularios.any((f) => f.clienteId == a.clienteId)
        ).toList();
        break;
      case TipoRutina.administrativas:
        // No mostrar clientes en vista administrativa
        return [];
      case TipoRutina.todas:
        // Mostrar todos
        break;
    }
    
    // Filtrar por ruta si está seleccionada
    if (_rutaFiltro != null && _rutaFiltro!.isNotEmpty) {
      // TODO: Implementar filtro por ruta cuando tengamos esa información
    }
    
    // Filtrar por cliente si está seleccionado
    if (_clienteFiltro != null && _clienteFiltro!.isNotEmpty) {
      actividades = actividades.where((a) => a.clienteId == _clienteFiltro).toList();
    }
    
    return actividades;
  }

  bool _tieneFormularioRutina(VisitaClienteUnificadaHive visita) {
    // Buscar en los formularios del día si existe uno para este cliente
    final formularios = _diaPlan?.formularios ?? [];
    return formularios.any((f) => f.clienteId == visita.clienteId);
  }

  void _cambiarDia(String nuevoDia) async {
    setState(() {
      _diaSeleccionado = nuevoDia;
      _cargandoRutinas = true;
    });
    
    // Actualizar el día del plan
    if (_planSeleccionado != null && _planSeleccionado!.dias.containsKey(nuevoDia)) {
      _diaPlan = _planSeleccionado!.dias[nuevoDia];
      
      // Sincronizar estados de visitas para el nuevo día
      await _sincronizarEstadosVisitas();
      
      // Recalcular KPIs
      _kpis = _calcularKPIsRutina();
      
      setState(() {
        _cargandoRutinas = false;
      });
    } else {
      await _cargarDatosRutinas();
    }
  }

  void _cambiarRutina(TipoRutina nuevaRutina) {
    setState(() {
      _rutinaSeleccionada = nuevaRutina;
      _kpis = _calcularKPIsRutina();
    });
  }

  void _cambiarPlan(PlanTrabajoUnificadoHive nuevoPlan) {
    setState(() {
      _planSeleccionado = nuevoPlan;
      _diaSeleccionado = ''; // Resetear día seleccionado
      _diaPlan = null;
      _rutaFiltro = null;
      _clienteFiltro = null;
    });
    
    // Seleccionar el primer día con actividades
    final diasConActividades = nuevoPlan.dias.entries
        .where((entry) => entry.value.configurado)
        .toList();
    if (diasConActividades.isNotEmpty) {
      setState(() {
        _diaSeleccionado = diasConActividades.first.key;
        _diaPlan = diasConActividades.first.value;
        _kpis = _calcularKPIsRutina();
      });
    }
  }

  Color _obtenerColorSemaforo(int porcentaje) {
    if (porcentaje >= 80) return AppColors.dianaGreen;
    if (porcentaje >= 60) return AppColors.dianaYellow;
    return AppColors.dianaRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar de navegación
          _buildSidebar(),
          
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          _buildSidebarItem('dashboard', 'Dashboard', Icons.dashboard),
          _buildSidebarItem('formularios', 'Formularios', Icons.description),
          _buildSidebarItem('programa_excelencia', 'Programa de excelencia', Icons.star),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String id, String label, IconData icon) {
    final isActive = _vistaSeleccionada == id;
    
    return InkWell(
      onTap: () {
        setState(() => _vistaSeleccionada = id);
        _cargarDatos();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDE1327).withOpacity(0.1) : null,
          border: isActive
              ? const Border(
                  left: BorderSide(
                    color: Color(0xFFDE1327),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFFDE1327) : const Color(0xFF8F8E8E),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? const Color(0xFFDE1327) : const Color(0xFF8F8E8E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getTituloVista(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const Spacer(),
          
          // Search bar
          if (_vistaSeleccionada != 'configuracion' && _vistaSeleccionada != 'dashboard' && _vistaSeleccionada != 'formularios') ...[
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (value) => setState(() => _busqueda = value),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Actions
          if (_vistaSeleccionada == 'usuarios' || 
              _vistaSeleccionada == 'roles' || 
              _vistaSeleccionada == 'permisos') ...[
            ElevatedButton.icon(
              onPressed: _vistaSeleccionada == 'formularios' ? _navegarAFormularios : _agregarNuevo,
              icon: const Icon(Icons.add),
              label: Text(_vistaSeleccionada == 'formularios' ? 'Gestionar Formularios' : 'Agregar ${_getNombreSingular()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE1327),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_vistaSeleccionada) {
      case 'dashboard':
        return _buildDashboardView();
      case 'formularios':
        return _buildFormulariosView();
      case 'programa_excelencia':
        return _buildProgramaExcelenciaView();
      default:
        return const Center(child: Text('Vista no disponible'));
    }
  }

  Widget _buildUsuariosView() {
    final usuariosFiltrados = _usuarios.where((usuario) {
      if (_busqueda.isEmpty) return true;
      return usuario.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
             usuario.correo.toLowerCase().contains(_busqueda.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Stats cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatCard('Total Usuarios', _usuarios.length.toString(), Icons.people, const Color(0xFF38A169)),
                  const SizedBox(width: 16),
                  _buildStatCard('Activos', _usuarios.where((u) => u.estado == 'activo').length.toString(), Icons.check_circle, const Color(0xFFF6C343)),
                  const SizedBox(width: 16),
                  _buildStatCard('Administradores', '3', Icons.admin_panel_settings, const Color(0xFFDE1327)),
                  const SizedBox(width: 16),
                  _buildStatCard('Conectados', '12', Icons.online_prediction, Colors.purple),
                ],
              ),
            ),
            
            // Data table
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Centro')),
                    DataColumn(label: Text('Último Acceso')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: usuariosFiltrados.map((usuario) {
                    return DataRow(cells: [
                      DataCell(Text(usuario.id.toString())),
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFDE1327),
                            child: Text(
                              usuario.nombre.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(usuario.nombre),
                        ],
                      )),
                      DataCell(Text(usuario.correo)),
                      DataCell(_buildRolChip(usuario.rol)),
                      DataCell(Text(usuario.centroDistribucion ?? 'N/A')),
                      DataCell(Text(_formatearFecha(DateTime.fromMillisecondsSinceEpoch(usuario.updatedAt)))),
                      DataCell(_buildEstadoChip(usuario.estado == 'activo')),
                      DataCell(_buildAccionesUsuario(usuario)),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final rol = _roles[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE1327).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForRol(rol['nombre']),
                        color: const Color(0xFFDE1327),
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(child: Text('Editar')),
                        const PopupMenuItem(child: Text('Duplicar')),
                        const PopupMenuItem(child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rol['nombre'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                Text(
                  rol['descripcion'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF8F8E8E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${rol['usuarios']} usuarios',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                    Text(
                      '${rol['permisos']} permisos',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermisosView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Módulo')),
              DataColumn(label: Text('Ver')),
              DataColumn(label: Text('Crear')),
              DataColumn(label: Text('Editar')),
              DataColumn(label: Text('Eliminar')),
              DataColumn(label: Text('Exportar')),
              DataColumn(label: Text('Administrar')),
            ],
            rows: _permisos.map((permiso) {
              return DataRow(cells: [
                DataCell(Text(permiso['modulo'])),
                DataCell(Checkbox(value: permiso['ver'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['crear'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['editar'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['eliminar'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['exportar'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['administrar'], onChanged: (v) {})),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulariosView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Gestión de Formularios Dinámicos',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administre las plantillas de formularios para captura de datos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navegarAFormularios,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Ir a Gestión de Formularios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDE1327),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditoriaView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Registro de Actividades',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return _buildAuditoriaItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditoriaItem(int index) {
    final acciones = ['creó', 'modificó', 'eliminó', 'accedió a'];
    final objetos = ['un usuario', 'un rol', 'un permiso', 'un reporte'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '${DateTime.now().subtract(Duration(hours: index)).hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFDE1327).withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 16,
              color: Color(0xFFDE1327),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Usuario ${index + 1} ',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  TextSpan(
                    text: '${acciones[index % acciones.length]} ${objetos[index % objetos.length]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF8F8E8E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigSection('Configuración General', [
            _buildConfigItem('Nombre del Sistema', 'Diana Líderes Comerciales'),
            _buildConfigItem('Versión', '2.0.0'),
            _buildConfigItem('Ambiente', 'Producción'),
            _buildConfigItem('URL API', 'https://api.diana.com'),
          ]),
          const SizedBox(height: 24),
          _buildConfigSection('Configuración de Seguridad', [
            _buildConfigSwitch('Autenticación de dos factores', true),
            _buildConfigSwitch('Bloqueo por intentos fallidos', true),
            _buildConfigItem('Intentos máximos', '3'),
            _buildConfigItem('Duración del token', '24 horas'),
          ]),
          const SizedBox(height: 24),
          _buildConfigSection('Configuración de Notificaciones', [
            _buildConfigSwitch('Notificaciones por email', true),
            _buildConfigSwitch('Notificaciones push', false),
            _buildConfigSwitch('Resumen diario', true),
          ]),
        ],
      ),
    );
  }

  Widget _buildConfigSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSwitch(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: const Color(0xFFDE1327),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF8F8E8E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolChip(String rol) {
    final color = rol == 'admin' ? const Color(0xFFDE1327) : const Color(0xFF38A169);
    
    return Chip(
      label: Text(
        rol,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildEstadoChip(bool activo) {
    return Chip(
      label: Text(
        activo ? 'Activo' : 'Inactivo',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: activo ? const Color(0xFF38A169) : Colors.grey,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildAccionesUsuario(UsuarioDto usuario) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _editarUsuario(usuario),
          color: const Color(0xFFDE1327),
        ),
        IconButton(
          icon: const Icon(Icons.lock_reset, size: 18),
          onPressed: () => _resetearPassword(usuario),
          color: const Color(0xFFF6C343),
        ),
        IconButton(
          icon: Icon(
            usuario.estado == 'activo' ? Icons.block : Icons.check_circle,
            size: 18,
          ),
          onPressed: () => _toggleEstadoUsuario(usuario),
          color: usuario.estado == 'activo' ? Colors.red : const Color(0xFF38A169),
        ),
      ],
    );
  }

  String _getTituloVista() {
    switch (_vistaSeleccionada) {
      case 'usuarios':
        return 'Gestión de Usuarios';
      case 'roles':
        return 'Gestión de Roles';
      case 'permisos':
        return 'Gestión de Permisos';
      case 'formularios':
        return 'Gestión de Formularios';
      case 'auditoria':
        return 'Auditoría del Sistema';
      case 'configuracion':
        return 'Configuración del Sistema';
      default:
        return 'Administración';
    }
  }

  String _getNombreSingular() {
    switch (_vistaSeleccionada) {
      case 'usuarios':
        return 'Usuario';
      case 'roles':
        return 'Rol';
      case 'permisos':
        return 'Permiso';
      default:
        return '';
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Nunca';
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    } else {
      return 'Hace ${diferencia.inDays} días';
    }
  }

  IconData _getIconForRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.supervised_user_circle;
      case 'líder comercial':
        return Icons.person;
      default:
        return Icons.people;
    }
  }

  void _agregarNuevo() {
    // TODO: Implementar diálogo para agregar nuevo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${_getNombreSingular()}'),
        content: const Text('Funcionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cargarDatos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editarUsuario(UsuarioDto usuario) {
    // TODO: Implementar edición de usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando usuario: ${usuario.nombre}')),
    );
  }

  void _resetearPassword(UsuarioDto usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetear Contraseña'),
        content: Text('¿Está seguro de resetear la contraseña de ${usuario.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraseña reseteada exitosamente')),
              );
            },
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  void _toggleEstadoUsuario(UsuarioDto usuario) {
    final accion = usuario.estado == 'activo' ? 'desactivar' : 'activar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${accion.substring(0, 1).toUpperCase()}${accion.substring(1)} Usuario'),
        content: Text('¿Está seguro de $accion a ${usuario.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar cambio de estado
              _cargarDatos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: usuario.estado == 'activo' ? Colors.red : const Color(0xFF38A169),
            ),
            child: Text(accion.substring(0, 1).toUpperCase() + accion.substring(1)),
          ),
        ],
      ),
    );
  }

  void _navegarAFormularios() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioListPage(),
      ),
    );
  }

  // Métodos para generar datos de prueba
  List<UsuarioDto> _generarUsuariosDePrueba() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(15, (index) => UsuarioDto(
      id: 'USR${(index + 1).toString().padLeft(3, '0')}',
      nombre: 'Usuario ${index + 1}',
      correo: 'usuario${index + 1}@diana.com',
      rol: index % 3 == 0 ? 'admin' : 'lider',
      estado: index % 5 != 0 ? 'activo' : 'inactivo',
      centroDistribucion: 'Centro ${(index % 3) + 1}',
      createdAt: now - (86400000 * index), // días en milisegundos
      updatedAt: now - (3600000 * index * 2), // horas en milisegundos
      deletedAt: 0, // 0 para indicar no eliminado
      createdBy: 'admin',
      updatedBy: 'admin',
      deletedBy: '', // string vacío en lugar de null
      isDeleted: false,
    ));
  }

  List<Map<String, dynamic>> _generarRolesDePrueba() {
    return [
      {
        'nombre': 'Administrador',
        'descripcion': 'Acceso completo al sistema',
        'usuarios': 3,
        'permisos': 45,
      },
      {
        'nombre': 'Supervisor',
        'descripcion': 'Gestión de equipos y reportes',
        'usuarios': 8,
        'permisos': 32,
      },
      {
        'nombre': 'Líder Comercial',
        'descripcion': 'Gestión de visitas y clientes',
        'usuarios': 25,
        'permisos': 18,
      },
      {
        'nombre': 'Auditor',
        'descripcion': 'Acceso de solo lectura para auditoría',
        'usuarios': 2,
        'permisos': 12,
      },
    ];
  }

  List<Map<String, dynamic>> _generarPermisosDePrueba() {
    return [
      {
        'modulo': 'Dashboard',
        'ver': true,
        'crear': false,
        'editar': false,
        'eliminar': false,
        'exportar': true,
        'administrar': false,
      },
      {
        'modulo': 'Visitas',
        'ver': true,
        'crear': true,
        'editar': true,
        'eliminar': false,
        'exportar': true,
        'administrar': false,
      },
      {
        'modulo': 'Clientes',
        'ver': true,
        'crear': true,
        'editar': true,
        'eliminar': true,
        'exportar': true,
        'administrar': true,
      },
      {
        'modulo': 'Reportes',
        'ver': true,
        'crear': false,
        'editar': false,
        'eliminar': false,
        'exportar': true,
        'administrar': false,
      },
      {
        'modulo': 'Usuarios',
        'ver': true,
        'crear': true,
        'editar': true,
        'eliminar': true,
        'exportar': false,
        'administrar': true,
      },
    ];
  }
  
  Widget _buildDashboardView() {
    if (_cargandoRutinas) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.dianaRed),
            const SizedBox(height: 16),
            Text(
              'Cargando dashboard de rutinas...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_errorRutinas != null) {
      return _buildErrorRutinas();
    }
    
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1400, // Limitar ancho máximo para mejor lectura
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y filtros principales
            _buildDashboardHeader(),
            
            const SizedBox(height: 24),
            
            // Offline banner si aplica
            if (_isOffline) _buildOfflineBanner(),
            
            // Tabs de rutinas si hay plan seleccionado
            if (_planSeleccionado != null && _tieneActividadesParaMostrar()) ...[
              _buildTabsRutinas(),
              const SizedBox(height: 24),
            ],
            
            // Contenido principal o mensaje de sin datos
            if (_planSeleccionado == null || _planesDisponibles.isEmpty)
              _buildSinDatosMessage()
            else ...[
              // Selector de día
              _buildSelectorDia(),
              
              const SizedBox(height: 32),
              
              // KPIs
              _buildKPIsRutinas(),
              
              const SizedBox(height: 32),
              
              // Lista de actividades
              _buildListaActividades(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorRutinas() {
    final bool noHayDatos = _errorRutinas == 'No Existen Datos Disponibles';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noHayDatos ? Icons.inbox : Icons.error_outline,
            size: 64,
            color: noHayDatos ? Colors.grey.shade300 : Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            noHayDatos ? 'Sin Datos' : 'Error',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorRutinas ?? 'Ha ocurrido un error',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cargarDatosRutinas,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dianaRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reintentar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinPlanRutinas() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.orange.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Plan de Trabajo',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No hay un plan de trabajo programado para esta semana.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize, color: AppColors.dianaRed, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard de Rutinas',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestión y seguimiento de actividades comerciales',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de sincronizar
              if (!_isOffline)
                IconButton(
                  onPressed: _cargarDatosRutinas,
                  icon: Icon(Icons.sync, color: AppColors.dianaRed),
                  tooltip: 'Sincronizar datos',
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Filtros principales
          Row(
            children: [
              // Selector de semana
              Expanded(
                flex: 2,
                child: _buildSelectorSemana(),
              ),
              const SizedBox(width: 16),
              // Selector de año
              Expanded(
                child: _buildSelectorAnio(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorSemana() {
    if (_planesDisponibles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.mediumGray, size: 20),
            const SizedBox(width: 12),
            Text(
              'Sin planes disponibles',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: AppColors.dianaRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PlanTrabajoUnificadoHive>(
                value: _planSeleccionado,
                isExpanded: true,
                hint: Text(
                  'Seleccionar semana',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.mediumGray),
                ),
                items: _planesDisponibles.map((plan) {
                  return DropdownMenuItem(
                    value: plan,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plan.semana,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.estatus == 'enviado' 
                              ? AppColors.dianaGreen.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan.estatus.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: plan.estatus == 'enviado' 
                                ? AppColors.dianaGreen
                                : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (plan) {
                  if (plan != null) _cambiarPlan(plan);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorAnio() {
    final aniosDisponibles = _planesDisponibles
        .map((p) => p.anio)
        .toSet()
        .toList()
        ..sort((a, b) => b.compareTo(a));

    if (aniosDisponibles.isEmpty) {
      return Container();
    }

    final anioActual = _planSeleccionado?.anio ?? aniosDisponibles.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: AppColors.dianaRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: anioActual,
                isExpanded: true,
                items: aniosDisponibles.map((anio) {
                  return DropdownMenuItem(
                    value: anio,
                    child: Text(
                      'Año $anio',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (anio) {
                  if (anio != null) {
                    // Filtrar planes por año y seleccionar el primero
                    final planesPorAnio = _planesDisponibles
                        .where((p) => p.anio == anio)
                        .toList();
                    if (planesPorAnio.isNotEmpty) {
                      _cambiarPlan(planesPorAnio.first);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinDatosMessage() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No hay planes de trabajo disponibles',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron planes para el líder actual',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatosRutinas,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Actualizar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo sin conexión - Los cambios se sincronizarán cuando se restablezca la conexión',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTabsRutinas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: TipoRutina.values.map((rutina) {
          final isSelected = _rutinaSeleccionada == rutina;
          return Expanded(
            child: InkWell(
              onTap: () => _cambiarRutina(rutina),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.dianaRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rutina.titulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.mediumGray,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectorDia() {
    if (_planSeleccionado == null) return const SizedBox.shrink();
    
    final diasConfigurados = _planSeleccionado!.dias.entries
        .where((entry) => entry.value.configurado)
        .map((entry) => entry.key)
        .toList();
    
    if (diasConfigurados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              'No hay días configurados en este plan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona un día',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: diasConfigurados.length,
            itemBuilder: (context, index) {
              final dia = diasConfigurados[index];
              final diaPlan = _planSeleccionado!.dias[dia]!;
              final isSelected = dia == _diaSeleccionado;
              
              final totalClientes = diaPlan.clientes.length;
              final clientesCompletados = diaPlan.clientes
                  .where((c) => c.estatus == 'completada')
                  .length;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _cambiarDia(dia),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.dianaRed : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.dianaRed : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.dianaRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dia.substring(0, 3).toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (diaPlan.tipo == 'gestion_cliente') ...[
                          Text(
                            '$clientesCompletados/$totalClientes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isSelected ? Colors.white : AppColors.mediumGray,
                            ),
                          ),
                        ] else if (diaPlan.tipo == 'administrativo') ...[
                          Icon(
                            Icons.business_center,
                            size: 20,
                            color: isSelected ? Colors.white : AppColors.mediumGray,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKPIsRutinas() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.dianaRed, size: 28),
              const SizedBox(width: 12),
              Text(
                'Indicadores de ${_rutinaSeleccionada.titulo}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              // Hacer los KPIs responsivos
              if (constraints.maxWidth < 600) {
                // Vista móvil: 2 columnas
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            'Planificados',
                            _kpis['clientesPlanificados'] ?? 0,
                            AppColors.darkGray,
                            Icons.assignment,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKPICard(
                            'Visitados',
                            _kpis['visitados'] ?? 0,
                            AppColors.dianaGreen,
                            Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            'Cumplimiento',
                            _kpis['porcentajeCumplimiento'] ?? 0,
                            _obtenerColorSemaforo(_kpis['porcentajeCumplimiento'] ?? 0),
                            Icons.trending_up,
                            esPorcentaje: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKPICard(
                            'Duración Prom.',
                            _kpis['duracionPromedio'] ?? 0,
                            AppColors.dianaYellow,
                            Icons.timer,
                            sufijo: ' min',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Vista desktop: 4 columnas
                return Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        'Planificados',
                        _kpis['clientesPlanificados'] ?? 0,
                        AppColors.darkGray,
                        Icons.assignment,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        'Visitados',
                        _kpis['visitados'] ?? 0,
                        AppColors.dianaGreen,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        'Cumplimiento',
                        _kpis['porcentajeCumplimiento'] ?? 0,
                        _obtenerColorSemaforo(_kpis['porcentajeCumplimiento'] ?? 0),
                        Icons.trending_up,
                        esPorcentaje: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        'Duración Prom.',
                        _kpis['duracionPromedio'] ?? 0,
                        AppColors.dianaYellow,
                        Icons.timer,
                        sufijo: ' min',
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String titulo, int valor, Color color, IconData icono, {bool esPorcentaje = false, String? sufijo}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
                Icon(
                  Icons.trending_up,
                  color: color.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$valor${esPorcentaje ? '%' : ''}${sufijo ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaActividades() {
    if (_diaPlan == null) return const SizedBox.shrink();
    
    // Si es día administrativo - COMENTADO TEMPORALMENTE
    // if (_diaPlan!.tipo == 'administrativo' && 
    //     (_rutinaSeleccionada == TipoRutina.administrativas || 
    //      _rutinaSeleccionada == TipoRutina.todas)) {
    //   return _buildActividadAdministrativa();
    // }
    
    final actividades = _obtenerActividadesFiltradas();
    
    if (actividades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividades con los filtros aplicados',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividades del día',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          ...actividades.map((actividad) => _buildClienteTile(actividad)),
        ],
      ),
    );
  }

  // MÉTODO COMENTADO TEMPORALMENTE - Actividad Administrativa no se muestra correctamente
  // Widget _buildActividadAdministrativa() {
  //   String tipoActividad = _diaPlan!.tipoActividadAdministrativa ?? 'Sin especificar';
  //   
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Actividad Administrativa',
  //           style: GoogleFonts.poppins(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: AppColors.darkGray,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: Colors.blue.shade50,
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.blue.shade200),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(Icons.business_center, color: Colors.blue.shade700, size: 32),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       tipoActividad,
  //                       style: GoogleFonts.poppins(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w600,
  //                         color: AppColors.darkGray,
  //                       ),
  //                     ),
  //                     if (_diaPlan!.objetivoNombre != null) ...[
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         'Objetivo: ${_diaPlan!.objetivoNombre}',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 14,
  //                           color: AppColors.mediumGray,
  //                         ),
  //                       ),
  //                     ],
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildClienteTile(VisitaClienteUnificadaHive visita) {
    Color estadoColor;
    IconData estadoIcon;
    String estadoTexto;
    
    switch (visita.estatus) {
      case 'completada':
        estadoColor = AppColors.dianaGreen;
        estadoIcon = Icons.check_circle;
        estadoTexto = 'Completada';
        break;
      case 'en_proceso':
        estadoColor = AppColors.dianaYellow;
        estadoIcon = Icons.timelapse;
        estadoTexto = 'En proceso';
        break;
      default:
        estadoColor = AppColors.mediumGray;
        estadoIcon = Icons.pending;
        estadoTexto = 'Pendiente';
    }
    
    final tieneFormularios = _diaPlan!.formularios.any((f) => f.clienteId == visita.clienteId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(estadoIcon, color: estadoColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente ${visita.clienteId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      estadoTexto,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: estadoColor,
                      ),
                    ),
                    if (visita.horaInicio != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 12, color: AppColors.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        visita.horaInicio!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                    if (tieneFormularios) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.assignment_turned_in, size: 12, color: AppColors.dianaGreen),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.mediumGray),
        ],
      ),
    );
  }

  bool _tieneActividadesParaMostrar() {
    if (_planSeleccionado == null) return false;
    
    return _planSeleccionado!.dias.values.any((dia) => 
      dia.configurado && (dia.clientes.isNotEmpty || dia.tipo == 'administrativo')
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String trend) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trend.startsWith('+') ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trend.startsWith('+'))
                      Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 16,
                      )
                    else if (trend == 'En línea')
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 8,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trend.startsWith('+') ? Colors.green : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C2120),
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF8F8E8E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgramaExcelenciaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Programa de Excelencia',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gestión y seguimiento del programa de excelencia comercial',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          const SizedBox(height: 32),
          
          // Filtros en cascada
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros de búsqueda',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Grid de filtros
                Column(
                  children: [
                    // Primera fila de filtros
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            'País', 
                            _selectedPais, 
                            _paisesData.map((p) => {'id': p['id'] as String, 'nombre': p['nombre'] as String}).toList(),
                            (value) {
                              setState(() {
                                _selectedPais = value;
                                _selectedCentro = null;
                                _selectedRuta = null;
                                _selectedRutaData = null;
                                
                                // Actualizar centros disponibles
                                if (value != null) {
                                  final pais = _paisesData.firstWhere((p) => p['id'] == value);
                                  _centrosDisponibles = List<Map<String, dynamic>>.from(pais['centrosDistribucion']);
                                } else {
                                  _centrosDisponibles = [];
                                }
                                _rutasDisponibles = [];
                              });
                            }
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFilterDropdown(
                            'Centro de Distribución', 
                            _selectedCentro, 
                            _centrosDisponibles.map((c) => {'id': c['id'] as String, 'nombre': c['nombre'] as String}).toList(),
                            _selectedPais == null ? null : (value) {
                              setState(() {
                                _selectedCentro = value;
                                _selectedRuta = null;
                                _selectedRutaData = null;
                                
                                // Actualizar rutas disponibles
                                if (value != null) {
                                  final centro = _centrosDisponibles.firstWhere((c) => c['id'] == value);
                                  _rutasDisponibles = List<Map<String, dynamic>>.from(centro['rutas']);
                                } else {
                                  _rutasDisponibles = [];
                                }
                              });
                            }
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFilterDropdown(
                            'Ruta', 
                            _selectedRuta, 
                            _rutasDisponibles.map((r) => {'id': r['id'] as String, 'nombre': r['nombre'] as String}).toList(),
                            _selectedCentro == null ? null : (value) {
                              setState(() {
                                _selectedRuta = value;
                                if (value != null) {
                                  _selectedRutaData = _rutasDisponibles.firstWhere((r) => r['id'] == value);
                                  // Cargar formularios cuando se selecciona una ruta
                                  _cargarFormulariosProgramaExcelencia();
                                  // Recargar evaluaciones para la ruta seleccionada
                                  _cargarEvaluacionesDesdeHive();
                                } else {
                                  _selectedFormulario = null;
                                  _formulariosProgramaExcelencia = [];
                                }
                              });
                            }
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Información de la ruta seleccionada
                    if (_selectedRutaData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información de la Ruta',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('Canal de Venta', _selectedRutaData!['canalVenta']),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoItem('Subcanal de Venta', _selectedRutaData!['subcanalVenta']),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoItem('Estado', _selectedRutaData!['estadoRuta']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Información del Líder',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('Nombre', _selectedRutaData!['lider']['nombre']),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoItem('Correo', _selectedRutaData!['lider']['correo']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Seleccionar Formulario',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingFormularios
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _buildFilterDropdown(
                                    'Formulario de Evaluación',
                                    _selectedFormulario,
                                    _formulariosProgramaExcelencia.map((f) => {
                                      'id': f['id'] as String,
                                      'nombre': f['nombre'] as String,
                                    }).toList(),
                                    _formulariosProgramaExcelencia.isEmpty ? null : (value) {
                                      setState(() {
                                        _selectedFormulario = value;
                                      });
                                    },
                                  ),
                            if (_formulariosProgramaExcelencia.isEmpty && !_isLoadingFormularios)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'No hay formularios de programa de excelencia disponibles',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _selectedFormulario != null ? () => _navegarAEvaluacion() : null,
                                icon: const Icon(Icons.assignment),
                                label: Text(
                                  'Evaluar Desempeño',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDE1327),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _limpiarFiltros,
                      icon: const Icon(Icons.clear),
                      label: Text(
                        'Limpiar filtros',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sección de Evaluaciones Realizadas
          Container(
            height: 600, // Altura fija para el contenedor
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedRutaData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Seleccione los filtros para ver las evaluaciones',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Elija país, centro de distribución y ruta',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Evaluaciones Realizadas',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1C2120),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Líder: ${_selectedRutaData!['lider']['nombre']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF8F8E8E),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_selectedFormulario != null)
                                  ElevatedButton.icon(
                                    onPressed: () => _navegarAEvaluacion(),
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      'Nueva Evaluación',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDE1327),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDE1327).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_evaluacionesRealizadas.length} evaluaciones',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFDE1327),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Lista de evaluaciones o mensaje vacío
                        Expanded(
                          child: _evaluacionesRealizadas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay evaluaciones realizadas',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Las evaluaciones completadas aparecerán aquí',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      if (_selectedFormulario != null) ...[
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => _navegarAEvaluacion(),
                                          icon: const Icon(Icons.assignment),
                                          label: Text(
                                            'Realizar Primera Evaluación',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFDE1327),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _evaluacionesRealizadas.length,
                                  itemBuilder: (context, index) {
                                    return _buildEvaluacionCard(_evaluacionesRealizadas[index]);
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterDropdown(String label, String? value, List<Map<String, String>> items, Function(String?)? onChanged) {
    final isEnabled = onChanged != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isEnabled ? const Color(0xFF8F8E8E) : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
            color: isEnabled ? Colors.white : Colors.grey.shade50,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
            ),
            hint: Text(
              isEnabled ? 'Seleccionar' : 'Seleccione primero ${label == 'Centro de Distribución' ? 'un país' : 'un centro'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: isEnabled ? null : Colors.grey.shade400),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1C2120),
            ),
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item['id'],
                child: Text(item['nombre'] ?? ''),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8F8E8E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C2120),
          ),
        ),
      ],
    );
  }
  
  void _limpiarFiltros() {
    setState(() {
      _selectedPais = null;
      _selectedCentro = null;
      _selectedRuta = null;
      _selectedRutaData = null;
      _selectedFormulario = null;
      _centrosDisponibles = [];
      _rutasDisponibles = [];
      _formulariosProgramaExcelencia = [];
    });
  }
  
  Future<void> _cargarFormulariosProgramaExcelencia() async {
    setState(() => _isLoadingFormularios = true);
    
    try {
      // Obtener todos los formularios
      final formularios = await _formulariosApiService.obtenerFormularios();
      
      // Filtrar solo los de tipo programa_excelencia que estén activos
      _formulariosProgramaExcelencia = formularios.where((formulario) {
        final tipo = formulario['tipo']?.toString().toLowerCase();
        final activa = formulario['activa'] ?? false;
        return (tipo == 'programa_excelencia' || tipo == 'programa de excelencia') && activa;
      }).toList();
      
      print('📋 Formularios programa excelencia encontrados: ${_formulariosProgramaExcelencia.length}');
      
      setState(() => _isLoadingFormularios = false);
    } catch (e) {
      print('❌ Error al cargar formularios: $e');
      setState(() => _isLoadingFormularios = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar formularios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _aplicarFiltros() {
    // Aquí se implementaría la lógica para aplicar los filtros
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtros aplicados: País: ${_selectedPais ?? "Todos"}, Centro: ${_selectedCentro ?? "Todos"}, Ruta: ${_selectedRuta ?? "Todos"}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFDE1327),
      ),
    );
  }
  
  Widget _buildEvaluacionCard(Map<String, dynamic> evaluacion) {
    final fecha = evaluacion['fecha'] as DateTime;
    final puntuacion = evaluacion['puntuacion'] ?? 0;
    final puntuacionMaxima = evaluacion['puntuacionMaxima'] ?? 10;
    final porcentaje = puntuacionMaxima > 0 ? (puntuacion / puntuacionMaxima) * 100 : 0;
    final enviada = evaluacion['enviada'] ?? false;
    
    // Determinar color según puntuación
    Color colorPuntuacion;
    if (porcentaje >= 90) {
      colorPuntuacion = const Color(0xFF38A169);
    } else if (porcentaje >= 60) {
      colorPuntuacion = const Color(0xFFF6C343);
    } else {
      colorPuntuacion = const Color(0xFFE53E3E);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navegar a la pantalla de resumen
            final datosCompletos = evaluacion['datosCompletos'] as ResultadoExcelenciaHive?;
            if (datosCompletos != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaResumenEvaluacion(
                    evaluacion: datosCompletos,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al cargar los datos de la evaluación'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de puntuación
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorPuntuacion.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        puntuacion.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorPuntuacion,
                        ),
                      ),
                      Text(
                        '/$puntuacionMaxima',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información de la evaluación
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              evaluacion['formulario'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C2120),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (enviada)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38A169).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: const Color(0xFF38A169),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Enviada',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF38A169),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pending,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pendiente',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Evaluador: ${evaluacion['evaluador']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatearFechaCompleta(fecha),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Flecha de navegación
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatearFechaCompleta(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inDays == 0) {
      return 'Hoy ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
  
  void _navegarAEvaluacion() async {
    if (_selectedFormulario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un formulario de evaluación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final formularioSeleccionado = _formulariosProgramaExcelencia.firstWhere(
      (f) => f['id'] == _selectedFormulario,
    );
    
    // Agregar la información del formulario a rutaData para pasarla
    final rutaDataConFormulario = Map<String, dynamic>.from(_selectedRutaData!);
    rutaDataConFormulario['formularioId'] = _selectedFormulario;
    rutaDataConFormulario['formularioData'] = formularioSeleccionado;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEvaluacionDesempeno(
          liderData: _selectedRutaData!['lider'],
          rutaData: rutaDataConFormulario,
          pais: _paisesData.firstWhere((p) => p['id'] == _selectedPais)['nombre'],
          centroDistribucion: _centrosDisponibles.firstWhere((c) => c['id'] == _selectedCentro)['nombre'],
        ),
      ),
    );
    
    // Recargar evaluaciones al regresar
    _cargarEvaluacionesDesdeHive();
  }
}