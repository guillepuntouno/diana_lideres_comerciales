import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/plan_trabajo_servicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';

class VistaAsignacionClientes extends StatefulWidget {
  const VistaAsignacionClientes({super.key});

  @override
  State<VistaAsignacionClientes> createState() =>
      _VistaAsignacionClientesState();
}

class _VistaAsignacionClientesState extends State<VistaAsignacionClientes> {
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();

  // Parámetros recibidos
  late String diaAsignado;
  late String rutaSeleccionada;
  late String centroDistribucion;
  late String semana;
  late String liderId;
  bool esEdicion = false;

  // Datos precargados
  LiderComercial? _liderComercial;
  Ruta? _rutaActual;
  String _asesorAsignado = '';
  List<Negocio> _clientesDisponibles = [];
  Map<String, bool> _clientesSeleccionados = {};
  bool _todosSeleccionados = false;

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
    esEdicion = args['esEdicion'] ?? false;

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    try {
      // Cargar datos del líder comercial
      _liderComercial = await SesionServicio.obtenerLiderComercial();

      if (_liderComercial != null) {
        // Encontrar la ruta seleccionada
        _rutaActual = _liderComercial!.rutas.firstWhere(
          (ruta) => ruta.nombre == rutaSeleccionada,
          orElse:
              () => Ruta(
                asesor: 'Asesor no encontrado',
                nombre: rutaSeleccionada,
                negocios: [],
              ),
        );

        // Precargar asesor
        _asesorAsignado = _rutaActual!.asesor;

        // Precargar clientes de la ruta
        _clientesDisponibles = _rutaActual!.negocios;

        // Inicializar selección de clientes
        _clientesSeleccionados = {
          for (var cliente in _clientesDisponibles) cliente.clave: false,
        };

        // Cargar asignaciones existentes si es edición
        await _cargarAsignacionesExistentes();

        print('Datos cargados:');
        print('Ruta: $rutaSeleccionada');
        print('Asesor: $_asesorAsignado');
        print('Clientes disponibles: ${_clientesDisponibles.length}');
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _cargando = false);
  }

  Future<void> _cargarAsignacionesExistentes() async {
    try {
      final plan = await _planServicio.obtenerPlanTrabajo(semana, liderId);

      if (plan != null && plan.dias.containsKey(diaAsignado)) {
        final diaData = plan.dias[diaAsignado]!;

        // Marcar clientes ya asignados
        for (var clienteAsignado in diaData.clientesAsignados) {
          if (_clientesSeleccionados.containsKey(clienteAsignado.clienteId)) {
            _clientesSeleccionados[clienteAsignado.clienteId] = true;
          }
        }

        // Verificar si todos están seleccionados
        _todosSeleccionados = _clientesSeleccionados.values.every((v) => v);

        print(
          'Asignaciones existentes cargadas: ${diaData.clientesAsignados.length} clientes',
        );
      }
    } catch (e) {
      print('Error al cargar asignaciones existentes: $e');
    }
  }

  void _seleccionarTodos(bool? value) {
    setState(() {
      _todosSeleccionados = value ?? false;
      _clientesSeleccionados.updateAll((key, _) => _todosSeleccionados);
    });
  }

  void _onClienteSeleccionado(String clienteId, bool? value) {
    setState(() {
      _clientesSeleccionados[clienteId] = value ?? false;

      // Actualizar estado de "todos seleccionados"
      _todosSeleccionados = _clientesSeleccionados.values.every((v) => v);
    });
  }

