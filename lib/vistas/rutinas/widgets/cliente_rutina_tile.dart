import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../pantalla_rutinas_resultados.dart';

/// Tile para mostrar un cliente en la lista de rutinas
class ClienteRutinaTile extends StatelessWidget {
  final VisitaClienteUnificadaHive visita;
  final DiaPlanHive dia;
  final TipoRutina rutina;
  final VoidCallback onTap;

  const ClienteRutinaTile({
    Key? key,
    required this.visita,
    required this.dia,
    required this.rutina,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tieneFormulario = _tieneFormularioRutina();
    final porcentajeFormulario = _calcularPorcentajeFormulario();
    final cantidadCompromisos = visita.compromisos.length;
    final estadoVisita = _obtenerEstadoVisita();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con cliente ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Cliente ${visita.clienteId}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2120),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildEstadoBadge(estadoVisita),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Badges de información
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Badge de formulario
                  if (rutina != TipoRutina.planTrabajo)
                    _buildFormularioBadge(tieneFormulario, porcentajeFormulario),
                  
                  // Badge de compromisos
                  if (cantidadCompromisos > 0)
                    _buildCompromisosBadge(cantidadCompromisos),
                  
                  // Badge de indicadores
                  if (visita.indicadorIds != null && visita.indicadorIds!.isNotEmpty)
                    _buildIndicadoresBadge(visita.indicadorIds!.length),
                ],
              ),
              
              // Horarios si existen
              if (visita.horaInicio != null || visita.horaFin != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: const Color(0xFF8F8E8E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${visita.horaInicio ?? '--:--'} - ${visita.horaFin ?? '--:--'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                    if (visita.horaInicio != null && visita.horaFin != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${_calcularDuracion()} min)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF8F8E8E),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _tieneFormularioRutina() {
    final formularios = dia.formularios;
    return formularios.any((f) => 
      f.clienteId == visita.clienteId && 
      f.formularioId == rutina.plantillaId
    );
  }

  int _calcularPorcentajeFormulario() {
    // TODO: Implementar cálculo real basado en respuestas del formulario
    if (_tieneFormularioRutina()) {
      return 100; // Por ahora asumimos que está completo
    }
    return 0;
  }

  String _obtenerEstadoVisita() {
    if (visita.estatus == 'completada' || visita.horaFin != null) {
      return 'COMPLETADA';
    } else if (visita.estatus == 'en_proceso' || visita.horaInicio != null) {
      return 'EN_PROCESO';
    } else if (visita.estatus == 'cancelada') {
      return 'OMITIDA';
    }
    return 'PENDIENTE';
  }

  int _calcularDuracion() {
    if (visita.horaInicio == null || visita.horaFin == null) return 0;
    try {
      final inicio = DateTime.parse(visita.horaInicio!);
      final fin = DateTime.parse(visita.horaFin!);
      return fin.difference(inicio).inMinutes;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    IconData icon;
    
    switch (estado) {
      case 'COMPLETADA':
        color = const Color(0xFF38A169);
        icon = Icons.check_circle;
        break;
      case 'EN_PROCESO':
        color = const Color(0xFFF6C343);
        icon = Icons.timelapse;
        break;
      case 'OMITIDA':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      default:
        color = const Color(0xFFDE1327);
        icon = Icons.pending;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            estado,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioBadge(bool tieneFormulario, int porcentaje) {
    final color = tieneFormulario 
        ? (porcentaje >= 80 ? const Color(0xFF38A169) : const Color(0xFFF6C343))
        : const Color(0xFF8F8E8E);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tieneFormulario ? Icons.assignment_turned_in : Icons.assignment_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            tieneFormulario ? '$porcentaje%' : 'Sin form.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompromisosBadge(int cantidad) {
    // Por ahora usar el color amarillo para indicar compromisos pendientes
    // ya que el modelo CompromisoHive no tiene campo status
    final color = cantidad > 0 
        ? const Color(0xFFF6C343) // Amarillo para compromisos existentes
        : const Color(0xFF38A169); // Verde si no hay compromisos
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.handshake,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$cantidad comp.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadoresBadge(int cantidad) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics,
            size: 12,
            color: Colors.purple,
          ),
          const SizedBox(width: 4),
          Text(
            '$cantidad ind.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}