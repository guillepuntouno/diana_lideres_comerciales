// lib/vistas/rutinas/pantalla_rutina_diaria.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/activity_model.dart';
import '../../servicios/plan_trabajo_offline_service.dart';
import '../../servicios/sesion_servicio.dart';
import '../../servicios/visita_cliente_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../modelos/visita_cliente_modelo.dart';
import '../../configuracion/ambiente_config.dart';
import '../../servicios/clientes_servicio.dart';
import '../../servicios/plan_trabajo_unificado_service.dart';
import '../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../../servicios/visita_cliente_unificado_service.dart';

// -----------------------------------------------------------------------------
// COLORES CORPORATIVOS DIANA
// -----------------------------------------------------------------------------
class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

// -----------------------------------------------------------------------------
// CLASE PARA OPCIONES DE PLAN
// -----------------------------------------------------------------------------
class PlanOpcion {
  final String planId;
  final int semana;
  final String etiqueta;
  final String estatus;
  final String fechaInicio;
  final String fechaFin;
  final String liderNombre;

  PlanOpcion({
    required this.planId,
    required this.semana,
    required this.etiqueta,
    required this.estatus,
    required this.fechaInicio,
    required this.fechaFin,
    required this.liderNombre,
  });

  factory PlanOpcion.fromJson(Map<String, dynamic> json) {
    // Extraer información básica
    String planId = json['PlanId'] ?? '';

    // Manejar número de semana de manera segura
    int semana = 0;
    if (json['Semana'] != null) {
      if (json['Semana'] is int) {
        semana = json['Semana'];
      } else if (json['Semana'] is String) {
        semana = int.tryParse(json['Semana']) ?? 0;
      }
    }

    // Intentar extraer datos del plan si existen
    String fechaInicio = '';
    String fechaFin = '';
    String liderNombre = '';
    String estatus = 'borrador';

    if (json['datos'] != null && json['datos']['semana'] != null) {
      var datosSemanales = json['datos']['semana'];
      fechaInicio = datosSemanales['fechaInicio'] ?? '';
      fechaFin = datosSemanales['fechaFin'] ?? '';
      liderNombre = datosSemanales['liderNombre'] ?? '';
      estatus = datosSemanales['estatus'] ?? 'borrador';
    }

    String etiqueta = 'Semana $semana';
    if (fechaInicio.isNotEmpty && fechaFin.isNotEmpty) {
      etiqueta = 'Semana $semana ($fechaInicio - $fechaFin)';
    }

    return PlanOpcion(
      planId: planId,
      semana: semana,
      etiqueta: etiqueta,
      estatus: estatus,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      liderNombre: liderNombre,
    );
  }

  @override
  String toString() => 'PlanOpcion(semana: $semana, estatus: $estatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanOpcion &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          semana == other.semana;

  @override
  int get hashCode => planId.hashCode ^ semana.hashCode;
}

// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL
// -----------------------------------------------------------------------------
class PantallaRutinaDiaria extends StatefulWidget {
  const PantallaRutinaDiaria({super.key});

  @override
  State<PantallaRutinaDiaria> createState() => _PantallaRutinaDiariaState();
}

class _PantallaRutinaDiariaState extends State<PantallaRutinaDiaria> {
  final PlanTrabajoOfflineService _planServicio = PlanTrabajoOfflineService();
  final VisitaClienteServicio _visitaServicio = VisitaClienteServicio();
  final ClientesServicio _clientesServicio = ClientesServicio();
  final PlanTrabajoUnificadoService _planUnificadoService =
      PlanTrabajoUnificadoService();
  final VisitaClienteUnificadoService _visitaUnificadoService =
      VisitaClienteUnificadoService();

  List<ActivityModel> _actividades = [];
  List<PlanOpcion> _planesDisponibles = [];
  PlanOpcion? _planSeleccionado;
  LiderComercial? _liderActual;
  PlanTrabajoUnificadoHive? _planUnificado;

  // Map para rastrear estados de visitas
  Map<String, VisitaClienteModelo> _visitasEstados = {};
  // Map para rastrear visitas del plan unificado
  Map<String, VisitaClienteUnificadaHive> _visitasUnificadas = {};

  // Para manejo de clientes y filtrado
  List<Map<String, dynamic>> _todosLosClientes = [];
  List<Map<String, dynamic>> _clientesFiltrados = [];
  List<String> _clientesFoco = []; // IDs de clientes FOCO del plan
  List<Map<String, dynamic>> _clientesAsignadosFoco =
      []; // Clientes FOCO del plan
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _clientesAdicionalescargados = false;

  // Variables para ruta
  String? _rutaSeleccionada;
  List<String> _rutasDisponibles = [];

  bool _isLoading = true;
  bool _cargandoPlanes = false;
  bool _cargandoDetalle = false;
  bool _cargandoClientes = false;
  bool _offline = false;

  String _diaActual = '';
  String _semanaActual = '';
  String _fechaFormateada = '';

