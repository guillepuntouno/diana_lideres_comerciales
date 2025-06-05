// lib/vistas/menu_principal/vista_asignacion_clientes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';

class VistaAsignacionClientes extends StatefulWidget {
  const VistaAsignacionClientes({super.key});

  @override
  State<VistaAsignacionClientes> createState() =>
      _VistaAsignacionClientesState();
}

class _VistaAsignacionClientesState extends State<VistaAsignacionClientes> {
  final _formKey = GlobalKey<FormState>();
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();

  // Parámetros recibidos
  late String diaAsignado;
  late String rutaSeleccionada;
  late String centroDistribucion;
  late String semana;
  late String liderId;

  // Estado del formulario
  String? asesorSeleccionado;
  List<Map<String, String>> asesoresDisponibles = [];
  List<Map<String, dynamic>> clientesDisponibles = [];
  Map<String, bool> clientesSeleccionados = {};
  bool todosSeleccionados = false;

  // Lista de asignaciones temporales (antes de guardar)
  List<AsignacionTemporal> asignacionesTemporales = [];

  int _currentIndex = 1;
  bool _cargando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    diaAsignado = args['dia'] ?? '';
    rutaSeleccionada = args['ruta'] ?? '';
    centroDistribucion = args['centro'] ?? '';
    semana = args['semana'] ?? '';
    liderId = args['liderId'] ?? '';

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    // Simular carga de datos - En producción vendría de una API o base de datos
    await Future.delayed(const Duration(seconds: 1));

    // Cargar asesores del centro de distribución
    asesoresDisponibles = _obtenerAsesoresPorCentro(centroDistribucion);

    // Cargar clientes de la ruta
    clientesDisponibles = _obtenerClientesPorRuta(rutaSeleccionada);

    // Inicializar checkboxes
    for (var cliente in clientesDisponibles) {
      clientesSeleccionados[cliente['id']] = false;
    }

