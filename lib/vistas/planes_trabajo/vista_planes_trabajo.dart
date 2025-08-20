// lib/vistas/planes_trabajo/vista_planes_trabajo.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:diana_lc_front/shared/modelos/plan_trabajo_modelo.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/servicios/plan_trabajo_servicio.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';
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
    final totalActividades = _calcularTotalActividades(plan);
    final totalClientes = _calcularTotalClientes(plan);

    return Card(
      elevation: esActual ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esActual
            ? const BorderSide(color: Color(0xFFDE1327), width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.centerLeft,
        title: Text(
          plan.semana,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2120),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildInfoRow('Periodo:', '${plan.fechaInicio} - ${plan.fechaFin}'),
            const SizedBox(height: 4),
            _buildInfoRow('Días trabajados:', '${plan.diasConfigurados}/6'),
          ],
        ),
        children: [
          // Metadata del plan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información del Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('ID:', plan.id),
                const SizedBox(height: 4),
                _buildInfoRow('Líder:', plan.liderNombre),
                const SizedBox(height: 4),
                _buildInfoRow('Centro:', plan.centroDistribucion),
                const SizedBox(height: 4),
                _buildInfoRow('Total actividades:', totalActividades.toString()),
                const SizedBox(height: 4),
                _buildInfoRow('Total clientes:', totalClientes.toString()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Resumen por días
          Text(
            'Resumen Semanal',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 12),
          ..._buildDailyActivitySummary(plan),
        ],
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

  int _calcularTotalActividades(PlanTrabajoUnificadoHive plan) {
    int total = 0;
    plan.dias.forEach((_, dia) {
      if (dia.configurado) {
        if (dia.tipo == 'administrativo' || dia.tipo == 'mixto') {
          if (dia.tipoActividadAdministrativa != null && dia.tipoActividadAdministrativa!.isNotEmpty) {
            try {
              if (dia.tipoActividadAdministrativa!.startsWith('[')) {
                final actividades = jsonDecode(dia.tipoActividadAdministrativa!);
                total += (actividades as List).length;
              } else {
                total += 1;
              }
            } catch (e) {
              total += 1;
            }
          }
        }
      }
    });
    return total;
  }

  List<Widget> _buildDailyActivitySummary(PlanTrabajoUnificadoHive plan) {
    final diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return diasSemana.map((nombreDia) {
      final dia = plan.dias[nombreDia];
      if (dia == null || !dia.configurado) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombreDia,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Text(
                'Sin configurar',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }

      // Contar actividades administrativas
      int actividadesAdmin = 0;
      if (dia.tipo == 'administrativo' || dia.tipo == 'mixto') {
        if (dia.tipoActividadAdministrativa != null && dia.tipoActividadAdministrativa!.isNotEmpty) {
          try {
            if (dia.tipoActividadAdministrativa!.startsWith('[')) {
              final actividades = jsonDecode(dia.tipoActividadAdministrativa!);
              actividadesAdmin = (actividades as List).length;
            } else {
              actividadesAdmin = 1;
            }
          } catch (e) {
            actividadesAdmin = 1;
          }
        }
      }

      // Contar clientes
      int clientesCount = 0;
      if (dia.tipo == 'gestion_cliente' || dia.tipo == 'mixto') {
        clientesCount = dia.clienteIds.length;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombreDia,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTipoColor(dia.tipo),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTipoTexto(dia.tipo),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (actividadesAdmin > 0) ...[
                  Icon(
                    Icons.assignment_turned_in,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$actividadesAdmin actividad${actividadesAdmin > 1 ? 'es' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                  if (clientesCount > 0) ...[
                    const SizedBox(width: 16),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 16),
                  ],
                ],
                if (clientesCount > 0) ...[
                  Icon(
                    Icons.people,
                    color: Colors.orange.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$clientesCount cliente${clientesCount > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'administrativo':
        return Colors.blue;
      case 'gestion_cliente':
        return Colors.orange;
      case 'mixto':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTipoTexto(String tipo) {
    switch (tipo) {
      case 'administrativo':
        return 'ADMIN';
      case 'gestion_cliente':
        return 'CLIENTES';
      case 'mixto':
        return 'MIXTO';
      default:
        return 'OTRO';
    }
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
