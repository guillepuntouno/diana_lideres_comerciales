// lib/vistas/menu_principal/vista_configuracion_plan.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';
import '../../servicios/plan_trabajo_offline_service.dart';
import '../../widgets/connection_status_widget.dart';
import '../../data/api/plan_api.dart';
import '../../servicios/hive_service.dart';
import '../../modelos/hive/plan_trabajo_semanal_hive.dart';
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
  final PlanTrabajoOfflineService _planOfflineService = PlanTrabajoOfflineService();
  final PlanApi _planApi = PlanApi();
  PlanTrabajoModelo? _planActual;
  LiderComercial? _liderActual;
  bool _cargando = true;
  int _currentIndex = 1;
  bool _modoOffline = false;

  // Selector de semanas
  List<SemanaOpcion> _semanasDisponibles = [];
  String? _semanaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializarVista();
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
      _cargarPlanDesdeServidor();
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

  void _generarSemanasDisponibles() {
    _semanasDisponibles.clear();
    DateTime ahora = DateTime.now();

    // NUEVA LÓGICA: Si es lunes o después, empezar desde la siguiente semana
    DateTime fechaBase = ahora;
    if (ahora.weekday >= 1) {
      // Lunes = 1, Martes = 2, etc.
      fechaBase = ahora.add(Duration(days: 7 - ahora.weekday + 1));
    }

    for (int i = 0; i < 5; i++) {
      DateTime fechaSemana = fechaBase.add(Duration(days: i * 7));
      DateTime inicioSemana = fechaSemana.subtract(
        Duration(days: fechaSemana.weekday - 1),
      );

      int numeroSemana =
          ((inicioSemana.difference(DateTime(inicioSemana.year, 1, 1)).inDays +
                      DateTime(inicioSemana.year, 1, 1).weekday -
                      1) /
                  7)
              .ceil();

      String codigoSemana = 'SEMANA $numeroSemana - ${inicioSemana.year}';
      DateTime finSemana = inicioSemana.add(const Duration(days: 4));

      String fechaInicio = DateFormat('dd/MM/yyyy').format(inicioSemana);
      String fechaFin = DateFormat('dd/MM/yyyy').format(finSemana);

      // Determinar etiquetas más precisas
      String etiqueta;
      if (i == 0) {
        // La primera semana disponible para programar
        bool esSemanaSiguiente = inicioSemana.isAfter(DateTime.now());
        etiqueta =
            esSemanaSiguiente
                ? '$codigoSemana (Próxima)'
                : '$codigoSemana (Actual)';
      } else if (i == 1) {
        etiqueta = '$codigoSemana';
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
          esActual: i == 0,
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

      setState(() {
        _cargando = false;
        _modoOffline = true; // Indicar que estamos en modo offline
      });

      print('Plan cargado desde almacenamiento local para ${_planActual!.semana}');
    } catch (e) {
      print('Error al crear/cargar plan local: $e');
      setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoPlanBloqueado() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.lock, color: Colors.orange),
                SizedBox(width: 8),
                Text('Plan en ejecución'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ya existe un plan enviado para ${_planActual!.semana}.'),
                const SizedBox(height: 12),
                const Text(
                  'Podrá crear el plan de la siguiente semana a partir del día viernes.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El plan actual está en modo de solo lectura.',
                          style: TextStyle(
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  Future<void> _onSemanaSeleccionada(String? nuevaSemana) async {
    if (nuevaSemana == null || nuevaSemana == _semanaSeleccionada) return;

    setState(() {
      _semanaSeleccionada = nuevaSemana;
    });

    // Solo consultar servidor cuando el usuario cambie de semana
    await _cargarPlanDesdeServidor();
  }

  /// Cargar plan cuando el usuario cambia de semana (offline-first)
  Future<void> _cargarPlanDesdeServidor() async {
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

      // Verificar restricciones para semana actual
      if (semanaSeleccionada.esActual &&
          planCargado.estatus == 'enviado' &&
          DateTime.now().weekday < 5) {
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
          _cargando = false;
          _modoOffline = true;
        });
      }

      // Intentar sincronizar con el servidor en segundo plano
      _sincronizarEnSegundoPlano();

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
          _modoOffline = false;
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
            (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFDE1327)),
                  const SizedBox(height: 16),
                  Text(
                    'Enviando plan al servidor...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          (plan) => plan.semana == _semanaSeleccionada! && plan.liderClave == _liderActual!.clave,
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
        if (apiError.toString().contains('401') || apiError.toString().contains('autenticación')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error de autenticación. Por favor, inicie sesión nuevamente.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Ir a Login',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
                content: Text('Plan guardado localmente. Se sincronizará cuando haya conexión.'),
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
                              Icon(Icons.cloud_done, size: 16, color: Colors.blue.shade700),
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Plan Incompleto'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debe configurar todos los días de la semana antes de enviar el plan.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Días pendientes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...diasSemana
                    .where(
                      (dia) =>
                          !_planActual!.dias.containsKey(dia) ||
                          _planActual!.dias[dia]!.objetivo == null,
                    )
                    .map(
                      (dia) => Text(
                        '• $dia',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
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
    }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () => Navigator.of(context).pop(),
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
            if (_modoOffline)
              Text(
                'Modo Offline',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Indicador de conexión
          ConnectionStatusWidget(),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 16),

                // SELECTOR DE SEMANA
                _buildSelectorSemana(),
                const SizedBox(height: 12),

                // INFORMACIÓN DE LA SEMANA SELECCIONADA
                Row(
                  children: [
                    Expanded(
                      child: _buildDato('Desde:', _planActual!.fechaInicio),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDato('Hasta:', _planActual!.fechaFin),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDato('Estatus:', _planActual!.estatus.toUpperCase()),
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
                            fontSize: 12,
                            color:
                                _puedeEditarPlan(_planActual!)
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // INDICADOR DE SINCRONIZACIÓN
                const SizedBox(height: 8),
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

                const Divider(color: Colors.grey, thickness: 0.5, height: 32),
                const Text(
                  'Programación de la semana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 16),

                // DÍAS DE LA SEMANA
                ...diasSemana.map((dia) {
                  final tieneDia = _planActual!.dias.containsKey(dia);
                  final tieneObjetivo = tieneDia && _planActual!.dias[dia]!.objetivo != null && _planActual!.dias[dia]!.objetivo!.isNotEmpty;
                  final diaConfigurado = tieneDia && tieneObjetivo;
                  
                  // Log para todos los días para debug
                  print('UI - Verificando $dia: tieneDia=$tieneDia, tieneObjetivo=$tieneObjetivo, configurado=$diaConfigurado');
                  if (tieneDia && _planActual!.dias[dia] != null) {
                    final diaData = _planActual!.dias[dia]!;
                    print('  - Objetivo: "${diaData.objetivo}"');
                    print('  - Tipo: ${diaData.tipo}');
                    print('  - TipoActividad: ${diaData.tipoActividad}');
                  }
                  
                  final esEditable =
                      _planActual!.estatus == 'borrador' ||
                      _puedeEditarPlan(_planActual!);

                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side:
                          !esEditable && _planActual!.estatus == 'enviado'
                              ? BorderSide(color: Colors.red.shade200, width: 1)
                              : BorderSide.none,
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dia,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    !esEditable
                                        ? Colors.grey
                                        : const Color(0xFF1C2120),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (!esEditable && _planActual!.estatus == 'enviado')
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Colors.red.shade400,
                            ),
                        ],
                      ),
                      subtitle:
                          diaConfigurado
                              ? Text(
                                _planActual!.dias[dia]!.objetivo!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      !esEditable
                                          ? Colors.grey.shade400
                                          : Colors.grey,
                                ),
                              )
                              : null,
                      trailing: Icon(
                        diaConfigurado
                            ? Icons.check_circle
                            : Icons.hourglass_bottom,
                        color:
                            !esEditable
                                ? Colors.grey.shade400
                                : (diaConfigurado ? Colors.green : Colors.grey),
                      ),
                      onTap:
                          (_planActual!.estatus == 'borrador' ||
                                  _puedeEditarPlan(_planActual!))
                              ? () async {
                                final resultado = await Navigator.pushNamed(
                                  context,
                                  '/programar_dia',
                                  arguments: {
                                    'dia': dia,
                                    'semana': _planActual!.semana,
                                    'liderId': _planActual!.liderId,
                                    'esEdicion':
                                        _planActual!.estatus ==
                                        'enviado', // Indicar si es edición
                                  },
                                );

                                print('Navigator.pushNamed retornó: $resultado');
                                
                                if (resultado == true && mounted) {
                                  print('Recargando plan después de configurar día: $dia');
                                  
                                  // Si fue una edición, incrementar contador
                                  if (_planActual!.estatus == 'enviado') {
                                    print(
                                      'Plan editado - incrementando contador de modificaciones',
                                    );
                                  }

                                  try {
                                    // Mostrar loading mientras se recarga
                                    setState(() => _cargando = true);
                                    
                                    // Esperar un frame para que el loading se muestre
                                    await Future.delayed(Duration(milliseconds: 50));
                                    
                                    print('Recargando plan desde servicio offline...');
                                    
                                    // Recargar el plan directamente sin usar _cargarPlanDesdeServidor
                                    final planActualizado = await _planOfflineService.obtenerOCrearPlan(
                                      _semanaSeleccionada!,
                                      _liderActual!.clave,
                                      _liderActual!,
                                    );
                                    
                                    print('Plan recargado. Días configurados:');
                                    planActualizado.dias.forEach((diaKey, config) {
                                      print('  - $diaKey: ${config.objetivo ?? "No configurado"}');
                                    });
                                    
                                    // Actualizar el estado con el plan recargado
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
                              : () {
                                // Mostrar mensaje de que no se puede editar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Este plan ya no puede ser editado. Ha excedido el límite de 7 días.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 32),

                // BOTÓN ENVIAR - Solo para borradores
                if (_planActual!.estatus == 'borrador')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviarPlan,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        'ENVIAR PLAN',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDE1327),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: Colors.black12,
                      ),
                    ),
                  ),

                // INFORMACIÓN ADICIONAL PARA PLANES ENVIADOS
                if (_planActual!.estatus == 'enviado') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                                fontSize: 16,
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
                            fontSize: 14,
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
            icon: Icon(Icons.assignment_outlined),
            label: 'Rutinas',
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
                          Text(
                            '${semana.fechaInicio} - ${semana.fechaFin}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