    setState(() => _cargando = false);
  }

  List<Map<String, String>> _obtenerAsesoresPorCentro(String centro) {
    // Simulación - En producción vendría de base de datos
    final asesoresPorCentro = {
      'Centro de Servicio': [
        {'id': 'ASE001', 'nombre': 'Néstor Alfonso Mejía Flores'},
        {'id': 'ASE002', 'nombre': 'Fran Lima'},
        {'id': 'ASE003', 'nombre': 'Francisco Alejandro Lara'},
      ],
      'Distribuidora Santa Ana': [
        {'id': 'ASE004', 'nombre': 'Juan Carlos Rodríguez'},
        {'id': 'ASE005', 'nombre': 'María Fernanda López'},
      ],
      'Distribuidora San Miguel': [
        {'id': 'ASE006', 'nombre': 'Carlos Alberto Martínez'},
        {'id': 'ASE007', 'nombre': 'Ana Patricia Gómez'},
      ],
      'Distribuidora Sonsonate': [
        {'id': 'ASE008', 'nombre': 'Roberto Hernández'},
        {'id': 'ASE009', 'nombre': 'Claudia Ramírez'},
        {'id': 'ASE010', 'nombre': 'Miguel Ángel Castro'},
      ],
    };

    return asesoresPorCentro[centro] ?? [];
  }

  List<Map<String, dynamic>> _obtenerClientesPorRuta(String ruta) {
    // Simulación - En producción vendría de base de datos
    return List.generate(
      25,
      (index) => {
        'id': 'CLI${(1000 + index).toString()}',
        'nombre': 'Cliente ${index + 1} - ${_generarNombreAleatorio()}',
        'direccion': 'Av. Principal ${index + 100}, Local ${index + 1}',
        'tipo': index % 3 == 0 ? 'mayoreo' : 'detalle',
      },
    );
  }

  String _generarNombreAleatorio() {
    final nombres = [
      'Tienda La Bendición',
      'Abarrotes El Progreso',
      'Mini Super Express',
      'Comercial Santa Fe',
      'Tienda y Librería ABC',
      'Supermercado Central',
      'Abarrotes Don Juan',
      'Tienda La Esperanza',
      'Mini Market 24/7',
    ];
    return nombres[DateTime.now().millisecond % nombres.length];
  }

  void _seleccionarTodos(bool? value) {
    setState(() {
      todosSeleccionados = value ?? false;
      clientesSeleccionados.updateAll((key, _) => todosSeleccionados);
    });
  }

  void _agregarAsignacion() {
    if (asesorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un asesor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final clientesAsignados =
        clientesSeleccionados.entries
            .where((entry) => entry.value)
            .map(
              (entry) =>
                  clientesDisponibles.firstWhere((c) => c['id'] == entry.key),
            )
            .toList();

    if (clientesAsignados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione al menos un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Buscar el asesor seleccionado
    final asesor = asesoresDisponibles.firstWhere(
      (a) => a['id'] == asesorSeleccionado,
    );

    // Verificar si el asesor ya tiene asignación para este día
    final yaAsignado = asignacionesTemporales.any(
      (a) => a.asesorId == asesorSeleccionado,
    );

    if (yaAsignado) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Asesor ya asignado'),
              content: Text(
                '${asesor['nombre']} ya tiene una asignación para el $diaAsignado',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
      return;
    }

    // Agregar la asignación temporal
    setState(() {
      asignacionesTemporales.add(
        AsignacionTemporal(
          asesorId: asesorSeleccionado!,
          asesorNombre: asesor['nombre']!,
          clientes: clientesAsignados,
        ),
      );

      // Limpiar selección
      asesorSeleccionado = null;
      clientesSeleccionados.updateAll((key, value) => false);
      todosSeleccionados = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Asignación agregada para ${asesor['nombre']}'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _eliminarAsignacion(int index) {
    setState(() {
      asignacionesTemporales.removeAt(index);
    });
  }

  Future<void> _guardarTodasLasAsignaciones() async {
    if (asignacionesTemporales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay asignaciones para guardar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación con resumen
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar asignaciones'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se guardarán ${asignacionesTemporales.length} asignaciones para el $diaAsignado:',
                  ),
                  const SizedBox(height: 12),
                  ...asignacionesTemporales.map(
                    (asignacion) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• ${asignacion.asesorNombre}: ${asignacion.clientes.length} clientes',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
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
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    // Guardar en el plan de trabajo
    try {
      final plan = await _planServicio.obtenerPlanTrabajo(semana, liderId);

      if (plan != null && plan.dias.containsKey(diaAsignado)) {
        final diaTrabajo = plan.dias[diaAsignado]!;

        // Convertir asignaciones temporales a modelo
        for (var asignacion in asignacionesTemporales) {
          for (var cliente in asignacion.clientes) {
            diaTrabajo.clientesAsignados.add(
              ClienteAsignadoModelo(
                clienteId: cliente['id'],
                clienteNombre: cliente['nombre'],
                clienteDireccion: cliente['direccion'],
                clienteTipo: cliente['tipo'],
              ),
            );
          }
        }

        // Actualizar el plan
        await _planServicio.actualizarDiaTrabajo(
          semana,
          liderId,
          diaAsignado,
          diaTrabajo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asignaciones guardadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
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
              Text('Cargando datos...'),
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
        title: Text(
          'Asignación de Clientes',
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
            // Información de contexto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDE1327).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDE1327).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFDE1327)),
                      const SizedBox(width: 8),
                      Text(
                        'Información de la asignación',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C2120),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Día: $diaAsignado',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    'Ruta: $rutaSeleccionada',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    'Centro: $centroDistribucion',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Formulario de asignación
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
                  Text(
                    'Asesor de venta:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'SELECCIONE UN ASESOR',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    value: asesorSeleccionado,
                    items:
                        asesoresDisponibles
                            .where(
                              (asesor) =>
                                  !asignacionesTemporales.any(
                                    (a) => a.asesorId == asesor['id'],
                                  ),
                            )
                            .map(
                              (asesor) => DropdownMenuItem(
                                value: asesor['id'],
                                child: Text(
                                  asesor['nombre']!,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        asesorSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Clientes disponibles:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Opción de seleccionar todos
                  CheckboxListTile(
                    title: Text(
                      'Seleccionar todos los clientes del día',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDE1327),
                      ),
                    ),
                    value: todosSeleccionados,
                    onChanged: _seleccionarTodos,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFFDE1327),
                  ),

                  const Divider(),

                  // Lista de clientes
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: clientesDisponibles.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cliente = clientesDisponibles[index];
                        return CheckboxListTile(
                          title: Text(
                            cliente['nombre'],
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${cliente['direccion']} • ${cliente['tipo'].toUpperCase()}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          value: clientesSeleccionados[cliente['id']],
                          onChanged: (value) {
                            setState(() {
                              clientesSeleccionados[cliente['id']] =
                                  value ?? false;
                              // Actualizar estado de "todos seleccionados"
                              todosSeleccionados = clientesSeleccionados.values
                                  .every((v) => v);
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFFDE1327),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón agregar asignación
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _agregarAsignacion,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'AGREGAR ASIGNACIÓN',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBD59),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de asignaciones temporales
            if (asignacionesTemporales.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Resumen de asignaciones',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C2120),
                ),
              ),
              const SizedBox(height: 12),
              ...asignacionesTemporales.asMap().entries.map((entry) {
                final index = entry.key;
                final asignacion = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFDE1327),
                      child: Text(
                        asignacion.asesorNombre.substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      asignacion.asesorNombre,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${asignacion.clientes.length} clientes asignados',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarAsignacion(index),
                    ),
                  ),
                );
              }),
            ],

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
                    onPressed:
                        asignacionesTemporales.isNotEmpty
                            ? _guardarTodasLasAsignaciones
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'ENVIAR',
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

// Clase auxiliar para manejar las asignaciones temporales
class AsignacionTemporal {
  final String asesorId;
  final String asesorNombre;
  final List<Map<String, dynamic>> clientes;

  AsignacionTemporal({
    required this.asesorId,
    required this.asesorNombre,
    required this.clientes,
  });
}
