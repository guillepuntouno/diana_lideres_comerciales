import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../servicios/hive_service.dart';
import '../../modelos/hive/plan_trabajo_semanal_hive.dart';
import '../../modelos/hive/dia_trabajo_hive.dart';
import '../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../../modelos/hive/cliente_hive.dart';
import '../../modelos/hive/objetivo_hive.dart';
import '../../modelos/hive/visita_cliente_hive.dart';
import '../../modelos/hive/user_hive.dart';
import '../../modelos/hive/lider_comercial_hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../configuracion/ambiente_config.dart';
import '../../servicios/sesion_servicio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaDebugHive extends StatefulWidget {
  const PantallaDebugHive({super.key});

  @override
  State<PantallaDebugHive> createState() => _PantallaDebugHiveState();
}

class _PantallaDebugHiveState extends State<PantallaDebugHive> {
  final HiveService _hiveService = HiveService();
  int _selectedIndex = 0;
  
  final List<String> _tabs = [
    'Planes Trabajo',
    'Planes Unificados (Webservice)',
    'Planes Unificados (Local)',
    'Visitas',
    'Clientes',
    'Objetivos',
    'Config',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFDE1327),
        title: Text(
          'Debug - Datos Hive',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'clear_all') {
                final confirmar = await _mostrarDialogoConfirmacion(
                  'Limpiar todos los datos',
                  '¿Estás seguro de que deseas eliminar todos los datos locales?',
                );
                if (confirmar == true) {
                  await _limpiarTodosLosDatos();
                }
              } else if (value == 'export_all') {
                _exportarTodosLosDatos();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Exportar todos los datos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpiar todos los datos'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _tabs[index],
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? const Color(0xFFDE1327)
                                : Colors.grey[600],
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 3,
                          width: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDE1327)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Contenido
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildPlanesTrabajoTab();
      case 1:
        return _buildPlanesUnificadosTab();
      case 2:
        return _buildPlanesUnificadosLocalTab();
      case 3:
        return _buildVisitasTab();
      case 4:
        return _buildClientesTab();
      case 5:
        return _buildObjetivosTab();
      case 6:
        return _buildConfigTab();
      default:
        return const Center(child: Text('Tab no implementado'));
    }
  }

  Widget _buildPlanesTrabajoTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<PlanTrabajoSemanalHive>('planes_trabajo_semanal').listenable(),
      builder: (context, Box<PlanTrabajoSemanalHive> box, widget) {
        final planes = box.values.toList();
        
        if (planes.isEmpty) {
          return _buildEmptyState('No hay planes de trabajo guardados');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: planes.length,
          itemBuilder: (context, index) {
            final plan = planes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  'Plan Semana ${plan.semana}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Líder: ${plan.liderNombre} - Estado: ${plan.estatus}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarPlanTrabajo(index),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Plan ID', plan.id),
                        _buildInfoRow('Fecha Inicio', plan.fechaInicio),
                        _buildInfoRow('Fecha Fin', plan.fechaFin),
                        _buildInfoRow('Creado', plan.fechaCreacion.toString()),
                        _buildInfoRow('Actualizado', plan.fechaModificacion.toString()),
                        const SizedBox(height: 12),
                        Text(
                          'Días de trabajo: ${plan.dias.length}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        ...plan.dias.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.value.dia}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Clientes: ${entry.value.clienteIds.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlanesUnificadosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Prueba de Endpoints - Planes Unificados',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Utiliza estas tarjetas para probar las operaciones CRUD del API de planes.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tarjeta GET /planes?userId
          GetPlanesCard(),
          
          const SizedBox(height: 16),
          
          // Tarjeta POST /planes
          PostPlanesCard(),
          
          const SizedBox(height: 16),
          
          // Tarjeta PUT /planes/{id}
          PutPlanesCard(),
          
          const SizedBox(height: 16),
          
          // Tarjeta DELETE /planes/{id}
          DeletePlanesCard(),
          
          const SizedBox(height: 16),
          
          // TODO: Sección de sincronización Hive ↔️ API
        ],
      ),
    );
  }

  Widget _buildPlanesUnificadosLocalTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado').listenable(),
      builder: (context, Box<PlanTrabajoUnificadoHive> box, widget) {
        final planes = box.values.toList();
        
        if (planes.isEmpty) {
          return _buildEmptyState('No hay planes unificados locales guardados');
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: planes.length,
            itemBuilder: (context, index) {
              final plan = planes[index];
              return _PlanUnificadoLocalCard(
                plan: plan,
                index: index,
                onDelete: () => _eliminarPlanUnificado(index),
                onUpdate: (updatedPlan) => _actualizarPlanUnificado(index, updatedPlan),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVisitasTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VisitaClienteHive>('visitas_clientes').listenable(),
      builder: (context, Box<VisitaClienteHive> box, widget) {
        final visitas = box.values.toList();
        
        if (visitas.isEmpty) {
          return _buildEmptyState('No hay visitas registradas');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visitas.length,
          itemBuilder: (context, index) {
            final visita = visitas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  'Visita ${visita.clienteNombre}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Fecha: ${visita.fechaCreacion.toString().split(' ')[0]} - Estado: ${visita.estatus}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarVisita(index),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Visita ID', visita.visitaId),
                        _buildInfoRow('Cliente ID', visita.clienteId),
                        _buildInfoRow('Hora Check-in', visita.checkIn.timestamp.toString()),
                        _buildInfoRow('Hora Check-out', visita.checkOut?.timestamp.toString() ?? 'N/A'),
                        _buildInfoRow(
                          'Ubicación Check-in',
                          '${visita.checkIn.ubicacion.latitud}, ${visita.checkIn.ubicacion.longitud}',
                        ),
                        if (visita.checkOut != null)
                          _buildInfoRow(
                            'Ubicación Check-out',
                            '${visita.checkOut!.ubicacion.latitud}, ${visita.checkOut!.ubicacion.longitud}',
                          ),
                        _buildInfoRow('Sincronizado', visita.syncStatus == 'synced' ? 'Sí' : 'No'),
                        _buildInfoRow('Creado', visita.fechaCreacion.toString()),
                        _buildInfoRow('Actualizado', visita.lastUpdated.toString()),
                        if (visita.formularios.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Respuestas del formulario:',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              const JsonEncoder.withIndent('  ')
                                  .convert(visita.formularios),
                              style: GoogleFonts.robotoMono(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClientesTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ClienteHive>('clientes').listenable(),
      builder: (context, Box<ClienteHive> box, widget) {
        final clientes = box.values.toList();
        
        if (clientes.isEmpty) {
          return _buildEmptyState('No hay clientes guardados');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  cliente.nombre,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${cliente.id}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      'Ruta: ${cliente.rutaNombre} - Activo: ${cliente.activo ? "Sí" : "No"}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    if (cliente.direccion != null)
                      Text(
                        'Dirección: ${cliente.direccion}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarCliente(index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildObjetivosTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ObjetivoHive>('objetivos').listenable(),
      builder: (context, Box<ObjetivoHive> box, widget) {
        final objetivos = box.values.toList();
        
        if (objetivos.isEmpty) {
          return _buildEmptyState('No hay objetivos guardados');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: objetivos.length,
          itemBuilder: (context, index) {
            final objetivo = objetivos[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  objetivo.nombre,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${objetivo.id}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      'Tipo: ${objetivo.tipo} - Activo: ${objetivo.activo ? "Sí" : "No"}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      'Orden: ${objetivo.orden} - Modificado: ${objetivo.fechaModificacion.toString().split(' ')[0]}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarObjetivo(index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Usuario',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<UserHive>('users').listenable(),
                    builder: (context, Box<UserHive> box, widget) {
                      if (box.isEmpty) {
                        return Text(
                          'No hay información de usuario guardada',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        );
                      }
                      
                      final user = box.values.first;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('User ID', user.id),
                          _buildInfoRow('Email', user.email),
                          _buildInfoRow('Nombre', user.nombreCompleto),
                          _buildInfoRow('Rol', user.rol),
                          _buildInfoRow('Creado', user.fechaCreacion.toString()),
                          _buildInfoRow('Actualizado', user.lastUpdated.toString()),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _eliminarUsuario(),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              'Eliminar Usuario',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Líder Comercial',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<LiderComercialHive>('lideres_comerciales').listenable(),
                    builder: (context, Box<LiderComercialHive> box, widget) {
                      if (box.isEmpty) {
                        return Text(
                          'No hay información del líder guardada',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        );
                      }
                      
                      final lider = box.values.first;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Líder ID', lider.id),
                          _buildInfoRow('Nombre', lider.nombre),
                          _buildInfoRow('Clave', lider.clave),
                          _buildInfoRow('Centro Distribución', lider.centroDistribucion),
                          _buildInfoRow('País', lider.pais),
                          _buildInfoRow('Rutas', lider.rutas.length.toString()),
                          _buildInfoRow('Sincronizado', lider.syncStatus),
                          _buildInfoRow('Actualizado', lider.lastUpdated.toString()),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _eliminarLider(),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              'Eliminar Líder',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas de Base de Datos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEstadisticas(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    final stats = {
      'Planes de trabajo': Hive.box<PlanTrabajoSemanalHive>('planes_trabajo_semanal').length,
      'Planes unificados': Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado').length,
      'Visitas': Hive.box<VisitaClienteHive>('visitas_clientes').length,
      'Clientes': Hive.box<ClienteHive>('clientes').length,
      'Objetivos': Hive.box<ObjetivoHive>('objetivos').length,
    };

    return Column(
      children: stats.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.value > 0 ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: entry.value > 0 ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<bool?> _mostrarDialogoConfirmacion(String titulo, String mensaje) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          titulo,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          mensaje,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Confirmar',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _limpiarTodosLosDatos() async {
    try {
      await _hiveService.clearAllBoxes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Todos los datos han sido eliminados',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al limpiar datos: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportarTodosLosDatos() {
    // TODO: Implementar exportación de datos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Funcionalidad de exportación en desarrollo',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _eliminarPlanTrabajo(int index) async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Plan de Trabajo',
      '¿Estás seguro de que deseas eliminar este plan?',
    );
    
    if (confirmar == true) {
      await Hive.box<PlanTrabajoSemanalHive>('planes_trabajo_semanal').deleteAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan de trabajo eliminado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarVisita(int index) async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Visita',
      '¿Estás seguro de que deseas eliminar esta visita?',
    );
    
    if (confirmar == true) {
      await Hive.box<VisitaClienteHive>('visitas_clientes').deleteAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visita eliminada',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCliente(int index) async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Cliente',
      '¿Estás seguro de que deseas eliminar este cliente?',
    );
    
    if (confirmar == true) {
      await Hive.box<ClienteHive>('clientes').deleteAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cliente eliminado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarObjetivo(int index) async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Objetivo',
      '¿Estás seguro de que deseas eliminar este objetivo?',
    );
    
    if (confirmar == true) {
      await Hive.box<ObjetivoHive>('objetivos').deleteAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Objetivo eliminado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarUsuario() async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Usuario',
      '¿Estás seguro de que deseas eliminar la información del usuario?',
    );
    
    if (confirmar == true) {
      await Hive.box<UserHive>('users').clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuario eliminado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarLider() async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Líder',
      '¿Estás seguro de que deseas eliminar la información del líder?',
    );
    
    if (confirmar == true) {
      await Hive.box<LiderComercialHive>('lideres_comerciales').clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Líder eliminado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarPlanUnificado(int index) async {
    final confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Plan Unificado',
      '¿Estás seguro de eliminar este plan local? Esta acción no afecta al backend.',
    );
    
    if (confirmar == true) {
      await Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado').deleteAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan unificado eliminado localmente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _actualizarPlanUnificado(int index, PlanTrabajoUnificadoHive planActualizado) async {
    try {
      await Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado').putAt(index, planActualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan unificado actualizado correctamente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar plan: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// -----------------------------------------------------------------------------
// TARJETA PARA PLAN UNIFICADO LOCAL
// -----------------------------------------------------------------------------
class _PlanUnificadoLocalCard extends StatefulWidget {
  final PlanTrabajoUnificadoHive plan;
  final int index;
  final VoidCallback onDelete;
  final Function(PlanTrabajoUnificadoHive) onUpdate;

  const _PlanUnificadoLocalCard({
    required this.plan,
    required this.index,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<_PlanUnificadoLocalCard> createState() => _PlanUnificadoLocalCardState();
}

class _PlanUnificadoLocalCardState extends State<_PlanUnificadoLocalCard> {
  late TextEditingController _jsonController;
  bool _isExpanded = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: _planToJson());
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  String _planToJson() {
    try {
      final planMap = {
        'id': widget.plan.id,
        'liderClave': widget.plan.liderClave,
        'liderNombre': widget.plan.liderNombre,
        'semana': widget.plan.semana,
        'numeroSemana': widget.plan.numeroSemana,
        'anio': widget.plan.anio,
        'centroDistribucion': widget.plan.centroDistribucion,
        'fechaInicio': widget.plan.fechaInicio,
        'fechaFin': widget.plan.fechaFin,
        'estatus': widget.plan.estatus,
        'dias': widget.plan.dias.map((key, value) => MapEntry(key, {
          'dia': value.dia,
          'tipo': value.tipo,
          'objetivoId': value.objetivoId,
          'objetivoNombre': value.objetivoNombre,
          'tipoActividadAdministrativa': value.tipoActividadAdministrativa,
          'rutaId': value.rutaId,
          'rutaNombre': value.rutaNombre,
          'clienteIds': value.clienteIds,
          'clientes': value.clientes.map((cliente) => {
            'clienteId': cliente.clienteId,
            'horaInicio': cliente.horaInicio,
            'horaFin': cliente.horaFin,
            'estatus': cliente.estatus,
          }).toList(),
          'configurado': value.configurado,
        })),
        'sincronizado': widget.plan.sincronizado,
        'fechaCreacion': widget.plan.fechaCreacion.toIso8601String(),
        'fechaModificacion': widget.plan.fechaModificacion.toIso8601String(),
        'fechaUltimaSincronizacion': widget.plan.fechaUltimaSincronizacion?.toIso8601String(),
      };
      return const JsonEncoder.withIndent('  ').convert(planMap);
    } catch (e) {
      return 'Error al convertir a JSON: $e';
    }
  }

  void _guardarCambios() {
    try {
      // Validar JSON
      final jsonData = jsonDecode(_jsonController.text);
      
      // Crear nuevo objeto PlanTrabajoUnificadoHive desde JSON
      // Por simplicidad, mantenemos el objeto original y solo actualizamos la fecha de modificación
      final planActualizado = widget.plan;
      planActualizado.fechaModificacion = DateTime.now();
      
      widget.onUpdate(planActualizado);
      
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JSON inválido: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Plan ID: ${widget.plan.id}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semana ${widget.plan.numeroSemana} - ${widget.plan.estatus}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                Text(
                  '${widget.plan.fechaInicio} al ${widget.plan.fechaFin}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Sincronizado: ${widget.plan.sincronizado ? "Sí" : "No"}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: widget.plan.sincronizado ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[700],
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JSON del Plan:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          if (!_isEditing)
                            TextButton.icon(
                              onPressed: () => setState(() => _isEditing = true),
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(
                                'Editar',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                          if (_isEditing) ...[
                            TextButton.icon(
                              onPressed: _guardarCambios,
                              icon: const Icon(Icons.save, size: 16, color: Colors.green),
                              label: Text(
                                'Guardar',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.green),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _jsonController.text = _planToJson();
                                });
                              },
                              icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                              label: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.red),
                              ),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _jsonController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('JSON copiado al portapapeles'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copiar JSON',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _jsonController,
                      readOnly: !_isEditing,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: 'JSON del plan...',
                        hintStyle: GoogleFonts.robotoMono(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      style: GoogleFonts.robotoMono(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Última actualización: ${widget.plan.fechaModificacion.toString().split('.')[0]}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TARJETA PARA GET /planes?userId
// -----------------------------------------------------------------------------
class GetPlanesCard extends StatefulWidget {
  const GetPlanesCard({super.key});

  @override
  State<GetPlanesCard> createState() => _GetPlanesCardState();
}

class _GetPlanesCardState extends State<GetPlanesCard> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _isTokenVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() async {
    // Cargar token desde sesión
    final sesionService = SesionServicio();
    // Obtener token desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    if (token != null) {
      _tokenController.text = token;
    }

    // Cargar userId desde Hive
    final userBox = Hive.box<UserHive>('users');
    if (userBox.isNotEmpty) {
      final user = userBox.values.first;
      _userIdController.text = user.clave;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  String _construirUrl() {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      return '${AmbienteConfig.baseUrl}/planes?userId={userId}';
    }
    return '${AmbienteConfig.baseUrl}/planes?userId=$userId';
  }

  Future<void> _ejecutarPeticion() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showSnackBar('Por favor ingresa un userId', Colors.orange);
      return;
    }

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showSnackBar('Por favor ingresa el token', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(_construirUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar('✅ GET exitoso', Colors.green);
        _mostrarRespuesta(response);
      } else {
        _showSnackBar(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
          Colors.red,
        );
        _mostrarRespuesta(response);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarRespuesta(http.Response response) {
    final bodyController = TextEditingController(text: _formatearRespuesta(response.body));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Respuesta GET ${response.statusCode}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Headers:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.headers.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Body:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: bodyController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Respuesta copiada al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copiar respuesta',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: bodyController,
                  maxLines: null,
                  readOnly: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                    fillColor: Colors.grey[50],
                    filled: true,
                  ),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearRespuesta(String body) {
    try {
      final json = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GET',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '/planes?userId={userId}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo userId
            Text(
              'User ID:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                hintText: 'Ingresa el userId',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // URL construida
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _construirUrl(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Campo Token
            Row(
              children: [
                Text(
                  'Bearer Token:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isTokenVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isTokenVisible = !_isTokenVisible),
                  tooltip: _isTokenVisible ? 'Ocultar token' : 'Mostrar token',
                ),
              ],
            ),
            TextField(
              controller: _tokenController,
              obscureText: !_isTokenVisible,
              decoration: InputDecoration(
                hintText: 'Ingresa el token JWT',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Botón ejecutar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _ejecutarPeticion,
                icon: const Icon(Icons.send),
                label: Text(
                  'Ejecutar GET',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
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
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TARJETA PARA POST /planes
// -----------------------------------------------------------------------------
class PostPlanesCard extends StatefulWidget {
  const PostPlanesCard({super.key});

  @override
  State<PostPlanesCard> createState() => _PostPlanesCardState();
}

class _PostPlanesCardState extends State<PostPlanesCard> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  bool _isTokenVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() async {
    // Cargar token desde sesión
    final sesionService = SesionServicio();
    // Obtener token desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    if (token != null) {
      _tokenController.text = token;
    }

    // Template de plan inicial
    _jsonController.text = jsonEncode({
      "liderClave": "123456",
      "userId": "123456",
      "semana": {
        "numero": 1,
        "fechaInicio": "2024-01-01",
        "fechaFin": "2024-01-07",
        "estatus": "borrador"
      },
      "diasTrabajo": []
    });

    _formatearJson();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _formatearJson() {
    try {
      final jsonObj = jsonDecode(_jsonController.text);
      setState(() {
        _jsonController.text = const JsonEncoder.withIndent('  ').convert(jsonObj);
      });
    } catch (e) {
      _showSnackBar('JSON inválido: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _ejecutarPeticion() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showSnackBar('Por favor ingresa el token', Colors.orange);
      return;
    }

    // Validar JSON
    try {
      jsonDecode(_jsonController.text);
    } catch (e) {
      _showSnackBar('JSON inválido: ${e.toString()}', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AmbienteConfig.baseUrl}/planes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: _jsonController.text,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackBar('✅ POST exitoso', Colors.green);
        _mostrarRespuesta(response);
      } else {
        _showSnackBar(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
          Colors.red,
        );
        _mostrarRespuesta(response);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarRespuesta(http.Response response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Respuesta POST ${response.statusCode}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Headers:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.headers.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Body:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.body.isEmpty ? '(vacío)' : _formatearRespuesta(response.body),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearRespuesta(String body) {
    try {
      final json = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'POST',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '/planes',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo Token
            Row(
              children: [
                Text(
                  'Bearer Token:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isTokenVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isTokenVisible = !_isTokenVisible),
                  tooltip: _isTokenVisible ? 'Ocultar token' : 'Mostrar token',
                ),
              ],
            ),
            TextField(
              controller: _tokenController,
              obscureText: !_isTokenVisible,
              decoration: InputDecoration(
                hintText: 'Ingresa el token JWT',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // JSON Body
            Row(
              children: [
                Text(
                  'JSON Body:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _formatearJson,
                  icon: const Icon(Icons.format_align_left, size: 16),
                  label: Text(
                    'Formatear',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Ingresa el JSON del plan...',
                  hintStyle: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.robotoMono(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Botón ejecutar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _ejecutarPeticion,
                icon: const Icon(Icons.send),
                label: Text(
                  'Ejecutar POST',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
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
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TARJETA PARA PUT /planes/{id}
// -----------------------------------------------------------------------------
class PutPlanesCard extends StatefulWidget {
  const PutPlanesCard({super.key});

  @override
  State<PutPlanesCard> createState() => _PutPlanesCardState();
}

class _PutPlanesCardState extends State<PutPlanesCard> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _planIdController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  bool _isTokenVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() async {
    // Cargar token desde sesión
    final sesionService = SesionServicio();
    // Obtener token desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    if (token != null) {
      _tokenController.text = token;
    }

    // Template JSON inicial (vacío por defecto)
    _jsonController.text = jsonEncode({
      "semana": {
        "estatus": "publicado"
      }
    });

    _formatearJson();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _planIdController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  String _construirUrl() {
    final planId = _planIdController.text.trim();
    if (planId.isEmpty) {
      return '${AmbienteConfig.baseUrl}/planes/{id}';
    }
    return '${AmbienteConfig.baseUrl}/planes/$planId';
  }

  void _formatearJson() {
    try {
      final jsonObj = jsonDecode(_jsonController.text);
      setState(() {
        _jsonController.text = const JsonEncoder.withIndent('  ').convert(jsonObj);
      });
    } catch (e) {
      _showSnackBar('JSON inválido: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _ejecutarPeticion() async {
    // Validaciones
    final planId = _planIdController.text.trim();
    if (planId.isEmpty) {
      _showSnackBar('Por favor ingresa el Plan ID', Colors.orange);
      return;
    }

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showSnackBar('Por favor ingresa el token', Colors.orange);
      return;
    }

    // Validar JSON
    try {
      jsonDecode(_jsonController.text);
    } catch (e) {
      _showSnackBar('JSON inválido: ${e.toString()}', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse(_construirUrl()),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: _jsonController.text,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackBar('✅ PUT exitoso', Colors.green);
        _mostrarRespuesta(response);
      } else {
        _showSnackBar(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
          Colors.red,
        );
        _mostrarRespuesta(response);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarRespuesta(http.Response response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Respuesta PUT ${response.statusCode}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Headers:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.headers.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Body:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.body.isEmpty ? '(vacío)' : _formatearRespuesta(response.body),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearRespuesta(String body) {
    try {
      final json = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PUT',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '/planes/{id}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo Plan ID
            Text(
              'Plan ID:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _planIdController,
              decoration: InputDecoration(
                hintText: 'Ej: PLAN-1234567890',
                hintStyle: GoogleFonts.robotoMono(fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // URL construida
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _construirUrl(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Campo Token
            Row(
              children: [
                Text(
                  'Bearer Token:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isTokenVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isTokenVisible = !_isTokenVisible),
                  tooltip: _isTokenVisible ? 'Ocultar token' : 'Mostrar token',
                ),
              ],
            ),
            TextField(
              controller: _tokenController,
              obscureText: !_isTokenVisible,
              decoration: InputDecoration(
                hintText: 'Ingresa el token JWT',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // JSON Body
            Row(
              children: [
                Text(
                  'JSON Body:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _formatearJson,
                  icon: const Icon(Icons.format_align_left, size: 16),
                  label: Text(
                    'Formatear',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Ingresa el JSON del plan actualizado...',
                  hintStyle: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.robotoMono(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Botón ejecutar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _ejecutarPeticion,
                icon: const Icon(Icons.send),
                label: Text(
                  'Ejecutar PUT',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
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
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TARJETA PARA DELETE /planes/{id}
// -----------------------------------------------------------------------------
class DeletePlanesCard extends StatefulWidget {
  const DeletePlanesCard({super.key});

  @override
  State<DeletePlanesCard> createState() => _DeletePlanesCardState();
}

class _DeletePlanesCardState extends State<DeletePlanesCard> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _planIdController = TextEditingController();
  bool _isTokenVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() async {
    // Cargar token desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    if (token != null) {
      _tokenController.text = token;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _planIdController.dispose();
    super.dispose();
  }

  String _construirUrl() {
    final planId = _planIdController.text.trim();
    if (planId.isEmpty) {
      return '${AmbienteConfig.baseUrl}/planes/{id}';
    }
    return '${AmbienteConfig.baseUrl}/planes/$planId';
  }

  Future<void> _mostrarConfirmacion() async {
    final planId = _planIdController.text.trim();
    if (planId.isEmpty) {
      _showSnackBar('Por favor ingresa el Plan ID', Colors.orange);
      return;
    }

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showSnackBar('Por favor ingresa el token', Colors.orange);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Seguro que deseas eliminar el plan $planId? Esta acción es irreversible.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Confirmar',
              style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _ejecutarPeticion();
    }
  }

  Future<void> _ejecutarPeticion() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse(_construirUrl()),
        headers: {
          'Authorization': 'Bearer ${_tokenController.text}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar('✅ Plan eliminado exitosamente', Colors.green);
        _mostrarRespuesta(response);
      } else {
        _showSnackBar(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
          Colors.red,
        );
        _mostrarRespuesta(response);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarRespuesta(http.Response response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Respuesta DELETE ${response.statusCode}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Headers:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.headers.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Body:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.body.isEmpty ? '(vacío)' : _formatearRespuesta(response.body),
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearRespuesta(String body) {
    try {
      final json = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DELETE',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '/planes/{id}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Descripción
            Text(
              'Este endpoint elimina un plan unificado existente. Usa el id obtenido desde el método GET.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),

            // Campo Plan ID
            Text(
              'Plan ID:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _planIdController,
              decoration: InputDecoration(
                hintText: 'Ej: PLAN-1234567890',
                hintStyle: GoogleFonts.robotoMono(fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // URL construida
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _construirUrl(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.red[900],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Campo Token
            Row(
              children: [
                Text(
                  'Bearer Token:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isTokenVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isTokenVisible = !_isTokenVisible),
                  tooltip: _isTokenVisible ? 'Ocultar token' : 'Mostrar token',
                ),
              ],
            ),
            TextField(
              controller: _tokenController,
              obscureText: !_isTokenVisible,
              decoration: InputDecoration(
                hintText: 'Ingresa el token JWT',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: GoogleFonts.robotoMono(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Botón ejecutar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _planIdController.text.trim().isEmpty || _tokenController.text.trim().isEmpty) 
                    ? null 
                    : _mostrarConfirmacion,
                icon: const Icon(Icons.delete),
                label: Text(
                  'Ejecutar DELETE',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
