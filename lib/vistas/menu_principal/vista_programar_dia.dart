import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:diacritic/diacritic.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';
import '../../servicios/plan_trabajo_offline_service.dart';
import '../../modelos/hive/cliente_hive.dart';
import '../../modelos/hive/objetivo_hive.dart';
import '../../servicios/catalogo_dias_service.dart';
import '../../servicios/rutas_servicio.dart';

class VistaProgramarDia extends StatefulWidget {
  const VistaProgramarDia({super.key});

  @override
  State<VistaProgramarDia> createState() => _VistaProgramarDiaState();
}

class _VistaProgramarDiaState extends State<VistaProgramarDia> {
  final _formKey = GlobalKey<FormState>();
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  final PlanTrabajoOfflineService _planOfflineService = PlanTrabajoOfflineService();
  final RutasServicio _rutasServicio = RutasServicio();

  // Variables de estado
  late String diaSeleccionado;
  late String semana;
  late String liderId;
  late DateTime _fechaReal;
  Map<String, String>? _catDia; // mapa resuelto
  String? _codigoDiaVisita; // clave que va al backend
  bool esEdicion = false; // Nuevo: detectar si es edición
  String? _tipoObjetivoExistente; // Para rastrear el tipo de objetivo ya guardado
  bool _cargandoRutas = false; // Estado de carga de rutas

  String? _objetivoSeleccionado;
  String? _rutaSeleccionada;
  List<String> _objetivosAbordajeSeleccionados = []; // Lista para múltiples objetivos
  String? _comentarioAdicional; // Campo de comentario opcional
  String? _objetivoAbordajeSeleccionado; // Mantener para compatibilidad
  String? _tipoActividadAdministrativa;

  // Datos del líder (precargados)
  LiderComercial? _liderComercial;
  String _centroDistribucionInterno = ''; // Oculto pero capturado
  List<Ruta> _rutasDisponibles = [];

  // Listas de opciones
  final List<String> _objetivos = [
    'Gestión de cliente',
    'Actividad administrativa',
  ];

  final List<String> _tiposActividad = [
    'Día festivo',
    'Vacaciones',
    'Capacitaciones',
    'Entrevistas',
  ];

  final List<String> _objetivosAbordaje = [
    'Asesor nuevo ingreso',
    'Ruta abajo de PE',
    'Ticket de compra',
    'Censo de clientes',
    'Visitas efectivas',
    'Efectividad de la visita',
    'Cumplimiento al plan',
    'Promedio de visitas planeadas',
  ];


  @override
  void initState() {
    super.initState();
  }

  bool _datosInicializados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Solo cargar datos la primera vez
    if (!_datosInicializados) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      diaSeleccionado = args['dia'] as String;
      semana = args['semana'] as String;
      liderId = args['liderId'] as String;
      _fechaReal = args['fecha'] ?? _calcularFechaParaDia(diaSeleccionado, semana);
      esEdicion = args['esEdicion'] ?? false; // Detectar si es edición

      print('🚀 Inicializando VistaProgramarDia');
      print('  - Día: $diaSeleccionado');
      print('  - Fecha: $_fechaReal');
      print('  - Semana: $semana');

      _datosInicializados = true;
      
