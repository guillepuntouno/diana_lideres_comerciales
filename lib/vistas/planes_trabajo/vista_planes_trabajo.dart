// lib/vistas/planes_trabajo/vista_planes_trabajo.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../../servicios/plan_trabajo_servicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../servicios/hive_service.dart';
import '../../modelos/lider_comercial_modelo.dart';
import '../../configuracion/ambiente_config.dart';
import 'package:intl/intl.dart';

class VistaPlanesTrabajo extends StatefulWidget {
  const VistaPlanesTrabajo({super.key});

  @override
  State<VistaPlanesTrabajo> createState() => _VistaPlanesTrabajo();
}

class _VistaPlanesTrabajo extends State<VistaPlanesTrabajo> {
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  bool _cargando = false;
  LiderComercial? _liderActual;
  String? _liderEmail;

  // Para identificar el plan activo (semana actual)
  String? _semanaActual;

  @override
  void initState() {
    super.initState();
    _inicializarVista();
  }
  
  Future<void> _asegurarHiveInicializado() async {
    final hiveService = HiveService();
    if (!hiveService.isInitialized) {
      await hiveService.initialize();
    }
  }

  Future<void> _inicializarVista() async {
    try {
      // Asegurar que Hive esté inicializado
      await _asegurarHiveInicializado();
      
      // Obtener datos del líder desde la sesión
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('usuario');
      
      if (userDataString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        _liderActual = LiderComercial.fromJson(userMap);
        
        // Obtener el correo directamente de los datos del usuario
        _liderEmail = userMap['correo'] ?? userMap['email'] ?? 'No disponible';
      } else {
        // Intentar obtener del líder comercial guardado
        _liderActual = await SesionServicio.obtenerLiderComercial();
        _liderEmail = 'No disponible';
      }

      if (_liderActual == null) {
        throw Exception(
          'No hay sesión activa. Por favor, inicie sesión nuevamente.',
        );
      }

      // Calcular semana actual
      DateTime ahora = DateTime.now();
      int numeroSemana = ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                  DateTime(ahora.year, 1, 1).weekday - 1) / 7).ceil();
      _semanaActual = 'SEMANA $numeroSemana - ${ahora.year}';

      setState(() {});
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

  void _actualizarVista() {
    setState(() {});
  }