  Future<void> _enviarAsignaciones() async {
    // Validar que haya clientes seleccionados
    final clientesSeleccionadosList =
        _clientesSeleccionados.entries
            .where((entry) => entry.value)
            .map(
              (entry) =>
                  _clientesDisponibles.firstWhere((c) => c.clave == entry.key),
            )
            .toList();

    if (clientesSeleccionadosList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione al menos un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await _mostrarDialogoConfirmacion(
      clientesSeleccionadosList,
    );
    if (confirmar != true) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFDE1327)),
            ),
      );

      // Obtener el plan actual
      final plan = await _planServicio.obtenerPlanTrabajo(semana, liderId);

      if (plan != null && plan.dias.containsKey(diaAsignado)) {
        final diaData = plan.dias[diaAsignado]!;

        // Limpiar asignaciones existentes
        diaData.clientesAsignados.clear();

        // Agregar nuevas asignaciones
        for (var cliente in clientesSeleccionadosList) {
          diaData.clientesAsignados.add(
            ClienteAsignadoModelo(
              clienteId: cliente.clave,
              clienteNombre: cliente.nombre,
              clienteDireccion:
                  'Dirección no disponible', // Los negocios no tienen dirección en el modelo
              clienteTipo:
                  cliente.canal.toLowerCase().contains('detalle')
                      ? 'detalle'
                      : 'mayoreo',
            ),
          );
        }

        // Actualizar el plan en el servidor
        await _planServicio.actualizarDiaTrabajo(
          semana,
          liderId,
          diaAsignado,
          diaData,
        );

        // Cerrar loading
        if (mounted) Navigator.of(context).pop();

        // Mostrar éxito y regresar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${clientesSeleccionadosList.length} clientes asignados correctamente',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar asignaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion(
    List<Negocio> clientesSeleccionados,
  ) {
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
                  // Ícono y título
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE1327).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in,
                      color: Color(0xFFDE1327),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Confirmar Asignación',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C2120),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se asignarán ${clientesSeleccionados.length} clientes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Información de la asignación con diseño mejorado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildConfirmacionRow(
                          Icons.calendar_today,
                          'Día',
                          diaAsignado,
                          const Color(0xFFDE1327),
                        ),
                        const SizedBox(height: 12),
                        _buildConfirmacionRow(
                          Icons.route,
                          'Ruta',
                          rutaSeleccionada,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildConfirmacionRow(
                          Icons.person,
                          'Asesor',
                          _asesorAsignado,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildConfirmacionRow(
                          Icons.business,
                          'Centro',
                          centroDistribucion,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  // Indicador de edición si aplica
                  if (esEdicion) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Modificando plan enviado',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botones mejorados
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
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confirmar',
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

  Widget _buildConfirmacionRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ],
          ),
        ),
      ],
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
              Text('Cargando clientes de la ruta...'),
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
          esEdicion ? 'Editar Asignación' : 'Asignación de Clientes',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1C2120),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información de contexto con datos reales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (esEdicion ? Colors.orange : const Color(0xFFDE1327))
                  .withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (esEdicion ? Colors.orange : const Color(0xFFDE1327))
                    .withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      esEdicion ? Icons.edit : Icons.info_outline,
                      color:
                          esEdicion ? Colors.orange : const Color(0xFFDE1327),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      esEdicion
                          ? 'Modificando asignación existente'
                          : 'Información de la asignación',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Día:', diaAsignado),
                _buildInfoRow('Ruta:', rutaSeleccionada),
                _buildInfoRow('Asesor:', _asesorAsignado),
                _buildInfoRow('Centro:', centroDistribucion),
                _buildInfoRow(
                  'Clientes disponibles:',
                  '${_clientesDisponibles.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección de asignación simplificada
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seleccionar clientes:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE1327).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_clientesSeleccionados.values.where((v) => v).length}/${_clientesDisponibles.length} seleccionados',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDE1327),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Opción de seleccionar todos
                CheckboxListTile(
                  title: Text(
                    'Seleccionar todos los clientes de la ruta',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDE1327),
                    ),
                  ),
                  value: _todosSeleccionados,
                  onChanged: _seleccionarTodos,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFFDE1327),
                ),

                const Divider(),

                // Lista de clientes con datos reales
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _clientesDisponibles.isEmpty
                          ? Container(
                            height: 100,
                            child: Center(
                              child: Text(
                                'No hay clientes disponibles para esta ruta',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _clientesDisponibles.length,
                            separatorBuilder:
                                (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final cliente = _clientesDisponibles[index];
                              return CheckboxListTile(
                                title: Text(
                                  cliente.nombre,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Código: ${cliente.clave}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                cliente.canal
                                                        .toLowerCase()
                                                        .contains('detalle')
                                                    ? Colors.blue.shade100
                                                    : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            cliente.canal,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  cliente.canal
                                                          .toLowerCase()
                                                          .contains('detalle')
                                                      ? Colors.blue.shade700
                                                      : Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Clase ${cliente.clasificacion}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                value:
                                    _clientesSeleccionados[cliente.clave] ??
                                    false,
                                onChanged:
                                    (value) => _onClienteSeleccionado(
                                      cliente.clave,
                                      value,
                                    ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: const Color(0xFFDE1327),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botones de acción simplificados
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
                  onPressed: _enviarAsignaciones,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
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
      ),
    );
  }
}