      // Cargar catálogo del día después de tener la fecha
      _cargarCatalogoDelDia();
      _inicializarDatos();
    }
  }

  Future<void> _inicializarDatos() async {
    // Cargar datos del líder comercial desde sesión
    await _cargarDatosLider();

    // Cargar datos existentes si los hay
    await _cargarDatosExistentes();
  }

  Future<void> _cargarCatalogoDelDia() async {
    try {
      print('🔍 Cargando catálogo para fecha: $_fechaReal');
      print('📅 Día seleccionado: $diaSeleccionado');
      
      final box = await CatalogoDiasService.openBox();
      print('📦 Caja abierta con ${box.values.length} registros');
      
      // Buscar por el día que ya tenemos en español
      final Map? registro = box.values.firstWhere(
        (e) => _normaliza(e['dia']) == _normaliza(diaSeleccionado),
        orElse: () => null,
      );
      
      if (registro == null) {
        print('⚠️ No se encontró registro para el día: $diaSeleccionado');
        print('📋 Días disponibles en la caja:');
        for (var item in box.values) {
          print('  - ${item['dia']} (normalizado: ${_normaliza(item['dia'])})');
        }
        throw Exception('Día no encontrado en el catálogo');
      }
      
      print('✅ Registro encontrado: $registro');

      // Calcular número de semana ISO usando DateTime
      final int numeroSemana = _calcularNumeroSemanaISO(_fechaReal);
      print('🗓️ Número de semana ISO: $numeroSemana (${numeroSemana.isEven ? "par" : "impar"})');
      
      final String sufijo = numeroSemana.isEven ? '03' : '02';
      print('🔢 Sufijo seleccionado: $sufijo');

      setState(() {
        _catDia = {
          'clave01': registro['codes']['01'],
          'texto01': registro['desc']['01'],
          'clave02': registro['codes']['02'],
          'texto02': registro['desc']['02'],
          'clave03': registro['codes']['03'],
          'texto03': registro['desc']['03'],
          'inicial': registro['codes'][sufijo],
        };
        _codigoDiaVisita = _catDia!['inicial'];
        print('✅ Catálogo cargado. Código inicial: $_codigoDiaVisita');
      });
    } catch (e) {
      print('❌ Error al cargar catálogo del día: $e');
      print('Stack trace: ${StackTrace.current}');
      // En caso de error, usar valores por defecto basados en el día actual
      final String diaActual = diaSeleccionado;
      String inicial;
      
      // Manejar las iniciales especiales
      switch (diaActual.toLowerCase()) {
        case 'lunes':
          inicial = 'L';
          break;
        case 'martes':
          inicial = 'M';
          break;
        case 'miércoles':
        case 'miercoles':
          inicial = 'W';  // Miércoles usa W
          break;
        case 'jueves':
          inicial = 'J';
          break;
        case 'viernes':
          inicial = 'V';
          break;
        case 'sábado':
        case 'sabado':
          inicial = 'S';
          break;
        case 'domingo':
          inicial = 'D';
          break;
        default:
          inicial = diaActual.substring(0, 1).toUpperCase();
      }
      
      // Calcular si la semana es par o impar para el sufijo por defecto
      final int numeroSemana = _calcularNumeroSemanaISO(_fechaReal);
      final String sufijo = numeroSemana.isEven ? '03' : '02';
      
      setState(() {
        _catDia = {
          'clave01': '${inicial}01',
          'texto01': '$diaActual (Semanal)',
          'clave02': '${inicial}02',
          'texto02': '$diaActual (Quincenal 1)',
          'clave03': '${inicial}03',
          'texto03': '$diaActual (Quincenal 2)',
          'inicial': '${inicial}$sufijo',
        };
        _codigoDiaVisita = _catDia!['inicial'];
      });
    }
  }

  int _calcularNumeroSemanaISO(DateTime fecha) {
    // Calcular el número de semana ISO 8601
    // Ajustar al jueves de la semana
    int diasHastaJueves = DateTime.thursday - fecha.weekday;
    DateTime jueves = fecha.add(Duration(days: diasHastaJueves));
    
    // Primer jueves del año
    DateTime primerEnero = DateTime(jueves.year, 1, 1);
    int diasHastaPrimerJueves = DateTime.thursday - primerEnero.weekday;
    DateTime primerJueves = primerEnero.add(Duration(days: diasHastaPrimerJueves));
    
    // Si el primer jueves es después del 4 de enero, pertenece a la semana anterior
    if (primerJueves.day > 4) {
      primerJueves = primerJueves.subtract(Duration(days: 7));
    }
    
    // Calcular diferencia en días y convertir a semanas
    int diferenciaDias = jueves.difference(primerJueves).inDays;
    return (diferenciaDias / 7).floor() + 1;
  }

  String _normaliza(String s) => removeDiacritics(s.toLowerCase());

  Future<void> _cargarDatosLider() async {
    try {
      _liderComercial = await SesionServicio.obtenerLiderComercial();

      if (_liderComercial != null) {
        setState(() {
          _centroDistribucionInterno = _liderComercial!.centroDistribucion;
          // Ya no cargamos las rutas aquí, se cargarán dinámicamente según el día
        });

        print('Datos del líder cargados:');
        print('Centro: $_centroDistribucionInterno');
        print('Código líder: ${_liderComercial!.clave}');
      }
    } catch (e) {
      print('Error al cargar datos del líder: $e');

      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del líder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarRutasDelDia() async {
    if (_liderComercial == null || _codigoDiaVisita == null) {
      print('⚠️ No se puede cargar rutas sin líder o código de día');
      return;
    }

    setState(() {
      _cargandoRutas = true;
      _rutasDisponibles = [];
      _rutaSeleccionada = null;
    });

    try {
      print('🔄 Cargando rutas para código líder: ${_liderComercial!.clave}, día: $_codigoDiaVisita');
      
      final rutas = await _rutasServicio.obtenerRutasPorDia(
        _liderComercial!.clave,
        _codigoDiaVisita!,
      );

      setState(() {
        _rutasDisponibles = rutas;
        _cargandoRutas = false;
        
        // AUTO-SELECCIONAR RUTA SI SOLO HAY UNA DISPONIBLE
        if (_rutasDisponibles.length == 1 && _rutaSeleccionada == null) {
          _rutaSeleccionada = _rutasDisponibles.first.nombre;
          print('Auto-seleccionando única ruta disponible: $_rutaSeleccionada');
        }
      });

      print('✅ Rutas cargadas: ${_rutasDisponibles.length}');
      _rutasDisponibles.forEach((ruta) {
        print('  - ${ruta.nombre} (Asesor: ${ruta.asesor})');
      });
    } catch (e) {
      print('❌ Error al cargar rutas: $e');
      
      setState(() {
        _cargandoRutas = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar rutas del día: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarDatosExistentes() async {
    try {
      final plan = await _planServicio.obtenerPlanTrabajo(semana, liderId);
      if (plan != null && plan.dias.containsKey(diaSeleccionado)) {
        final diaData = plan.dias[diaSeleccionado]!;
        setState(() {
          // Rastrear el tipo de objetivo existente
          _tipoObjetivoExistente = diaData.objetivo;
          
          // Validar que el objetivo existe en la lista antes de asignarlo
          if (_objetivos.contains(diaData.objetivo)) {
            _objetivoSeleccionado = diaData.objetivo;
          }

          // Validar que la ruta existe en las rutas disponibles
          if (_rutasDisponibles.any((ruta) => ruta.nombre == diaData.rutaId)) {
            _rutaSeleccionada = diaData.rutaId;
          }

          // Validar que el tipo de actividad existe en la lista
          if (_tiposActividad.contains(diaData.tipoActividad)) {
            _tipoActividadAdministrativa = diaData.tipoActividad;
          }

          // Cargar código del día si existe (sobrescribir el calculado automáticamente)
          if (diaData.codigoDiaVisita != null && diaData.codigoDiaVisita!.isNotEmpty) {
            _codigoDiaVisita = diaData.codigoDiaVisita;
            print('📌 Código día existente cargado: $_codigoDiaVisita');
          }

          // Cargar datos del comentario que puede contener JSON con múltiples objetivos
          if (diaData.comentario != null) {
            try {
              // Intentar parsear como JSON
              final comentarioData = jsonDecode(diaData.comentario!);
              if (comentarioData is Map && comentarioData.containsKey('objetivos')) {
                _objetivosAbordajeSeleccionados = List<String>.from(comentarioData['objetivos']);
                _comentarioAdicional = comentarioData['comentario'];
              } else {
                // Si no es JSON, es un objetivo único (retrocompatibilidad)
                if (_objetivosAbordaje.contains(diaData.comentario)) {
                  _objetivosAbordajeSeleccionados = [diaData.comentario!];
                  _objetivoAbordajeSeleccionado = diaData.comentario;
                }
              }
            } catch (e) {
              // Si falla el parseo, es un objetivo único
              if (_objetivosAbordaje.contains(diaData.comentario)) {
                _objetivosAbordajeSeleccionados = [diaData.comentario!];
                _objetivoAbordajeSeleccionado = diaData.comentario;
              }
            }
          }
        });

        print('Datos existentes cargados para $diaSeleccionado');
        print('Objetivo: $_objetivoSeleccionado');
        print('Tipo objetivo existente: $_tipoObjetivoExistente');
        print('Ruta: $_rutaSeleccionada');
        print('Tipo actividad: $_tipoActividadAdministrativa');
        print('Objetivo abordaje: $_objetivoAbordajeSeleccionado');
        
        // Si hay objetivo de gestión de cliente, cargar las rutas del día
        if (_objetivoSeleccionado == 'Gestión de cliente' && _codigoDiaVisita != null) {
          await _cargarRutasDelDia();
        }
      }
    } catch (e) {
      print('Error al cargar datos existentes: $e');
    }
  }

  // Método auxiliar para calcular fechas de la semana
  (String, String) _calcularFechasSemana() {
    try {
      // Extraer el número de semana del string "SEMANA XX - YYYY"
      final partes = semana.split(' ');
      final numeroSemana = int.parse(partes[1]);
      final ano = int.parse(partes[3]);

      // Calcular el primer día del año
      final primerDiaAno = DateTime(ano, 1, 1);

      // Calcular cuántos días hay que sumar para llegar a la semana deseada
      final diasHastaSemana = (numeroSemana - 1) * 7;

      // Ajustar para que empiece en lunes
      final primerLunesAno = primerDiaAno.add(
        Duration(days: (8 - primerDiaAno.weekday) % 7),
      );

      // Calcular fecha de inicio y fin de la semana
      final fechaInicio = primerLunesAno.add(Duration(days: diasHastaSemana));
      final fechaFin = fechaInicio.add(Duration(days: 4)); // Lunes a Viernes

      final formato = DateFormat('dd/MM/yyyy');
      return (formato.format(fechaInicio), formato.format(fechaFin));
    } catch (e) {
      print('⚠️ Error al calcular fechas, usando fechas por defecto: $e');
      // Fallback: usar fecha actual
      final ahora = DateTime.now();
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final finSemana = inicioSemana.add(Duration(days: 4));

      final formato = DateFormat('dd/MM/yyyy');
      return (formato.format(inicioSemana), formato.format(finSemana));
    }
  }

  Future<void> _guardarConfiguracion() async {
    try {
      // Crear el modelo del día
      final diaTrabajo = DiaTrabajoModelo(
        dia: diaSeleccionado,
        objetivo: _objetivoSeleccionado,
        tipo:
            _objetivoSeleccionado == 'Gestión de cliente'
                ? 'gestion_cliente'
                : 'administrativo',
        centroDistribucion: _centroDistribucionInterno,
        rutaId: _rutaSeleccionada,
        rutaNombre:
            _rutaSeleccionada != null
                ? _rutasDisponibles
                    .firstWhere(
                      (ruta) => ruta.nombre == _rutaSeleccionada,
                      orElse:
                          () => Ruta(
                            asesor: '',
                            nombre: _rutaSeleccionada!,
                            negocios: [],
                          ),
                    )
                    .nombre
                : null,
        tipoActividad: _tipoActividadAdministrativa,
        comentario: _objetivosAbordajeSeleccionados.isNotEmpty
            ? jsonEncode({
                'objetivos': _objetivosAbordajeSeleccionados,
                'comentario': _comentarioAdicional ?? '',
              })
            : _comentarioAdicional,
        codigoDiaVisita: _codigoDiaVisita,
      );

      // Guardar usando el servicio offline
      await _planOfflineService.guardarConfiguracionDia(
        semana,
        liderId,
        diaTrabajo,
      );

      print('💾 Configuración guardada offline para $diaSeleccionado');
      print('   └── Tipo: ${diaTrabajo.tipo}');
      print('   └── Centro: $_centroDistribucionInterno');
      print('   └── Ruta: $_rutaSeleccionada');
      print('   └── Objetivo: $_objetivoSeleccionado');
    } catch (e) {
      print('❌ Error al guardar configuración: $e');
      rethrow;
    }
  }

  // Método para crear un plan de trabajo nuevo (integrado en la vista)
  Future<void> _crearPlanTrabajo(PlanTrabajoModelo plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener planes existentes
      const keyPlanes = 'planes_trabajo_local';
      final planesJson = prefs.getString(keyPlanes) ?? '{}';
      final Map<String, dynamic> todosLosPlanes = jsonDecode(planesJson);

      // Crear clave única para el plan
      final clavePlan = '${plan.liderId}_${plan.semana}';

      // Verificar que no exista ya
      if (todosLosPlanes.containsKey(clavePlan)) {
        throw Exception('Ya existe un plan para esta semana y líder');
      }

      // Agregar el nuevo plan
      todosLosPlanes[clavePlan] = plan.toJson();

      // Guardar en SharedPreferences
      await prefs.setString(keyPlanes, jsonEncode(todosLosPlanes));

      print('✅ Plan creado y guardado: $clavePlan');
      print('   └── Semana: ${plan.semana}');
      print('   └── Líder: ${plan.liderId}');
      print('   └── Días configurados: ${plan.dias.length}');
    } catch (e) {
      print('❌ Error al crear plan de trabajo: $e');
      throw Exception('Error al crear plan de trabajo: $e');
    }
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 1) {
      // Mostrar opción de cerrar sesión
      _mostrarOpcionesPerfil();
    }
  }
  
  void _mostrarOpcionesPerfil() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                Navigator.pop(context);
                await SesionServicio.cerrarSesion(context);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          esEdicion ? 'Editar Día' : 'Programar Día',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1C2120),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título con el día seleccionado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (esEdicion ? Colors.orange : const Color(0xFFFFBD59))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: esEdicion ? Colors.orange : const Color(0xFFFFBD59),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    esEdicion ? Icons.edit_calendar : Icons.calendar_today,
                    color: const Color(0xFFDE1327),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${esEdicion ? 'Editando' : 'Configurando'}: $diaSeleccionado',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C2120),
                          ),
                        ),
                        if (esEdicion)
                          Text(
                            'Modificando plan enviado',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulario principal
            Container(
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
                  // Objetivo
                  Text(
                    'Objetivo:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'SELECCIONE UN OBJETIVO',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFDE1327),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    value: _objetivoSeleccionado,
                    items:
                        _objetivos
                            .map(
                              (objetivo) => DropdownMenuItem(
                                value: objetivo,
                                child: Text(
                                  objetivo == 'Gestión de cliente' ? 'Abordaje de ruta' : objetivo,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _objetivoSeleccionado = value;
                        // Limpiar rutas al cambiar de objetivo
                        if (value != 'Gestión de cliente') {
                          _rutasDisponibles = [];
                          _rutaSeleccionada = null;
                        }
                      });
                      
                      // AJUSTE TEMPORAL - 2025-07-16 - Guillermo Martinez
                      // Revisión con Ricardo Medrano / Remi Aguilar
                      // AUTO-CARGA DE RUTAS: Cuando se selecciona 'Gestión de cliente', 
                      // automáticamente se cargan las rutas con el código día 01 (ya forzado)
                      // Para 'Actividad administrativa' no se ejecuta este flujo
                      if (value == 'Gestión de cliente' && _codigoDiaVisita != null) {
                        await _cargarRutasDelDia();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor seleccione un objetivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // AJUSTE TEMPORAL - 2025-07-16 - Guillermo Martinez
                  // Revisión con Ricardo Medrano / Remi Aguilar
                  // CAMPO DÍA ASIGNADO OCULTO: El campo existe pero no se muestra al usuario
                  // Se mantiene la lógica interna para no romper funcionalidad
                  // El valor se establece automáticamente con terminación 01
                  
                  // Widget oculto que mantiene la funcionalidad del campo día asignado
                  if (_catDia != null)
                    Visibility(
                      visible: false, // AJUSTE: Campo oculto
                      maintainState: true, // Mantener el estado interno
                      maintainAnimation: true,
                      maintainSize: false,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'SELECCIONE DÍA',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFDE1327),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        value: _codigoDiaVisita,
                        items: [
                          DropdownMenuItem(value: _catDia!['clave01'], child: Text(_catDia!['texto01']!)),
                          DropdownMenuItem(value: _catDia!['clave02'], child: Text(_catDia!['texto02']!)),
                          DropdownMenuItem(value: _catDia!['clave03'], child: Text(_catDia!['texto03']!)),
                        ],
                        onChanged: (v) async {
                          setState(() => _codigoDiaVisita = v);
                          
                          // Si hay objetivo de gestión de cliente seleccionado, recargar rutas
                          if (_objetivoSeleccionado == 'Gestión de cliente' && v != null) {
                            await _cargarRutasDelDia();
                          }
                        },
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                    ),

                  // Campos para Actividad administrativa
                  if (_objetivoSeleccionado == 'Actividad administrativa') ...[
                    const SizedBox(height: 20),
                    Text(
                      'Tipo de actividad:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'SELECCIONE TIPO DE ACTIVIDAD',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFDE1327),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      value: _tipoActividadAdministrativa,
                      items:
                          _tiposActividad
                              .map(
                                (tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(
                                    tipo,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoActividadAdministrativa = value;
                        });
                      },
                      validator: (value) {
                        if (_objetivoSeleccionado ==
                                'Actividad administrativa' &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor seleccione el tipo de actividad';
                        }
                        return null;
                      },
                    ),
                  ],

                  // Campos EXCLUSIVOS para Gestión de cliente
                  if (_objetivoSeleccionado == 'Gestión de cliente') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Ruta disponible:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C2120),
                          ),
                        ),
                        if (_rutasDisponibles.length == 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'AUTO',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_cargandoRutas)
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFDE1327),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText:
                              _rutasDisponibles.isEmpty
                                  ? 'NO HAY RUTAS PARA ESTE DÍA'
                                  : _rutasDisponibles.length == 1
                                  ? 'RUTA SELECCIONADA AUTOMÁTICAMENTE'
                                  : 'SELECCIONE UNA RUTA',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFDE1327),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      value: _rutaSeleccionada,
                      items:
                          _rutasDisponibles
                              .map(
                                (ruta) => DropdownMenuItem(
                                  value: ruta.nombre,
                                  child: Text(
                                    '${ruta.nombre} - ${ruta.asesor}',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _rutasDisponibles.isNotEmpty
                              ? (value) {
                                setState(() {
                                  _rutaSeleccionada = value;
                                });
                              }
                              : null,
                      validator: (value) {
                        if (_objetivoSeleccionado == 'Gestión de cliente' &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor seleccione una ruta';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Indicador de ruta:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Widget simplificado para selección múltiple
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _objetivosAbordajeSeleccionados.isEmpty
                                ? 'Seleccione uno o más indicadores:'
                                : '${_objetivosAbordajeSeleccionados.length} indicador(es) seleccionado(s):',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF1C2120),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._objetivosAbordaje.map((objetivo) {
                            final isSelected = _objetivosAbordajeSeleccionados.contains(objetivo);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _objetivosAbordajeSeleccionados.remove(objetivo);
                                  } else {
                                    _objetivosAbordajeSeleccionados.add(objetivo);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected 
                                              ? const Color(0xFFDE1327) 
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: isSelected 
                                            ? const Color(0xFFDE1327) 
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        objetivo,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF1C2120),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    if (_objetivosAbordajeSeleccionados.isEmpty && _objetivoSeleccionado == 'Gestión de cliente')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Por favor seleccione al menos un indicador de ruta',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Campo de comentario opcional
                    Text(
                      'Comentario (opcional):',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      onChanged: (value) {
                        _comentarioAdicional = value;
                      },
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Agregue comentarios adicionales si es necesario',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFDE1327),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],

                  // Mensaje informativo
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          (_objetivoSeleccionado == 'Actividad administrativa'
                                  ? Colors.blue
                                  : Colors.green)
                              .shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            (_objetivoSeleccionado == 'Actividad administrativa'
                                    ? Colors.blue
                                    : Colors.green)
                                .shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color:
                              (_objetivoSeleccionado ==
                                          'Actividad administrativa'
                                      ? Colors.blue
                                      : Colors.green)
                                  .shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _objetivoSeleccionado == 'Actividad administrativa'
                                ? 'Al presionar GUARDAR, se registrará esta actividad administrativa para el $diaSeleccionado'
                                : _objetivoSeleccionado == 'Gestión de cliente'
                                ? 'Al presionar SIGUIENTE, procederá a la asignación de clientes para la ruta seleccionada'
                                : 'Seleccione un objetivo para continuar',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color:
                                  _objetivoSeleccionado ==
                                          'Actividad administrativa'
                                      ? Colors.blue.shade700
                                      : _objetivoSeleccionado ==
                                          'Gestión de cliente'
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Información del centro (solo para debug, no visible al usuario)
                  if (_centroDistribucionInterno.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Centro: $_centroDistribucionInterno (capturado internamente)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDE1327)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'CANCELAR',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFDE1327),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Validación adicional para objetivos de abordaje
                        if (_objetivoSeleccionado == 'Gestión de cliente' && _objetivosAbordajeSeleccionados.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor seleccione al menos un indicador de ruta'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        try {
                          // Mostrar loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFDE1327),
                                  ),
                                ),
                          );

                          // Guardar la configuración básica
                          await _guardarConfiguracion();

                          // Cerrar loading
                          if (mounted) Navigator.of(context).pop();

                          if (_objetivoSeleccionado == 'Gestión de cliente') {
                            // Navegar a asignación de clientes
                            final resultado = await Navigator.pushNamed(
                              context,
                              '/asignacion_clientes',
                              arguments: {
                                'dia': diaSeleccionado,
                                'ruta': _rutaSeleccionada,
                                'centro': _centroDistribucionInterno,
                                'semana': semana,
                                'liderId': liderId,
                                'liderNombre': _liderComercial?.nombre ?? '', // Agregar nombre del líder
                                'esEdicion': esEdicion,
                                'codigoDiaVisita': _codigoDiaVisita, // Pasar código del día
                                'fecha': _fechaReal, // Pasar la fecha también
                              },
                            );

                            if (resultado == true && mounted) {
                              Navigator.pop(context, true);
                            }
                          } else if (_objetivoSeleccionado ==
                              'Actividad administrativa') {
                            // Mostrar confirmación
                            print('Actividad administrativa guardada para $diaSeleccionado');
                            
                            // Esperar un poco más para asegurar que Hive complete el guardado
                            await Future.delayed(Duration(milliseconds: 300));
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$diaSeleccionado configurado correctamente',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              
                              // Preguntar si desea agregar otro objetivo
                              final bool? agregarOtro = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Actividad guardada'),
                                    ],
                                  ),
                                  titleTextStyle: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C2120),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '¿Desea agregar otro objetivo para el día $diaSeleccionado?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.blue.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Puede agregar más actividades administrativas o cambiar a gestión de clientes',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(
                                        'No, finalizar',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFDE1327),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Sí, agregar otro objetivo',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (agregarOtro == true && mounted) {
                                // Limpiar campos para nuevo objetivo
                                setState(() {
                                  _objetivoSeleccionado = null;
                                  _tipoActividadAdministrativa = null;
                                  _rutaSeleccionada = null;
                                  _objetivosAbordajeSeleccionados.clear();
                                  _objetivoAbordajeSeleccionado = null;
                                  _comentarioAdicional = null;
                                });
                              } else if (mounted) {
                                Navigator.of(context).pop(true);
                              }
                            }
                          }
                        } catch (e) {
                          // Cerrar loading si está abierto
                          if (mounted) Navigator.of(context).pop();

                          // Mostrar error
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al guardar: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _objetivoSeleccionado == 'Actividad administrativa'
                          ? 'GUARDAR'
                          : 'SIGUIENTE',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onNavBarTap,
        selectedItemColor: const Color(0xFFDE1327),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  DateTime _calcularFechaParaDia(String dia, String semana) {
    try {
      // Extraer el año y número de semana del formato "SEMANA XX - YYYY"
      final partes = semana.split(' ');
      if (partes.length >= 4) {
        final numeroSemana = int.tryParse(partes[1]) ?? 1;
        final anio = int.tryParse(partes[3]) ?? DateTime.now().year;
        
        // Calcular el primer día del año
        final primerDiaDelAnio = DateTime(anio, 1, 1);
        
        // Encontrar el primer lunes del año
        var primerLunes = primerDiaDelAnio;
        while (primerLunes.weekday != DateTime.monday) {
          primerLunes = primerLunes.add(const Duration(days: 1));
        }
        
        // Calcular el lunes de la semana deseada
        final lunesDeSemana = primerLunes.add(Duration(days: (numeroSemana - 1) * 7));
        
        // Mapear el día a un número
        final diasSemana = {
          'Lunes': 0,
          'Martes': 1,
          'Miércoles': 2,
          'Jueves': 3,
          'Viernes': 4,
          'Sábado': 5,
          'Domingo': 6,
        };
        
        final offsetDia = diasSemana[dia] ?? 0;
        return lunesDeSemana.add(Duration(days: offsetDia));
      }
    } catch (e) {
      print('Error calculando fecha para día: $e');
    }
    
    // Si hay algún error, devolver la fecha actual
    return DateTime.now();
  }
}
