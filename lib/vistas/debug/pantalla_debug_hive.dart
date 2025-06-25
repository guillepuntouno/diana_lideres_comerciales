import 'package:flutter/material.dart';
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
    'Planes Unificados',
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
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  );
                }),
              ),
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
        return _buildVisitasTab();
      case 3:
        return _buildClientesTab();
      case 4:
        return _buildObjetivosTab();
      case 5:
        return _buildConfiguracionTab();
      default:
        return const Center(child: Text('Tab no implementado'));
    }
  }

  Widget _buildPlanesTrabajoTab() {
    try {
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
                    _buildStatusChip(plan.estatus),
                    const SizedBox(width: 8),
                    if (!plan.sincronizado)
                      _buildSyncChip(false),
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
                    _buildInfoRow('Núm. Semana', plan.numeroSemana?.toString() ?? 'N/A'),
                    _buildInfoRow('Año', plan.anio?.toString() ?? 'N/A'),
                    const SizedBox(height: 16),
                    Text(
                      'Días Configurados:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plan.dias.entries.map((entry) => _buildDiaInfo(entry.key, entry.value)),
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
                          onPressed: () => _editarPlan(plan),
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          label: Text(
                            'Editar',
                            style: TextStyle(color: Colors.blue),
                          ),
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
                              _mostrarSnackBar('Plan eliminado', Colors.green);
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
    } catch (e) {
      return _buildEmptyState('Error al cargar planes de trabajo: $e');
    }
  }

  Widget _buildPlanesUnificadosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta GET /planes?userId
        GetPlanesCard(),
        
        const SizedBox(height: 16),
        
        // TODO: Aquí irán las demás tarjetas (POST, PUT, DELETE)
      ],
    );
  }

  Widget _buildVisitasTab() {
    try {
      final box = _hiveService.visitasClientes;
      final visitas = box.values.toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    if (visitas.isEmpty) {
      return _buildEmptyState('No hay visitas guardadas');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visitas.length,
      itemBuilder: (context, index) {
        final visita = visitas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getVisitaStatusColor(visita.estatus),
              child: Icon(
                _getVisitaStatusIcon(visita.estatus),
                color: Colors.white,
              ),
            ),
            title: Text(
              visita.clienteNombre,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Día: ${visita.dia}'),
                Text('Estatus: ${visita.estatus}'),
                if (visita.checkIn != null)
                  Text('Check-in: ${_formatTime(visita.checkIn.timestamp)}'),
                if (visita.checkOut != null)
                  Text('Check-out: ${_formatTime(visita.checkOut!.timestamp)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!visita.requiresSync)
                  Icon(Icons.cloud_done, color: Colors.green, size: 20),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _mostrarJsonCompleto(visita.toJson()),
                ),
              ],
            ),
          ),
        );
      },
    );
    } catch (e) {
      return _buildEmptyState('Error al cargar visitas: $e');
    }
  }

  Widget _buildClientesTab() {
    try {
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
    } catch (e) {
      return _buildEmptyState('Error al cargar clientes: $e');
    }
  }

  Widget _buildObjetivosTab() {
    try {
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
    } catch (e) {
      return _buildEmptyState('Error al cargar objetivos: $e');
    }
  }

  Widget _buildConfiguracionTab() {
    try {
      final syncMetadataBox = _hiveService.syncMetadata;
      final userBox = _hiveService.usersBox;
      final stats = _hiveService.getBoxesStats();

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
                  'Estadísticas de Almacenamiento',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ...stats.entries.map((entry) => 
                  _buildInfoRow(entry.key, '${entry.value} registros')
                ),
                const SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _hiveService.getStorageUsage(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final mb = (snapshot.data! / 1024 / 1024).toStringAsFixed(2);
                      return _buildInfoRow('Uso estimado', '$mb MB');
                    }
                    return _buildInfoRow('Uso estimado', 'Calculando...');
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
                  'Acciones de Mantenimiento',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Limpiar datos de sincronización antiguos
                    final metadata = syncMetadataBox.toMap();
                    int cleaned = 0;
                    metadata.forEach((key, value) {
                      if (key.toString().startsWith('temp_') || 
                          key.toString().startsWith('old_')) {
                        syncMetadataBox.delete(key);
                        cleaned++;
                      }
                    });
                    _mostrarSnackBar('$cleaned registros temporales eliminados', Colors.green);
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Limpiar datos temporales'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Compactar las cajas
                    await Hive.box(HiveService.planTrabajoSemanalBox).compact();
                    await Hive.box(HiveService.clienteBox).compact();
                    await Hive.box(HiveService.visitaClienteBox).compact();
                    _mostrarSnackBar('Bases de datos compactadas', Colors.green);
                  },
                  icon: const Icon(Icons.compress),
                  label: const Text('Compactar bases de datos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    } catch (e) {
      return _buildEmptyState('Error al cargar configuración: $e');
    }
  }

  Widget _buildDiaInfo(String dia, DiaTrabajoHive diaInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: diaInfo.configurado 
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: diaInfo.configurado 
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
                dia,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                diaInfo.configurado 
                    ? Icons.check_circle 
                    : Icons.radio_button_unchecked,
                color: diaInfo.configurado 
                    ? Colors.green 
                    : Colors.grey,
                size: 20,
              ),
            ],
          ),
          if (diaInfo.configurado) ...[
            const SizedBox(height: 4),
            Text(
              'Objetivo: ${diaInfo.objetivoNombre ?? "No definido"}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            if (diaInfo.tipo != null)
              Text(
                'Tipo: ${diaInfo.tipo}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            if (diaInfo.rutaNombre != null)
              Text(
                'Ruta: ${diaInfo.rutaNombre}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            if (diaInfo.tipoActividadAdministrativa != null)
              Text(
                'Actividad: ${diaInfo.tipoActividadAdministrativa}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            if (diaInfo.clienteIds.isNotEmpty)
              Text(
                'Clientes asignados: ${diaInfo.clienteIds.length}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildSyncChip(bool synced) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: synced ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            synced ? Icons.cloud_done : Icons.cloud_off,
            size: 14,
            color: synced ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            synced ? 'SINCRONIZADO' : 'NO SINCRONIZADO',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: synced ? Colors.green : Colors.orange,
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

  Color _getVisitaStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'en_proceso':
        return Colors.blue;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getVisitaStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return Icons.check_circle;
      case 'en_proceso':
        return Icons.access_time;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          // Copiar al portapapeles en web
                          final jsonStr = const JsonEncoder.withIndent('  ').convert(json);
                          // En una app real, usarías clipboard
                          _mostrarSnackBar('JSON copiado (simulado)', Colors.green);
                        },
                        tooltip: 'Copiar JSON',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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

  void _editarPlan(PlanTrabajoSemanalHive plan) {
    final TextEditingController estatusController = TextEditingController(text: plan.estatus);
    final TextEditingController liderNombreController = TextEditingController(text: plan.liderNombre);
    bool sincronizado = plan.sincronizado;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Plan ${plan.semana}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: estatusController,
                decoration: const InputDecoration(
                  labelText: 'Estatus',
                  helperText: 'borrador, enviado, rechazado',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: liderNombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Líder',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Sincronizado'),
                value: sincronizado,
                onChanged: (value) {
                  setState(() {
                    sincronizado = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              plan.estatus = estatusController.text;
              plan.liderNombre = liderNombreController.text;
              plan.sincronizado = sincronizado;
              plan.fechaModificacion = DateTime.now();
              
              await plan.save();
              Navigator.pop(context);
              setState(() {});
              _mostrarSnackBar('Plan actualizado', Colors.green);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _limpiarTodosLosDatos() async {
    try {
      await _hiveService.clearAllBoxes();
      setState(() {});
      _mostrarSnackBar('Todos los datos han sido eliminados', Colors.green);
    } catch (e) {
      _mostrarSnackBar('Error al limpiar datos: $e', Colors.red);
    }
  }

  void _exportarTodosLosDatos() {
    final allData = {
      'exportDate': DateTime.now().toIso8601String(),
      'planes': _hiveService.planesTrabajoSemanalesBox.values.map((p) => p.toJson()).toList(),
      'clientes': _hiveService.clientesBox.values.map((c) => c.toJson()).toList(),
      'objetivos': _hiveService.objetivosBox.values.map((o) => o.toJson()).toList(),
      'visitas': _hiveService.visitasClientes.values.map((v) => v.toJson()).toList(),
    };

    _mostrarJsonCompleto(allData);
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }
}

// Tarjeta para GET /planes?userId
class GetPlanesCard extends StatefulWidget {
  const GetPlanesCard({super.key});

  @override
  State<GetPlanesCard> createState() => _GetPlanesCardState();
}

class _GetPlanesCardState extends State<GetPlanesCard> {
  // Estado
  bool _isLoading = false;
  String? _userId;
  String? _responseData;
  String? _errorMessage;
  bool _showToken = false;
  
  // Controladores
  final TextEditingController _tokenController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUserIdAndToken();
  }
  
  Future<void> _loadUserIdAndToken() async {
    try {
      // Obtener el líder comercial actual
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider != null) {
        setState(() {
          _userId = lider.clave; // CoSEupervisor
        });
      }
      
      // Intentar obtener el token
      final token = await SesionServicio.obtenerToken();
      if (token != null) {
        _tokenController.text = token;
      }
    } catch (e) {
      print('Error cargando datos iniciales: $e');
    }
  }
  
  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String url = '${AmbienteConfig.baseUrl}/planes?userId=${_userId ?? ''}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y descripción
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud_download,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GET /planes?userId',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Este endpoint recupera la lista de planes del líder comercial logeado.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
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
            
            // Campo URL (solo lectura)
            TextField(
              controller: TextEditingController(text: url),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'URL del Endpoint',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // TODO: Implementar copiar al portapapeles
                    _showSnackBar('URL copiada', Colors.green);
                  },
                  tooltip: 'Copiar URL',
                ),
              ),
              style: GoogleFonts.robotoMono(fontSize: 12),
            ),
            
            const SizedBox(height: 16),
            
            // Campo Token
            TextFormField(
              controller: _tokenController,
              obscureText: !_showToken,
              decoration: InputDecoration(
                labelText: 'Token de Autenticación',
                hintText: 'Bearer eyJhbGc...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.security),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showToken ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showToken = !_showToken;
                        });
                      },
                      tooltip: _showToken ? 'Ocultar token' : 'Mostrar token',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadUserIdAndToken,
                      tooltip: 'Recargar token de sesión',
                    ),
                  ],
                ),
              ),
              style: GoogleFonts.robotoMono(fontSize: 12),
            ),
            
            const SizedBox(height: 20),
            
            // Botón Ejecutar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _executeGetRequest,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Cargando...' : 'Ejecutar GET',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Resultado
            if (_responseData != null || _errorMessage != null)
              Container(
                decoration: BoxDecoration(
                  color: _errorMessage != null 
                      ? Colors.red.withOpacity(0.05)
                      : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header del resultado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _errorMessage != null
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage != null
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: _errorMessage != null
                                ? Colors.red
                                : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _errorMessage != null
                                ? 'Error en la petición'
                                : 'Respuesta exitosa (200)',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: _errorMessage != null
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Body del resultado
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red[700],
                          ),
                        ),
                      )
                    else if (_responseData != null)
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _responseData!,
                            style: GoogleFonts.robotoMono(fontSize: 11),
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
  
  Future<void> _executeGetRequest() async {
    // Validar que tenemos userId y token
    if (_userId == null || _userId!.isEmpty) {
      _showSnackBar('Completa userId y token para continuar', Colors.orange);
      return;
    }
    
    if (_tokenController.text.isEmpty) {
      _showSnackBar('Completa userId y token para continuar', Colors.orange);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _responseData = null;
    });
    
    try {
      final url = Uri.parse('${AmbienteConfig.baseUrl}/planes?userId=$_userId');
      final token = _tokenController.text;
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        // Formatear JSON de respuesta
        try {
          final jsonData = jsonDecode(response.body);
          setState(() {
            _responseData = const JsonEncoder.withIndent('  ').convert(jsonData);
            _errorMessage = null;
          });
        } catch (e) {
          setState(() {
            _responseData = response.body;
            _errorMessage = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.reasonPhrase}';
          _responseData = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _responseData = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

// ELIMINADO: Toda la implementación anterior de _PlanUnificadoDebugCard
