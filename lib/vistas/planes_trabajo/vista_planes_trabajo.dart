// lib/vistas/planes_trabajo/vista_planes_trabajo.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';
import 'package:intl/intl.dart';

class VistaPlanesTrabajo extends StatefulWidget {
  const VistaPlanesTrabajo({super.key});

  @override
  State<VistaPlanesTrabajo> createState() => _VistaPlanesTrabajo();
}

class _VistaPlanesTrabajo extends State<VistaPlanesTrabajo> {
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  List<PlanTrabajoModelo> _planes = [];
  bool _cargando = true;
  int _currentIndex = 1;
  LiderComercial? _liderActual;

  // Para identificar el plan activo (semana actual)
  String? _semanaActual;

  @override
  void initState() {
    super.initState();
    _inicializarVista();
  }

  Future<void> _inicializarVista() async {
    try {
      // Obtener datos del líder desde la sesión
      _liderActual = await SesionServicio.obtenerLiderComercial();

      if (_liderActual == null) {
        throw Exception(
          'No hay sesión activa. Por favor, inicie sesión nuevamente.',
        );
      }

      await _cargarPlanes();
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

  Future<void> _cargarPlanes() async {
    if (_liderActual == null) return;

    setState(() => _cargando = true);

    try {
      // Calcular semana actual
      DateTime ahora = DateTime.now();
      int numeroSemana =
          ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                      DateTime(ahora.year, 1, 1).weekday -
                      1) /
                  7)
              .ceil();
      _semanaActual = 'SEMANA $numeroSemana - ${ahora.year}';

      print('Cargando planes para líder: ${_liderActual!.clave}');

      // Obtener todos los planes del líder
      final planes = await _planServicio.obtenerTodosLosPlanes(
        _liderActual!.clave,
      );

      print('Planes obtenidos: ${planes.length}');

      // Ordenar por semana (más reciente primero)
      planes.sort((a, b) => b.semana.compareTo(a.semana));

      setState(() {
        _planes = planes;
        _cargando = false;
      });

      print('Planes cargados exitosamente: ${_planes.length}');
    } catch (e) {
      print('Error al cargar planes: $e');
      setState(() => _cargando = false);

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

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 2) {
      // TODO: Navegar a perfil
    }
  }

  void _abrirDetallePlan(PlanTrabajoModelo plan) {
    // Permitir abrir cualquier plan para ver los detalles
    if (plan.estatus == 'borrador') {
      // Para borradores, abrir la pantalla de configuración
      Navigator.pushNamed(
        context,
        '/plan_configuracion',
        arguments: {'planExistente': plan},
      );
      return;
    }

    // Para planes enviados, navegar al detalle del plan (ejecución diaria)
    Navigator.pushNamed(
      context,
      '/rutina_diaria',
      arguments: {
        'plan': plan,
        'diaActual': _obtenerDiaActual(),
        'liderId': _liderActual?.clave,
      },
    );
  }

  void _editarPlan(PlanTrabajoModelo plan) {
    Navigator.pushNamed(
      context,
      '/plan_configuracion',
      arguments: {'planExistente': plan},
    ).then((resultado) {
      if (resultado == true) {
        // Recargar planes si hubo cambios
        _cargarPlanes();
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

  Widget _buildPlanCard(PlanTrabajoModelo plan) {
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
                        _buildInfoRow('Días config.:', '${plan.dias.length}/6'),
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
                      if (!plan.sincronizado)
                        Icon(
                          Icons.cloud_off,
                          color: Colors.orange.shade600,
                          size: 16,
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
                  const Spacer(),
                  if (!plan.sincronizado)
                    Text(
                      'Sin sincronizar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),

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
            onPressed: _cargarPlanes,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDE1327).withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDE1327).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planes disponibles para ejecutar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Líder: ${_liderActual!.nombre}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Centro: ${_liderActual!.centroDistribucion}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de planes
          Expanded(
            child:
                _cargando
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFDE1327)),
                          SizedBox(height: 16),
                          Text('Cargando planes de trabajo...'),
                        ],
                      ),
                    )
                    : _planes.isEmpty
                    ? Center(
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
                                  _cargarPlanes();
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
                    )
                    : RefreshIndicator(
                      onRefresh: _cargarPlanes,
                      color: const Color(0xFFDE1327),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _planes.length,
                        itemBuilder: (context, index) {
                          return _buildPlanCard(_planes[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),

      // FAB para crear nuevo plan
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/plan_configuracion').then((resultado) {
            if (resultado == true) {
              _cargarPlanes();
            }
          });
        },
        backgroundColor: const Color(0xFFDE1327),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear nuevo plan',
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
}
