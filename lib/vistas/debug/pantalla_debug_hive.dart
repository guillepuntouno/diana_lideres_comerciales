import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../servicios/hive_service.dart';
import '../../modelos/hive/plan_trabajo_semanal_hive.dart';
import '../../modelos/hive/cliente_hive.dart';
import '../../modelos/hive/objetivo_hive.dart';
import 'dart:convert';

class PantallaDebugHive extends StatefulWidget {
  const PantallaDebugHive({super.key});

  @override
  State<PantallaDebugHive> createState() => _PantallaDebugHiveState();
}

class _PantallaDebugHiveState extends State<PantallaDebugHive> {
  final HiveService _hiveService = HiveService();
  int _selectedIndex = 0;
  
  final List<String> _tabs = [
    'Planes de Trabajo',
    'Clientes',
    'Objetivos',
    'Configuración',
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
              }
            },
            itemBuilder: (context) => [
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
            color: Colors.white,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected 
                                ? const Color(0xFFDE1327) 
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isSelected 
                              ? const Color(0xFFDE1327) 
                              : Colors.grey[600],
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
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
        return _buildClientesTab();
      case 2:
        return _buildObjetivosTab();
      case 3:
        return _buildConfiguracionTab();
      default:
        return const Center(child: Text('Tab no implementado'));
    }
  }

  Widget _buildPlanesTrabajoTab() {
    final box = _hiveService.planesTrabajoSemanalesBox;
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
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              'Plan: ${plan.semana}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Líder: ${plan.liderNombre} (${plan.liderClave})',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(plan.estatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plan.estatus.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(plan.estatus),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!plan.sincronizado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NO SINCRONIZADO',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('ID', plan.id),
                    _buildInfoRow('Centro Dist.', plan.centroDistribucion),
                    _buildInfoRow('Fecha Inicio', plan.fechaInicio),
                    _buildInfoRow('Fecha Fin', plan.fechaFin),
                    _buildInfoRow('Creación', plan.fechaCreacion.toString()),
                    _buildInfoRow('Modificación', plan.fechaModificacion.toString()),
                    const SizedBox(height: 16),
                    Text(
                      'Días Configurados:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plan.dias.entries.map((entry) {
                      final dia = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dia.configurado 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: dia.configurado 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  dia.configurado 
                                      ? Icons.check_circle 
                                      : Icons.radio_button_unchecked,
                                  color: dia.configurado 
                                      ? Colors.green 
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                            if (dia.configurado) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Objetivo: ${dia.objetivoNombre ?? "No definido"}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              if (dia.rutaNombre != null)
                                Text(
                                  'Ruta: ${dia.rutaNombre}',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              if (dia.clienteIds.isNotEmpty)
                                Text(
                                  'Clientes asignados: ${dia.clienteIds.length}',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _mostrarJsonCompleto(plan.toJson()),
                          icon: const Icon(Icons.code),
                          label: Text('Ver JSON'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final confirmar = await _mostrarDialogoConfirmacion(
                              'Eliminar Plan',
                              '¿Estás seguro de que deseas eliminar este plan?',
                            );
                            if (confirmar == true) {
                              await box.delete(plan.id);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Plan eliminado'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
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
      },
    );
  }

  Widget _buildClientesTab() {
    final box = _hiveService.clientesBox;
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
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFDE1327),
              child: Text(
                cliente.nombre.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              cliente.nombre,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${cliente.id}'),
                Text('Ruta: ${cliente.rutaNombre}'),
                if (cliente.tipoNegocio != null)
                  Text('Tipo: ${cliente.tipoNegocio}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _mostrarJsonCompleto(cliente.toJson()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildObjetivosTab() {
    final box = _hiveService.objetivosBox;
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
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFDE1327),
              child: Text(
                objetivo.orden.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              objetivo.nombre,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Tipo: ${objetivo.tipo}'),
          ),
        );
      },
    );
  }

  Widget _buildConfiguracionTab() {
    final syncMetadataBox = _hiveService.syncMetadata;
    final userBox = _hiveService.usersBox;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de Sincronización',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Última sincronización',
                  _hiveService.getLastSyncDate()?.toString() ?? 'Nunca',
                ),
                _buildInfoRow(
                  'Versión de datos',
                  syncMetadataBox.get('dataVersion', defaultValue: {'value': '1.0.0'})['value'] ?? '1.0.0',
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
                  'Datos del Usuario',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Usuarios registrados',
                  '${userBox.length} usuarios',
                ),
                if (userBox.isNotEmpty) ...[
                  _buildInfoRow(
                    'Primer usuario',
                    userBox.values.first.nombreCompleto,
                  ),
                  _buildInfoRow(
                    'Email',
                    userBox.values.first.email,
                  ),
                  _buildInfoRow(
                    'Rol',
                    userBox.values.first.rol,
                  ),
                ],
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
                  'Líder Comercial Actual',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                if (_hiveService.lideresComerciales.isNotEmpty) ...[
                  _buildInfoRow(
                    'Nombre',
                    _hiveService.lideresComerciales.values.first.nombre,
                  ),
                  _buildInfoRow(
                    'Clave',
                    _hiveService.lideresComerciales.values.first.clave,
                  ),
                  _buildInfoRow(
                    'Centro Dist.',
                    _hiveService.lideresComerciales.values.first.centroDistribucion,
                  ),
                  _buildInfoRow(
                    'Rutas',
                    '${_hiveService.lideresComerciales.values.first.rutas.length} rutas',
                  ),
                ] else
                  const Text('No hay líder comercial guardado'),
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
                  'Estadísticas de Almacenamiento',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Planes de trabajo',
                  '${_hiveService.planesTrabajoSemanalesBox.length} registros',
                ),
                _buildInfoRow(
                  'Clientes',
                  '${_hiveService.clientesBox.length} registros',
                ),
                _buildInfoRow(
                  'Objetivos',
                  '${_hiveService.objetivosBox.length} registros',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'enviado':
        return Colors.green;
      case 'borrador':
        return Colors.blue;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion(String titulo, String mensaje) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarJsonCompleto(Map<String, dynamic> json) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Datos JSON',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(json),
                      style: GoogleFonts.robotoMono(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _limpiarTodosLosDatos() async {
    try {
      await _hiveService.planesTrabajoSemanalesBox.clear();
      await _hiveService.clientesBox.clear();
      await _hiveService.objetivosBox.clear();
      
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los datos han sido eliminados'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al limpiar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}