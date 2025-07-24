import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/providers/formularios_provider.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/formulario_editor_page.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/widgets/version_dialog.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/widgets/modern_data_table.dart';

class FormularioListPage extends ConsumerStatefulWidget {
  const FormularioListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FormularioListPage> createState() => _FormularioListPageState();
}

class _FormularioListPageState extends ConsumerState<FormularioListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 3; // Fecha actualización por defecto
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formulariosState = ref.watch(formulariosProvider);

    return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Administración de Formularios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C2120),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
            ),
            body: Column(
              children: [
                // Barra de búsqueda y filtros
                _buildModernSearchBar(context),
                
                // Tabla de datos
                Expanded(
                  child: formulariosState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : formulariosState.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    formulariosState.error!,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reintentar'),
                                    onPressed: () => ref.read(formulariosProvider.notifier).cargarFormularios(),
                                  ),
                                ],
                              ),
                            )
                          : _buildDataTable(context, formulariosState),
                ),
              ],
            ),
            floatingActionButton: Container(
              height: 56,
              margin: const EdgeInsets.only(bottom: 16, right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _navegarACrear(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nuevo Formulario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE1327),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFFDE1327).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
          );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o versión...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                ref.read(formulariosProvider.notifier).buscar(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Filtro por estado
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<bool?>(
              value: ref.watch(formulariosProvider).filtroActivo,
              hint: const Text('Todos los estados'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Todos'),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text('Activos'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Inactivos'),
                ),
              ],
              onChanged: (value) {
                ref.read(formulariosProvider.notifier).filtrarPorEstado(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Botón actualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(formulariosProvider.notifier).cargarFormularios(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Campo de búsqueda moderno
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1C2120),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar formularios...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  ref.read(formulariosProvider.notifier).buscar(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Filtro por estado moderno
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<bool?>(
              value: ref.watch(formulariosProvider).filtroActivo,
              hint: Text(
                'Todos los estados',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF1C2120),
                fontSize: 15,
              ),
              underline: const SizedBox(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[600],
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('Activos'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Inactivos'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(formulariosProvider.notifier).filtrarPorEstado(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, FormulariosState state) {
    final formularios = state.formularios;
    
    if (formularios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron formularios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer formulario para comenzar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Ordenar datos
    final formulariosSorted = List<Map<String, dynamic>>.from(formularios);
    _sortData(formulariosSorted);

    return ModernDataTable(
      formularios: formulariosSorted,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
      },
      onEdit: _navegarAEditar,
      onDuplicate: _mostrarDialogoVersion,
      onDelete: _confirmarEliminar,
    );
  }

  Widget _buildDataTableOld(BuildContext context, FormulariosState state) {
    final formularios = state.formularios;
    
    if (formularios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No hay formularios disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Ordenar datos
    final formulariosSorted = List<Map<String, dynamic>>.from(formularios);
    _sortData(formulariosSorted);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: [
            DataColumn(
              label: const Text('Nombre'),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: const Text('Versión'),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                });
              },
            ),
            const DataColumn(
              label: Text('Estado'),
            ),
            DataColumn(
              label: const Text('Fecha Actualización'),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                });
              },
            ),
            const DataColumn(
              label: Text('Capturado'),
            ),
            const DataColumn(
              label: Text('Acciones'),
            ),
          ],
          rows: formulariosSorted.map((formulario) {
            final bool activo = formulario['activa'] ?? false;
            final bool capturado = formulario['capturado'] ?? false;
            
            return DataRow(
              cells: [
                DataCell(Text(formulario['nombre'] ?? '')),
                DataCell(Text(formulario['version'] ?? '1.0')),
                DataCell(
                  Switch(
                    value: activo,
                    onChanged: capturado ? null : (value) {
                      _cambiarEstado(context, formulario, value);
                    },
                  ),
                ),
                DataCell(Text(_formatFecha(formulario['fechaActualizacion']))),
                DataCell(
                  Tooltip(
                    message: capturado 
                        ? 'Este formulario tiene capturas'
                        : 'Este formulario no tiene capturas',
                    child: capturado
                        ? Icon(Icons.check_circle, color: Colors.green[600])
                        : Icon(Icons.cancel, color: Colors.grey[400]),
                  ),
                ),
                DataCell(
                  PopupMenuButton<String>(
                    onSelected: (value) => _accionSeleccionada(
                      context, 
                      value, 
                      formulario,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicar',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Eliminar', 
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _sortData(List<Map<String, dynamic>> data) {
    switch (_sortColumnIndex) {
      case 0: // Nombre
        data.sort((a, b) {
          final result = (a['nombre'] ?? '').compareTo(b['nombre'] ?? '');
          return _sortAscending ? result : -result;
        });
        break;
      case 1: // Versión
        data.sort((a, b) {
          final result = (a['version'] ?? '').compareTo(b['version'] ?? '');
          return _sortAscending ? result : -result;
        });
        break;
      case 3: // Fecha
        data.sort((a, b) {
          final fechaA = DateTime.tryParse(a['fechaActualizacion'] ?? '') ?? DateTime(2000);
          final fechaB = DateTime.tryParse(b['fechaActualizacion'] ?? '') ?? DateTime(2000);
          final result = fechaA.compareTo(fechaB);
          return _sortAscending ? result : -result;
        });
        break;
    }
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return 'Sin fecha';
    final date = DateTime.tryParse(fecha);
    if (date == null) return fecha;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatHora(String? fecha) {
    if (fecha == null) return '';
    final date = DateTime.tryParse(fecha);
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navegarACrear(BuildContext context) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioEditorPage(),
      ),
    );
    
    if (resultado == true) {
      ref.read(formulariosProvider.notifier).cargarFormularios();
    }
  }

  void _navegarAEditar(BuildContext context, Map<String, dynamic> formulario) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioEditorPage(formulario: formulario),
      ),
    );
    if (resultado == true) {
      ref.read(formulariosProvider.notifier).cargarFormularios();
    }
  }

  void _mostrarDialogoVersion(BuildContext context, Map<String, dynamic> formulario) async {
    final nuevaVersion = await showDialog<String>(
      context: context,
      builder: (context) => VersionDialog(
        versionActual: formulario['version'] ?? '1.0',
        onVersionSeleccionada: (version) => Navigator.pop(context, version),
      ),
    );
    
    if (nuevaVersion != null) {
      final exito = await ref.read(formulariosProvider.notifier).duplicarFormulario(
        formulario['id'],
        nuevaVersion,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exito 
                  ? 'Formulario duplicado exitosamente' 
                  : 'Error al duplicar formulario',
            ),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _cambiarEstado(BuildContext context, Map<String, dynamic> formulario, bool nuevoEstado) async {
    final exito = await ref.read(formulariosProvider.notifier).cambiarEstadoFormulario(
      formulario['id'],
      nuevoEstado,
    );
    
    if (context.mounted && !exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cambiar el estado del formulario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarEliminar(BuildContext context, Map<String, dynamic> formulario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el formulario "${formulario['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmar == true && context.mounted) {
      final exito = await ref.read(formulariosProvider.notifier).eliminarFormulario(
        formulario['id'],
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exito 
                  ? 'Formulario eliminado exitosamente' 
                  : ref.watch(formulariosProvider).error ?? 'Error al eliminar formulario',
            ),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _accionSeleccionada(BuildContext context, String accion, Map<String, dynamic> formulario) {
    switch (accion) {
      case 'editar':
        _navegarAEditar(context, formulario);
        break;
      case 'duplicar':
        _mostrarDialogoVersion(context, formulario);
        break;
      case 'eliminar':
        _confirmarEliminar(context, formulario);
        break;
    }
  }
}