// lib/vistas/menu_principal/vista_configuracion_plan.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:diana_lc_front/shared/modelos/plan_trabajo_modelo.dart';
import 'package:diana_lc_front/shared/modelos/indicador_gestion_modelo.dart';
import 'package:diana_lc_front/shared/servicios/plan_trabajo_servicio.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/indicadores_gestion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/servicios/plan_trabajo_offline_service.dart';
import 'package:diana_lc_front/widgets/connection_status_widget.dart';
import 'package:diana_lc_front/data/api/plan_api.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_semanal_hive.dart';
import 'package:hive/hive.dart';

class VistaProgramacionSemana extends StatefulWidget {
  const VistaProgramacionSemana({super.key});

  @override
  State<VistaProgramacionSemana> createState() =>
      _VistaProgramacionSemanaState();
}

class _VistaProgramacionSemanaState extends State<VistaProgramacionSemana>
    with WidgetsBindingObserver {
  final List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  final PlanTrabajoOfflineService _planOfflineService =
      PlanTrabajoOfflineService();
  final PlanApi _planApi = PlanApi();
  PlanTrabajoModelo? _planActual;
  LiderComercial? _liderActual;
  bool _cargando = true;
  int _currentIndex = 1;
  // bool _modoOffline = false;

  // Selector de semanas
  List<SemanaOpcion> _semanasDisponibles = [];
  String? _semanaSeleccionada;
  
  // Controlar expansión de días
  List<bool> _diasExpandidos = List.filled(6, false);
  
  // Para hacer sticky el selector
  final ScrollController _scrollController = ScrollController();
  
  // Control para evitar mostrar el diálogo múltiples veces
  bool _dialogoMostrado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeDateFormatting('es', null).then((_) {
      _inicializarVista();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refrescar cuando la app vuelve a primer plano
      print('App resumed - refrescando plan');
      _cargarPlanDesdeServidor(mostrarDialogo: false);
    }
  }

  Future<void> _inicializarVista() async {
    setState(() => _cargando = true);

    try {
      // Obtener datos del líder comercial desde la sesión
      _liderActual = await SesionServicio.obtenerLiderComercial();

      if (_liderActual == null) {
        throw Exception(
          'No hay sesión activa. Por favor, inicie sesión nuevamente.',
        );
      }

      // Generar semanas disponibles (actual + próximas 4)
      _generarSemanasDisponibles();

      // Seleccionar semana actual por defecto
      _semanaSeleccionada = _semanasDisponibles.first.codigo;

      // Crear plan local para la semana actual sin consultar servidor
      await _crearPlanLocalInicial();
    } catch (e) {
      print('Error al inicializar vista: $e');
      setState(() => _cargando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calcula el número de semana ISO 8601
  int _calcularNumeroSemanaISO(DateTime fecha) {
    // ISO 8601: Las semanas comienzan en lunes
    // La primera semana del año es la que contiene el primer jueves
    
    // Obtener el jueves de la semana actual
    DateTime jueves = fecha.add(Duration(days: 4 - fecha.weekday));
    
    // Obtener el 1 de enero del año del jueves
    DateTime primerEnero = DateTime(jueves.year, 1, 1);
    
    // Encontrar el primer jueves del año
    DateTime primerJueves = primerEnero;
    while (primerJueves.weekday != 4) {
      primerJueves = primerJueves.add(const Duration(days: 1));
    }
    
    // Obtener el lunes de la semana que contiene el primer jueves
    DateTime lunesSemana1 = primerJueves.subtract(Duration(days: primerJueves.weekday - 1));
    
    // Calcular la diferencia en días desde el lunes de la semana 1
    int diferenciaDias = fecha.difference(lunesSemana1).inDays;
    
    // Calcular el número de semana
    int numeroSemana = (diferenciaDias / 7).floor() + 1;
    
    // Si el número es menor a 1, pertenece a la última semana del año anterior
    if (numeroSemana < 1) {
      // Calcular el número de semana del año anterior
      DateTime ultimoDiaAnioAnterior = DateTime(fecha.year - 1, 12, 31);
      return _calcularNumeroSemanaISO(ultimoDiaAnioAnterior);
    }
    
    // Si es después de la semana 52, verificar si pertenece al año siguiente
    if (numeroSemana > 52) {
      DateTime ultimoDiaAnio = DateTime(fecha.year, 12, 31);
      DateTime juevesUltimaSemana = ultimoDiaAnio.add(Duration(days: 4 - ultimoDiaAnio.weekday));
      
      // Si el jueves de la última semana del año ya es del año siguiente,
      // entonces la semana 53 no existe y es semana 1 del año siguiente
      if (juevesUltimaSemana.year > fecha.year) {
        return 1;
      }
    }
    
    return numeroSemana;
  }

  void _generarSemanasDisponibles() {
    _semanasDisponibles.clear();
    DateTime ahora = DateTime.now();

    // Primero añadir la semana actual
    DateTime inicioSemanaActual = ahora.subtract(
      Duration(days: ahora.weekday - 1),
    );
    
    int numeroSemanaActual = _calcularNumeroSemanaISO(inicioSemanaActual);
    
    String codigoSemanaActual = 'SEMANA $numeroSemanaActual - ${inicioSemanaActual.year}';
    DateTime finSemanaActual = inicioSemanaActual.add(const Duration(days: 5));
    
    _semanasDisponibles.add(
      SemanaOpcion(
        codigo: codigoSemanaActual,
        etiqueta: 'SEMANA $numeroSemanaActual (Actual)',
        fechaInicio: DateFormat('dd/MM/yyyy').format(inicioSemanaActual),
        fechaFin: DateFormat('dd/MM/yyyy').format(finSemanaActual),
        inicioSemana: inicioSemanaActual,
        esActual: true,
      ),
    );
    
    // Empezar desde la próxima semana
    DateTime fechaBase = ahora;

    for (int i = 1; i <= 4; i++) { // Empezar desde 1 para saltar la semana actual
      DateTime fechaSemana = fechaBase.add(Duration(days: i * 7));
      DateTime inicioSemana = fechaSemana.subtract(
        Duration(days: fechaSemana.weekday - 1),
      );

      int numeroSemana = _calcularNumeroSemanaISO(inicioSemana);

      String codigoSemana = 'SEMANA $numeroSemana - ${inicioSemana.year}';
      DateTime finSemana = inicioSemana.add(const Duration(days: 5));

      String fechaInicio = DateFormat('dd/MM/yyyy').format(inicioSemana);
      String fechaFin = DateFormat('dd/MM/yyyy').format(finSemana);

      // Determinar etiquetas más precisas
      String etiqueta;
      if (i == 1) {
        // La primera semana disponible para programar
        etiqueta = '$codigoSemana (Próxima)';
      } else {
        etiqueta = codigoSemana;
      }

      _semanasDisponibles.add(
        SemanaOpcion(
          codigo: codigoSemana,
          etiqueta: etiqueta,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          inicioSemana: inicioSemana,
          esActual: false,
        ),
      );
    }

    print(
      'Semanas generadas desde: ${DateFormat('dd/MM/yyyy').format(fechaBase)}',
    );
    print(
      'Día de la semana actual: ${ahora.weekday} (${_nombreDiaSemana(ahora.weekday)})',
    );
  }

  /// Obtener nombre del día de la semana
  String _nombreDiaSemana(int diaSemana) {
    const dias = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dias[diaSemana];
  }

  /// Verificar si un plan puede ser editado
  bool _puedeEditarPlan(PlanTrabajoModelo plan) {
    if (plan.estatus != 'enviado') return true; // Borradores siempre editables

    // Plan enviado: verificar si han pasado más de 7 días
    final diasTranscurridos =
        DateTime.now().difference(plan.fechaModificacion).inDays;
    return diasTranscurridos <= 7;
  }

  /// Crear plan local inicial usando el servicio offline
  Future<void> _crearPlanLocalInicial() async {
    if (_liderActual == null || _semanaSeleccionada == null) return;

    try {
      // Usar el servicio offline para obtener o crear el plan
      _planActual = await _planOfflineService.obtenerOCrearPlan(
        _semanaSeleccionada!,
        _liderActual!.clave,
        _liderActual!,
      );
      
      // No podemos modificar fechaInicio y fechaFin porque son final

      setState(() {
        _cargando = false;
        // _modoOffline = true; // Indicar que estamos en modo offline
      });

      print(
        'Plan cargado desde almacenamiento local para ${_planActual!.semana}',
      );
    } catch (e) {
      print('Error al crear/cargar plan local: $e');
      setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoPlanBloqueado() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lock, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Plan en ejecución',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ya existe un plan enviado para ${_planActual!.semana}.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Podrá crear el plan de la siguiente semana a partir del día viernes.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El plan actual está en modo de solo lectura.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE1327),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSemanaSeleccionada(String? nuevaSemana) async {
    if (nuevaSemana == null || nuevaSemana == _semanaSeleccionada) return;

    setState(() {
      _semanaSeleccionada = nuevaSemana;
      _dialogoMostrado = false; // Resetear la bandera al cambiar de semana
    });

    // Solo consultar servidor cuando el usuario cambie de semana
    await _cargarPlanDesdeServidor();
  }

  /// Cargar plan cuando el usuario cambia de semana (offline-first)
  Future<void> _cargarPlanDesdeServidor({bool mostrarDialogo = true}) async {
    if (_liderActual == null || _semanaSeleccionada == null) return;

    setState(() => _cargando = true);

    try {
      // Primero intentar cargar desde almacenamiento local
      final planCargado = await _planOfflineService.obtenerOCrearPlan(
        _semanaSeleccionada!,
        _liderActual!.clave,
        _liderActual!,
      );

      final semanaSeleccionada = _semanasDisponibles.firstWhere(
        (s) => s.codigo == _semanaSeleccionada,
      );

      // Verificar restricciones para semana actual solo si debe mostrar diálogo
      if (mostrarDialogo &&
          !_dialogoMostrado &&
          semanaSeleccionada.esActual &&
          planCargado.estatus == 'enviado' &&
          DateTime.now().weekday < 5) {
        _dialogoMostrado = true;
        _mostrarDialogoPlanBloqueado();
      }

      // Log para debug
      print('Plan cargado desde servicio offline:');
      print('- Semana: ${planCargado.semana}');
      print('- Días configurados:');
      planCargado.dias.forEach((dia, config) {
        print('  * $dia: ${config.objetivo ?? "No configurado"}');
      });

      // Actualizar estado con el plan cargado
      if (mounted) {
        setState(() {
          _planActual = planCargado;
          
          // No podemos modificar fechaInicio y fechaFin porque son final
          
          _cargando = false;
          // _modoOffline = true;
        });
      }

      // Comentado: Ya no sincronizamos con el servidor, usamos solo HIVE
      // _sincronizarEnSegundoPlano();
    } catch (e) {
      print('Error al cargar plan: $e');
      setState(() => _cargando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el plan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Intenta sincronizar con el servidor en segundo plano
  Future<void> _sincronizarEnSegundoPlano() async {
    try {
      // Intentar obtener plan desde el servidor
      final planDesdeServidor = await _planServicio.obtenerPlanTrabajo(
        _semanaSeleccionada!,
        _liderActual!.clave,
      );

      if (planDesdeServidor != null && mounted) {
        setState(() {
          _planActual = planDesdeServidor;
          
          // No podemos modificar fechaInicio y fechaFin porque son final
          
          // _modoOffline = false;
        });
        print('Plan sincronizado desde servidor');
      }
    } catch (e) {
      print('No se pudo sincronizar con el servidor: $e');
      // Mantener trabajando offline
    }
  }

  /// Sincronizar cambios locales con el servidor
  Future<void> _sincronizarCambios() async {
    if (_planActual == null) return;

    try {
      // Intentar sincronizar con el servidor
      await _planServicio.guardarPlanTrabajo(_planActual!);

      // Recargar el plan completo desde el servidor para obtener la versión más actualizada
      await _cargarPlanDesdeServidor();

      print('Plan sincronizado y recargado exitosamente');
    } catch (e) {
      print('Error al sincronizar: $e');

      // Mantener como no sincronizado
      if (_planActual != null) {
        _planActual!.sincronizado = false;
        setState(() {});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Cambios guardados localmente. Se sincronizarán cuando haya conexión.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _enviarPlan() async {
    if (_planActual == null) return;

    // Validar que todos los días estén configurados
    bool todosConfigurados = diasSemana.every(
      (dia) =>
          _planActual!.dias.containsKey(dia) &&
          _planActual!.dias[dia]!.objetivo != null,
    );

    if (!todosConfigurados) {
      _mostrarDialogoPlanIncompleto();
      return;
    }

    // Mostrar confirmación antes de enviar
    final confirmar = await _mostrarDialogoConfirmacionEnvio();
    if (confirmar != true) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFDE1327)),
                    const SizedBox(height: 16),
                    Text(
                      'Enviando plan al servidor...',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF1C2120),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      // Enviar plan usando el servicio offline (que intentará sincronizar)
      await _planOfflineService.enviarPlan(
        _semanaSeleccionada!,
        _liderActual!.clave,
      );

      // Recargar el plan para obtener el estado actualizado
      _planActual = await _planOfflineService.obtenerOCrearPlan(
        _semanaSeleccionada!,
        _liderActual!.clave,
        _liderActual!,
      );
      
      // No podemos modificar fechaInicio y fechaFin porque son final

      // Sincronizar con el plan unificado para que esté disponible en la rutina diaria
      await _planOfflineService.sincronizarConPlanUnificado(
        _semanaSeleccionada!,
        _liderActual!.clave,
      );
      print('✅ Plan sincronizado con plan unificado');

      // Integración con API para enviar al backend
      bool sincronizadoConExito = false;
      try {
        // Obtener el plan desde Hive
        final box = HiveService().planesTrabajoSemanalesBox;
        final planHive = box.values.firstWhere(
          (plan) =>
              plan.semana == _semanaSeleccionada! &&
              plan.liderClave == _liderActual!.clave,
          orElse: () => null as PlanTrabajoSemanalHive,
        );

        if (planHive != null) {
          // Enviar al backend usando el API
          await _planApi.postPlan(planHive.toJson());

          // Marcar como sincronizado
          planHive.sincronizado = true;
          planHive.fechaUltimaSincronizacion = DateTime.now();
          await planHive.save();

          sincronizadoConExito = true;
          print('Plan sincronizado con éxito al backend');
        }
      } catch (apiError) {
        // Si falla la sincronización, solo loguear el error
        // El plan ya está guardado localmente
        print('Error al sincronizar con backend: $apiError');

        // Verificar si el error es de autenticación
        if (apiError.toString().contains('401') ||
            apiError.toString().contains('autenticación')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error de autenticación. Por favor, inicie sesión nuevamente.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Ir a Login',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ),
            );
          }
        } else {
          // Mostrar SnackBar informativo para otros errores
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Plan guardado localmente. Se sincronizará cuando haya conexión.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      print('Plan enviado exitosamente:');
      print('- Semana: ${_planActual!.semana}');
      print('- Estatus: ${_planActual!.estatus}');
      print('- Días configurados: ${_planActual!.dias.length}');
      print('- Fecha envío: ${_planActual!.fechaModificacion}');

      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar éxito y regresar
      if (mounted) {
        // Capturar el estado de sincronización antes del diálogo
        final mostrarSincronizado = sincronizadoConExito;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green.shade50, Colors.white],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícono de éxito
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '¡Plan Enviado!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C2120),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'El plan de trabajo para ${_planActual!.semana} ha sido enviado correctamente y está listo para ejecutarse.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Estado: ACTIVO',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      if (mostrarSincronizado) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sincronizado con el servidor',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Cierra diálogo
                            Navigator.of(
                              context,
                            ).pop(true); // Regresa al menú con resultado
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.home, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Ir al Menú Principal',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted) Navigator.of(context).pop();

      // Revertir cambios locales
      _planActual!.estatus = 'borrador';

      print('Error al enviar plan: $e');

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Error al Enviar'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No se pudo enviar el plan al servidor.'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('¿Qué puedes hacer?'),
                    const Text('• Verifica tu conexión a internet'),
                    const Text('• Intenta nuevamente en unos momentos'),
                    const Text('• El plan se mantendrá en borrador'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _enviarPlan(); // Reintentar
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<bool?> _mostrarDialogoConfirmacionEnvio() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFDE1327).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono de envío
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE1327).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Color(0xFFDE1327),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Confirmar Envío',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C2120),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Está seguro de enviar el plan de trabajo para ${_planActual!.semana}?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Información del plan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Días configurados:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_planActual!.dias.length}/6',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Líder:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _planActual!.liderNombre,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Advertencia
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Una vez enviado, podrá editarlo máximo 7 días.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE1327),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: const Color(
                              0xFFDE1327,
                            ).withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enviar Plan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _mostrarDialogoPlanIncompleto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Plan Incompleto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Debe configurar todos los días de la semana antes de enviar el plan.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Días pendientes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: diasSemana
                      .where(
                        (dia) =>
                            !_planActual!.dias.containsKey(dia) ||
                            _planActual!.dias[dia]!.objetivo == null,
                      )
                      .map(
                        (dia) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dia,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE1327),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.send, color: Color(0xFFDE1327)),
                SizedBox(width: 8),
                Text('Confirmar envío'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Está seguro de enviar el plan de trabajo para ${_planActual!.semana}?',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Una vez enviado, podrá editarlo máximo 7 días.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade700,
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
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE1327),
                ),
                child: const Text('Enviar Plan'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('¡Éxito!'),
              ],
            ),
            content: const Text(
              'El plan ha sido enviado correctamente y está listo para ejecutarse.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra diálogo
                  Navigator.of(
                    context,
                  ).pop(true); // Regresa al menú con resultado
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

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

  void _mostrarResumenDia(String dia, DiaTrabajoModelo diaData) {
    // Calcular la fecha completa del día
    final indice = diasSemana.indexOf(dia);
    final semanaSeleccionadaObj = _semanasDisponibles.firstWhere(
      (s) => s.codigo == _semanaSeleccionada,
    );
    final fechaDia = semanaSeleccionadaObj.inicioSemana.add(Duration(days: indice));
    final fechaFormateada = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es').format(fechaDia);
    final esEditable = _planActual!.estatus == 'borrador' || _puedeEditarPlan(_planActual!);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado mejorado
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFDE1327),
                      const Color(0xFFDE1327).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dia,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            fechaFormateada,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              
              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de objetivo principal
                      _buildSeccionResumenMejorada(
                        'Objetivo Principal',
                        diaData.objetivo == 'Múltiples objetivos' 
                          ? 'Día con múltiples objetivos' 
                          : diaData.objetivo ?? 'No especificado',
                        diaData.objetivo == 'Múltiples objetivos' 
                          ? Icons.dashboard 
                          : diaData.objetivo == 'Gestión de cliente' 
                            ? Icons.people 
                            : Icons.assignment,
                        diaData.objetivo == 'Múltiples objetivos'
                          ? Colors.purple
                          : diaData.objetivo == 'Gestión de cliente' 
                            ? Colors.blue 
                            : Colors.orange,
                      ),
                      
                      // Actividades administrativas
                      if (diaData.tipoActividad != null && diaData.tipoActividad!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSeccionActividadesMejorada(
                          'Actividades Administrativas',
                          diaData.tipoActividad!,
                          Icons.folder_special,
                          Colors.orange,
                          esEditable,
                          dia,
                        ),
                      ],
                      
                      // Gestión de clientes
                      if ((diaData.objetivo == 'Gestión de cliente' || 
                           diaData.objetivo == 'Múltiples objetivos') && 
                          diaData.clientesAsignados.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSeccionClientesMejorada(
                          'Clientes Asignados',
                          diaData,
                          Icons.store,
                          Colors.blue,
                          esEditable,
                          dia,
                        ),
                      ],
                      
                      // Objetivos de abordaje - COMENTADO POR SOLICITUD DEL USUARIO
                      // if (diaData.comentario != null && diaData.comentario!.isNotEmpty) ...[
                      //   const SizedBox(height: 20),
                      //   _buildSeccionObjetivosAbordajeMejorada(
                      //     'Indicadores de Ruta',
                      //     diaData.comentario!,
                      //     Icons.track_changes,
                      //     Colors.green,
                      //     esEditable,
                      //     dia,
                      //   ),
                      // ],
                      
                      // Indicadores de gestión
                      if (diaData.clientesAsignados.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        FutureBuilder<Widget>(
                          future: _buildSeccionIndicadores(diaData),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFFDE1327).withOpacity(0.5),
                                ),
                              );
                            }
                            return snapshot.data ?? const SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Botón de cerrar como principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSeccionResumenMejorada(String titulo, String contenido, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contenido,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF1C2120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeccionResumen(String titulo, String contenido, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contenido,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF1C2120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeccionActividadesMejorada(String titulo, String tipoActividad, IconData icono, Color color, bool esEditable, String dia) {
    List<Map<String, dynamic>> actividades = [];
    
    try {
      // Intentar parsear como JSON array
      if (tipoActividad.startsWith('[')) {
        final actividadesJson = jsonDecode(tipoActividad) as List;
        for (var actividad in actividadesJson) {
          actividades.add({
            'tipo': actividad['tipo'] ?? 'Sin especificar',
            'estatus': actividad['estatus'] ?? 'pendiente',
          });
        }
      } else {
        // Si no es JSON, mostrar como actividad simple
        actividades.add({
          'tipo': tipoActividad,
          'estatus': 'pendiente',
        });
      }
    } catch (e) {
      // Si falla el parseo, mostrar como texto simple
      actividades.add({
        'tipo': tipoActividad,
        'estatus': 'pendiente',
      });
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF1C2120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actividades.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${actividades.length} actividades',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...actividades.asMap().entries.map((entry) {
            final index = entry.key;
            final actividad = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    actividad['estatus'] == 'completado' 
                      ? Icons.check_circle 
                      : Icons.radio_button_unchecked,
                    size: 20,
                    color: actividad['estatus'] == 'completado' 
                      ? Colors.green 
                      : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      actividad['tipo'],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF1C2120),
                        decoration: actividad['estatus'] == 'completado' 
                          ? TextDecoration.lineThrough 
                          : null,
                      ),
                    ),
                  ),
                  if (esEditable) ...[
                    // Botones de acción solo si hay una actividad
                    if (actividades.length == 1) ...[
                      TextButton.icon(
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Editar'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDE1327),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () async {
                          Navigator.pop(context); // Cerrar el modal
                          // Navegar a la pantalla de edición
                          await _navegarAEditarDiaDesdeModal(dia);
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.delete_outline, size: 16),
                        label: Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Cerrar el modal
                          _confirmarEliminarDia(dia);
                        },
                      ),
                    ] else ...[
                      // Si hay múltiples actividades, mostrar botón de eliminar individual
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20),
                        color: Colors.red.shade400,
                        tooltip: 'Eliminar esta actividad',
                        onPressed: () {
                          // TODO: Implementar eliminación individual de actividad administrativa
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Función en desarrollo para eliminar actividad individual'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            );
          }).toList(),
          // Botón para agregar nueva actividad
          if (esEditable) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                icon: Icon(Icons.add_circle_outline, size: 20),
                label: Text('Agregar nueva actividad'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // Cerrar el modal
                  // Navegar a la pantalla de programar día indicando que es para agregar nueva actividad
                  await _navegarAAgregarNuevaActividad(dia);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSeccionClientesMejorada(String titulo, DiaTrabajoModelo diaData, IconData icono, Color color, bool esEditable, String dia) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF1C2120),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (diaData.rutaNombre != null)
                      Text(
                        'Ruta: ${diaData.rutaNombre}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${diaData.clientesAsignados.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (esEditable) ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Editar'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDE1327),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // Cerrar el modal
                      await _navegarAEditarDiaDesdeModal(dia);
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text('Eliminar todo'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Cerrar el modal
                      _confirmarEliminarDia(dia);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: diaData.clientesAsignados.length,
              itemBuilder: (context, index) {
                final cliente = diaData.clientesAsignados[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cliente.visitado 
                        ? Colors.green.shade200 
                        : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cliente.visitado 
                            ? Colors.green.shade50 
                            : Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cliente.visitado 
                            ? Icons.check_circle 
                            : Icons.store_outlined,
                          size: 20,
                          color: cliente.visitado 
                            ? Colors.green 
                            : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente.clienteNombre,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF1C2120),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(Icons.tag, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: ${cliente.clienteId}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.category_outlined, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  cliente.clienteTipo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (cliente.visitado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Visitado',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Botón para agregar nueva gestión de clientes
          if (esEditable) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                icon: Icon(Icons.add_circle_outline, size: 20),
                label: Text('Agregar nueva actividad'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // Cerrar el modal
                  // Navegar a la pantalla de programar día indicando que es para agregar nueva actividad
                  await _navegarAAgregarNuevaActividad(dia);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSeccionObjetivosAbordajeMejorada(String titulo, String comentario, IconData icono, Color color, bool esEditable, String dia) {
    List<String> objetivos = [];
    String comentarioAdicional = '';
    
    try {
      // Intentar parsear como JSON
      final comentarioData = jsonDecode(comentario);
      if (comentarioData is Map && comentarioData.containsKey('objetivos')) {
        objetivos = List<String>.from(comentarioData['objetivos']);
        comentarioAdicional = comentarioData['comentario'] ?? '';
      } else {
        throw Exception('No es formato de múltiples objetivos');
      }
    } catch (e) {
      // Si no es JSON, tratar como objetivo único
      if (comentario.isNotEmpty) {
        objetivos = [comentario];
      }
    }
    
    if (objetivos.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF1C2120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${objetivos.length} objetivo${objetivos.length > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (esEditable) ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Editar'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDE1327),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // Cerrar el modal
                      await _navegarAEditarDiaDesdeModal(dia);
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text('Eliminar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Cerrar el modal
                      _confirmarEliminarDia(dia);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...objetivos.map((objetivo) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    objetivo,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF1C2120),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          if (comentarioAdicional.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline, 
                    size: 20, 
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comentario adicional',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comentarioAdicional,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSeccionActividades(String titulo, String tipoActividad, IconData icono, Color color) {
    List<Widget> actividades = [];
    
    try {
      // Intentar parsear como JSON array
      if (tipoActividad.startsWith('[')) {
        final actividadesJson = jsonDecode(tipoActividad);
        for (var actividad in actividadesJson) {
          actividades.add(_buildItemActividad(
            actividad['tipo'] ?? 'Sin especificar',
            actividad['estatus'] ?? 'pendiente',
          ));
        }
      } else {
        // Si no es JSON, mostrar como actividad simple
        actividades.add(_buildItemActividad(tipoActividad, 'pendiente'));
      }
    } catch (e) {
      // Si falla el parseo, mostrar como texto simple
      actividades.add(_buildItemActividad(tipoActividad, 'pendiente'));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1C2120),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actividades,
        ],
      ),
    );
  }
  
  Widget _buildItemActividad(String tipo, String estatus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            estatus == 'completado' ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: estatus == 'completado' ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tipo,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1C2120),
                decoration: estatus == 'completado' ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeccionClientes(String titulo, DiaTrabajoModelo diaData, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1C2120),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (diaData.rutaNombre != null)
                      Text(
                        'Ruta: ${diaData.rutaNombre}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${diaData.clientesAsignados.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: diaData.clientesAsignados.length,
              itemBuilder: (context, index) {
                final cliente = diaData.clientesAsignados[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        cliente.visitado ? Icons.check_circle : Icons.store_outlined,
                        size: 16,
                        color: cliente.visitado ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente.clienteNombre,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF1C2120),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${cliente.clienteId} • ${cliente.clienteTipo}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeccionObjetivosAbordaje(String titulo, String comentario, IconData icono, Color color) {
    List<String> objetivos = [];
    String comentarioAdicional = '';
    
    try {
      // Intentar parsear como JSON
      final comentarioData = jsonDecode(comentario);
      if (comentarioData is Map && comentarioData.containsKey('objetivos')) {
        objetivos = List<String>.from(comentarioData['objetivos']);
        comentarioAdicional = comentarioData['comentario'] ?? '';
      } else {
        throw Exception('No es formato de múltiples objetivos');
      }
    } catch (e) {
      // Si no es JSON, tratar como objetivo único
      if (comentario.isNotEmpty) {
        objetivos = [comentario];
      }
    }
    
    if (objetivos.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1C2120),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...objetivos.map((objetivo) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
          )).toList(),
          if (comentarioAdicional.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comentarioAdicional,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<Widget> _buildSeccionIndicadores(DiaTrabajoModelo diaData) async {
    final indicadoresServicio = IndicadoresGestionServicio();
    
    // Generar ID del plan para buscar indicadores
    final planVisitaId = '${_planActual!.semana}_${diaData.dia}_${diaData.rutaId ?? ''}';
    final clienteIds = diaData.clientesAsignados.map((c) => c.clienteId).toList();
    
    // Obtener resumen de indicadores
    final resumen = await indicadoresServicio.obtenerResumenIndicadores(planVisitaId, clienteIds);
    
    if (resumen.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Contar clientes con indicadores
    final clientesConIndicadores = resumen.where((r) => (r['indicadores'] as List).isNotEmpty).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Indicadores de Gestión',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1C2120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$clientesConIndicadores/${clienteIds.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Mostrar resumen de indicadores por cliente
          ...resumen.take(3).map((clienteResumen) {
            final indicadores = clienteResumen['indicadores'] as List<String>;
            final resultados = clienteResumen['resultados'] as Map<String, String>? ?? {};
            final comentario = clienteResumen['comentario'] as String?;
            
            if (indicadores.isEmpty) return const SizedBox.shrink();
            
            // Obtener catálogo de indicadores para saber el tipo de resultado
            final catalogoIndicadores = CatalogoIndicadores.indicadoresIniciales;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clienteResumen['clienteNombre'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: indicadores.take(2).map((indicadorNombre) {
                      // Buscar el indicador por nombre para obtener su ID y tipo
                      final indicador = catalogoIndicadores.firstWhere(
                        (ind) => ind.nombre == indicadorNombre,
                        orElse: () => IndicadorGestionModelo(
                          id: '',
                          nombre: indicadorNombre,
                          descripcion: '',
                          tipoResultado: 'numero',
                        ),
                      );
                      final resultado = resultados[indicador.id] ?? '';
                      final mostrarResultado = resultado.isNotEmpty ? ' - $resultado' : '';
                      final sufijo = indicador.tipoResultado == 'porcentaje' && resultado.isNotEmpty ? '%' : '';
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$indicadorNombre$mostrarResultado$sufijo',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (indicadores.length > 2)
                    Text(
                      '+${indicadores.length - 2} más',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.purple.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          
          if (resumen.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Y ${resumen.length - 3} clientes más...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.purple.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFFDE1327)),
              SizedBox(height: 16),
              Text('Cargando plan de trabajo...'),
            ],
          ),
        ),
      );
    }

    if (_planActual == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error al cargar el plan de trabajo'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _inicializarVista,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _planActual != null && _planActual!.estatus == 'borrador'
          ? FloatingActionButton.extended(
              onPressed: _enviarPlan,
              backgroundColor: const Color(0xFFDE1327),
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'ENVIAR PLAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              // Hay al menos otra ruta debajo: regresa a ella
              Navigator.of(context).pop();
            } else {
              // Esta es la única ruta: reemplaza por /home
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: Column(
          children: [
            const Text(
              'Crear Plan de Trabajo',
              style: TextStyle(
                color: Color(0xFF1C2120),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            // if (_modoOffline)
            //   Text(
            //     'Modo Offline',
            //     style: TextStyle(
            //       color: Colors.orange.shade700,
            //       fontSize: 12,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Indicador de conexión comentado
          // CompactConnectionStatusWidget(),
          // const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          // Definir ancho máximo del contenido según el tamaño de pantalla
          double contentWidth;
          if (width >= 1200) {
            contentWidth = 1200;
          } else if (width >= 800) {
            contentWidth = 800;
          } else {
            contentWidth = width - 32; // Padding horizontal de 16 en cada lado
          }
          
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Selector de semana sticky
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    pinned: true,
                    floating: false,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    expandedHeight: 120,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildSelectorSemana(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Contenido principal
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos Generales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // INFORMACIÓN DE LA SEMANA SELECCIONADA
                    Row(
                      children: [
                        Expanded(
                          child: _buildDato('Desde:', _obtenerFechaInicioSemanaSeleccionada()),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDato('Hasta:', _obtenerFechaFinSemanaSeleccionada()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDato('Estatus:', _planActual!.estatus == 'borrador' ? 'EN PROCESO' : _planActual!.estatus.toUpperCase()),
                    _buildDato('Líder:', _planActual!.liderNombre),
                    _buildDato('Centro:', _planActual!.centroDistribucion),
                    // INDICADOR DE EDITABILIDAD PARA PLANES ENVIADOS
                    if (_planActual!.estatus == 'enviado') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _puedeEditarPlan(_planActual!)
                                ? Icons.edit
                                : Icons.lock_outline,
                            size: 16,
                            color:
                                _puedeEditarPlan(_planActual!)
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _puedeEditarPlan(_planActual!)
                                  ? 'Editable hasta ${DateFormat('dd/MM/yyyy').format(_planActual!.fechaModificacion.add(Duration(days: 7)))}'
                                  : 'Plan bloqueado para edición',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    _puedeEditarPlan(_planActual!)
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                // INDICADOR DE SINCRONIZACIÓN
                /*   const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _planActual!.sincronizado
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      size: 16,
                      color:
                          _planActual!.sincronizado
                              ? Colors.green
                              : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _planActual!.sincronizado
                                ? 'Sincronizado'
                                : 'Pendiente de sincronizar',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  _planActual!.sincronizado
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          FutureBuilder<DateTime?>(
                            future: Future.value(_planOfflineService.obtenerFechaUltimaSincronizacion()),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                final fechaSync = snapshot.data!;
                                final diferencia = DateTime.now().difference(fechaSync);
                                String texto;
                                if (diferencia.inMinutes < 1) {
                                  texto = 'Hace menos de un minuto';
                                } else if (diferencia.inHours < 1) {
                                  texto = 'Hace ${diferencia.inMinutes} minutos';
                                } else if (diferencia.inDays < 1) {
                                  texto = 'Hace ${diferencia.inHours} horas';
                                } else {
                                  texto = 'Hace ${diferencia.inDays} días';
                                }
                                return Text(
                                  'Última sincronización: $texto',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
*/
                    if (_planActual!.estatus == 'enviado') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plan Activo en Ejecución',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Enviado el ${DateFormat('dd/MM/yyyy HH:mm').format(_planActual!.fechaModificacion)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(color: Colors.grey, thickness: 0.5, height: 24),
                    const Text(
                      'Programación de la semana',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // DÍAS DE LA SEMANA CON EXPANSION
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionPanelList(
                        elevation: 0,
                        expandedHeaderPadding: EdgeInsets.zero,
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            _diasExpandidos[index] = !_diasExpandidos[index];
                          });
                        },
                        children: diasSemana.asMap().entries.map((entry) {
                          final indice = entry.key;
                          final dia = entry.value;
                          
                          // Calcular la fecha real del día
                          final semanaSeleccionadaObj = _semanasDisponibles.firstWhere(
                            (s) => s.codigo == _semanaSeleccionada,
                          );
                          final fechaDia = semanaSeleccionadaObj.inicioSemana.add(Duration(days: indice));
                          final fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaDia);
                          
                          final tieneDia = _planActual!.dias.containsKey(dia);
                          final tieneObjetivo =
                              tieneDia &&
                              _planActual!.dias[dia]!.objetivo != null &&
                              _planActual!.dias[dia]!.objetivo!.isNotEmpty;
                          final diaConfigurado = tieneDia && tieneObjetivo;

                          // Log para todos los días para debug
                          print(
                            'UI - Verificando $dia: tieneDia=$tieneDia, tieneObjetivo=$tieneObjetivo, configurado=$diaConfigurado',
                          );
                          if (tieneDia && _planActual!.dias[dia] != null) {
                            final diaData = _planActual!.dias[dia]!;
                            print('  - Objetivo: "${diaData.objetivo}"');
                            print('  - Tipo: ${diaData.tipo}');
                            print('  - TipoActividad: ${diaData.tipoActividad}');
                          }

                          final esEditable =
                              _planActual!.estatus == 'borrador' ||
                              _puedeEditarPlan(_planActual!);

                          return ExpansionPanel(
                            backgroundColor: Colors.white,
                            isExpanded: _diasExpandidos[indice],
                            canTapOnHeader: true,
                            headerBuilder: (BuildContext context, bool isExpanded) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !esEditable && _planActual!.estatus == 'enviado'
                                      ? Colors.red.shade50
                                      : diaConfigurado 
                                        ? Colors.green.shade50 
                                        : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      diaConfigurado
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color:
                                          !esEditable
                                              ? Colors.grey.shade400
                                              : (diaConfigurado ? Colors.green : Colors.grey),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$dia - $fechaFormateada',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: !esEditable ? Colors.grey : const Color(0xFF1C2120),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (diaConfigurado)
                                            Text(
                                              _planActual!.dias[dia]!.objetivo!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: !esEditable ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (!esEditable && _planActual!.estatus == 'enviado')
                                      Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: Colors.red.shade400,
                                      )
                                    else if (diaConfigurado)
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey.shade600,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'ver') {
                                            _mostrarResumenDia(dia, _planActual!.dias[dia]!);
                                          } else if (value == 'editar') {
                                            _navegarAEditarDia(dia, fechaDia, indice);
                                          } else if (value == 'eliminar') {
                                            _confirmarEliminarDia(dia);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'ver',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility_outlined, size: 20),
                                                SizedBox(width: 8),
                                                Text('Ver resumen'),
                                              ],
                                            ),
                                          ),
                                          if (esEditable) ...[
                                            PopupMenuItem<String>(
                                              value: 'editar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'eliminar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      )
                                    else
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                  ],
                                ),
                              );
                            },
                            body: Container(
                              padding: const EdgeInsets.all(16),
                              child: diaConfigurado
                                  ? Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Resumen del día
                                          _buildResumenCompactoDia(dia, _planActual!.dias[dia]!),
                                          const SizedBox(height: 16),
                                          // Botón de acción centrado
                                          Center(
                                            child: ElevatedButton.icon(
                                              icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.white),
                                              label: Text('Ver detalle', style: TextStyle(color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFDE1327),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                elevation: 2,
                                              ),
                                              onPressed: () => _mostrarResumenDia(dia, _planActual!.dias[dia]!),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.event_available,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Día no configurado',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (esEditable) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.add, color: Colors.white),
                                        label: Text('Configurar día', style: TextStyle(color: Colors.white, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFDE1327),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          elevation: 2,
                                        ),
                                        onPressed: () => _navegarAEditarDia(dia, fechaDia, indice),
                                      ),
                                    ],
                                          ],
                                        ),
                                      ),
                                    ),
                            )
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24), // Reducido de 32 a 24
                    // INFORMACIÓN ADICIONAL PARA PLANES ENVIADOS
                    if (_planActual!.estatus == 'enviado') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Plan en Ejecución',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _puedeEditarPlan(_planActual!)
                                  ? 'Puede realizar modificaciones hasta el ${DateFormat('dd/MM/yyyy').format(_planActual!.fechaModificacion.add(Duration(days: 7)))}.'
                                  : 'Este plan ya no puede ser modificado.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
                ],
              ),
            ),
          );
        },
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

  Widget _buildSelectorSemana() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semana:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 8),
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
              value: _semanaSeleccionada,
              isExpanded: true,
              items:
                  _semanasDisponibles.map((semana) {
                    return DropdownMenuItem<String>(
                      value: semana.codigo,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            semana.etiqueta,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Text(
                          //   '${semana.fechaInicio} - ${semana.fechaFin}',
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: Colors.grey.shade600,
                          //   ),
                          // ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: _onSemanaSeleccionada,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1C2120)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDato(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1C2120),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1C2120)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResumenCompactoDia(String dia, DiaTrabajoModelo diaData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Objetivo principal con diseño mejorado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: diaData.objetivo == 'Gestión de cliente' 
              ? Colors.blue.shade50 
              : diaData.objetivo == 'Múltiples objetivos'
                ? Colors.purple.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: diaData.objetivo == 'Gestión de cliente' 
                ? Colors.blue.shade200 
                : diaData.objetivo == 'Múltiples objetivos'
                  ? Colors.purple.shade200
                  : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                diaData.objetivo == 'Gestión de cliente' 
                  ? Icons.people 
                  : diaData.objetivo == 'Múltiples objetivos'
                    ? Icons.dashboard
                    : Icons.assignment,
                size: 20,
                color: diaData.objetivo == 'Gestión de cliente' 
                  ? Colors.blue.shade700 
                  : diaData.objetivo == 'Múltiples objetivos'
                    ? Colors.purple.shade700
                    : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diaData.objetivo ?? 'No especificado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C2120),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Detalles en contenedor
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clientes asignados
              if (diaData.clientesAsignados.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.store, size: 16, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${diaData.clientesAsignados.length} clientes asignados',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF1C2120),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (diaData.rutaNombre != null)
                            Text(
                              'Ruta: ${diaData.rutaNombre}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              
              // Actividades administrativas
              if (diaData.tipoActividad != null && diaData.tipoActividad!.isNotEmpty) ...[
                if (diaData.clientesAsignados.isNotEmpty) 
                  const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.folder_special, size: 16, color: Colors.orange.shade600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _contarActividadesAdministrativas(diaData.tipoActividad!),
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF1C2120),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  String _contarActividadesAdministrativas(String tipoActividad) {
    try {
      if (tipoActividad.startsWith('[')) {
        final actividades = jsonDecode(tipoActividad) as List;
        return '${actividades.length} actividad${actividades.length > 1 ? 'es' : ''} administrativa${actividades.length > 1 ? 's' : ''}';
      }
    } catch (e) {
      // Si falla el parseo, es una actividad simple
    }
    return '1 actividad administrativa';
  }
  
  Future<void> _navegarAEditarDia(String dia, DateTime fechaDia, int indice) async {
    if (!(_planActual!.estatus == 'borrador' || _puedeEditarPlan(_planActual!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Este plan ya no puede ser editado. Ha excedido el límite de 7 días.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Si hay datos existentes del día, incluirlos en los argumentos
    final diaExistente = _planActual!.dias[dia];
    
    final resultado = await Navigator.pushNamed(
      context,
      '/programar_dia',
      arguments: {
        'dia': dia,
        'semana': _planActual!.semana,
        'liderId': _planActual!.liderId,
        'fecha': fechaDia,
        'esEdicion': true, // Siempre true cuando se navega desde editar
        // Pasar los datos existentes si los hay
        if (diaExistente != null) ...{
          'datosExistentes': {
            'objetivo': diaExistente.objetivo,
            'tipoActividad': diaExistente.tipoActividad,
            'rutaId': diaExistente.rutaId,
            'rutaNombre': diaExistente.rutaNombre,
            'comentario': diaExistente.comentario,
            'codigoDiaVisita': diaExistente.codigoDiaVisita,
            'clientesAsignados': diaExistente.clientesAsignados.map((c) => c.toJson()).toList(),
          },
        },
      },
    );

    if (resultado == true && mounted) {
      print('Recargando plan después de configurar día: $dia');

      if (_planActual!.estatus == 'enviado') {
        print('Plan editado - incrementando contador de modificaciones');
      }

      try {
        setState(() => _cargando = true);
        await Future.delayed(Duration(milliseconds: 50));

        print('Recargando plan desde servicio offline...');
        final planActualizado = await _planOfflineService.obtenerOCrearPlan(
          _semanaSeleccionada!,
          _liderActual!.clave,
          _liderActual!,
        );

        print('Plan recargado. Días configurados:');
        planActualizado.dias.forEach((diaKey, config) {
          print('  - $diaKey: ${config.objetivo ?? "No configurado"}');
        });

        if (mounted) {
          setState(() {
            _planActual = planActualizado;
            _cargando = false;
            print('Estado actualizado con el plan recargado');
          });
        }
      } catch (e) {
        print('Error al recargar plan: $e');
        if (mounted) {
          setState(() => _cargando = false);
        }
      }
    }
  }
  
  Future<void> _navegarAEditarDiaDesdeModal(String dia) async {
    // Calcular la fecha del día
    final indice = diasSemana.indexOf(dia);
    final semanaSeleccionadaObj = _semanasDisponibles.firstWhere(
      (s) => s.codigo == _semanaSeleccionada,
    );
    final fechaDia = semanaSeleccionadaObj.inicioSemana.add(Duration(days: indice));
    
    // Llamar al método existente de navegación
    await _navegarAEditarDia(dia, fechaDia, indice);
  }
  
  Future<void> _navegarAAgregarNuevaActividad(String dia) async {
    // Calcular la fecha del día
    final indice = diasSemana.indexOf(dia);
    final semanaSeleccionadaObj = _semanasDisponibles.firstWhere(
      (s) => s.codigo == _semanaSeleccionada,
    );
    final fechaDia = semanaSeleccionadaObj.inicioSemana.add(Duration(days: indice));
    
    final resultado = await Navigator.pushNamed(
      context,
      '/programar_dia',
      arguments: {
        'dia': dia,
        'semana': _planActual!.semana,
        'liderId': _planActual!.liderId,
        'fecha': fechaDia,
        'esEdicion': false, // Importante: false para indicar que es nueva actividad
        'esNuevaActividad': true, // Indicar explícitamente que es para agregar nueva actividad
        // Los datos existentes se cargarán automáticamente en vista_programar_dia
      },
    );
    
    if (resultado == true) {
      // Recargar el plan
      await _cargarPlanDesdeServidor(mostrarDialogo: false);
    }
  }
  
  Future<void> _confirmarEliminarDia(String dia) async {
    final diaData = _planActual!.dias[dia];
    if (diaData == null) return;
    
    final confirmado = await showDialog<bool>(
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
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Eliminar configuración',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de eliminar la configuración del día $dia?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mostrar resumen de lo que se eliminará
            if (diaData.objetivo != null) ...[
              Text(
                'Se eliminará:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Objetivo: ${diaData.objetivo}',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    if (diaData.rutaNombre != null)
                      Text(
                        '• Ruta: ${diaData.rutaNombre}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    if (diaData.clientesAsignados.isNotEmpty)
                      Text(
                        '• ${diaData.clientesAsignados.length} clientes asignados',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    if (diaData.tipoActividad != null)
                      Text(
                        '• Tipo: ${diaData.tipoActividad}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmado == true) {
      try {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFDE1327),
            ),
          ),
        );
        
        // Eliminar el día del plan
        await _planOfflineService.eliminarConfiguracionDia(
          _planActual!.semana,
          _planActual!.liderId,
          dia,
        );
        
        // Cerrar loading
        if (mounted) Navigator.of(context).pop();
        
        // Recargar el plan
        await _cargarPlanDesdeServidor();
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Configuración del $dia eliminada'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Cerrar loading si está abierto
        if (mounted) Navigator.of(context).pop();
        
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _obtenerFechaInicioSemanaSeleccionada() {
    if (_semanaSeleccionada == null) return '';
    final semana = _semanasDisponibles.firstWhere(
      (s) => s.codigo == _semanaSeleccionada,
      orElse: () => _semanasDisponibles.first,
    );
    return semana.fechaInicio;
  }

  String _obtenerFechaFinSemanaSeleccionada() {
    if (_semanaSeleccionada == null) return '';
    final semana = _semanasDisponibles.firstWhere(
      (s) => s.codigo == _semanaSeleccionada,
      orElse: () => _semanasDisponibles.first,
    );
    return semana.fechaFin;
  }
}

// Clase auxiliar para las opciones de semana
class SemanaOpcion {
  final String codigo;
  final String etiqueta;
  final String fechaInicio;
  final String fechaFin;
  final DateTime inicioSemana;
  final bool esActual;

  SemanaOpcion({
    required this.codigo,
    required this.etiqueta,
    required this.fechaInicio,
    required this.fechaFin,
    required this.inicioSemana,
    required this.esActual,
  });
}
