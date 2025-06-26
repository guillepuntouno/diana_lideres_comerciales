import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../../../servicios/resultados_dia_service.dart';

/// Bottom sheet para mostrar el detalle completo de una visita (solo lectura)
class DetalleVisitaBottomSheet extends StatelessWidget {
  final VisitaClienteUnificadaHive visita;
  final ResultadosDiaService service;

  const DetalleVisitaBottomSheet({
    Key? key,
    required this.visita,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final infoCliente = service.obtenerInfoCliente(visita.clienteId);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle del bottom sheet
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Encabezado
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle de Visita',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C2120),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            infoCliente['nombre'] ?? 'Cliente ${visita.clienteId}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Contenido scrolleable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Check-in/Check-out
                    _buildSeccion(
                      titulo: 'Registro de Visita',
                      icono: Icons.access_time,
                      contenido: _buildCheckInOut(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Cuestionario
                    if (visita.cuestionario != null) ...[
                      _buildSeccion(
                        titulo: 'Cuestionario',
                        icono: Icons.assignment,
                        contenido: _buildCuestionario(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Compromisos
                    if (visita.compromisos.isNotEmpty) ...[
                      _buildSeccion(
                        titulo: 'Compromisos (${visita.compromisos.length})',
                        icono: Icons.handshake,
                        contenido: _buildCompromisos(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Retroalimentación
                    if (visita.retroalimentacion != null && visita.retroalimentacion!.isNotEmpty) ...[
                      _buildSeccion(
                        titulo: 'Retroalimentación',
                        icono: Icons.comment,
                        contenido: _buildTexto(visita.retroalimentacion!),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Reconocimiento
                    if (visita.reconocimiento != null && visita.reconocimiento!.isNotEmpty) ...[
                      _buildSeccion(
                        titulo: 'Reconocimiento',
                        icono: Icons.star,
                        contenido: _buildTexto(visita.reconocimiento!),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required Widget contenido,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: const Color(0xFFDE1327)),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        contenido,
      ],
    );
  }

  Widget _buildCheckInOut() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Check-in
          if (visita.horaInicio != null) ...[
            _buildRegistroTiempo(
              titulo: 'Check-in',
              hora: visita.horaInicio!,
              ubicacion: visita.ubicacionInicio,
              comentario: visita.comentarioInicio,
              color: Colors.green,
            ),
          ],
          
          if (visita.horaInicio != null && visita.horaFin != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          
          // Check-out
          if (visita.horaFin != null) ...[
            _buildRegistroTiempo(
              titulo: 'Check-out',
              hora: visita.horaFin!,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            // Duración
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Duración: ${_calcularDuracion()} minutos',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistroTiempo({
    required String titulo,
    required String hora,
    UbicacionUnificadaHive? ubicacion,
    String? comentario,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatearHoraCompleta(hora),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        
        if (ubicacion != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Lat: ${ubicacion.lat.toStringAsFixed(6)}, Lon: ${ubicacion.lon.toStringAsFixed(6)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
        
        if (comentario != null && comentario.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              comentario,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCuestionario() {
    final cuestionario = visita.cuestionario!;
    
    return Column(
      children: [
        // Tipo de Exhibidor
        if (cuestionario.tipoExhibidor != null) ...[
          _buildSubseccion(
            'Tipo de Exhibidor',
            _buildRespuestasExhibidor(cuestionario.tipoExhibidor!),
          ),
        ],
        
        // Estándares de Ejecución
        if (cuestionario.estandaresEjecucion != null) ...[
          const SizedBox(height: 16),
          _buildSubseccion(
            'Estándares de Ejecución',
            _buildRespuestasEstandares(cuestionario.estandaresEjecucion!),
          ),
        ],
        
        // Disponibilidad
        if (cuestionario.disponibilidad != null) ...[
          const SizedBox(height: 16),
          _buildSubseccion(
            'Disponibilidad',
            _buildRespuestasDisponibilidad(cuestionario.disponibilidad!),
          ),
        ],
      ],
    );
  }

  Widget _buildSubseccion(String titulo, Widget contenido) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          contenido,
        ],
      ),
    );
  }

  Widget _buildRespuestasExhibidor(TipoExhibidorHive exhibidor) {
    return Column(
      children: [
        _buildRespuestaItem('¿Posee exhibidor adecuado?', exhibidor.poseeAdecuado ? 'Sí' : 'No'),
        if (exhibidor.tipo != null)
          _buildRespuestaItem('Tipo', exhibidor.tipo!),
        if (exhibidor.modelo != null)
          _buildRespuestaItem('Modelo', exhibidor.modelo!),
        if (exhibidor.cantidad != null)
          _buildRespuestaItem('Cantidad', exhibidor.cantidad.toString()),
      ],
    );
  }

  Widget _buildRespuestasEstandares(EstandaresEjecucionHive estandares) {
    return Column(
      children: [
        _buildRespuestaBool('Primera posición', estandares.primeraPosicion),
        _buildRespuestaBool('Planograma', estandares.planograma),
        _buildRespuestaBool('Portafolio foco', estandares.portafolioFoco),
        _buildRespuestaBool('Anclaje', estandares.anclaje),
      ],
    );
  }

  Widget _buildRespuestasDisponibilidad(DisponibilidadHive disponibilidad) {
    return Column(
      children: [
        _buildRespuestaBool('Ristras', disponibilidad.ristras),
        _buildRespuestaBool('Max', disponibilidad.max),
        _buildRespuestaBool('Familiar', disponibilidad.familiar),
        _buildRespuestaBool('Dulce', disponibilidad.dulce),
        _buildRespuestaBool('Galleta', disponibilidad.galleta),
      ],
    );
  }

  Widget _buildRespuestaItem(String pregunta, String respuesta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            pregunta,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            respuesta,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1C2120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRespuestaBool(String pregunta, bool valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            pregunta,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Icon(
            valor ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: valor ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCompromisos() {
    return Column(
      children: visita.compromisos.map((compromiso) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      compromiso.tipo,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cant: ${compromiso.cantidad}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                compromiso.detalle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Fecha límite: ${_formatearFecha(compromiso.fechaPlazo)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTexto(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.5,
        ),
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

  String _formatearHoraCompleta(String isoString) {
    try {
      final fecha = DateTime.parse(isoString);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} '
             '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day.toString().padLeft(2, '0')}/'
             '${date.month.toString().padLeft(2, '0')}/'
             '${date.year}';
    } catch (e) {
      return fecha;
    }
  }
}