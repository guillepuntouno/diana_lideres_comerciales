// lib/web/vistas/dashboard/pantalla_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/servicios/indicadores_gestion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/indicador_gestion_modelo.dart';
import 'package:diana_lc_front/widgets/connection_status_widget.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({Key? key}) : super(key: key);

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard> {
  final IndicadoresGestionServicio _indicadoresServicio = IndicadoresGestionServicio();
  List<IndicadorGestion> _indicadores = [];
  bool _isLoading = true;
  String _selectedPeriod = 'hoy';
  
  @override
  void initState() {
    super.initState();
    _cargarIndicadores();
  }

  Future<void> _cargarIndicadores() async {
    try {
      setState(() => _isLoading = true);
      final indicadores = await _indicadoresServicio.obtenerIndicadoresGestion();
      setState(() {
        _indicadores = indicadores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar indicadores: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KPI Cards
                              _buildKPISection(),
                              const SizedBox(height: 32),
                              
                              // Charts Section
                              _buildChartsSection(),
                              const SizedBox(height: 32),
                              
                              // Recent Activity
                              _buildRecentActivitySection(),
                            ],
                          ),
                        ),
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
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/logo_diana.png',
              height: 60,
            ),
          ),
          
          // Menu items
          _buildMenuItem(Icons.dashboard, 'Dashboard', true),
          _buildMenuItem(Icons.assessment, 'Reportes', false),
          _buildMenuItem(Icons.business, 'Gestión de Datos', false),
          _buildMenuItem(Icons.people, 'Administración', false),
          
          const Spacer(),
          
          // Connection status
          const Padding(
            padding: EdgeInsets.all(16),
            child: ConnectionStatusWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isActive) {
    return InkWell(
      onTap: () {
        // TODO: Implement navigation
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
              color: isActive ? const Color(0xFFDE1327) : const Color(0xFF8F8E8E),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFFDE1327) : const Color(0xFF1C2120),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            'Dashboard de Gestión',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const Spacer(),
          
          // Period selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                DropdownMenuItem(value: 'semana', child: Text('Esta semana')),
                DropdownMenuItem(value: 'mes', child: Text('Este mes')),
                DropdownMenuItem(value: 'año', child: Text('Este año')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                  _cargarIndicadores();
                }
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarIndicadores,
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores Clave',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _indicadores.length > 4 ? 4 : _indicadores.length,
          itemBuilder: (context, index) {
            final indicador = _indicadores[index];
            return _buildKPICard(
              indicador.nombre,
              indicador.valor.toString(),
              indicador.meta.toString(),
              _getIconForIndicador(indicador.tipo),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String target, IconData icon) {
    final percentage = double.tryParse(value) ?? 0;
    final targetValue = double.tryParse(target) ?? 100;
    final achievementRate = (percentage / targetValue * 100).clamp(0, 100);
    
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFFDE1327), size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForPercentage(achievementRate).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${achievementRate.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getColorForPercentage(achievementRate),
                  ),
                ),
              ),
            ],
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C2120),
                ),
              ),
              Text(
                ' / $target',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF8F8E8E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de Tendencias',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 300,
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
                child: Center(
                  child: Text(
                    'Gráfico de Visitas por Día',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF8F8E8E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 300,
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
                child: Center(
                  child: Text(
                    'Gráfico de Efectividad',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF8F8E8E),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE1327).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFDE1327),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Líder ${index + 1} completó visita a Cliente ${100 + index}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1C2120),
                            ),
                          ),
                          Text(
                            'Hace ${index + 1} horas',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF8F8E8E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  IconData _getIconForIndicador(String tipo) {
    switch (tipo) {
      case 'visitas':
        return Icons.location_on;
      case 'efectividad':
        return Icons.trending_up;
      case 'cumplimiento':
        return Icons.check_circle;
      case 'productividad':
        return Icons.speed;
      default:
        return Icons.analytics;
    }
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return const Color(0xFF38A169);
    if (percentage >= 60) return const Color(0xFFF6C343);
    return const Color(0xFFDE1327);
  }
}