// lib/vistas/planes_trabajo/vista_planes_trabajo.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';
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

  // Para identificar el plan activo (semana actual)
  String? _semanaActual;

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
  }

  Future<void> _cargarPlanes() async {
    setState(() => _cargando = true);

    try {
      // Obtener ID del usuario (vendría del login)
      final liderId =
          'guillermo.martinez@diana.com.sv'; // TODO: Obtener de sesión

      // Calcular semana actual
      DateTime ahora = DateTime.now();
      int numeroSemana =
          ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                      DateTime(ahora.year, 1, 1).weekday -
                      1) /
                  7)
              .ceil();
      _semanaActual = 'SEMANA $numeroSemana - ${ahora.year}';

      // Obtener todos los planes
      final planes = await _planServicio.obtenerTodosLosPlanes(liderId);

      // Ordenar por semana (más reciente primero)
      planes.sort((a, b) => b.semana.compareTo(a.semana));

      setState(() {
        _planes = planes;
        _cargando = false;
      });
    } catch (e) {
      print('Error al cargar planes: $e');
      setState(() => _cargando = false);
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
        return estatus;
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
    // Solo permitir abrir planes enviados o en ejecución
    if (plan.estatus == 'borrador') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este plan aún está en borrador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar al detalle del plan (ejecución diaria)
    Navigator.pushNamed(
      context,
      '/ejecucion_plan',
      arguments: {'plan': plan, 'diaActual': _obtenerDiaActual()},
    );
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
      ),

      body: Column(
        children: [
          // Título de la sección
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Rutinas disponibles para ejecutar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),

          // Lista de planes
          Expanded(
            child:
                _cargando
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFDE1327),
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/plan_configuracion',
                              );
                            },
                            child: const Text('Crear primer plan'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _planes.length,
                      itemBuilder: (context, index) {
                        final plan = _planes[index];
                        final esActual = plan.semana == _semanaActual;
                        final puedeEjecutar =
                            plan.estatus == 'enviado' && esActual;

                        return Card(
                          elevation: esActual ? 4 : 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                esActual
                                    ? const BorderSide(
                                      color: Color(0xFFDE1327),
                                      width: 2,
                                    )
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
                                  // Encabezado con semana
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plan.semana,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1C2120),
                                        ),
                                      ),
                                      if (puedeEjecutar)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Información del plan
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(
                                              'Fecha inicial:',
                                              plan.fechaInicio,
                                            ),
                                            const SizedBox(height: 4),
                                            _buildInfoRow(
                                              'Fecha final:',
                                              plan.fechaFin,
                                            ),
                                            const SizedBox(height: 4),
                                            _buildInfoRow(
                                              'Líder:',
                                              plan.liderNombre,
                                            ),
                                            const SizedBox(height: 4),
                                            _buildInfoRow(
                                              'Ruta:',
                                              _obtenerRutasPlan(plan),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Icono de búsqueda/detalle
                                      IconButton(
                                        onPressed:
                                            () => _abrirDetallePlan(plan),
                                        icon: const Icon(
                                          Icons.search,
                                          color: Color(0xFFDE1327),
                                          size: 28,
                                        ),
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

                                  // Botón Ver más... solo para planes ejecutables
                                  if (puedeEjecutar) ...[
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed:
                                            () => _abrirDetallePlan(plan),
                                        child: Text(
                                          'Ver más...',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFFDE1327),
                                            fontWeight: FontWeight.w600,
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
                      },
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

  String _obtenerRutasPlan(PlanTrabajoModelo plan) {
    // Obtener rutas únicas de los días configurados
    final rutas =
        plan.dias.values
            .where((dia) => dia.rutaId != null)
            .map((dia) => dia.rutaId!)
            .toSet()
            .toList();

    if (rutas.isEmpty) return 'Sin rutas asignadas';
    if (rutas.length == 1) return rutas.first;
    return '${rutas.first} (+${rutas.length - 1} más)';
  }
}
