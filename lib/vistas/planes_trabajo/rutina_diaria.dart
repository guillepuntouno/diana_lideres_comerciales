// lib/vistas/rutinas/pantalla_rutina_diaria.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/activity_model.dart';
import '../../servicios/plan_trabajo_servicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../servicios/visita_cliente_servicio.dart'; // NUEVO IMPORT
import '../../modelos/lider_comercial_modelo.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../modelos/visita_cliente_modelo.dart'; // NUEVO IMPORT

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

// [Mantener todas las clases PlanOpcion y el resto del código igual...]

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
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  final VisitaClienteServicio _visitaServicio =
      VisitaClienteServicio(); // NUEVO SERVICIO

  List<ActivityModel> _actividades = [];
  List<PlanOpcion> _planesDisponibles = [];
  PlanOpcion? _planSeleccionado;
  LiderComercial? _liderActual;

  // NUEVO: Map para rastrear estados de visitas
  Map<String, VisitaClienteModelo> _visitasEstados = {};

  bool _isLoading = true;
  bool _cargandoPlanes = false;
  bool _cargandoDetalle = false;
  bool _offline = false;

  String _diaActual = '';
  String _semanaActual = '';
  String _fechaFormateada = '';

  @override
  void initState() {
    super.initState();
    _inicializarRutina();
  }

  // [Mantener todos los métodos existentes hasta _procesarDetallePlan...]

  Future<void> _inicializarRutina() async {
    try {
      print('🔄 Iniciando rutina diaria...');
      setState(() => _isLoading = true);

      // Obtener datos del líder desde la sesión
      _liderActual = await SesionServicio.obtenerLiderComercial();

      if (_liderActual == null) {
        throw Exception(
          'No hay sesión activa. Por favor, inicie sesión nuevamente.',
        );
      }

      print(
        '👤 Líder obtenido: ${_liderActual!.nombre} (${_liderActual!.clave})',
      );

      // Configurar fecha actual
      DateTime ahora = DateTime.now();
      _configurarFechaActual(ahora);

      // Cargar planes disponibles desde el servidor
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
    // Configurar día actual
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

    // Calcular número de semana
    int numeroSemana =
        ((fecha.difference(DateTime(fecha.year, 1, 1)).inDays +
                    DateTime(fecha.year, 1, 1).weekday -
                    1) /
                7)
            .ceil();
    _semanaActual = 'SEMANA $numeroSemana - ${fecha.year}';

    // Formatear fecha legible
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

      // Llamar al endpoint para obtener todos los planes del líder
      final planes = await _planServicio.obtenerTodosLosPlanes(
        _liderActual!.clave,
      );

      print('📋 Planes obtenidos: ${planes.length}');

      // Convertir a PlanOpcion y ordenar por semana (más reciente primero)
      List<PlanOpcion> opcionesPlan =
          planes.map((plan) {
            // Extraer número de semana del formato "SEMANA 24 - 2025"
            int numeroSemana = _extraerNumeroSemanaDePlan(plan.semana);

            // Generar planId basado en el patrón del servidor
            String planId = '${plan.liderId}_SEM$numeroSemana';

            return PlanOpcion(
              planId: planId,
              semana: numeroSemana,
              etiqueta:
                  '${plan.semana} (${plan.fechaInicio} - ${plan.fechaFin})',
              estatus: plan.estatus,
              fechaInicio: plan.fechaInicio,
              fechaFin: plan.fechaFin,
              liderNombre: plan.liderNombre,
            );
          }).toList();

      // Ordenar por semana descendente
      opcionesPlan.sort((a, b) => b.semana.compareTo(a.semana));

      setState(() {
        _planesDisponibles = opcionesPlan;
        _cargandoPlanes = false;
      });

      print('✅ ${_planesDisponibles.length} planes cargados exitosamente');

      // Auto-seleccionar el plan más reciente con estatus 'enviado'
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

  /// Método auxiliar para extraer número de semana de manera segura
  int _extraerNumeroSemanaDePlan(String semanaTexto) {
    try {
      // Formato esperado: "SEMANA 24 - 2025"
      final RegExp regex = RegExp(r'SEMANA (\d+) - (\d+)');
      final match = regex.firstMatch(semanaTexto);

      if (match != null) {
        return int.parse(match.group(1)!);
      }

      return 0; // Valor por defecto si no se puede extraer
    } catch (e) {
      print('Error al extraer número de semana de $semanaTexto: $e');
      return 0;
    }
  }

  void _autoSeleccionarPlan() {
    if (_planesDisponibles.isEmpty) return;

    // Buscar el plan más reciente con estatus 'enviado'
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

    await _cargarDetallePlan();
  }

  Future<void> _cargarDetallePlan() async {
    if (_planSeleccionado == null || _liderActual == null) return;

    setState(() => _cargandoDetalle = true);

    try {
      print(
        '🔍 Cargando detalle del plan: Semana ${_planSeleccionado!.semana}',
      );

      // Convertir el número de semana a int de manera segura
      int numeroSemana = _planSeleccionado!.semana;

      print(
        '📡 Llamando endpoint con: líder=${_liderActual!.clave}, semana=$numeroSemana',
      );

      // Llamar al endpoint de detalle del plan con int
      final response = await _planServicio.obtenerDetallePlan(
        _liderActual!.clave,
        numeroSemana,
      );

      if (response != null) {
        print('📄 Detalle del plan obtenido exitosamente');
        await _procesarDetallePlan(response);
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

      // Navegar hasta los datos de la semana
      if (detallePlan['datos'] != null &&
          detallePlan['datos']['semana'] != null) {
        var datosSemanales = detallePlan['datos']['semana'];

        print('📅 Buscando actividades para el día: $_diaActual');

        // Buscar el día actual (lunes, martes, etc.)
        String diaKey = _diaActual.toLowerCase();

        if (datosSemanales[diaKey] != null) {
          var diaData = datosSemanales[diaKey] as Map<String, dynamic>;

          print('📋 ✅ Datos encontrados para $_diaActual:');
          print('   └── Objetivo: ${diaData['objetivo']}');
          print('   └── Tipo: ${diaData['tipo']}');

          String tipoActividad = diaData['tipo'] ?? '';

          if (tipoActividad == 'administrativo') {
            // Actividad administrativa
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
            // Actividades de gestión de clientes
            final clientesAsignados =
                diaData['clientesAsignados'] as List<dynamic>?;

            print('👥 Clientes asignados: ${clientesAsignados?.length ?? 0}');

            if (clientesAsignados != null && clientesAsignados.isNotEmpty) {
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
                  ),
                );

                print('➕ ✅ VISITA CREADA: $clienteNombre');
              }
            } else {
              // Gestión sin clientes específicos
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
            // Tipo desconocido
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
          print('   └── Días disponibles: ${datosSemanales.keys.toList()}');
        }
      } else {
        print('❌ Estructura de datos del plan inválida');
      }

      // Cargar estados guardados
      await _cargarEstadoActividades(actividadesDelDia);

      // NUEVO: Verificar estados de visitas en API
      await _verificarEstadosVisitas(actividadesDelDia);

      setState(() => _actividades = actividadesDelDia);

      print('🎉 Actividades procesadas: ${_actividades.length}');
    } catch (e, stackTrace) {
      print('❌ Error al procesar detalle del plan: $e');
      print('Stack trace: $stackTrace');

      setState(() => _actividades = []);
    }
  }

  // NUEVO MÉTODO: Verificar estados de visitas
  Future<void> _verificarEstadosVisitas(List<ActivityModel> actividades) async {
    if (_liderActual == null) return;

    try {
      print('🔍 Verificando estados de visitas...');

      // Filtrar solo actividades de tipo visita
      final actividadesVisita =
          actividades.where((a) => a.type == ActivityType.visita).toList();

      for (final actividad in actividadesVisita) {
        if (actividad.cliente != null) {
          // Generar clave de visita
          final claveVisita = _visitaServicio.generarClaveVisita(
            liderClave: _liderActual!.clave,
            numeroSemana: _obtenerSemanaActual(),
            dia: _diaActual,
            clienteId: actividad.cliente!,
          );

          // Verificar si existe visita
          final visita = await _visitaServicio.obtenerVisita(claveVisita);

          if (visita != null) {
            _visitasEstados[actividad.id] = visita;

            // Actualizar estado de la actividad según el estado de la visita
            if (visita.estaCompletada) {
              actividad.status = ActivityStatus.completada;
            } else if (visita.estaEnProceso) {
              actividad.status = ActivityStatus.enCurso;
            }

            print('✅ Estado de visita ${actividad.title}: ${visita.estatus}');
          }
        }
      }

      print('📊 Estados de visitas verificados');
    } catch (e) {
      print('⚠️ Error al verificar estados de visitas: $e');
      // No bloquear la carga si falla la verificación
    }
  }

  // MÉTODO AUXILIAR: Obtener semana actual
  int _obtenerSemanaActual() {
    final ahora = DateTime.now();
    return ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                DateTime(ahora.year, 1, 1).weekday -
                1) /
            7)
        .ceil();
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
      body: Column(
        children: [
          if (_offline) const _OfflineBanner(),

          // SELECTOR DE PLAN
          _buildSelectorPlan(),

          // HEADER DEL DÍA
          _HeaderHoy(
            diaActual: _diaActual,
            fechaFormateada: _fechaFormateada,
            completadas: _actividadesCompletadas,
            total: total,
            progreso: progreso,
            planSeleccionado: _planSeleccionado,
            cargandoDetalle: _cargandoDetalle,
          ),

          const SizedBox(height: 16),

          // LISTA DE ACTIVIDADES
          Expanded(
            child:
                _cargandoDetalle
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.dianaRed),
                          SizedBox(height: 16),
                          Text('Cargando actividades del día...'),
                        ],
                      ),
                    )
                    : total == 0
                    ? _EstadoVacio(planSeleccionado: _planSeleccionado)
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final actividad = _actividades[index];
                        final visita = _visitasEstados[actividad.id]; // NUEVO
                        return _ActivityTile(
                          actividad: actividad,
                          visita: visita, // NUEVO PARÁMETRO
                          onToggle: () => _cambiarEstadoActividad(actividad),
                          onPostpone: () => _postergarActividad(actividad),
                          onRefreshStatus:
                              () => _verificarEstadosVisitas([
                                actividad,
                              ]), // NUEVO CALLBACK
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: total,
                    ),
          ),
        ],
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
}

