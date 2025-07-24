import 'package:flutter/material.dart';
import 'package:diana_lc_front/widgets/encabezado_inicio.dart';
import 'package:diana_lc_front/widgets/connection_status_widget.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';

class PantallaMenuPrincipal extends StatefulWidget {
  const PantallaMenuPrincipal({super.key});

  @override
  State<PantallaMenuPrincipal> createState() => _PantallaMenuPrincipalState();
}

class _PantallaMenuPrincipalState extends State<PantallaMenuPrincipal> {
  LiderComercial? _liderComercial;
  String? _correoUsuario;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    try {
      // Inicializar Hive primero
      await HiveService().initialize();
      print('✅ Hive inicializado desde el menú principal');
      
      // Cargar datos del usuario
      await _cargarDatosUsuario();
    } catch (e) {
      print('❌ Error al inicializar la app: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('usuario');
    
    if (userDataString != null) {
      final Map<String, dynamic> userMap = jsonDecode(userDataString);
      final lider = LiderComercial.fromJson(userMap);
      
      // Obtener el correo directamente de los datos del usuario
      _correoUsuario = userMap['correo'] ?? userMap['email'];
      
      // Si no está en userData, intentar obtenerlo del token JWT
      if (_correoUsuario == null) {
        final idToken = prefs.getString('id_token');
        if (idToken != null) {
          try {
            final parts = idToken.split('.');
            if (parts.length == 3) {
              final payloadBase64 = parts[1];
              final normalized = base64.normalize(payloadBase64);
              final decoded = utf8.decode(base64Url.decode(normalized));
              final payload = json.decode(decoded);
              _correoUsuario = payload['email'];
            }
          } catch (e) {
            print('Error al decodificar token para obtener email: $e');
          }
        }
      }
      
      setState(() {
        _liderComercial = lider;
        _isLoading = false;
      });
      
      print('Datos cargados - Correo: $_correoUsuario');
    } else {
      setState(() {
        _isLoading = false;
      });
      print('No se encontró usuario en SharedPreferences');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nombreUsuario = _liderComercial?.nombre ?? 'Usuario';

    return WillPopScope(
      onWillPop: () async {
        // Mostrar diálogo de confirmación antes de salir
        return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar salida'),
              content: const Text('¿Realmente desea salir del sistema?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () async {
                    // Primero cerrar el diálogo
                    Navigator.of(context).pop(false);
                    // Luego cerrar sesión y navegar al login
                    await SesionServicio.cerrarSesion(context);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Sí'),
                ),
              ],
            );
          },
        ) ?? false;
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          // 1) Limitar el ancho máximo del contenido
          final contentWidth = width > 900 ? 900.0 : width;
          
          // 2) Breakpoints para el logo
          double logoHeight;
          if (width >= 1024) {
            logoHeight = 180;    // escritorio
          } else if (width >= 600) {
            logoHeight = 150;    // tablet  
          } else {
            logoHeight = 120;    // móvil
          }
          
          // 3) Breakpoints para número de columnas
          int crossAxisCount;
          double childAspectRatio;
          if (width >= 1200) {
            crossAxisCount = 4;
            childAspectRatio = 1.1;
          } else if (width >= 800) {
            crossAxisCount = 3;
            childAspectRatio = 1.15;
          } else if (width >= 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.3;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 1.2;
          }
          
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  // Encabezado con logo
                  EncabezadoInicio(
                    nombreUsuario: nombreUsuario,
                    logoHeight: logoHeight,
                  ),
                  const SizedBox(height: 24),

          // Estado de conexión y sincronización (temporalmente deshabilitado)
          // const ConnectionStatusWidget(),

          // Widget temporal de estado
          /*       Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Offline - Datos de Prueba',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        'Funcionalidad completa disponible próximamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
*/
                  // Información del usuario
                  if (_liderComercial != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Líder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Nombre del líder
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: const Color(0xFFDE1327),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nombre: ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _liderComercial!.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1C2120),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Clave del líder (comentada por no ser relevante)
                  /*
                  Row(
                    children: [
                      Icon(
                        Icons.badge,
                        color: const Color(0xFFDE1327),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clave del Líder: ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE1327),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _liderComercial!.clave,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  */
                  // Correo del líder
                  if (_correoUsuario != null) ...[  
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: const Color(0xFFDE1327),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Correo: ',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _correoUsuario!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1C2120),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Centro de distribución
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: const Color(0xFFDE1327),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Centro de Distribución: ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _liderComercial!.centroDistribucion,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1C2120),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // País de origen
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: const Color(0xFFDE1327),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'País de Origen: ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _liderComercial!.pais,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1C2120),
                        ),
                      ),
                    ],
                  ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Mostrar un mensaje si no hay datos
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade600),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se pudieron cargar los datos del usuario',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Secciones del menú
                  _buildSection(
                    title: 'Planificación',
                    items: [
                      _MenuItem(
                        icon: Icons.edit_calendar_outlined,
                        title: 'Crear plan de trabajo',
                        onTap:
                            () => Navigator.pushNamed(context, '/plan_configuracion'),
                      ),
                      _MenuItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'Planes de trabajo',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              '/planes_trabajo',
                            ),
                      ),
                    ],
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                  ),
                  const SizedBox(height: 32),

                  _buildSection(
                    title: 'Ejecución',
                    items: [
                      _MenuItem(
                        icon: Icons.people_alt_outlined,
                        title: 'Gestión de clientes',
                        onTap: () => Navigator.pushNamed(context, '/rutina_diaria'),
                      ),
                      _MenuItem(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Programa de excelencia',
                        onTap: null,
                      ),
                    ],
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                  ),
                  const SizedBox(height: 32),

                  _buildSection(
                    title: 'Seguimiento',
                    items: [
                      _MenuItem(
                        icon: Icons.bar_chart_outlined,
                        title: 'Rutinas / Resultados',
                        onTap: () => Navigator.pushNamed(context, '/rutinas_resultados'),
                      ),
                      _MenuItem(
                        icon: Icons.insert_chart_outlined_rounded,
                        title: 'Reporte de acuerdos',
                        onTap: null,
                      ),
                    ],
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSection(
                    title: 'Administración',
                    items: [
                      _MenuItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Administración',
                        onTap: () => Navigator.pushNamed(context, '/administracion'),
                      ),
                    ],
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
        onTap: (index) {
          if (index == 1) {
            // Mostrar opción de cerrar sesión
            _mostrarOpcionesPerfil(context);
          }
        },
      ),
    ),
    );
  }

  void _mostrarOpcionesPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!AmbienteConfig
                    .esProduccion) // Mostrar solo en ambientes no productivos
                  ListTile(
                    leading: const Icon(Icons.storage, color: Colors.blue),
                    title: const Text('Gestión de Datos Maestros'),
                    subtitle: Text(
                      'Ambiente: ${AmbienteConfig.nombreAmbiente}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/debug_hive');
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async {
                    Navigator.pop(context);
                    await SesionServicio.cerrarSesion(context);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _MenuItemWidget(item: items[index]);
          },
        ),
      ],
    );
  }
}

class _MenuItemWidget extends StatefulWidget {
  final _MenuItem item;

  const _MenuItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.item.onTap != null) {
      setState(() => _scale = 0.97);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.item.onTap != null) {
      setState(() => _scale = 1.0);
    }
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.item.onTap == null;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: Stack(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: isDisabled ? 0 : 4,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: widget.item.onTap,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              borderRadius: BorderRadius.circular(16),
              splashColor: const Color(0xFFDE1327).withOpacity(0.1),
              highlightColor: const Color(0xFFDE1327).withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDisabled ? Colors.grey.shade300 : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.item.icon,
                        size: 48,
                        color:
                            isDisabled
                                ? Colors.grey.shade400
                                : const Color(0xFFDE1327),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: Text(
                          widget.item.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color:
                                isDisabled
                                    ? Colors.grey.shade400
                                    : const Color(0xFF1C2120),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
            if (isDisabled)
              Positioned(
                top: 8,
                left: 8,
                child: Transform.rotate(
                  angle: -0.785398,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    color: Colors.redAccent,
                    child: const Text(
                      'NO DISPONIBLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuItem({required this.icon, required this.title, this.onTap});
}
