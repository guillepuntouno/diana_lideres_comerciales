import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';

class VistaProgramarDia extends StatefulWidget {
  const VistaProgramarDia({super.key});

  @override
  State<VistaProgramarDia> createState() => _VistaProgramarDiaState();
}

class _VistaProgramarDiaState extends State<VistaProgramarDia> {
  final _formKey = GlobalKey<FormState>();
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();

  // Variables de estado
  late String diaSeleccionado;
  late String semana;
  late String liderId;
  String? _objetivoSeleccionado;
  String? _centroSeleccionado;
  String? _rutaSeleccionada;

  // Listas de opciones
  final List<String> _objetivos = [
    'Gestión de cliente',
    'Actividad administrativa',
  ];

  final List<String> _centros = [
    'Centro de Servicio',
    'Distribuidora Santa Ana',
    'Distribuidora San Miguel',
    'Distribuidora Sonsonate',
  ];

  final Map<String, List<String>> _rutasPorCentro = {
    'Centro de Servicio': ['RUTAS01', 'RUTAS02', 'RUTAS03'],
    'Distribuidora Santa Ana': ['RUTAS04', 'RUTAS05'],
    'Distribuidora San Miguel': ['RUTAS06', 'RUTAS07'],
    'Distribuidora Sonsonate': ['RUTAS08', 'RUTAS09', 'RUTAS10'],
  };

  List<String> _rutasDisponibles = [];
  int _currentIndex = 1; // Rutinas seleccionado

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    diaSeleccionado = args['dia'] as String;
    semana = args['semana'] as String;
    liderId = args['liderId'] as String;

    // Cargar datos existentes si los hay
    _cargarDatosExistentes();
  }

  Future<void> _cargarDatosExistentes() async {
    final plan = await _planServicio.obtenerPlanTrabajo(semana, liderId);
    if (plan != null && plan.dias.containsKey(diaSeleccionado)) {
      final diaData = plan.dias[diaSeleccionado]!;
      setState(() {
        _objetivoSeleccionado = diaData.objetivo;
        _centroSeleccionado = diaData.centroDistribucion;
        _rutaSeleccionada = diaData.rutaId;
        if (_centroSeleccionado != null) {
          _rutasDisponibles = _rutasPorCentro[_centroSeleccionado] ?? [];
        }
      });
    }
  }

  Future<void> _guardarConfiguracion() async {
    // Crear el modelo del día
    final diaTrabajo = DiaTrabajoModelo(
      dia: diaSeleccionado,
      objetivo: _objetivoSeleccionado,
      tipo:
          _objetivoSeleccionado == 'Gestión de cliente'
              ? 'gestion_cliente'
              : 'administrativo',
      centroDistribucion: _centroSeleccionado,
      rutaId: _rutaSeleccionada,
      rutaNombre: _rutaSeleccionada, // Por ahora usamos el mismo valor
    );

    // Actualizar el día en el plan
    await _planServicio.actualizarDiaTrabajo(
      semana,
      liderId,
      diaSeleccionado,
      diaTrabajo,
    );

    if (context.mounted &&
        _objetivoSeleccionado == 'Actividad administrativa') {
      // Mostrar confirmación visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('$diaSeleccionado configurado correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navegación según el índice
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 2:
        // TODO: Implementar navegación a perfil
        break;
    }
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
          'Programar Día',
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
                color: const Color(0xFFFFBD59).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFBD59), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFDE1327),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Configurando: $diaSeleccionado',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
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
                                  objetivo,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _objetivoSeleccionado = value;
                        _centroSeleccionado = null;
                        _rutaSeleccionada = null;
                        _rutasDisponibles = [];
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor seleccione un objetivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Día asignado (solo lectura)
                  Text(
                    'Día asignado:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    readOnly: true,
                    initialValue: diaSeleccionado,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF1C2120),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  // Campos adicionales para Gestión de cliente
                  if (_objetivoSeleccionado == 'Gestión de cliente') ...[
                    const SizedBox(height: 20),
                    Text(
                      'Centro de distribución:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'SELECCIONE UN CENTRO',
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
                      value: _centroSeleccionado,
                      items:
                          _centros
                              .map(
                                (centro) => DropdownMenuItem(
                                  value: centro,
                                  child: Text(
                                    centro,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _centroSeleccionado = value;
                          _rutaSeleccionada = null;
                          _rutasDisponibles = _rutasPorCentro[value] ?? [];
                        });
                      },
                      validator: (value) {
                        if (_objetivoSeleccionado == 'Gestión de cliente' &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor seleccione un centro';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ruta disponible:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'SELECCIONE UNA RUTA',
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
                                  value: ruta,
                                  child: Text(
                                    ruta,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _rutaSeleccionada = value;
                        });
                      },
                      validator: (value) {
                        if (_objetivoSeleccionado == 'Gestión de cliente' &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor seleccione una ruta';
                        }
                        return null;
                      },
                    ),
                  ],

                  // Mensaje informativo para actividad administrativa
                  if (_objetivoSeleccionado == 'Actividad administrativa') ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Al presionar GUARDAR, se registrará esta actividad administrativa para el $diaSeleccionado',
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
                        // Primero guardar la configuración básica
                        await _guardarConfiguracion();

                        if (_objetivoSeleccionado == 'Gestión de cliente') {
                          // Navegar a asignación de clientes
                          final resultado = await Navigator.pushNamed(
                            context,
                            '/asignacion_clientes',
                            arguments: {
                              'dia': diaSeleccionado,
                              'ruta': _rutaSeleccionada,
                              'centro': _centroSeleccionado,
                              'semana': semana,
                              'liderId': liderId,
                            },
                          );

                          if (resultado == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        } else if (_objetivoSeleccionado ==
                            'Actividad administrativa') {
                          // Ya se guardó en _guardarConfiguracion
                          // Redirigir inmediatamente
                          if (context.mounted) {
                            Navigator.pop(context, true);
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
}
