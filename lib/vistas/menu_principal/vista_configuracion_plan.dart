// lib/vistas/menu_principal/vista_configuracion_plan.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';

class VistaProgramacionSemana extends StatefulWidget {
  const VistaProgramacionSemana({super.key});

  @override
  State<VistaProgramacionSemana> createState() =>
      _VistaProgramacionSemanaState();
}

class _VistaProgramacionSemanaState extends State<VistaProgramacionSemana> {
  final List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  PlanTrabajoModelo? _planActual;
  bool _cargando = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _inicializarPlan();
  }

  Future<void> _inicializarPlan() async {
    setState(() => _cargando = true);

    try {
      // Obtener datos del usuario (esto vendría del login/sesión)
      final prefs = await SharedPreferences.getInstance();
      final liderId =
          prefs.getString('usuario_id') ?? 'guillermo.martinez@diana.com.sv';
      final liderNombre =
          prefs.getString('usuario_nombre') ?? 'Guillermo Martinez';
      final centroDistribucion =
          prefs.getString('centro_distribucion') ?? 'Centro de Servicio';

      // Obtener o crear el plan de la semana actual
      _planActual = await _planServicio.obtenerOCrearPlanSemanaActual(
        liderId: liderId,
        liderNombre: liderNombre,
        centroDistribucion: centroDistribucion,
      );

      setState(() => _cargando = false);
    } catch (e) {
      print('Error al inicializar plan: $e');
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

  Future<void> _enviarPlan() async {
    if (_planActual == null) return;

    // Validar que todos los días estén configurados
    bool todosConfigurados = diasSemana.every(
      (dia) =>
          _planActual!.dias.containsKey(dia) &&
          _planActual!.dias[dia]!.objetivo != null,
    );

    if (!todosConfigurados) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Plan Incompleto'),
              content: const Text(
                'Debe configurar todos los días de la semana antes de enviar el plan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
      return;
    }

    // Cambiar estatus y guardar
    _planActual!.estatus = 'programado';
    await _planServicio.guardarPlanTrabajo(_planActual!);

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('¡Éxito!'),
              content: const Text('El plan ha sido enviado correctamente.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra diálogo
                    Navigator.of(context).pop(); // Regresa
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
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
                onPressed: _inicializarPlan,
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
        title: const Text(
          'Crear Plan de Trabajo',
          style: TextStyle(
            color: Color(0xFF1C2120),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
                _buildDato('Semana:', _planActual!.semana),
                const SizedBox(height: 8),
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
                ...diasSemana.map((dia) {
                  final diaConfigurado =
                      _planActual!.dias.containsKey(dia) &&
                      _planActual!.dias[dia]!.objetivo != null;

                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        dia,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1C2120),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle:
                          diaConfigurado
                              ? Text(
                                _planActual!.dias[dia]!.objetivo!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )
                              : null,
                      trailing: Icon(
                        diaConfigurado
                            ? Icons.check_circle
                            : Icons.hourglass_bottom,
                        color: diaConfigurado ? Colors.green : Colors.grey,
                      ),
                      onTap:
                          _planActual!.estatus == 'borrador'
                              ? () async {
                                final resultado = await Navigator.pushNamed(
                                  context,
                                  '/programar_dia',
                                  arguments: {
                                    'dia': dia,
                                    'semana': _planActual!.semana,
                                    'liderId': _planActual!.liderId,
                                  },
                                );

                                if (resultado == true) {
                                  // Recargar el plan para mostrar los cambios
                                  await _inicializarPlan();
                                }
                              }
                              : null,
                    ),
                  );
                }).toList(),
                const SizedBox(height: 32),
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

  Widget _buildDato(String label, String value) {
    return Row(
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
    );
  }
}