// WIDGETS HELPER MODIFICADOS

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

  const _HeaderHoy({
    required this.diaActual,
    required this.fechaFormateada,
    required this.completadas,
    required this.total,
    required this.progreso,
    this.planSeleccionado,
    required this.cargandoDetalle,
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
                  Text(
                    'Hoy · $diaActual',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  Text(
                    fechaFormateada,
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

// ACTIVITY TILE MODIFICADO CON INTEGRACIÓN DE VISITAS
class _ActivityTile extends StatelessWidget {
  final ActivityModel actividad;
  final VisitaClienteModelo? visita; // NUEVO PARÁMETRO
  final VoidCallback onToggle;
  final VoidCallback onPostpone;
  final VoidCallback onRefreshStatus; // NUEVO CALLBACK

  const _ActivityTile({
    required this.actividad,
    this.visita, // NUEVO
    required this.onToggle,
    required this.onPostpone,
    required this.onRefreshStatus, // NUEVO
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

    // NUEVA LÓGICA: Priorizar estado de visita sobre estado local
    Color statusColor;
    IconData statusIcon;
    String statusText;

    // Si hay visita, usar su estado
    if (visita != null) {
      if (visita!.estaCompletada) {
        statusColor = AppColors.dianaGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Completada';
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
      // Usar estado local de la actividad
      switch (actividad.status) {
        case ActivityStatus.completada:
          statusColor = AppColors.dianaGreen;
          statusIcon = Icons.check_circle;
          statusText = 'Completada';
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                Icon(leadingIcon, color: leadingColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actividad.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      if (actividad.asesor != null) ...[
                        const SizedBox(height: 4),
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
                        Text(
                          actividad.direccion!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                          ),
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
                          // NUEVO: Indicador de sincronización para visitas
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
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Botón de visita SOLO para actividades de tipo visita
                if (actividad.type == ActivityType.visita) ...[
                  IconButton(
                    onPressed: () async {
                      final resultado = await Navigator.pushNamed(
                        context,
                        '/visita_cliente',
                        arguments:
                            actividad, // CAMBIO: Pasar ActivityModel directamente
                      );

                      // NUEVO: Si se completó la visita, actualizar estados
                      if (resultado == true) {
                        onToggle(); // Actualizar estado local
                        onRefreshStatus(); // Verificar estado en API
                      }
                    },
                    icon: Icon(
                      visita?.estaCompletada == true
                          ? Icons
                              .assignment_turned_in // Icono completado
                          : Icons.assignment_outlined, // Icono pendiente
                      color:
                          visita?.estaCompletada == true
                              ? AppColors.dianaGreen
                              : AppColors.dianaRed,
                    ),
                    tooltip:
                        visita?.estaCompletada == true
                            ? 'Ver Visita Completada'
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

                // Icono de estado
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
