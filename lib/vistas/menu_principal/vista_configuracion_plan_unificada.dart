// lib/vistas/menu_principal/vista_configuracion_plan_unificada.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/servicios/plan_trabajo_unificado_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/widgets/connection_status_widget.dart';

class VistaProgramacionSemanaUnificada extends StatefulWidget {
  const VistaProgramacionSemanaUnificada({super.key});

  @override
  State<VistaProgramacionSemanaUnificada> createState() =>
      _VistaProgramacionSemanaUnificadaState();
}

class _VistaProgramacionSemanaUnificadaState extends State<VistaProgramacionSemanaUnificada>
    with WidgetsBindingObserver {
  final List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  final PlanTrabajoUnificadoService _planServicio = PlanTrabajoUnificadoService();
  PlanTrabajoUnificadoHive? _planActual;
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
      _cargarPlan();
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
  bool _puedeEditarPlan(PlanTrabajoUnificadoHive plan) {
    return plan.puedeEditar();
  }

  /// Crear plan local inicial usando el servicio unificado
  Future<void> _crearPlanLocalInicial() async {
    if (_liderActual == null || _semanaSeleccionada == null) return;

    try {
      // Usar el servicio unificado para obtener o crear el plan
      _planActual = await _planServicio.obtenerOCrearPlan(
        _semanaSeleccionada!,
        _liderActual!.clave,
        _liderActual!,
      );

      setState(() {
        _cargando = false;
        _modoOffline = !_planActual!.sincronizado;
      });

      print('Plan cargado: ${_planActual!.id} - Sincronizado: ${_planActual!.sincronizado}');
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

    await _cargarPlan();
  }

  /// Cargar plan cuando el usuario cambia de semana
  Future<void> _cargarPlan() async {
    if (_liderActual == null || _semanaSeleccionada == null) return;

    setState(() => _cargando = true);

    try {
      _planActual = await _planServicio.obtenerOCrearPlan(
        _semanaSeleccionada!,
        _liderActual!.clave,
        _liderActual!,
      );

      setState(() {
        _cargando = false;
        _modoOffline = !_planActual!.sincronizado;
      });

      // Intentar sincronizar en segundo plano
      _sincronizarEnSegundoPlano();
    } catch (e) {
      print('Error al cargar plan: $e');
      setState(() => _cargando = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sincronizarEnSegundoPlano() async {
    try {
      final sincronizados = await _planServicio.sincronizarPlanesPendientes();
      if (sincronizados > 0 && mounted) {
        // Recargar el plan actual si fue sincronizado
        final planRecargado = await _planServicio.recargarPlan(_planActual!.id);
        if (planRecargado != null) {
          setState(() {
            _planActual = planRecargado;
            _modoOffline = !planRecargado.sincronizado;
          });
        }
      }
    } catch (e) {
      print('Error en sincronización de fondo: $e');
    }
  }

  Future<void> _sincronizarCambios() async {
    if (!mounted) return;

    setState(() => _cargando = true);

    try {
      final sincronizados = await _planServicio.sincronizarPlanesPendientes();
      
      if (sincronizados > 0) {
        // Recargar el plan actual
        final planRecargado = await _planServicio.recargarPlan(_planActual!.id);
        if (planRecargado != null) {
          setState(() {
            _planActual = planRecargado;
            _modoOffline = !planRecargado.sincronizado;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$sincronizados planes sincronizados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay cambios pendientes'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sincronizando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _enviarPlan() async {
    if (_planActual == null) return;

    // Validar que todos los días estén configurados
    bool todosConfigurados = _planActual!.dias.values.every((dia) => dia.configurado);

    if (!todosConfigurados) {
      _mostrarDialogoError(
        'Plan incompleto',
        'Debe configurar todos los días de la semana antes de enviar el plan.',
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar envío'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Desea enviar el plan de ${_planActual!.semana}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Una vez enviado, el plan no podrá ser modificado después de 7 días.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('ENVIAR PLAN'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _cargando = true);

    try {
      await _planServicio.enviarPlan(_planActual!.id);
      
      // Recargar el plan para obtener el estado actualizado
      final planActualizado = await _planServicio.recargarPlan(_planActual!.id);
      if (planActualizado != null) {
        setState(() {
          _planActual = planActualizado;
          _modoOffline = !planActualizado.sincronizado;
        });
      }

      if (mounted) {
        _mostrarDialogoExito();
      }
    } catch (e) {
      print('Error enviando plan: $e');
      if (mounted) {
        _mostrarDialogoError('Error al enviar', e.toString());
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Plan enviado exitosamente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El plan de ${_planActual!.semana} ha sido enviado correctamente.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
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
                      _modoOffline 
                          ? 'El plan se sincronizará cuando haya conexión.'
                          : 'El plan ha sido sincronizado con el servidor.',
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/menu_principal');
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }

  Future<void> _irAProgramarDia(String dia) async {
    if (_planActual == null) return;

    final puedeEditar = _puedeEditarPlan(_planActual!);
    if (!puedeEditar) {
      _mostrarDialogoPlanBloqueado();
      return;
    }

    final resultado = await Navigator.pushNamed(
      context,
      '/programar_dia',
      arguments: {
        'dia': dia,
        'semana': _planActual!.semana,
        'liderId': _liderActual!.clave,
        'esEdicion': _planActual!.dias[dia]?.configurado ?? false,
        'planId': _planActual!.id,
      },
    );

    if (resultado == true && mounted) {
      // Recargar el plan si hubo cambios
      final planRecargado = await _planServicio.recargarPlan(_planActual!.id);
      if (planRecargado != null) {
        setState(() {
          _planActual = planRecargado;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Color(0xFF1976D2),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programación Semanal',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  if (_planActual != null)
                    Text(
                      _planActual!.estatus == 'enviado' ? 'Plan Enviado' : 'Borrador',
                      style: TextStyle(
                        fontSize: 12,
                        color: _planActual!.estatus == 'enviado' 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_modoOffline)
            IconButton(
              icon: const Icon(Icons.cloud_off, color: Colors.orange),
              onPressed: _sincronizarCambios,
              tooltip: 'Modo offline - Toque para sincronizar',
            ),
          if (!_modoOffline)
            IconButton(
              icon: const Icon(Icons.sync, color: Color(0xFF2C3E50)),
              onPressed: _sincronizarCambios,
              tooltip: 'Sincronizar cambios',
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ConnectionStatusWidget(),
                // Selector de semana
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, 
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Seleccionar semana:',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButton<String>(
                          value: _semanaSeleccionada,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: _onSemanaSeleccionada,
                          items: _semanasDisponibles.map((semana) {
                            return DropdownMenuItem<String>(
                              value: semana.codigo,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      semana.etiqueta,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '${semana.fechaInicio} - ${semana.fechaFin}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de días
                Expanded(
                  child: _planActual == null
                      ? const Center(
                          child: Text('No hay plan disponible'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: diasSemana.length,
                          itemBuilder: (context, index) {
                            final dia = diasSemana[index];
                            final diaConfig = _planActual!.dias[dia];
                            final estaConfigurado = diaConfig?.configurado ?? false;
                            final esGestionCliente = diaConfig?.tipo == 'gestion_cliente';
                            final cantidadClientes = esGestionCliente 
                                ? (diaConfig?.clienteIds.length ?? 0)
                                : 0;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: estaConfigurado ? 3 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: estaConfigurado
                                      ? Colors.green.shade200
                                      : Colors.grey.shade200,
                                  width: estaConfigurado ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _irAProgramarDia(dia),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: estaConfigurado
                                              ? Colors.green.shade50
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (index + 1).toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: estaConfigurado
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dia,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF2C3E50),
                                              ),
                                            ),
                                            if (estaConfigurado) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                diaConfig?.objetivoNombre ?? 'Sin objetivo',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              if (esGestionCliente && cantidadClientes > 0)
                                                Text(
                                                  '$cantidadClientes clientes asignados',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                            ] else
                                              Text(
                                                'Sin configurar',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.orange.shade700,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        estaConfigurado
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: estaConfigurado
                                            ? Colors.green
                                            : Colors.grey.shade400,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Botón de enviar plan
                if (_planActual != null && _planActual!.estatus == 'borrador')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: _planActual!.estaCompleto ? _enviarPlan : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ENVIAR PLAN',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Modelo auxiliar para las opciones de semana
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