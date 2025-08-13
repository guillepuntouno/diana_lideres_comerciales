import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:diana_lc_front/shared/modelos/plan_trabajo_modelo.dart';
import 'package:diana_lc_front/shared/servicios/plan_trabajo_offline_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/servicios/clientes_servicio.dart';
import 'package:diana_lc_front/shared/servicios/rutas_servicio.dart';
import 'package:diana_lc_front/servicios/clientes_locales_service.dart';

class VistaAsignacionClientes extends StatefulWidget {
  const VistaAsignacionClientes({super.key});

  @override
  State<VistaAsignacionClientes> createState() =>
      _VistaAsignacionClientesState();
}

class _VistaAsignacionClientesState extends State<VistaAsignacionClientes> {
  final PlanTrabajoOfflineService _planServicio = PlanTrabajoOfflineService();
  final ClientesServicio _clientesServicio = ClientesServicio();
  final RutasServicio _rutasServicio = RutasServicio();
  final ClientesLocalesService _clientesLocalesService = ClientesLocalesService();

  // Parámetros recibidos
  late String diaAsignado;
  late String rutaSeleccionada;
  late String centroDistribucion;
  late String semana;
  late String liderId;
  late String liderNombre;
  late String codigoDiaVisita;
  late String diaVisitaCod; // Nuevo: DIA_VISITA_COD de la ruta
  late DateTime fechaReal;
  String asesorRecibido = ''; // Asesor recibido desde programar_dia
  bool esEdicion = false;

  // Datos precargados
  LiderComercial? _liderComercial;
  Ruta? _rutaActual;
  String _asesorAsignado = '';
  List<Negocio> _clientesDisponibles = [];
  Map<String, bool> _clientesSeleccionados = {};
  bool _todosSeleccionados = false;
  List<DiaTrabajoModelo> _actividadesExistentes = [];

