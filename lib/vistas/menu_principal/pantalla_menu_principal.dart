import 'package:flutter/material.dart';
import '../../widgets/encabezado_inicio.dart';
import 'package:diana_lc_front/vistas/menu_principal/vista_configuracion_plan.dart';

class PantallaMenuPrincipal extends StatelessWidget {
  const PantallaMenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco más limpio
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EncabezadoInicio(nombreUsuario: 'Guillermo'),
          const SizedBox(height: 24),

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
                onTap: () => Navigator.pushNamed(context, '/planes_trabajo'),
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
            childAspectRatio: 1.3, // Más ancho
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
      setState(() => _scale = 0.97); // Reducción suave
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.item.onTap != null) {
      setState(() => _scale = 1.0); // Regreso suave
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
                  angle: -0.785398, // -45 grados
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
