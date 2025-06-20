import 'package:flutter/material.dart';
import '../../widgets/encabezado_inicio.dart';
import '../../servicios/sesion_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';

class PantallaMenuPrincipal extends StatefulWidget {
  const PantallaMenuPrincipal({super.key});

  @override
  State<PantallaMenuPrincipal> createState() => _PantallaMenuPrincipalState();
}

class _PantallaMenuPrincipalState extends State<PantallaMenuPrincipal> {
  LiderComercial? _liderComercial;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final lider = await SesionServicio.obtenerLiderComercial();
      print('Datos del líder cargados: ${lider?.toJson()}'); // Debug
      setState(() {
        _liderComercial = lider;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error cargando datos del usuario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nombreUsuario = _liderComercial?.nombre ?? 'Usuario';

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EncabezadoInicio(nombreUsuario: nombreUsuario),
          const SizedBox(height: 24),

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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: const Color(0xFFDE1327),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _liderComercial!.centroDistribucion,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _liderComercial!.pais,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
                  Text(
                    'No se pudieron cargar los datos del usuario',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ],

          _buildSection(
            title: 'Planificación',
            items: [
              _MenuItem(
                icon: Icons.edit_calendar_outlined,
                title: 'Crear Plan\nde trabajo',
                onTap:
                    () => Navigator.pushNamed(context, '/plan_configuracion'),
              ),
              _MenuItem(
                icon: Icons.calendar_month_outlined,
                title: 'Ver Plan\nde trabajo',
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/planes_trabajo',
                    ), // CORREGIDO: cambié de '/vista_planes_trabajo' a '/planes_trabajo'
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildSection(
            title: 'Ejecución',
            items: [
              _MenuItem(
                icon: Icons.people_alt_outlined,
                title: 'Gestión de\nclientes',
                onTap: null,
              ),
              _MenuItem(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Evaluación\nde desempeño',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildSection(
            title: 'Seguimiento',
            items: [
              _MenuItem(
                icon: Icons.bar_chart_outlined,
                title: 'Resultados\ndel día',
                onTap: null,
              ),
              _MenuItem(
                icon: Icons.insert_chart_outlined_rounded,
                title: 'Reporte de\nacuerdos',
                onTap: null,
              ),
            ],
          ),
        ],
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
            icon: Icon(Icons.assignment_outlined),
            label: 'Rutinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            // Mostrar opción de cerrar sesión
            _mostrarOpcionesPerfil(context);
          }
        },
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
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async {
                    Navigator.pop(context);
                    await SesionServicio.cerrarSesion();
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
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

    return GestureDetector(
      onTap: widget.item.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDisabled ? Colors.grey.shade300 : Colors.transparent,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.item.icon,
                      size: 52,
                      color:
                          isDisabled
                              ? Colors.grey.shade400
                              : const Color(0xFFDE1327),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color:
                            isDisabled
                                ? Colors.grey.shade400
                                : const Color(0xFF1C2120),
                      ),
                    ),
                  ],
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
