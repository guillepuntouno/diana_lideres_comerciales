// lib/vistas/menu_principal/vista_indicadores_gestion.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../modelos/indicador_gestion_modelo.dart';
import '../../modelos/plan_trabajo_modelo.dart';
import '../../servicios/indicadores_gestion_servicio.dart';
import '../../servicios/sesion_servicio.dart';

class VistaIndicadoresGestion extends StatefulWidget {
  const VistaIndicadoresGestion({super.key});

  @override
  State<VistaIndicadoresGestion> createState() => _VistaIndicadoresGestionState();
}

class _VistaIndicadoresGestionState extends State<VistaIndicadoresGestion> {
  final IndicadoresGestionServicio _indicadoresServicio = IndicadoresGestionServicio();
  
  // Datos recibidos por navegación
  late String dia;
  late String semana;
  late String rutaId;
  late String rutaNombre;
  late String asesor;
  late String centroDistribucion;
  late String planVisitaId;
  late List<ClienteAsignadoModelo> clientesAsignados;
  
  // Estado de la vista
  List<IndicadorGestionModelo> _indicadoresDisponibles = [];
  Map<String, List<String>> _indicadoresSeleccionados = {};
  Map<String, Map<String, String>> _resultadosIndicadores = {}; // clienteId -> indicadorId -> resultado
  Map<String, String> _comentarios = {};
  Map<String, bool> _clientesCompletados = {};
  int _clienteActualIndex = 0;
  bool _cargando = true;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    dia = args['dia'] ?? '';
    semana = args['semana'] ?? '';
    rutaId = args['rutaId'] ?? '';
    rutaNombre = args['rutaNombre'] ?? '';
    asesor = args['asesor'] ?? '';
    centroDistribucion = args['centroDistribucion'] ?? '';
    clientesAsignados = args['clientesAsignados'] ?? [];
    
    // Generar ID del plan
    planVisitaId = '${semana}_${dia}_${rutaId}';
    
