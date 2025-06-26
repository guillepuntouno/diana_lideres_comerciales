import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../../../servicios/resultados_dia_service.dart';

/// Tile para mostrar el resumen de una visita
class ClienteResultadoTile extends StatelessWidget {
  final VisitaClienteUnificadaHive visita;
  final ResultadosDiaService service;
  final VoidCallback onTap;

  const ClienteResultadoTile({
    Key? key,
    required this.visita,
    required this.service,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final infoCliente = service.obtenerInfoCliente(visita.clienteId);
    final puntuacionCuestionario = service.calcularPuntuacionCuestionario(visita.cuestionario);
    final duracionMinutos = _calcularDuracion();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con nombre y estado
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            infoCliente['nombre'] ?? 'Cliente ${visita.clienteId}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C2120),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${visita.clienteId}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Información de tiempo
                if (visita.horaInicio != null) ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatearHora(visita.horaInicio!),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (visita.horaFin != null) ...[
                        Text(
                          ' - ',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          _formatearHora(visita.horaFin!),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$duracionMinutos min',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Indicadores de resultados
                Row(
                  children: [
                    // Puntuación del cuestionario
                    if (visita.cuestionario != null) ...[
                      _buildIndicador(
                        'Cuestionario',
                        '$puntuacionCuestionario%',
                        _getColorPuntuacion(puntuacionCuestionario),
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    // Compromisos
                    if (visita.compromisos.isNotEmpty) ...[
                      _buildIndicador(
                        'Compromisos',
                        '${visita.compromisos.length}',
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    // Retroalimentación
                    if (visita.retroalimentacion != null && visita.retroalimentacion!.isNotEmpty) ...[
                      Icon(
                        Icons.comment,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                    ],
                    
                    // Reconocimiento
                    if (visita.reconocimiento != null && visita.reconocimiento!.isNotEmpty) ...[
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Flecha para ver más
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String texto;
    IconData icono;

    switch (visita.estatus) {
      case 'terminado':
        color = const Color(0xFF38A169);
        texto = 'Completada';
        icono = Icons.check_circle;
        break;
      case 'en_proceso':
        color = Colors.orange;
        texto = 'En proceso';
        icono = Icons.access_time;
        break;
      default:
        // No mostrar badge para estados pendientes
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicador(String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _calcularDuracion() {
    if (visita.horaInicio == null || visita.horaFin == null) return 0;
    
    try {
      final inicio = DateTime.parse(visita.horaInicio!);
      final fin = DateTime.parse(visita.horaFin!);
      return fin.difference(inicio).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  String _formatearHora(String isoString) {
    try {
      final fecha = DateTime.parse(isoString);
      return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  Color _getColorPuntuacion(int puntuacion) {
    if (puntuacion >= 80) return const Color(0xFF38A169);
    if (puntuacion >= 60) return Colors.orange;
    return Colors.red;
  }
}