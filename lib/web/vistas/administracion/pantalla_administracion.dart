// lib/web/vistas/administracion/pantalla_administracion.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/user_dto.dart';

class PantallaAdministracion extends StatefulWidget {
  const PantallaAdministracion({Key? key}) : super(key: key);

  @override
  State<PantallaAdministracion> createState() => _PantallaAdministracionState();
}

class _PantallaAdministracionState extends State<PantallaAdministracion> {
  final SesionServicio _sesionServicio = SesionServicio();
  
  String _vistaSeleccionada = 'usuarios';
  List<UsuarioDto> _usuarios = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permisos = [];
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
      switch (_vistaSeleccionada) {
        case 'usuarios':
          // TODO: Implementar servicio real de usuarios
          setState(() => _usuarios = _generarUsuariosDePrueba());
          break;
        case 'roles':
          setState(() => _roles = _generarRolesDePrueba());
          break;
        case 'permisos':
          setState(() => _permisos = _generarPermisosDePrueba());
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
      body: Row(
        children: [
          // Sidebar de navegación
          _buildSidebar(),
          
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Administración',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          _buildSidebarItem('usuarios', 'Usuarios', Icons.people),
          _buildSidebarItem('roles', 'Roles', Icons.security),
          _buildSidebarItem('permisos', 'Permisos', Icons.lock),
          const Divider(),
          _buildSidebarItem('auditoria', 'Auditoría', Icons.history),
          _buildSidebarItem('configuracion', 'Configuración', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String id, String label, IconData icon) {
    final isActive = _vistaSeleccionada == id;
    
    return InkWell(
      onTap: () {
        setState(() => _vistaSeleccionada = id);
        _cargarDatos();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDE1327).withOpacity(0.1) : null,
          border: isActive
              ? const Border(
                  left: BorderSide(
                    color: Color(0xFFDE1327),
                    width: 3,
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
            const SizedBox(width: 12),
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
            _getTituloVista(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const Spacer(),
          
          // Search bar
          if (_vistaSeleccionada != 'configuracion') ...[
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
          ],
          
          // Actions
          if (_vistaSeleccionada == 'usuarios' || 
              _vistaSeleccionada == 'roles' || 
              _vistaSeleccionada == 'permisos') ...[
            ElevatedButton.icon(
              onPressed: _agregarNuevo,
              icon: const Icon(Icons.add),
              label: Text('Agregar ${_getNombreSingular()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE1327),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_vistaSeleccionada) {
      case 'usuarios':
        return _buildUsuariosView();
      case 'roles':
        return _buildRolesView();
      case 'permisos':
        return _buildPermisosView();
      case 'auditoria':
        return _buildAuditoriaView();
      case 'configuracion':
        return _buildConfiguracionView();
      default:
        return const Center(child: Text('Vista no disponible'));
    }
  }

  Widget _buildUsuariosView() {
    final usuariosFiltrados = _usuarios.where((usuario) {
      if (_busqueda.isEmpty) return true;
      return usuario.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
             usuario.correo.toLowerCase().contains(_busqueda.toLowerCase());
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
          children: [
            // Stats cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatCard('Total Usuarios', _usuarios.length.toString(), Icons.people, const Color(0xFF38A169)),
                  const SizedBox(width: 16),
                  _buildStatCard('Activos', _usuarios.where((u) => u.estado == 'activo').length.toString(), Icons.check_circle, const Color(0xFFF6C343)),
                  const SizedBox(width: 16),
                  _buildStatCard('Administradores', '3', Icons.admin_panel_settings, const Color(0xFFDE1327)),
                  const SizedBox(width: 16),
                  _buildStatCard('Conectados', '12', Icons.online_prediction, Colors.purple),
                ],
              ),
            ),
            
            // Data table
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Centro')),
                    DataColumn(label: Text('Último Acceso')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: usuariosFiltrados.map((usuario) {
                    return DataRow(cells: [
                      DataCell(Text(usuario.id.toString())),
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFDE1327),
                            child: Text(
                              usuario.nombre.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(usuario.nombre),
                        ],
                      )),
                      DataCell(Text(usuario.correo)),
                      DataCell(_buildRolChip(usuario.rol)),
                      DataCell(Text(usuario.centroDistribucion ?? 'N/A')),
                      DataCell(Text(_formatearFecha(DateTime.fromMillisecondsSinceEpoch(usuario.updatedAt)))),
                      DataCell(_buildEstadoChip(usuario.estado == 'activo')),
                      DataCell(_buildAccionesUsuario(usuario)),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final rol = _roles[index];
          return Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE1327).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForRol(rol['nombre']),
                        color: const Color(0xFFDE1327),
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(child: Text('Editar')),
                        const PopupMenuItem(child: Text('Duplicar')),
                        const PopupMenuItem(child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rol['nombre'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                Text(
                  rol['descripcion'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF8F8E8E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${rol['usuarios']} usuarios',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                    Text(
                      '${rol['permisos']} permisos',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermisosView() {
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
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Módulo')),
              DataColumn(label: Text('Ver')),
              DataColumn(label: Text('Crear')),
              DataColumn(label: Text('Editar')),
              DataColumn(label: Text('Eliminar')),
              DataColumn(label: Text('Exportar')),
              DataColumn(label: Text('Administrar')),
            ],
            rows: _permisos.map((permiso) {
              return DataRow(cells: [
                DataCell(Text(permiso['modulo'])),
                DataCell(Checkbox(value: permiso['ver'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['crear'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['editar'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['eliminar'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['exportar'], onChanged: (v) {})),
                DataCell(Checkbox(value: permiso['administrar'], onChanged: (v) {})),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditoriaView() {
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Registro de Actividades',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return _buildAuditoriaItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditoriaItem(int index) {
    final acciones = ['creó', 'modificó', 'eliminó', 'accedió a'];
    final objetos = ['un usuario', 'un rol', 'un permiso', 'un reporte'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '${DateTime.now().subtract(Duration(hours: index)).hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFDE1327).withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 16,
              color: Color(0xFFDE1327),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Usuario ${index + 1} ',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  TextSpan(
                    text: '${acciones[index % acciones.length]} ${objetos[index % objetos.length]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF8F8E8E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigSection('Configuración General', [
            _buildConfigItem('Nombre del Sistema', 'Diana Líderes Comerciales'),
            _buildConfigItem('Versión', '2.0.0'),
            _buildConfigItem('Ambiente', 'Producción'),
            _buildConfigItem('URL API', 'https://api.diana.com'),
          ]),
          const SizedBox(height: 24),
          _buildConfigSection('Configuración de Seguridad', [
            _buildConfigSwitch('Autenticación de dos factores', true),
            _buildConfigSwitch('Bloqueo por intentos fallidos', true),
            _buildConfigItem('Intentos máximos', '3'),
            _buildConfigItem('Duración del token', '24 horas'),
          ]),
          const SizedBox(height: 24),
          _buildConfigSection('Configuración de Notificaciones', [
            _buildConfigSwitch('Notificaciones por email', true),
            _buildConfigSwitch('Notificaciones push', false),
            _buildConfigSwitch('Resumen diario', true),
          ]),
        ],
      ),
    );
  }

  Widget _buildConfigSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8F8E8E),
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
    );
  }

  Widget _buildConfigSwitch(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: const Color(0xFFDE1327),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF8F8E8E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolChip(String rol) {
    final color = rol == 'admin' ? const Color(0xFFDE1327) : const Color(0xFF38A169);
    
    return Chip(
      label: Text(
        rol,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
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

  Widget _buildAccionesUsuario(UsuarioDto usuario) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _editarUsuario(usuario),
          color: const Color(0xFFDE1327),
        ),
        IconButton(
          icon: const Icon(Icons.lock_reset, size: 18),
          onPressed: () => _resetearPassword(usuario),
          color: const Color(0xFFF6C343),
        ),
        IconButton(
          icon: Icon(
            usuario.estado == 'activo' ? Icons.block : Icons.check_circle,
            size: 18,
          ),
          onPressed: () => _toggleEstadoUsuario(usuario),
          color: usuario.estado == 'activo' ? Colors.red : const Color(0xFF38A169),
        ),
      ],
    );
  }

  String _getTituloVista() {
    switch (_vistaSeleccionada) {
      case 'usuarios':
        return 'Gestión de Usuarios';
      case 'roles':
        return 'Gestión de Roles';
      case 'permisos':
        return 'Gestión de Permisos';
      case 'auditoria':
        return 'Auditoría del Sistema';
      case 'configuracion':
        return 'Configuración del Sistema';
      default:
        return 'Administración';
    }
  }

  String _getNombreSingular() {
    switch (_vistaSeleccionada) {
      case 'usuarios':
        return 'Usuario';
      case 'roles':
        return 'Rol';
      case 'permisos':
        return 'Permiso';
      default:
        return '';
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Nunca';
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    } else {
      return 'Hace ${diferencia.inDays} días';
    }
  }

  IconData _getIconForRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.supervised_user_circle;
      case 'líder comercial':
        return Icons.person;
      default:
        return Icons.people;
    }
  }

  void _agregarNuevo() {
    // TODO: Implementar diálogo para agregar nuevo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${_getNombreSingular()}'),
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

  void _editarUsuario(UsuarioDto usuario) {
    // TODO: Implementar edición de usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando usuario: ${usuario.nombre}')),
    );
  }

  void _resetearPassword(UsuarioDto usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetear Contraseña'),
        content: Text('¿Está seguro de resetear la contraseña de ${usuario.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraseña reseteada exitosamente')),
              );
            },
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  void _toggleEstadoUsuario(UsuarioDto usuario) {
    final accion = usuario.estado == 'activo' ? 'desactivar' : 'activar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${accion.substring(0, 1).toUpperCase()}${accion.substring(1)} Usuario'),
        content: Text('¿Está seguro de $accion a ${usuario.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar cambio de estado
              _cargarDatos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: usuario.estado == 'activo' ? Colors.red : const Color(0xFF38A169),
            ),
            child: Text(accion.substring(0, 1).toUpperCase() + accion.substring(1)),
          ),
        ],
      ),
    );
  }

  // Métodos para generar datos de prueba
  List<UsuarioDto> _generarUsuariosDePrueba() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(15, (index) => UsuarioDto(
      id: 'USR${(index + 1).toString().padLeft(3, '0')}',
      nombre: 'Usuario ${index + 1}',
      correo: 'usuario${index + 1}@diana.com',
      rol: index % 3 == 0 ? 'admin' : 'lider',
      estado: index % 5 != 0 ? 'activo' : 'inactivo',
      centroDistribucion: 'Centro ${(index % 3) + 1}',
      createdAt: now - (86400000 * index), // días en milisegundos
      updatedAt: now - (3600000 * index * 2), // horas en milisegundos
      deletedAt: 0, // 0 para indicar no eliminado
      createdBy: 'admin',
      updatedBy: 'admin',
      deletedBy: '', // string vacío en lugar de null
      isDeleted: false,
    ));
  }

  List<Map<String, dynamic>> _generarRolesDePrueba() {
    return [
      {
        'nombre': 'Administrador',
        'descripcion': 'Acceso completo al sistema',
        'usuarios': 3,
        'permisos': 45,
      },
      {
        'nombre': 'Supervisor',
        'descripcion': 'Gestión de equipos y reportes',
        'usuarios': 8,
        'permisos': 32,
      },
      {
        'nombre': 'Líder Comercial',
        'descripcion': 'Gestión de visitas y clientes',
        'usuarios': 25,
        'permisos': 18,
      },
      {
        'nombre': 'Auditor',
        'descripcion': 'Acceso de solo lectura para auditoría',
        'usuarios': 2,
        'permisos': 12,
      },
    ];
  }

  List<Map<String, dynamic>> _generarPermisosDePrueba() {
    return [
      {
        'modulo': 'Dashboard',
        'ver': true,
        'crear': false,
        'editar': false,
        'eliminar': false,
        'exportar': true,
        'administrar': false,
      },
      {
        'modulo': 'Visitas',
        'ver': true,
        'crear': true,
        'editar': true,
        'eliminar': false,
        'exportar': true,
        'administrar': false,
      },
      {
        'modulo': 'Clientes',
        'ver': true,
        'crear': true,
        'editar': true,
        'eliminar': true,
        'exportar': true,
        'administrar': true,
      },
      {
        'modulo': 'Reportes',
        'ver': true,
        'crear': false,
        'editar': false,
        'eliminar': false,
        'exportar': true,
        'administrar': false,
      },
      {
        'modulo': 'Usuarios',
        'ver': true,
        'crear': true,
        'editar': true,
        'eliminar': true,
        'exportar': false,
        'administrar': true,
      },
    ];
  }
}