  // Variables para simulación de día (solo en desarrollo/QA)
  String? _diaSimulado;
  final List<String> _diasDisponibles = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // ScrollController para el scroll principal
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inicializarRutina();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializarRutina() async {
    try {
      print('🔄 Iniciando rutina diaria...');
      setState(() => _isLoading = true);

      _liderActual = await SesionServicio.obtenerLiderComercial();

      if (_liderActual == null) {
        throw Exception(
          'No hay sesión activa. Por favor, inicie sesión nuevamente.',
        );
      }

      print(
        '👤 Líder obtenido: ${_liderActual!.nombre} (${_liderActual!.clave})',
      );

      DateTime ahora = DateTime.now();
      _configurarFechaActual(ahora);

      await _cargarPlanesDisponibles();

      setState(() => _isLoading = false);
      print('✅ Rutina inicializada correctamente');
    } catch (e, stackTrace) {
      print('❌ Error en _inicializarRutina: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar rutina: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _configurarFechaActual(DateTime fecha) {
    List<String> diasSemana = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    _diaActual = diasSemana[fecha.weekday - 1];

    int numeroSemana =
        ((fecha.difference(DateTime(fecha.year, 1, 1)).inDays +
                    DateTime(fecha.year, 1, 1).weekday -
                    1) /
                7)
            .ceil();
    _semanaActual = 'SEMANA $numeroSemana - ${fecha.year}';

    List<String> meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    String dia = fecha.day.toString();
    String mes = meses[fecha.month - 1];
    String anio = fecha.year.toString();

    _fechaFormateada = '$_diaActual, $dia de $mes de $anio';
  }

  Future<void> _cargarPlanesDisponibles() async {
    if (_liderActual == null) return;

    setState(() => _cargandoPlanes = true);

    try {
      print(
        '🔍 Cargando planes disponibles para líder: ${_liderActual!.clave}',
      );

      await _planServicio.initialize();

      final repositorio = _planServicio.getPlanRepository();
      final planesDelLider = repositorio.obtenerPlanesPorLider(
        _liderActual!.clave,
      );

      print('📋 Planes obtenidos: ${planesDelLider.length}');

      List<PlanOpcion> opcionesPlan =
          planesDelLider.map((planHive) {
            int numeroSemana = planHive.numeroSemana ?? 0;

            return PlanOpcion(
              planId: planHive.id,
              semana: numeroSemana,
              etiqueta:
                  '${planHive.semana} (${planHive.fechaInicio} - ${planHive.fechaFin})',
              estatus: planHive.estatus,
              fechaInicio: planHive.fechaInicio,
              fechaFin: planHive.fechaFin,
              liderNombre: planHive.liderNombre,
            );
          }).toList();

      opcionesPlan.sort((a, b) => b.semana.compareTo(a.semana));

      setState(() {
        _planesDisponibles = opcionesPlan;
        _cargandoPlanes = false;
      });

      print('✅ ${_planesDisponibles.length} planes cargados exitosamente');

      _autoSeleccionarPlan();
    } catch (e) {
      print('❌ Error al cargar planes: $e');
      setState(() => _cargandoPlanes = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar planes: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _autoSeleccionarPlan() {
    if (_planesDisponibles.isEmpty) return;

    PlanOpcion? planEnviado =
        _planesDisponibles.where((plan) => plan.estatus == 'enviado').isNotEmpty
            ? _planesDisponibles
                .where((plan) => plan.estatus == 'enviado')
                .first
            : null;

    if (planEnviado != null) {
      setState(() => _planSeleccionado = planEnviado);
      print(
        '📌 Plan auto-seleccionado: Semana ${planEnviado.semana} (enviado)',
      );
      _cargarDetallePlan();
    } else {
      print(
        '⚠️ No hay planes con estatus "enviado", seleccionando el más reciente',
      );
      setState(() => _planSeleccionado = _planesDisponibles.first);
      _cargarDetallePlan();
    }
  }

  Future<void> _onPlanSeleccionado(PlanOpcion? nuevoPlan) async {
    if (nuevoPlan == null || nuevoPlan == _planSeleccionado) return;

    setState(() => _planSeleccionado = nuevoPlan);
    print('🎯 Plan seleccionado: Semana ${nuevoPlan.semana}');

    // Limpiar datos anteriores
    setState(() {
      _clientesAdicionalescargados = false;
      _todosLosClientes = [];
      _clientesFiltrados = [];
      _searchController.clear();
    });

    await _cargarDetallePlan();
  }

  Future<void> _cargarDetallePlan() async {
    if (_planSeleccionado == null || _liderActual == null) return;

    setState(() => _cargandoDetalle = true);

    try {
      print(
        '🔍 Cargando detalle del plan: Semana ${_planSeleccionado!.semana}',
      );

      final planModelo = await _planServicio.obtenerOCrearPlan(
        _planSeleccionado!.etiqueta.split(' (')[0],
        _liderActual!.clave,
        _liderActual!,
      );

      if (planModelo != null) {
        print('📄 Detalle del plan obtenido exitosamente');

        final Map<String, dynamic> detallePlan = {
          'datos': {
            'semana': <String, dynamic>{
              'fechaInicio': planModelo.fechaInicio,
              'fechaFin': planModelo.fechaFin,
              'liderNombre': planModelo.liderNombre,
              'estatus': planModelo.estatus,
            },
          },
        };

        planModelo.dias.forEach((nombreDia, diaModelo) {
          final semanaMap =
              detallePlan['datos']['semana'] as Map<String, dynamic>;
          semanaMap[nombreDia.toLowerCase()] = {
            'objetivo': diaModelo.objetivo,
            'tipo':
                diaModelo.objetivo == 'Gestión de cliente'
                    ? 'gestion_cliente'
                    : 'administrativo',
            'tipoActividad': diaModelo.tipoActividad,
            'comentario': diaModelo.comentario,
            'rutaNombre': diaModelo.rutaNombre,
            'clientesAsignados':
                diaModelo.clientesAsignados
                    .map(
                      (c) => {
                        'clienteId': c.clienteId,
                        'clienteNombre': c.clienteNombre,
                        'clienteDireccion': c.clienteDireccion,
                        'clienteTipo': c.clienteTipo,
                        'visitado': false,
                      },
                    )
                    .toList(),
          };
        });

        await _procesarDetallePlan(detallePlan);
        
        // Cargar el plan unificado después de procesar el detalle
        await _cargarPlanUnificado();
      } else {
        print('❌ No se encontró detalle para el plan seleccionado');
        setState(() => _actividades = []);
      }

      setState(() => _cargandoDetalle = false);
    } catch (e) {
      print('❌ Error al cargar detalle del plan: $e');
      setState(() => _cargandoDetalle = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalle del plan: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _procesarDetallePlan(Map<String, dynamic> detallePlan) async {
    try {
      print('🔄 Procesando detalle del plan...');
      List<ActivityModel> actividadesDelDia = [];
      _clientesAsignadosFoco = [];
      _clientesFoco = [];
      _rutasDisponibles = [];
      _rutaSeleccionada = null;

      if (detallePlan['datos'] != null &&
          detallePlan['datos']['semana'] != null) {
        var datosSemanales = detallePlan['datos']['semana'];

        String diaParaBuscar = _diaSimulado ?? _diaActual;
        print('📅 Buscando actividades para el día: $diaParaBuscar');

        String diaKey = diaParaBuscar.toLowerCase();

        // Extraer rutas disponibles
        for (var dia in datosSemanales.entries) {
          if (dia.value is Map<String, dynamic>) {
            var diaData = dia.value as Map<String, dynamic>;
            String? rutaNombre = diaData['rutaNombre'];
            if (rutaNombre != null &&
                rutaNombre.isNotEmpty &&
                !_rutasDisponibles.contains(rutaNombre)) {
              _rutasDisponibles.add(rutaNombre);
            }
          }
        }

        if (datosSemanales[diaKey] != null) {
          var diaData = datosSemanales[diaKey] as Map<String, dynamic>;

          print('📋 ✅ Datos encontrados para $_diaActual:');
          print('   └── Objetivo: ${diaData['objetivo']}');
          print('   └── Tipo: ${diaData['tipo']}');

          _rutaSeleccionada = diaData['rutaNombre'];

          String tipoActividad = diaData['tipo'] ?? '';

          if (tipoActividad == 'administrativo') {
            String titulo = diaData['objetivo'] ?? 'Actividad administrativa';
            String descripcion =
                diaData['tipoActividad'] ??
                diaData['comentario'] ??
                'Sin descripción';

            actividadesDelDia.add(
              ActivityModel(
                id: '${_diaActual}_admin',
                type: ActivityType.admin,
                title: titulo,
                direccion: descripcion,
              ),
            );

            print('➕ ✅ ACTIVIDAD ADMINISTRATIVA CREADA: $titulo');
          } else if (tipoActividad == 'gestion_cliente') {
            final clientesAsignados =
                diaData['clientesAsignados'] as List<dynamic>?;

            print('👥 Clientes asignados: ${clientesAsignados?.length ?? 0}');

            if (clientesAsignados != null && clientesAsignados.isNotEmpty) {
              // Guardar clientes FOCO y sus IDs
              _clientesAsignadosFoco =
                  clientesAsignados
                      .map((c) => Map<String, dynamic>.from(c))
                      .toList();

              _clientesFoco =
                  clientesAsignados
                      .map((c) => c['clienteId']?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toList();

              print('🌟 IDs de clientes FOCO: $_clientesFoco');

              // Crear actividades para clientes FOCO
              for (int i = 0; i < clientesAsignados.length; i++) {
                final cliente = clientesAsignados[i] as Map<String, dynamic>;

                String clienteNombre =
                    cliente['clienteNombre'] ?? 'Cliente sin nombre';
                String clienteDireccion =
                    cliente['clienteDireccion'] ?? 'Dirección no disponible';
                String clienteId = cliente['clienteId'] ?? 'ID_$i';
                String clienteTipo =
                    cliente['clienteTipo'] ?? 'No especificado';

                actividadesDelDia.add(
                  ActivityModel(
                    id: '${_diaActual}_cliente_$clienteId',
                    type: ActivityType.visita,
                    title: clienteNombre,
                    direccion: clienteDireccion,
                    cliente: clienteId,
                    asesor: '${diaData['rutaNombre']} ($clienteTipo)',
                    status:
                        cliente['visitado'] == true
                            ? ActivityStatus.completada
                            : ActivityStatus.pendiente,
                    metadata: {
                      'esFoco': true,
                      'planId': _planUnificado?.id,
                      'dia': _diaSimulado ?? _diaActual,
                    },
                  ),
                );

                print('➕ ✅ VISITA CREADA: $clienteNombre (FOCO)');
              }
            } else {
              actividadesDelDia.add(
                ActivityModel(
                  id: '${_diaActual}_gestion_sin_clientes',
                  type: ActivityType.admin,
                  title: diaData['objetivo'] ?? 'Gestión de clientes',
                  direccion: 'No hay clientes asignados',
                ),
              );
            }
          } else {
            actividadesDelDia.add(
              ActivityModel(
                id: '${_diaActual}_$tipoActividad',
                type: ActivityType.admin,
                title: diaData['objetivo'] ?? 'Actividad sin definir',
                direccion: 'Tipo: $tipoActividad',
              ),
            );
          }
        } else {
          print('❌ No hay datos para el día $_diaActual');
        }
      }

      await _cargarEstadoActividades(actividadesDelDia);
      await _verificarEstadosVisitas(actividadesDelDia);

      setState(() => _actividades = actividadesDelDia);

      print('🎉 Actividades procesadas: ${_actividades.length}');
      print('🚦 Rutas disponibles: $_rutasDisponibles');
      print('🌟 Clientes FOCO: ${_clientesFoco.length}');
    } catch (e, stackTrace) {
      print('❌ Error al procesar detalle del plan: $e');
      print('Stack trace: $stackTrace');

      setState(() => _actividades = []);
    }
  }

  Future<void> _verificarEstadosVisitas(List<ActivityModel> actividades) async {
    if (_liderActual == null) return;

    try {
      print('🔍 Verificando estados de visitas...');

      final actividadesVisita =
          actividades.where((a) => a.type == ActivityType.visita).toList();

      for (final actividad in actividadesVisita) {
        if (actividad.cliente != null) {
          final claveVisita = _visitaServicio.generarClaveVisita(
            liderClave: _liderActual!.clave,
            numeroSemana: _obtenerSemanaActual(),
            dia: _diaActual,
            clienteId: actividad.cliente!,
          );

          final visita = await _visitaServicio.obtenerVisita(claveVisita);

          if (visita != null) {
            _visitasEstados[actividad.id] = visita;

            if (visita.estaCompletada) {
              actividad.status = ActivityStatus.completada;
            } else if (visita.estaEnProceso) {
              actividad.status = ActivityStatus.enCurso;
            }

            print('✅ Estado de visita ${actividad.title}: ${visita.estatus}');
          }
        }
      }

      // Verificar también en el plan unificado
      await _verificarVisitasEnPlanUnificado(actividades);

      print('📊 Estados de visitas verificados');
    } catch (e) {
      print('⚠️ Error al verificar estados de visitas: $e');
    }
  }

  int _obtenerSemanaActual() {
    final ahora = DateTime.now();
    return ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                DateTime(ahora.year, 1, 1).weekday -
                1) /
            7)
        .ceil();
  }

  Future<void> _cargarPlanUnificado() async {
    if (_liderActual == null || _planSeleccionado == null) return;

    try {
      print('📋 Cargando plan unificado...');
      
      // Generar ID del plan unificado
      final planId = '${_liderActual!.clave}_SEM${_planSeleccionado!.semana}_${DateTime.now().year}';
      
      // Obtener el plan usando el repositorio
      final repository = _planUnificadoService.repository;
      _planUnificado = repository.obtenerPlan(planId);
      
      if (_planUnificado != null) {
        print('✅ Plan unificado cargado: ${_planUnificado!.id}');
      } else {
        print('⚠️ Plan unificado no encontrado');
      }
    } catch (e) {
      print('❌ Error al cargar plan unificado: $e');
    }
  }

  Future<void> _verificarVisitasEnPlanUnificado(List<ActivityModel> actividades) async {
    if (_planUnificado == null) return;

    try {
      print('🔍 Verificando visitas en plan unificado...');
      
      final diaParaBuscar = _diaSimulado ?? _diaActual;
      final diaPlan = _planUnificado!.dias[diaParaBuscar];
      
      if (diaPlan == null) {
        print('⚠️ No hay datos para el día $diaParaBuscar en el plan unificado');
        return;
      }

      for (final actividad in actividades) {
        if (actividad.type == ActivityType.visita && actividad.cliente != null) {
          // Buscar la visita en el plan unificado
          for (final visitaUnificada in diaPlan.clientes) {
            if (visitaUnificada.clienteId == actividad.cliente) {
              _visitasUnificadas[actividad.id] = visitaUnificada;
              
              // Actualizar metadata con información del plan unificado
              actividad.metadata = actividad.metadata ?? {};
              actividad.metadata!['visitaUnificada'] = true;
              actividad.metadata!['estatusUnificado'] = visitaUnificada.estatus;
              
              // Si la visita está completada en el plan unificado, actualizar estado
              if (visitaUnificada.estatus == 'completada' && 
                  actividad.status != ActivityStatus.completada) {
                actividad.status = ActivityStatus.completada;
                print('✅ Visita ${actividad.title} marcada como completada desde plan unificado');
              }
              
              break;
            }
          }
        }
      }
      
      print('📊 Verificación de plan unificado completada');
    } catch (e) {
      print('❌ Error al verificar visitas en plan unificado: $e');
    }
  }

  Future<void> _cargarEstadoActividades(List<ActivityModel> actividades) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? estadosJson = prefs.getString(
        'estados_actividades_${_diaActual}',
      );

      if (estadosJson != null) {
        Map<String, dynamic> estados = jsonDecode(estadosJson);

        for (var actividad in actividades) {
          if (estados.containsKey(actividad.id)) {
            final estadoData = estados[actividad.id];
            actividad.status = ActivityStatus.values.firstWhere(
              (e) => e.name == estadoData['status'],
            );
            if (estadoData['horaInicio'] != null) {
              actividad.horaInicio = DateTime.fromMillisecondsSinceEpoch(
                estadoData['horaInicio'],
              );
            }
            if (estadoData['horaFin'] != null) {
              actividad.horaFin = DateTime.fromMillisecondsSinceEpoch(
                estadoData['horaFin'],
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error al cargar estados: $e');
    }
  }

  Future<void> _guardarEstadoActividades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> estados = {};

      for (var actividad in _actividades) {
        estados[actividad.id] = actividad.toJson();
      }

      await prefs.setString(
        'estados_actividades_${_diaActual}',
        jsonEncode(estados),
      );
    } catch (e) {
      print('Error al guardar estados: $e');
    }
  }

  Future<void> _cambiarEstadoActividad(ActivityModel actividad) async {
    setState(() {
      switch (actividad.status) {
        case ActivityStatus.pendiente:
          actividad.status = ActivityStatus.enCurso;
          actividad.horaInicio = DateTime.now();
          break;
        case ActivityStatus.enCurso:
          actividad.status = ActivityStatus.completada;
          actividad.horaFin = DateTime.now();
          break;
        case ActivityStatus.completada:
          actividad.status = ActivityStatus.pendiente;
          actividad.horaInicio = null;
          actividad.horaFin = null;
          break;
        case ActivityStatus.postergada:
          actividad.status = ActivityStatus.pendiente;
          break;
      }
    });

    await _guardarEstadoActividades();
  }

  Future<void> _postergarActividad(ActivityModel actividad) async {
    setState(() {
      actividad.status = ActivityStatus.postergada;
      actividad.horaInicio = null;
      actividad.horaFin = null;
    });

    await _guardarEstadoActividades();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actividad "${actividad.title}" postergada'),
        backgroundColor: AppColors.dianaYellow,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int get _actividadesCompletadas =>
      _actividades.where((a) => a.status == ActivityStatus.completada).length;

  Future<void> _cargarClientesAdicionales() async {
    if (_liderActual == null || _rutaSeleccionada == null) return;

    setState(() {
      _cargandoClientes = true;
    });

    try {
      String diaParaBuscar = _diaSimulado ?? _diaActual;

      print('🔍 Cargando clientes adicionales...');
      print('   Día: $diaParaBuscar');
      print('   Líder: ${_liderActual!.clave}');
      print('   Ruta: $_rutaSeleccionada');

      final clientes = await _clientesServicio.obtenerClientesPorRuta(
        dia: diaParaBuscar,
        lider: _liderActual!.clave,
        ruta: _rutaSeleccionada!,
      );

      if (clientes != null && clientes.isNotEmpty) {
        // Filtrar clientes que NO son FOCO (no duplicar)
        final clientesNoFoco =
            clientes.where((cliente) {
              final clienteId = cliente['Cliente_ID']?.toString() ?? '';
              return !_clientesFoco.contains(clienteId);
            }).toList();

        print('📊 Clientes obtenidos: ${clientes.length}');
        print('📊 Clientes FOCO a excluir: ${_clientesFoco.length}');
        print('📊 Clientes adicionales (no FOCO): ${clientesNoFoco.length}');

        _todosLosClientes = clientesNoFoco;
        _ordenarYFiltrarClientes();

        setState(() {
          _cargandoClientes = false;
          _clientesAdicionalescargados = true;
        });

        // Agregar actividades para clientes adicionales
        await _agregarActividadesClientesAdicionales();
      } else {
        print('❌ No se obtuvieron clientes del endpoint');
        setState(() {
          _cargandoClientes = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron clientes adicionales'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al cargar clientes: $e');
      setState(() {
        _cargandoClientes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _agregarActividadesClientesAdicionales() async {
    List<ActivityModel> nuevasActividades = [];

    for (final cliente in _todosLosClientes) {
      final clienteId = cliente['Cliente_ID']?.toString() ?? '';
      final nombre = cliente['Negocio'] ?? 'Sin nombre';
      final direccion = cliente['Direccion'] ?? 'Dirección no disponible';
      final ruta = cliente['Ruta'] ?? '';
      final clasificacion = cliente['Clasificación'] ?? '';

      // Crear actividad para cliente adicional
      nuevasActividades.add(
        ActivityModel(
          id: '${_diaActual}_cliente_adicional_$clienteId',
          type: ActivityType.visita,
          title: nombre,
          direccion: direccion,
          cliente: clienteId,
          asesor: '$ruta ($clasificacion)',
          status: ActivityStatus.pendiente,
          metadata: {
            'esFoco': false,
            'clienteData': cliente,
            'planId': _planUnificado?.id,
            'dia': _diaSimulado ?? _diaActual,
          },
        ),
      );
    }

    if (nuevasActividades.isNotEmpty) {
      // Verificar estados de las nuevas actividades
      await _verificarEstadosVisitas(nuevasActividades);

      setState(() {
        _actividades.addAll(nuevasActividades);
      });

      print(
        '➕ ${nuevasActividades.length} actividades de clientes adicionales agregadas',
      );
    }
  }

  void _ordenarYFiltrarClientes() {
    List<Map<String, dynamic>> clientesFiltrados = _todosLosClientes;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      clientesFiltrados =
          _todosLosClientes.where((cliente) {
            final nombre = (cliente['Negocio'] ?? '').toLowerCase();
            final clienteId = (cliente['Cliente_ID'] ?? '').toLowerCase();
            return nombre.contains(query) || clienteId.contains(query);
          }).toList();
    }

    setState(() {
      _clientesFiltrados = clientesFiltrados;
    });

    print('📊 Clientes filtrados: ${_clientesFiltrados.length}');
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _ordenarYFiltrarClientes();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.dianaRed),
              const SizedBox(height: 16),
              Text(
                'Cargando rutina diaria...',
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

    final int total = _actividades.length;
    final double progreso = total == 0 ? 0.0 : _actividadesCompletadas / total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Agenda de Hoy',
          style: GoogleFonts.poppins(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _offline ? Icons.cloud_off : Icons.cloud_done,
              color: _offline ? Colors.orange : AppColors.dianaGreen,
            ),
            onPressed: _cargarPlanesDisponibles,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarPlanesDisponibles,
        color: AppColors.dianaRed,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_offline) const _OfflineBanner(),

              // SELECTOR DE PLAN
              _buildSelectorPlan(),

              // CONTROL DE SIMULACIÓN DE DÍA (Solo en desarrollo/QA)
              if (AmbienteConfig.esDevelopment || AmbienteConfig.esQA)
                _buildControlSimulacionDia(),

              // HEADER DEL DÍA
              _HeaderHoy(
                diaActual: _diaActual,
                fechaFormateada: _fechaFormateada,
                completadas: _actividadesCompletadas,
                total: total,
                progreso: progreso,
                planSeleccionado: _planSeleccionado,
                cargandoDetalle: _cargandoDetalle,
                diaSimulado: _diaSimulado,
              ),

              const SizedBox(height: 16),

              // SELECTOR DE RUTA (si hay actividades de visita)
              if (_actividades.any((a) => a.type == ActivityType.visita) &&
                  _rutasDisponibles.isNotEmpty)
                _buildSelectorRuta(),

              // CONTENIDO PRINCIPAL
              if (_cargandoDetalle)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 100),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.dianaRed),
                        SizedBox(height: 16),
                        Text('Cargando actividades del día...'),
                      ],
                    ),
                  ),
                )
              else if (total == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 100),
                  child: _EstadoVacio(planSeleccionado: _planSeleccionado),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CAMPO DE BÚSQUEDA (si hay clientes)
                      if (_actividades.any(
                        (a) => a.type == ActivityType.visita,
                      )) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar cliente por nombre o ID...',
                              hintStyle: GoogleFonts.poppins(
                                color: AppColors.mediumGray,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              icon: const Icon(
                                Icons.search,
                                color: AppColors.mediumGray,
                              ),
                              suffixIcon:
                                  _searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: AppColors.mediumGray,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged();
                                        },
                                      )
                                      : null,
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // TÍTULO DE SECCIÓN
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: AppColors.dianaRed,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Actividades del día',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // LISTA UNIFICADA DE ACTIVIDADES
                      ..._buildListaUnificada(),

                      // BOTÓN CARGAR MÁS CLIENTES
                      if (_rutaSeleccionada != null &&
                          !_clientesAdicionalescargados &&
                          _actividades.any(
                            (a) => a.type == ActivityType.visita,
                          ))
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: ElevatedButton.icon(
                              onPressed:
                                  _cargandoClientes
                                      ? null
                                      : _cargarClientesAdicionales,
                              icon:
                                  _cargandoClientes
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.white,
                                      ),
                              label: Text(
                                _cargandoClientes
                                    ? 'Cargando...'
                                    : 'Cargar más clientes',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dianaRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.dianaRed,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Rutinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildListaUnificada() {
    List<Widget> widgets = [];

    // Filtrar actividades según la búsqueda
    List<ActivityModel> actividadesFiltradas = _actividades;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      actividadesFiltradas =
          _actividades.where((actividad) {
            final titulo = actividad.title.toLowerCase();
            final clienteId = (actividad.cliente ?? '').toLowerCase();
            return titulo.contains(query) || clienteId.contains(query);
          }).toList();
    }

    // Mostrar actividades (incluye tanto administrativas como visitas)
    for (final actividad in actividadesFiltradas) {
      final visita = _visitasEstados[actividad.id];
      final visitaUnificada = _visitasUnificadas[actividad.id];
      final esFoco = actividad.metadata?['esFoco'] == true;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _ActivityTile(
            actividad: actividad,
            visita: visita,
            visitaUnificada: visitaUnificada,
            esFoco: esFoco,
            onToggle: () => _cambiarEstadoActividad(actividad),
            onPostpone: () => _postergarActividad(actividad),
            onRefreshStatus: () => _verificarEstadosVisitas([actividad]),
            onVisitar: () async {
              // Crear copia local para null safety
              final visitaUnif = visitaUnificada;
              
              // Si la visita está completada en el plan unificado, navegar en modo consulta
              if (visitaUnif != null && visitaUnif.estatus == 'completada') {
                await Navigator.pushNamed(
                  context,
                  '/resumen_visita',
                  arguments: {
                    'modoConsulta': true,
                    'planId': _planUnificado!.id,
                    'dia': _diaSimulado ?? _diaActual,
                    'clienteId': actividad.cliente,
                    'clienteNombre': actividad.title,
                    'visitaUnificada': visitaUnificada,
                  },
                );
              } else {
                // Modo normal de visita
                final resultado = await Navigator.pushNamed(
                  context,
                  '/visita_cliente',
                  arguments: actividad,
                );

                if (resultado == true) {
                  _cambiarEstadoActividad(actividad);
                  _verificarEstadosVisitas([actividad]);
                }
              }
            },
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildSelectorPlan() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
            children: [
              const Icon(Icons.assignment, color: AppColors.dianaRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Seleccionar Plan de Trabajo:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_cargandoPlanes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: AppColors.dianaRed),
              ),
            )
          else if (_planesDisponibles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'No hay planes disponibles',
                style: GoogleFonts.poppins(
                  color: AppColors.mediumGray,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PlanOpcion>(
                  value: _planSeleccionado,
                  isExpanded: true,
                  hint: Text(
                    'Seleccione un plan...',
                    style: GoogleFonts.poppins(color: AppColors.mediumGray),
                  ),
                  items:
                      _planesDisponibles.map((plan) {
                        return DropdownMenuItem<PlanOpcion>(
                          value: plan,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                plan.etiqueta,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (plan.estatus.isNotEmpty)
                                Text(
                                  'Estado: ${plan.estatus.toUpperCase()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color:
                                        plan.estatus == 'enviado'
                                            ? AppColors.dianaGreen
                                            : AppColors.mediumGray,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: _onPlanSeleccionado,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlSimulacionDia() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
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
            children: [
              Icon(Icons.bug_report, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Simulación de Día (${AmbienteConfig.nombreAmbiente}):',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _diaSimulado,
                isExpanded: true,
                hint: Text(
                  'Día actual: $_diaActual (click para cambiar)',
                  style: GoogleFonts.poppins(
                    color: Colors.amber.shade700,
                    fontSize: 13,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Usar día actual ($_diaActual)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ..._diasDisponibles.map((dia) {
                    return DropdownMenuItem<String?>(
                      value: dia,
                      child: Row(
                        children: [
                          Text(
                            dia,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  dia == _diaActual
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          if (dia == _diaActual) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'HOY',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (nuevoValor) {
                  setState(() {
                    _diaSimulado = nuevoValor;
                    _clientesAdicionalescargados = false;
                    _todosLosClientes = [];
                    _clientesFiltrados = [];
                  });
                  _cargarDetallePlan();
                },
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '⚠️ Este control solo está visible en modo ${AmbienteConfig.nombreAmbiente}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.amber.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorRuta() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
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
            children: [
              const Icon(Icons.route, color: AppColors.dianaRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ruta disponible:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _rutaSeleccionada,
                isExpanded: true,
                hint: Text(
                  'Seleccione una ruta...',
                  style: GoogleFonts.poppins(color: AppColors.mediumGray),
                ),
                items:
                    _rutasDisponibles.map((ruta) {
                      return DropdownMenuItem<String>(
                        value: ruta,
                        child: Text(
                          ruta,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (nuevaRuta) {
                  setState(() {
                    _rutaSeleccionada = nuevaRuta;
                    _clientesAdicionalescargados = false;
                    _todosLosClientes = [];
                    _clientesFiltrados = [];
                    _searchController.clear();
                  });
                },
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGETS HELPER

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.all(8),
      child: Text(
        'Trabajando sin conexión – los cambios se enviarán al recuperar señal',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HeaderHoy extends StatelessWidget {
  final String diaActual;
  final String fechaFormateada;
  final int completadas;
  final int total;
  final double progreso;
  final PlanOpcion? planSeleccionado;
  final bool cargandoDetalle;
  final String? diaSimulado;

  const _HeaderHoy({
    required this.diaActual,
    required this.fechaFormateada,
    required this.completadas,
    required this.total,
    required this.progreso,
    this.planSeleccionado,
    required this.cargandoDetalle,
    this.diaSimulado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        diaSimulado != null
                            ? 'Simulando · $diaSimulado'
                            : 'Hoy · $diaActual',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      if (diaSimulado != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DEV',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    diaSimulado != null
                        ? 'Día real: $diaActual - $fechaFormateada'
                        : fechaFormateada,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
              if (cargandoDetalle)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.dianaRed,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),

          if (planSeleccionado != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    planSeleccionado!.estatus == 'enviado'
                        ? AppColors.dianaGreen.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Plan: Semana ${planSeleccionado!.semana} (${planSeleccionado!.estatus.toUpperCase()})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      planSeleccionado!.estatus == 'enviado'
                          ? AppColors.dianaGreen
                          : Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: Colors.grey.shade300,
            color: AppColors.dianaRed,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$completadas de $total actividades completadas',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ACTIVITY TILE MODIFICADO
class _ActivityTile extends StatelessWidget {
  final ActivityModel actividad;
  final VisitaClienteModelo? visita;
  final VisitaClienteUnificadaHive? visitaUnificada;
  final bool esFoco;
  final VoidCallback onToggle;
  final VoidCallback onPostpone;
  final VoidCallback onRefreshStatus;
  final VoidCallback? onVisitar;

  const _ActivityTile({
    required this.actividad,
    this.visita,
    this.visitaUnificada,
    required this.esFoco,
    required this.onToggle,
    required this.onPostpone,
    required this.onRefreshStatus,
    this.onVisitar,
  });

  @override
  Widget build(BuildContext context) {
    IconData leadingIcon;
    Color leadingColor;

    switch (actividad.type) {
      case ActivityType.admin:
        leadingIcon = Icons.description_outlined;
        leadingColor = AppColors.dianaRed;
        break;
      case ActivityType.visita:
        leadingIcon = Icons.storefront_outlined;
        leadingColor = AppColors.dianaRed;
        break;
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool esVisitaCompletada = false;

    // Crear copia local para null safety
    final visitaUnif = visitaUnificada;
    
    // Priorizar el estado del plan unificado
    if (visitaUnif != null && visitaUnif.estatus == 'completada') {
      statusColor = AppColors.dianaGreen;
      statusIcon = Icons.check_circle;
      statusText = 'Completada';
      esVisitaCompletada = true;
    } else if (visita != null) {
      if (visita!.estaCompletada) {
        statusColor = AppColors.dianaGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Completada';
        esVisitaCompletada = true;
      } else if (visita!.estaEnProceso) {
        statusColor = AppColors.dianaYellow;
        statusIcon = Icons.timelapse;
        statusText = 'En curso';
      } else {
        statusColor = Colors.grey.shade400;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Pendiente';
      }
    } else {
      switch (actividad.status) {
        case ActivityStatus.completada:
          statusColor = AppColors.dianaGreen;
          statusIcon = Icons.check_circle;
          statusText = 'Completada';
          esVisitaCompletada = true;
          break;
        case ActivityStatus.enCurso:
          statusColor = AppColors.dianaYellow;
          statusIcon = Icons.timelapse;
          statusText = 'En curso';
          break;
        case ActivityStatus.postergada:
          statusColor = Colors.grey;
          statusIcon = Icons.schedule;
          statusText = 'Postergada';
          break;
        default:
          statusColor = Colors.grey.shade400;
          statusIcon = Icons.radio_button_unchecked;
          statusText = 'Pendiente';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            esFoco && actividad.type == ActivityType.visita
                ? Border.all(
                  color: AppColors.dianaGreen.withOpacity(0.5),
                  width: 2,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color:
                esFoco && actividad.type == ActivityType.visita
                    ? AppColors.dianaGreen.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: actividad.type == ActivityType.admin ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono principal con indicador FOCO
                if (esFoco && actividad.type == ActivityType.visita)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.dianaGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: AppColors.dianaGreen,
                      size: 28,
                    ),
                  )
                else
                  Icon(leadingIcon, color: leadingColor, size: 24),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              actividad.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ),
                          if (esFoco &&
                              actividad.type == ActivityType.visita) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.dianaGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'FOCO',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (actividad.cliente != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${actividad.cliente}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                      if (actividad.asesor != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Ruta: ${actividad.asesor}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                      if (actividad.direccion != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                actividad.direccion!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.mediumGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            statusText,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (actividad.type == ActivityType.visita) ...[
                            const SizedBox(width: 8),
                            Icon(
                              visita != null
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              size: 12,
                              color:
                                  visita != null
                                      ? AppColors.dianaGreen
                                      : AppColors.mediumGray,
                            ),
                          ],
                          if (visitaUnif != null) ...[  
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: visitaUnif.cuestionario != null 
                                    ? AppColors.dianaGreen.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    visitaUnif.cuestionario != null
                                        ? Icons.assignment_turned_in
                                        : Icons.assignment_outlined,
                                    size: 12,
                                    color: visitaUnif.cuestionario != null
                                        ? AppColors.dianaGreen
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    visitaUnif.cuestionario != null
                                        ? 'Formulario completado'
                                        : 'Sin formulario',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: visitaUnif.cuestionario != null
                                          ? AppColors.dianaGreen
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Botón de visita SOLO para actividades de tipo visita
                if (actividad.type == ActivityType.visita &&
                    onVisitar != null) ...[
                  IconButton(
                    onPressed: onVisitar,
                    icon: Icon(
                      esVisitaCompletada
                          ? Icons.visibility
                          : Icons.assignment_outlined,
                      color:
                          esVisitaCompletada
                              ? AppColors.dianaGreen
                              : AppColors.dianaRed,
                    ),
                    tooltip:
                        esVisitaCompletada
                            ? 'Ver Detalle de Visita'
                            : 'Iniciar Visita',
                  ),
                  const SizedBox(width: 8),
                ],

                // Botón postergar
                if (actividad.status == ActivityStatus.enCurso ||
                    actividad.status == ActivityStatus.pendiente)
                  IconButton(
                    onPressed: onPostpone,
                    icon: const Icon(
                      Icons.schedule,
                      color: AppColors.mediumGray,
                    ),
                    tooltip: 'Postergar',
                  ),

                const SizedBox(width: 8),

                // Icono de estado (solo para actividades administrativas)
                if (actividad.type == ActivityType.admin)
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  )
                else
                  Icon(statusIcon, color: statusColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final PlanOpcion? planSeleccionado;

  const _EstadoVacio({this.planSeleccionado});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            planSeleccionado == null
                ? 'Seleccione un plan de trabajo'
                : 'No hay actividades programadas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            planSeleccionado == null
                ? 'para ver las actividades del día'
                : 'para el día de hoy en este plan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          if (planSeleccionado == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/plan_configuracion');
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text(
                'Crear Plan de Trabajo',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
