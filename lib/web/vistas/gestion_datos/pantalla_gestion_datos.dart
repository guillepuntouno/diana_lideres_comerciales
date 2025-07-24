// lib/web/vistas/gestion_datos/pantalla_gestion_datos.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/servicios/clientes_servicio.dart';
import 'package:diana_lc_front/shared/servicios/lider_comercial_servicio.dart';
import 'package:diana_lc_front/shared/servicios/plantilla_service_impl.dart';
import 'package:diana_lc_front/shared/modelos/hive/cliente_hive.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/modelos/formulario_dto.dart';

class PantallaGestionDatos extends StatefulWidget {
  const PantallaGestionDatos({Key? key}) : super(key: key);

  @override
  State<PantallaGestionDatos> createState() => _PantallaGestionDatosState();
}

class _PantallaGestionDatosState extends State<PantallaGestionDatos> {
  final ClientesServicio _clientesServicio = ClientesServicio();
  final LiderComercialServicio _lideresServicio = LiderComercialServicio();
  final PlantillaServiceImpl _plantillasServicio = PlantillaServiceImpl();
  
  String _tabSeleccionada = 'clientes';
  List<dynamic> _datosActuales = [];
  bool _isLoading = false;
  String _busqueda = '';
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      switch (_tabSeleccionada) {
        case 'clientes':
          final clientes = await _clientesServicio.obtenerTodosLosClientes();
          setState(() => _datosActuales = clientes);
          break;
        case 'lideres':
          final lideres = await _lideresServicio.obtenerLideresComerciales();
          setState(() => _datosActuales = lideres);
          break;
        case 'formularios':
          final plantillas = await _plantillasServicio.obtenerPlantillas();
          setState(() => _datosActuales = plantillas);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Tabs
          _buildTabs(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarNuevoRegistro,
        backgroundColor: const Color(0xFFDE1327),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Text(
            'Gestión de Datos Maestros',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const Spacer(),
          
          // Search bar
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (value) => setState(() => _busqueda = value),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Actions
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _importarDatos,
            tooltip: 'Importar datos',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportarDatos,
            tooltip: 'Exportar datos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _buildTab('clientes', 'Clientes', Icons.business),
          _buildTab('lideres', 'Líderes Comerciales', Icons.people),
          _buildTab('formularios', 'Formularios', Icons.assignment),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final isActive = _tabSeleccionada == id;
    
    return InkWell(
      onTap: () {
        setState(() => _tabSeleccionada = id);
        _cargarDatos();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFFDE1327),
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFFDE1327) : const Color(0xFF8F8E8E),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFFDE1327) : const Color(0xFF8F8E8E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final datosFiltrados = _datosActuales.where((dato) {
      if (_busqueda.isEmpty) return true;
      
      switch (_tabSeleccionada) {
        case 'clientes':
          final cliente = dato as ClienteHive;
          return cliente.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                 cliente.codigo.toLowerCase().contains(_busqueda.toLowerCase());
        case 'lideres':
          final lider = dato as LiderComercial;
          return lider.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                 lider.email.toLowerCase().contains(_busqueda.toLowerCase());
        case 'formularios':
          final formulario = dato as FormularioDto;
          return formulario.nombre.toLowerCase().contains(_busqueda.toLowerCase());
        default:
          return true;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${datosFiltrados.length} registros',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _seleccionMultiple,
                        icon: const Icon(Icons.check_box),
                        label: const Text('Seleccionar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _eliminarMultiple,
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Data table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: _buildColumns(),
                    rows: datosFiltrados.map((dato) => _buildRow(dato)).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    switch (_tabSeleccionada) {
      case 'clientes':
        return const [
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Dirección')),
          DataColumn(label: Text('Teléfono')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ];
      case 'lideres':
        return const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Centro Distribución')),
          DataColumn(label: Text('País')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ];
      case 'formularios':
        return const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Descripción')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Campos')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ];
      default:
        return [];
    }
  }

  DataRow _buildRow(dynamic dato) {
    switch (_tabSeleccionada) {
      case 'clientes':
        final cliente = dato as ClienteHive;
        return DataRow(cells: [
          DataCell(Text(cliente.codigo)),
          DataCell(Text(cliente.nombre)),
          DataCell(Text(cliente.direccion ?? 'N/A')),
          DataCell(Text(cliente.telefono ?? 'N/A')),
          DataCell(Text(cliente.email ?? 'N/A')),
          DataCell(_buildEstadoChip(cliente.activo)),
          DataCell(_buildAcciones(cliente)),
        ]);
      case 'lideres':
        final lider = dato as LiderComercial;
        return DataRow(cells: [
          DataCell(Text(lider.id.toString())),
          DataCell(Text(lider.nombre)),
          DataCell(Text(lider.email)),
          DataCell(Text(lider.centroDistribucion ?? 'N/A')),
          DataCell(Text(lider.pais ?? 'N/A')),
          DataCell(_buildEstadoChip(lider.activo)),
          DataCell(_buildAcciones(lider)),
        ]);
      case 'formularios':
        final formulario = dato as FormularioDto;
        return DataRow(cells: [
          DataCell(Text(formulario.id.toString())),
          DataCell(Text(formulario.nombre)),
          DataCell(Text(formulario.descripcion ?? 'N/A')),
          DataCell(Text(formulario.tipo ?? 'General')),
          DataCell(Text('${formulario.campos?.length ?? 0} campos')),
          DataCell(_buildEstadoChip(formulario.activo ?? true)),
          DataCell(_buildAcciones(formulario)),
        ]);
      default:
        return const DataRow(cells: []);
    }
  }

  Widget _buildEstadoChip(bool activo) {
    return Chip(
      label: Text(
        activo ? 'Activo' : 'Inactivo',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: activo ? const Color(0xFF38A169) : Colors.grey,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildAcciones(dynamic dato) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editarRegistro(dato),
          color: const Color(0xFFDE1327),
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => _eliminarRegistro(dato),
          color: Colors.red,
        ),
      ],
    );
  }

  void _agregarNuevoRegistro() {
    // TODO: Implementar diálogo para agregar nuevo registro
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${_obtenerNombreTipo()}'),
        content: const Text('Funcionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editarRegistro(dynamic dato) {
    // TODO: Implementar diálogo para editar registro
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${_obtenerNombreTipo()}'),
        content: const Text('Funcionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cargarDatos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarRegistro(dynamic dato) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar este ${_obtenerNombreTipo()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminación real
              _cargarDatos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _importarDatos() {
    // TODO: Implementar importación de datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de importación en desarrollo')),
    );
  }

  void _exportarDatos() {
    // TODO: Implementar exportación de datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de exportación en desarrollo')),
    );
  }

  void _seleccionMultiple() {
    // TODO: Implementar selección múltiple
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de selección múltiple en desarrollo')),
    );
  }

  void _eliminarMultiple() {
    // TODO: Implementar eliminación múltiple
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de eliminación múltiple en desarrollo')),
    );
  }

  String _obtenerNombreTipo() {
    switch (_tabSeleccionada) {
      case 'clientes':
        return 'Cliente';
      case 'lideres':
        return 'Líder Comercial';
      case 'formularios':
        return 'Formulario';
      default:
        return 'Registro';
    }
  }
}