  int _currentIndex = 0;
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
    liderNombre = args['liderNombre'] ?? '';
    codigoDiaVisita = args['codigoDiaVisita'] ?? '';
    diaVisitaCod = args['diaVisitaCod'] ?? ''; // Recibir DIA_VISITA_COD
    fechaReal = args['fecha'] ?? DateTime.now();
    asesorRecibido = args['asesor'] ?? ''; // Recibir el nombre del asesor
    esEdicion = args['esEdicion'] ?? false;

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    try {
      // Debug: Verificar datos recibidos
      print('🔍 VERIFICACIÓN DE DATOS RECIBIDOS EN ASIGNACIÓN CLIENTES:');
      print('   - Asesor recibido: "$asesorRecibido"');
      print('   - ID de ruta (encabezado): "$rutaSeleccionada"');
      print('   - Líder ID: "$liderId"');
      print('   - Código día visita (interno): "$codigoDiaVisita"');
      print('   - DIA_VISITA_COD (endpoint): "$diaVisitaCod"');
      print('   - Fecha real: $fechaReal');
      print('');
      print('✅ ENDPOINT CORRECTO SERÁ: /rutas/$liderId/$diaVisitaCod/$rutaSeleccionada');
      print('   - Ejemplo: /rutas/176/W01/MORD57');
      
      // Cargar datos del líder comercial
      _liderComercial = await SesionServicio.obtenerLiderComercial();

      if (_liderComercial != null) {
        print('📋 Buscando ruta en ${_liderComercial!.rutas.length} rutas disponibles');
        
        // Encontrar la ruta seleccionada
        _rutaActual = _liderComercial!.rutas.firstWhere(
          (ruta) {
            print('   Comparando: "${ruta.nombre}" vs "$rutaSeleccionada"');
            return ruta.nombre == rutaSeleccionada;
          },
          orElse: () {
            print('⚠️ Ruta no encontrada, usando valores por defecto');
            return Ruta(
              asesor: asesorRecibido.isNotEmpty ? asesorRecibido : 'Asesor no encontrado',
              nombre: rutaSeleccionada,
              negocios: [],
            );
          },
        );

        print('✅ Ruta encontrada:');
        print('   - Nombre: ${_rutaActual!.nombre}');
        print('   - Asesor en ruta: ${_rutaActual!.asesor}');
        
        // Usar el asesor recibido si está disponible, de lo contrario usar el de la ruta
        _asesorAsignado = asesorRecibido.isNotEmpty ? asesorRecibido : _rutaActual!.asesor;
        print('   - Asesor asignado final: $_asesorAsignado');

        // Cargar clientes desde el servicio AWS
        await _cargarClientesDeRuta();

        // Inicializar selección de clientes
        _clientesSeleccionados = {
          for (var cliente in _clientesDisponibles) cliente.clave: false,
        };

        // Cargar asignaciones existentes si es edición
        await _cargarAsignacionesExistentes();
        
        // Cargar todas las actividades del día
        await _cargarActividadesDelDia();

        print('Datos cargados:');
        print('Ruta: $rutaSeleccionada');
        print('Asesor: $_asesorAsignado');
        print('Clientes disponibles: ${_clientesDisponibles.length}');
        print('Actividades existentes: ${_actividadesExistentes.length}');
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

  Future<void> _cargarClientesDeRuta() async {
    try {
      print('🔄 Cargando clientes para ruta: $rutaSeleccionada');

      // Usar el endpoint correcto: /rutas/{liderId}/{diaVisitaCod}/{idRuta}
      print('📋 Parámetros FINALES para obtener clientes:');
      print('   - Líder ID: $liderId');
      print('   - DIA_VISITA_COD: $diaVisitaCod (ej: W01, L01)');
      print('   - ID de ruta: $rutaSeleccionada (ej: MORD57)');
      print('   - URL FINAL: /rutas/$liderId/$diaVisitaCod/$rutaSeleccionada');

      // Cargar clientes usando DIA_VISITA_COD correcto
      final resultado = await _rutasServicio.obtenerClientesPorRutaConJson(
        liderId,                // Código del líder (176)
        diaVisitaCod,          // DIA_VISITA_COD de la ruta (W01, L01, etc.)
        rutaSeleccionada,      // ID de la ruta (MORD57, etc.)
      );

      final clientes = resultado['negocios'] as List<Negocio>;
      final clientesJson = resultado['jsonData'] as List<Map<String, dynamic>>;

      if (clientes.isNotEmpty) {
        _clientesDisponibles = clientes;
        print('✅ Clientes cargados desde AWS: ${_clientesDisponibles.length}');

        // Guardar clientes en Hive para persistencia local
        try {
          await _clientesLocalesService.guardarClientesDesdeJson(
            clientesJson,
            rutaId: rutaSeleccionada,
            rutaNombre: rutaSeleccionada,
            asesorId: _rutaActual?.asesor,
            asesorNombre: _rutaActual?.asesor,
            codigoLider: liderId,
            nombreLider: liderNombre,
            emailLider: null, // El modelo LiderComercial no tiene email
            centroDistribucion: centroDistribucion,
          );
          print('✅ Clientes guardados en almacenamiento local');
        } catch (e) {
          print('⚠️ Error al guardar clientes localmente: $e');
          // No interrumpir el flujo si falla el guardado local
        }

        // Mostrar información del primer cliente para debug
        if (_clientesDisponibles.isNotEmpty) {
          final primerCliente = _clientesDisponibles.first;
          print('🔍 Primer cliente:');
          print('   - Clave: ${primerCliente.clave}');
          print('   - Nombre: ${primerCliente.nombre}');
          print('   - Canal: ${primerCliente.canal}');
          print('   - Clasificación: ${primerCliente.clasificacion}');
          print('   - Dirección: ${primerCliente.direccion}');
          print('   - Subcanal: ${primerCliente.subcanal}');
        }

        // Actualizar la ruta en memoria para mantener los datos
        // IMPORTANTE: Preservar el asesor recibido si está disponible
        _rutaActual = Ruta(
          asesor: _asesorAsignado, // Usar el asesor ya asignado que incluye el recibido
          nombre: _rutaActual!.nombre,
          negocios: _clientesDisponibles,
        );
      } else {
        print('⚠️ No se encontraron clientes para esta ruta');
        _clientesDisponibles = [];
      }
    } catch (e) {
      print('❌ Error al cargar clientes: $e');
      // Mantener lista vacía si hay error
      _clientesDisponibles = [];
    }
  }

  Future<void> _cargarAsignacionesExistentes() async {
    try {
      // Inicializar el servicio offline
      await _planServicio.initialize();

      // Obtener el plan usando el servicio offline
      final plan = await _planServicio.obtenerOCrearPlan(
        semana,
        liderId,
        _liderComercial!,
      );

      if (plan.dias.containsKey(diaAsignado)) {
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

  Future<void> _cargarActividadesDelDia() async {
    try {
      // Inicializar el servicio offline si no lo está
      await _planServicio.initialize();

      // Obtener el plan usando el servicio offline
      final plan = await _planServicio.obtenerOCrearPlan(
        semana,
        liderId,
        _liderComercial!,
      );

      // Limpiar lista de actividades
      _actividadesExistentes.clear();

      // Obtener todos los objetivos configurados para el día
      if (plan.dias.containsKey(diaAsignado)) {
        final diaData = plan.dias[diaAsignado]!;
        
        // Procesar actividades administrativas múltiples
        if ((diaData.objetivo == 'Actividad administrativa' || 
             diaData.objetivo == 'Múltiples objetivos' || 
             diaData.tipo == 'mixto') && 
            diaData.tipoActividad != null) {
          try {
            // Intentar parsear como JSON array
            if (diaData.tipoActividad!.startsWith('[')) {
              final actividades = jsonDecode(diaData.tipoActividad!);
              for (var actividad in actividades) {
                _actividadesExistentes.add(
                  DiaTrabajoModelo(
                    dia: diaAsignado,
                    objetivo: 'Actividad administrativa',
                    tipo: 'administrativo',
                    tipoActividad: actividad['tipo'],
                  ),
                );
              }
            } else {
              // Si es string simple, agregarlo como única actividad
              _actividadesExistentes.add(diaData);
            }
          } catch (e) {
            // Si falla el parseo, agregar como actividad simple
            _actividadesExistentes.add(diaData);
          }
        } 
        // Procesar objetivos de abordaje múltiples
        if (diaData.objetivo == 'Gestión de cliente' || 
            diaData.objetivo == 'Múltiples objetivos' || 
            diaData.tipo == 'mixto' || 
            diaData.tipo == 'gestion_cliente') {
          String? comentarioFinal;
          
          // Si hay objetivos de abordaje múltiples en el comentario
          if (diaData.comentario != null && diaData.comentario!.isNotEmpty) {
            try {
              // Intentar parsear como JSON para múltiples objetivos
              final comentarioData = jsonDecode(diaData.comentario!);
              if (comentarioData is Map && comentarioData.containsKey('objetivos')) {
                final objetivos = List<String>.from(comentarioData['objetivos']);
                comentarioFinal = objetivos.join(', ');
              } else {
                throw Exception('No es un formato de múltiples objetivos');
              }
            } catch (e) {
              // Si no es JSON o falla el parseo, usar el comentario tal cual
              comentarioFinal = diaData.comentario;
            }
          }
          
          // Crear la actividad con el comentario procesado
          _actividadesExistentes.add(
            DiaTrabajoModelo(
              dia: diaAsignado,
              objetivo: diaData.objetivo,
              tipo: diaData.tipo,
              rutaId: diaData.rutaId,
              rutaNombre: diaData.rutaNombre,
              clientesAsignados: diaData.clientesAsignados,
              comentario: comentarioFinal,
            ),
          );
        }
        // Si hay otro tipo de objetivo configurado
        else if (diaData.objetivo != null) {
          _actividadesExistentes.add(diaData);
        }
      }

      print('Actividades del día cargadas: ${_actividadesExistentes.length}');
    } catch (e) {
      print('Error al cargar actividades del día: $e');
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

      // Inicializar el servicio offline si no lo está
      await _planServicio.initialize();

      // Obtener el plan actual usando el servicio offline
      final plan = await _planServicio.obtenerOCrearPlan(
        semana,
        liderId,
        _liderComercial!,
      );

      // Crear el día de trabajo con las asignaciones
      final diaData = DiaTrabajoModelo(
        dia: diaAsignado,
        objetivo:
            'Gestión de cliente', // Objetivo por defecto para asignación de clientes
        tipo: 'gestion_cliente',
        centroDistribucion: centroDistribucion,
        rutaId: rutaSeleccionada,
        rutaNombre: rutaSeleccionada,
        clientesAsignados: [],
      );

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

      // Guardar la configuración del día usando el servicio offline
      await _planServicio.guardarConfiguracionDia(semana, liderId, diaData);

      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar éxito brevemente
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
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navegar a la vista de indicadores de gestión
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          final resultado = await Navigator.pushNamed(
            context,
            '/indicadores_gestion',
            arguments: {
              'dia': diaAsignado,
              'semana': semana,
              'rutaId': rutaSeleccionada,
              'rutaNombre': rutaSeleccionada,
              'asesor': _asesorAsignado,
              'centroDistribucion': centroDistribucion,
              'clientesAsignados': diaData.clientesAsignados,
            },
          );
          
          if (resultado == true && mounted) {
            // Si viene de indicadores con éxito, preguntar si desea agregar otro objetivo
            final bool? agregarOtro = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Asignación completada'),
                  ],
                ),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
                content: Text(
                  '¿Desea agregar otro objetivo para el día $diaAsignado?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'No, finalizar',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sí, agregar otro',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
            
            if (agregarOtro == true && mounted) {
              // Navegar de vuelta a programar día
              Navigator.pushReplacementNamed(
                context,
                '/programar_dia',
                arguments: {
                  'dia': diaAsignado,
                  'semana': semana,
                  'liderId': liderId,
                  'esEdicion': esEdicion,
                  'fecha': fechaReal,
                },
              );
            } else if (mounted) {
              Navigator.pop(context, true);
            }
          } else if (mounted) {
            // Si canceló en indicadores, volver atrás
            Navigator.pop(context);
          }
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
          
          // Mostrar actividades ya programadas si existen
          if (_actividadesExistentes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Actividades ya programadas para $diaAsignado:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C2120),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._actividadesExistentes.map((actividad) {
                    String descripcion = '';
                    if (actividad.objetivo == 'Actividad administrativa') {
                      descripcion = '${actividad.objetivo}: ${actividad.tipoActividad ?? 'N/A'}';
                    } else if (actividad.objetivo == 'Gestión de cliente') {
                      descripcion = 'Abordaje de ruta: ${actividad.comentario ?? 'Sin especificar'}';
                      if (actividad.clientesAsignados.isNotEmpty) {
                        descripcion += ' (${actividad.clientesAsignados.length} clientes)';
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              descripcion,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          
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
                      'Seleccionar clientes FOCO :',
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
                    'Seleccionar todos.',
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
                    'GUARDAR',
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
          Expanded(
            flex: 3,  // La etiqueta ocupa 3/5 del ancho
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
            flex: 2,  // El valor ocupa 2/5 del ancho
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF1C2120),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