  Color _getEstatusColor(String estatus) {
    switch (estatus.toLowerCase()) {
      case 'enviado':
      case 'agendado':
        return Colors.green;
      case 'en_ejecucion':
        return Colors.blue;
      case 'finalizado':
        return Colors.grey;
      case 'borrador':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstatusIcon(String estatus) {
    switch (estatus.toLowerCase()) {
      case 'enviado':
      case 'agendado':
        return Icons.check_circle;
      case 'en_ejecucion':
        return Icons.play_circle_filled;
      case 'finalizado':
        return Icons.check_circle;
      case 'borrador':
        return Icons.edit;
      default:
        return Icons.circle;
    }
  }

  String _getEstatusTexto(String estatus) {
    switch (estatus.toLowerCase()) {
      case 'enviado':
        return 'Agendado';
      case 'en_ejecucion':
        return 'En Ejecución';
      case 'finalizado':
        return 'Finalizado';
      case 'borrador':
        return 'Borrador';
      default:
        return estatus.toUpperCase();
    }
  }


  void _abrirDetallePlan(PlanTrabajoUnificadoHive plan) {
    // Convertir a PlanTrabajoModelo para compatibilidad con las otras pantallas
    final planModelo = PlanTrabajoModelo(
      semana: plan.semana,
      fechaInicio: plan.fechaInicio,
      fechaFin: plan.fechaFin,
      liderId: plan.liderClave,
      liderNombre: plan.liderNombre,
      centroDistribucion: plan.centroDistribucion,
      estatus: plan.estatus,
      sincronizado: plan.sincronizado,
    );
    
    // Convertir días
    plan.dias.forEach((nombreDia, diaHive) {
      if (diaHive.configurado && diaHive.objetivoNombre != null) {
        planModelo.dias[nombreDia] = DiaTrabajoModelo(
          dia: nombreDia,
          objetivo: diaHive.objetivoNombre,
          rutaId: diaHive.rutaId,
          rutaNombre: diaHive.rutaNombre,
          clientesAsignados: diaHive.clienteIds.map((id) => ClienteAsignadoModelo(
            clienteId: id,
            clienteNombre: 'Cliente $id',
            clienteDireccion: '',
            clienteTipo: 'detalle',
          )).toList(),
          tipoActividad: diaHive.tipoActividadAdministrativa,
        );
      }
    });
    
    // Permitir abrir cualquier plan para ver los detalles
    if (plan.estatus == 'borrador') {
      // Para borradores, abrir la pantalla de configuración
      Navigator.pushNamed(
        context,
        '/plan_configuracion',
        arguments: {'planExistente': planModelo},
      );
      return;
    }

    // Para planes enviados, navegar al detalle del plan (ejecución diaria)
    Navigator.pushNamed(
      context,
      '/rutina_diaria',
      arguments: {
        'plan': planModelo,
        'diaActual': _obtenerDiaActual(),
        'liderId': _liderActual?.clave,
      },
    );
  }

  void _editarPlan(PlanTrabajoUnificadoHive plan) {
    // Convertir a PlanTrabajoModelo para compatibilidad
    final planModelo = PlanTrabajoModelo(
      semana: plan.semana,
      fechaInicio: plan.fechaInicio,
      fechaFin: plan.fechaFin,
      liderId: plan.liderClave,
      liderNombre: plan.liderNombre,
      centroDistribucion: plan.centroDistribucion,
      estatus: plan.estatus,
      sincronizado: plan.sincronizado,
    );
    
    Navigator.pushNamed(
      context,
      '/plan_configuracion',
      arguments: {'planExistente': planModelo},
    ).then((resultado) {
      if (resultado == true) {
        // Actualizar vista
        _actualizarVista();
      }
    });
  }

  String _obtenerDiaActual() {
    final diasSemana = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return diasSemana[DateTime.now().weekday];
  }

  Widget _buildPlanCard(PlanTrabajoUnificadoHive plan) {
    final esActual = plan.semana == _semanaActual;
    final puedeEjecutar = plan.estatus == 'enviado' && esActual;
    final esBorrador = plan.estatus == 'borrador';

    return Card(
      elevation: esActual ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            esActual
                ? const BorderSide(color: Color(0xFFDE1327), width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _abrirDetallePlan(plan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con semana y badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.semana,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (puedeEjecutar)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'HOY',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (esActual && !puedeEjecutar)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ACTUAL',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del plan
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Fecha inicial:', plan.fechaInicio),
                        const SizedBox(height: 4),
                        _buildInfoRow('Fecha final:', plan.fechaFin),
                        const SizedBox(height: 4),
                        _buildInfoRow('Líder:', plan.liderNombre),
                        const SizedBox(height: 4),
                        _buildInfoRow('Centro:', plan.centroDistribucion),
                        const SizedBox(height: 4),
                        _buildInfoRow('Días config.:', '${plan.diasConfigurados}/6'),
                        const SizedBox(height: 4),
                        _buildInfoRow('Total clientes:', _calcularTotalClientes(plan).toString()),
                      ],
                    ),
                  ),
                  // Botones de acción
                  Column(
                    children: [
                      if (esBorrador)
                        IconButton(
                          onPressed: () => _editarPlan(plan),
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.orange,
                            size: 24,
                          ),
                          tooltip: 'Editar borrador',
                        )
                      else
                        IconButton(
                          onPressed: () => _abrirDetallePlan(plan),
                          icon: const Icon(
                            Icons.visibility,
                            color: Color(0xFFDE1327),
                            size: 24,
                          ),
                          tooltip: 'Ver rutinas',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Estado del plan
              Row(
                children: [
                  Icon(
                    _getEstatusIcon(plan.estatus),
                    color: _getEstatusColor(plan.estatus),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estatus: ${_getEstatusTexto(plan.estatus)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getEstatusColor(plan.estatus),
                    ),
                  ),
                ],
              ),

              // Mostrar resumen de indicadores si existen
              if (_tieneIndicadores(plan)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.purple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_contarClientesConIndicadores(plan)} clientes con indicadores asignados',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Botón de acción principal
              if (puedeEjecutar || esBorrador) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirDetallePlan(plan),
                    icon: Icon(
                      esBorrador ? Icons.edit : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: Text(
                      esBorrador
                          ? 'Continuar Configuración'
                          : 'Ejecutar Rutinas',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          esBorrador ? Colors.orange : const Color(0xFFDE1327),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
        title: const Text(
          'Planes de Trabajo',
          style: TextStyle(
            color: Color(0xFF1C2120),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1C2120)),
            onPressed: _actualizarVista,
            tooltip: 'Actualizar',
          ),
        ],
      ),

      body: Column(
        children: [
          // Header con información del líder
          if (_liderActual != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDE1327).withOpacity(0.15),
                    const Color(0xFFDE1327).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDE1327).withOpacity(0.1),
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
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE1327),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDE1327).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _liderActual!.nombre.substring(0, 2).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _liderActual!.nombre,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            Text(
                              'Líder Comercial',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Información detallada
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          Icons.badge_outlined,
                          'Clave',
                          _liderActual!.clave,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          Icons.email_outlined,
                          'Correo',
                          _liderEmail ?? 'No disponible',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          Icons.business_outlined,
                          'Centro de Distribución',
                          _liderActual!.centroDistribucion,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          Icons.route_outlined,
                          'Rutas asignadas',
                          '${_liderActual!.rutas.length} rutas',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Lista de planes desde Hive
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado').listenable(),
              builder: (context, Box<PlanTrabajoUnificadoHive> box, widget) {
                // Filtrar planes del líder actual
                final planes = box.values
                    .where((plan) => plan.liderClave == _liderActual?.clave)
                    .toList();
                
                // Ordenar por semana (más reciente primero)
                planes.sort((a, b) => b.semana.compareTo(a.semana));
                
                if (planes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay planes de trabajo',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer plan para comenzar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/plan_configuracion',
                            ).then((resultado) {
                              if (resultado == true) {
                                _actualizarVista();
                              }
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            'Crear Primer Plan',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE1327),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    _actualizarVista();
                  },
                  color: const Color(0xFFDE1327),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: planes.length,
                    itemBuilder: (context, index) {
                      return _buildPlanCard(planes[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // FAB removido según requerimiento

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else if (index == 1) {
            // Mostrar opción de cerrar sesión
            _mostrarOpcionesPerfil(context);
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF1C2120),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFDE1327)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C2120),
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  int _calcularTotalClientes(PlanTrabajoUnificadoHive plan) {
    int total = 0;
    plan.dias.forEach((_, dia) {
      if (dia.tipo == 'gestion_cliente' || dia.tipo == 'mixto') {
        total += dia.clienteIds.length;
      }
    });
    return total;
  }
  
  bool _tieneIndicadores(PlanTrabajoUnificadoHive plan) {
    for (var dia in plan.dias.values) {
      for (var cliente in dia.clientes) {
        if (cliente.indicadorIds != null && cliente.indicadorIds!.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }
  
  int _contarClientesConIndicadores(PlanTrabajoUnificadoHive plan) {
    int contador = 0;
    plan.dias.forEach((_, dia) {
      for (var cliente in dia.clientes) {
        if (cliente.indicadorIds != null && cliente.indicadorIds!.isNotEmpty) {
          contador++;
        }
      }
    });
    return contador;
  }
  
  void _mostrarOpcionesPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!AmbienteConfig.esProduccion) // Mostrar solo en ambientes no productivos
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.blue),
                title: const Text('Debug - Datos Hive'),
                subtitle: Text(
                  'Ambiente: ${AmbienteConfig.nombreAmbiente}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/debug_hive');
                },
              ),
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
}
