import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget para mostrar las tarjetas de KPIs
class KPICards extends StatelessWidget {
  final Map<String, dynamic> kpis;

  const KPICards({
    Key? key,
    required this.kpis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Primera fila de KPIs
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    titulo: 'Planificados',
                    valor: kpis['clientesPlanificados'].toString(),
                    icono: Icons.calendar_today,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    titulo: 'Visitados',
                    valor: kpis['visitados'].toString(),
                    icono: Icons.check_circle,
                    color: const Color(0xFF38A169),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    titulo: 'Cumplimiento',
                    valor: '${kpis['porcentajeCumplimiento']}%',
                    icono: Icons.trending_up,
                    color: _getColorPorcentaje(kpis['porcentajeCumplimiento']),
                  ),
                ),
              ],
            ),
          ),
          // Segunda fila de KPIs
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    titulo: 'Compromisos',
                    valor: kpis['compromisosGenerados'].toString(),
                    icono: Icons.handshake,
                    color: const Color(0xFFF6C343),
                    esSecundario: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    titulo: 'Duración Prom.',
                    valor: '${kpis['duracionPromedio']} min',
                    icono: Icons.timer,
                    color: const Color(0xFF9C27B0),
                    esSecundario: true,
                  ),
                ),
              ],
            ),
          ),
          // Indicadores de estado
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildEstadoIndicador(
                  'En proceso',
                  kpis['clientesEnProceso'],
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildEstadoIndicador(
                  'Pendientes',
                  kpis['clientesPendientes'],
                  Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    bool esSecundario = false,
  }) {
    return Container(
      padding: EdgeInsets.all(esSecundario ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: color,
                size: esSecundario ? 18 : 20,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: esSecundario ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: esSecundario ? 11 : 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoIndicador(String titulo, int cantidad, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$titulo: $cantidad',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorPorcentaje(int porcentaje) {
    if (porcentaje >= 80) return const Color(0xFF38A169);
    if (porcentaje >= 60) return const Color(0xFFF6C343);
    if (porcentaje >= 40) return Colors.orange;
    return Colors.red;
  }
}