    _inicializarDatos();
  }
  
  Future<void> _inicializarDatos() async {
    setState(() => _cargando = true);
    
    try {
      // Obtener datos del asesor activo
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider != null) {
        asesor = lider.nombre;
      }
      
      // Cargar indicadores disponibles
      _indicadoresDisponibles = await _indicadoresServicio.obtenerIndicadores();
      
      // Cargar indicadores guardados previamente
      for (final cliente in clientesAsignados) {
        final indicadorGuardado = await _indicadoresServicio.obtenerIndicadoresCliente(
          cliente.clienteId,
          planVisitaId,
        );
        
        if (indicadorGuardado != null) {
          _indicadoresSeleccionados[cliente.clienteId] = indicadorGuardado.indicadorIds;
          _resultadosIndicadores[cliente.clienteId] = indicadorGuardado.resultados;
          _comentarios[cliente.clienteId] = indicadorGuardado.comentario ?? '';
          _clientesCompletados[cliente.clienteId] = indicadorGuardado.completado;
        } else {
          _indicadoresSeleccionados[cliente.clienteId] = [];
          _resultadosIndicadores[cliente.clienteId] = {};
          _comentarios[cliente.clienteId] = '';
          _clientesCompletados[cliente.clienteId] = false;
        }
      }
    } catch (e) {
      print('Error al inicializar datos: $e');
      _mostrarError('Error al cargar los datos');
    } finally {
      setState(() => _cargando = false);
    }
  }
  
  ClienteAsignadoModelo get _clienteActual => clientesAsignados[_clienteActualIndex];
  
  int get _clientesFinalizados {
    int count = 0;
    for (final cliente in clientesAsignados) {
      if (_indicadoresSeleccionados[cliente.clienteId]?.isNotEmpty ?? false) {
        count++;
      }
    }
    return count;
  }
  
  bool get _puedeAvanzar {
    final indicadores = _indicadoresSeleccionados[_clienteActual.clienteId] ?? [];
    if (indicadores.isEmpty) return false;
    
    // Verificar que todos los indicadores seleccionados tengan resultado
    final resultados = _resultadosIndicadores[_clienteActual.clienteId] ?? {};
    for (final indicadorId in indicadores) {
      final resultado = resultados[indicadorId];
      if (resultado == null || resultado.isEmpty) {
        return false;
      }
    }
    
    return true;
  }
  
  Future<void> _guardarIndicadorCliente() async {
    if (!_puedeAvanzar) return;
    
    try {
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider == null) throw Exception('No hay sesión activa');
      
      final clienteIndicador = ClienteIndicadorModelo(
        planVisitaId: planVisitaId,
        rutaId: rutaId,
        clienteId: _clienteActual.clienteId,
        clienteNombre: _clienteActual.clienteNombre,
        indicadorIds: _indicadoresSeleccionados[_clienteActual.clienteId]!,
        resultados: _resultadosIndicadores[_clienteActual.clienteId] ?? {},
        comentario: _comentarios[_clienteActual.clienteId],
        userId: lider.clave,
        timestamp: DateTime.now(),
        completado: true,
      );
      
      await _indicadoresServicio.guardarIndicadoresCliente(clienteIndicador);
      
      setState(() {
        _clientesCompletados[_clienteActual.clienteId] = true;
      });
      
    } catch (e) {
      print('Error al guardar indicador: $e');
      _mostrarError('Error al guardar los indicadores');
    }
  }
  
  void _navegarSiguienteCliente() async {
    // Guardar el cliente actual
    await _guardarIndicadorCliente();
    
    if (_clienteActualIndex < clientesAsignados.length - 1) {
      setState(() {
        _clienteActualIndex++;
      });
    } else {
      // Es el último cliente, mostrar resumen
      _mostrarResumenFinal();
    }
  }
  
  void _navegarClienteAnterior() {
    if (_clienteActualIndex > 0) {
      setState(() {
        _clienteActualIndex--;
      });
    }
  }
  
  void _mostrarResumenFinal() async {
    final resumen = await _indicadoresServicio.obtenerResumenIndicadores(
      planVisitaId,
      clientesAsignados.map((c) => c.clienteId).toList(),
    );
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen de Indicadores',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C2120),
                          ),
                        ),
                        Text(
                          '$dia - $semana',
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
              const Divider(),
              const SizedBox(height: 20),
              
              // Resumen de clientes
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: resumen.length,
                  itemBuilder: (context, index) {
                    final clienteResumen = resumen[index];
                    final indicadores = clienteResumen['indicadores'] as List<String>;
                    final resultados = clienteResumen['resultados'] as Map<String, String>? ?? {};
                    final comentario = clienteResumen['comentario'] as String?;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    clienteResumen['clienteNombre'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Navegar al cliente específico
                                    setState(() {
                                      _clienteActualIndex = index;
                                    });
                                  },
                                  color: const Color(0xFFDE1327),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Indicadores con resultados
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: indicadores.map((indicadorNombre) {
                                // Buscar el indicador por nombre para obtener el ID
                                final indicador = _indicadoresDisponibles.firstWhere(
                                  (ind) => ind.nombre == indicadorNombre,
                                  orElse: () => IndicadorGestionModelo(
                                    id: '',
                                    nombre: indicadorNombre,
                                    descripcion: '',
                                    tipoResultado: 'numero',
                                  ),
                                );
                                final resultado = resultados[indicador.id] ?? '';
                                final mostrarResultado = resultado.isNotEmpty ? ' - $resultado' : '';
                                final sufijo = indicador.tipoResultado == 'porcentaje' && resultado.isNotEmpty ? '%' : '';
                                
                                return Chip(
                                  label: Text(
                                    '$indicadorNombre$mostrarResultado$sufijo',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: TextStyle(color: Colors.blue.shade700),
                                );
                              }).toList(),
                            ),
                            if (comentario != null && comentario.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.comment,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        comentario,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
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
                    );
                  },
                ),
              ),
              
              // Botones
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _clienteActualIndex = 0; // volver al primer cliente
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Revisar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Cerrar diálogo
                        Navigator.pop(context, true); // Regresar con resultado
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDE1327),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Enviar',
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
  
  void _mostrarAlertaSalir() {
    final clientesSinIndicador = clientesAsignados.length - _clientesFinalizados;
    
    if (clientesSinIndicador > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Indicadores Incompletos'),
            ],
          ),
          content: Text(
            'Faltan $clientesSinIndicador clientes por asignar indicador.\n\n¿Desea salir sin completar?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Salir de la vista
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
  
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
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
              Text('Cargando indicadores...'),
            ],
          ),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        _mostrarAlertaSalir();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
            onPressed: _mostrarAlertaSalir,
          ),
          title: Column(
            children: [
              Text(
                'Indicadores de Gestión',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1C2120),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                '$dia - $rutaNombre',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Cabecera con información
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Información del día
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(Icons.person, 'Asesor', asesor),
                      _buildInfoItem(Icons.business, 'CD', centroDistribucion),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Barra de progreso
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE1327).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFFDE1327),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_clientesFinalizados / ${clientesAsignados.length} Finalizados',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDE1327),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Navegación de clientes
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _clienteActualIndex > 0 ? _navegarClienteAnterior : null,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: const Color(0xFFDE1327),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Cliente ${_clienteActualIndex + 1} de ${clientesAsignados.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _clienteActualIndex < clientesAsignados.length - 1 
                      ? _navegarSiguienteCliente 
                      : null,
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: const Color(0xFFDE1327),
                  ),
                ],
              ),
            ),
            
            // Contenido del cliente actual
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del cliente
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _clienteActual.clienteNombre,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${_clienteActual.clienteId}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_clientesCompletados[_clienteActual.clienteId] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Completado',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (_clienteActual.clienteDireccion.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _clienteActual.clienteDireccion,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Selección de indicadores
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: const Color(0xFFDE1327),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Seleccionar Indicadores',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(mínimo 1)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Lista de indicadores
                            ..._indicadoresDisponibles.map((indicador) {
                              final seleccionados = _indicadoresSeleccionados[_clienteActual.clienteId] ?? [];
                              final estaSeleccionado = seleccionados.contains(indicador.id);
                              final resultados = _resultadosIndicadores[_clienteActual.clienteId] ?? {};
                              final resultado = resultados[indicador.id] ?? '';
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                color: estaSeleccionado 
                                  ? const Color(0xFFDE1327).withOpacity(0.05)
                                  : Colors.grey.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: estaSeleccionado
                                      ? const Color(0xFFDE1327).withOpacity(0.3)
                                      : Colors.transparent,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: estaSeleccionado,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                final lista = List<String>.from(
                                                  _indicadoresSeleccionados[_clienteActual.clienteId] ?? []
                                                );
                                                
                                                if (value == true) {
                                                  lista.add(indicador.id);
                                                  // Inicializar resultado vacío
                                                  if (_resultadosIndicadores[_clienteActual.clienteId] == null) {
                                                    _resultadosIndicadores[_clienteActual.clienteId] = {};
                                                  }
                                                } else {
                                                  lista.remove(indicador.id);
                                                  // Limpiar resultado al deseleccionar
                                                  _resultadosIndicadores[_clienteActual.clienteId]?.remove(indicador.id);
                                                }
                                                
                                                _indicadoresSeleccionados[_clienteActual.clienteId] = lista;
                                              });
                                            },
                                            activeColor: const Color(0xFFDE1327),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  indicador.nombre,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (indicador.descripcion.isNotEmpty)
                                                  Text(
                                                    indicador.descripcion,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Campo de resultado si está seleccionado
                                      if (estaSeleccionado) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const SizedBox(width: 40), // Alineación con el checkbox
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey('${_clienteActual.clienteId}-${indicador.id}'),
                                                initialValue: resultado,
                                                onChanged: (value) {
                                                  setState(() {
                                                    if (_resultadosIndicadores[_clienteActual.clienteId] == null) {
                                                      _resultadosIndicadores[_clienteActual.clienteId] = {};
                                                    }
                                                    _resultadosIndicadores[_clienteActual.clienteId]![indicador.id] = value;
                                                  });
                                                },
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Resultado',
                                                  hintText: indicador.tipoResultado == 'porcentaje' ? 'Ej: 80' : 'Ej: 1500',
                                                  suffix: indicador.tipoResultado == 'porcentaje' 
                                                    ? Text('%', style: GoogleFonts.poppins())
                                                    : null,
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(
                                                      color: const Color(0xFFDE1327),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Campo de comentarios
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.comment,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Comentarios',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(opcional)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: _comentarios[_clienteActual.clienteId],
                              onChanged: (value) {
                                _comentarios[_clienteActual.clienteId] = value;
                              },
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Agregar observaciones sobre el cliente...',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFDE1327).withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _mostrarAlertaSalir,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        disabledForegroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _puedeAvanzar ? _navegarSiguienteCliente : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDE1327),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _clienteActualIndex == clientesAsignados.length - 1
                          ? 'Finalizar'
                          : 'Siguiente',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}