// lib/vistas/resumen/pantalla_resumen_visita.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../modelos/activity_model.dart';
import '../../modelos/visita_cliente_modelo.dart';
import '../../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../../servicios/visita_cliente_unificado_service.dart';

class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

class PantallaResumenVisita extends StatefulWidget {
  const PantallaResumenVisita({super.key});

  @override
  State<PantallaResumenVisita> createState() => _PantallaResumenVisitaState();
}

class _PantallaResumenVisitaState extends State<PantallaResumenVisita> {
  final VisitaClienteUnificadoService _visitaUnificadoService = 
      VisitaClienteUnificadoService();
  
  bool _isLoading = true;
  VisitaClienteUnificadaHive? _visitaUnificada;
  bool _modoConsulta = false;
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
  
  Future<void> _cargarDatos() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args['modoConsulta'] == true) {
      _modoConsulta = true;
      
      // Cargar datos del plan unificado
      final planId = args['planId'] as String?;
      final dia = args['dia'] as String?;
      final clienteId = args['clienteId'] as String?;
      
      if (planId != null && dia != null && clienteId != null) {
        _visitaUnificada = await _visitaUnificadoService.obtenerVisitaDesdeplan(
          planId: planId,
          dia: dia,
          clienteId: clienteId,
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.dianaRed),
        ),
      );
    }
    
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Error al cargar resumen',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final ActivityModel? actividad = args['actividad'] as ActivityModel?;
    final VisitaClienteModelo? visita = args['visita'] as VisitaClienteModelo?;
    Map<String, dynamic>? formularios =
        args['formularios'] as Map<String, dynamic>?;
    final Duration? duracion = args['duracion'] as Duration?;
    
    // En modo consulta, construir formularios desde la visita unificada
    if (_modoConsulta && _visitaUnificada != null) {
      formularios = _construirFormulariosDesdeUnificada(_visitaUnificada!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.dianaRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _modoConsulta ? 'Detalle de Visita' : 'Resumen de Visita',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_modoConsulta)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _compartirResumen(context, actividad, visita),
              tooltip: 'Compartir resumen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de éxito o consulta
            _modoConsulta
                ? _buildHeaderConsulta(args)
                : _buildHeaderExito(actividad, duracion),

            const SizedBox(height: 24),

            // Información del cliente
            _modoConsulta
                ? _buildInfoClienteUnificada(args, _visitaUnificada)
                : _buildInfoCliente(actividad, visita),

            const SizedBox(height: 24),

            // Resumen del formulario
            if (formularios != null) _buildResumenFormulario(formularios),

            const SizedBox(height: 24),

            // Compromisos creados
            if (formularios?['seccion4']?['compromisos'] != null)
              _buildCompromisos(formularios!['seccion4']['compromisos']),

            const SizedBox(height: 32),

            // Botones de acción
            _modoConsulta
                ? _buildBotonesAccionConsulta(context)
                : _buildBotonesAccion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderExito(ActivityModel? actividad, Duration? duracion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dianaGreen, AppColors.dianaGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dianaGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            '¡Visita Completada!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            actividad?.title ?? 'Cliente',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          if (duracion != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Duración: ${_formatearDuracion(duracion)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCliente(
    ActivityModel? actividad,
    VisitaClienteModelo? visita,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            'Información de la Visita',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow('Cliente:', actividad?.title ?? 'N/A'),
          _buildInfoRow('ID Cliente:', actividad?.cliente ?? 'N/A'),
          _buildInfoRow('Dirección:', actividad?.direccion ?? 'N/A'),
          _buildInfoRow('Ruta:', actividad?.asesor ?? 'N/A'),

          if (visita != null) ...[
            _buildInfoRow(
              'Hora inicio:',
              _formatearFecha(visita.checkIn.timestamp),
            ),
            if (visita.checkOut != null)
              _buildInfoRow(
                'Hora fin:',
                _formatearFecha(visita.checkOut!.timestamp),
              ),
            _buildInfoRow('Estado:', visita.estatus.toUpperCase()),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenFormulario(Map<String, dynamic> formularios) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            'Resumen de Evaluación',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          // Sección 1: Tipo de Exhibidor
          if (formularios['seccion1'] != null)
            _buildSeccionResumen(
              'Tipo de Exhibidor',
              formularios['seccion1'],
              Icons.store,
            ),

          // Sección 2: Estándares de Ejecución
          if (formularios['seccion2'] != null)
            _buildSeccionResumen(
              'Estándares de Ejecución',
              formularios['seccion2'],
              Icons.checklist,
            ),

          // Sección 3: Disponibilidad
          if (formularios['seccion3'] != null)
            _buildSeccionResumen(
              'Disponibilidad',
              formularios['seccion3'],
              Icons.inventory,
            ),

          // Sección 5: Comentarios
          if (formularios['seccion5'] != null)
            _buildComentarios(formularios['seccion5']),
        ],
      ),
    );
  }

  Widget _buildSeccionResumen(
    String titulo,
    Map<String, dynamic> datos,
    IconData icono,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: AppColors.dianaRed),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mostrar campos con respuestas
          ...datos.entries.where((entry) => entry.value != null).map((entry) {
            if (entry.value is bool) {
              return _buildRespuestaBool(entry.key, entry.value);
            } else if (entry.value is String && entry.value.isNotEmpty) {
              return _buildRespuestaTexto(entry.key, entry.value);
            } else if (entry.value is int) {
              return _buildRespuestaTexto(entry.key, entry.value.toString());
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCompromisos(List<dynamic> compromisos) {
    if (compromisos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dianaGreen.withOpacity(0.3)),
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
            children: [
              Icon(
                Icons.assignment_turned_in,
                size: 20,
                color: AppColors.dianaGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Compromisos Creados (${compromisos.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...compromisos.asMap().entries.map((entry) {
            final index = entry.key;
            final compromiso = entry.value as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dianaGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dianaGreen.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${compromiso['tipo'] ?? 'Sin tipo'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detalle: ${compromiso['detalle'] ?? 'Sin detalle'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Cantidad: ${compromiso['cantidad'] ?? 0}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Fecha: ${compromiso['fechaFormateada'] ?? 'No definida'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildComentarios(Map<String, dynamic> comentarios) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment, size: 18, color: AppColors.dianaRed),
              const SizedBox(width: 8),
              Text(
                'Comentarios',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (comentarios['retroalimentacion']?.isNotEmpty == true)
            _buildComentario(
              'Retroalimentación',
              comentarios['retroalimentacion'],
            ),

          if (comentarios['reconocimiento']?.isNotEmpty == true)
            _buildComentario('Reconocimiento', comentarios['reconocimiento']),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/rutina_diaria');
            },
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: Text(
              'Volver a Rutinas',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dianaRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
            icon: const Icon(Icons.home, color: AppColors.dianaRed),
            label: Text(
              'Ir al Inicio',
              style: GoogleFonts.poppins(
                color: AppColors.dianaRed,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.dianaRed),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mediumGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRespuestaBool(String campo, bool valor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(
            valor ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: valor ? AppColors.dianaGreen : AppColors.dianaRed,
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatearCampo(campo)}: ${valor ? "SÍ" : "NO"}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildRespuestaTexto(String campo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        '${_formatearCampo(campo)}: $valor',
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.darkGray),
      ),
    );
  }

  Widget _buildComentario(String titulo, String contenido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contenido,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearCampo(String campo) {
    // Convertir camelCase a texto legible
    return campo
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .toLowerCase()
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ')
        .trim();
  }

  String _formatearDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);

    if (horas > 0) {
      return '${horas}h ${minutos}min';
    } else {
      return '${minutos}min';
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  void _compartirResumen(
    BuildContext context,
    ActivityModel? actividad,
    VisitaClienteModelo? visita,
  ) {
    // TODO: Implementar compartir resumen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Función de compartir en desarrollo',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.dianaYellow,
      ),
    );
  }
  
  Widget _buildHeaderConsulta(Map<String, dynamic>? args) {
    final clienteNombre = args?['clienteNombre'] ?? 'Cliente';
    final dia = args?['dia'] ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dianaRed, AppColors.dianaRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dianaRed.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            'Detalle de Visita',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            clienteNombre,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          if (dia.isNotEmpty) ...[  
            const SizedBox(height: 8),
            Text(
              'Día: $dia',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoClienteUnificada(
    Map<String, dynamic>? args,
    VisitaClienteUnificadaHive? visitaUnificada,
  ) {
    final clienteNombre = args?['clienteNombre'] ?? 'N/A';
    final clienteId = args?['clienteId'] ?? 'N/A';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            'Información de la Visita',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow('Cliente:', clienteNombre),
          _buildInfoRow('ID Cliente:', clienteId),
          
          if (visitaUnificada != null) ...[
            if (visitaUnificada.horaInicio != null)
              _buildInfoRow(
                'Hora inicio:',
                _formatearFecha(DateTime.parse(visitaUnificada.horaInicio!)),
              ),
            if (visitaUnificada.horaFin != null)
              _buildInfoRow(
                'Hora fin:',
                _formatearFecha(DateTime.parse(visitaUnificada.horaFin!)),
              ),
            _buildInfoRow('Estado:', visitaUnificada.estatus.toUpperCase()),
            
            if (visitaUnificada.ubicacionInicio != null)
              _buildInfoRow(
                'Ubicación:',
                'Lat: ${visitaUnificada.ubicacionInicio!.lat.toStringAsFixed(4)}, '
                'Lon: ${visitaUnificada.ubicacionInicio!.lon.toStringAsFixed(4)}',
              ),
              
            if (visitaUnificada.comentarioInicio?.isNotEmpty == true)
              _buildInfoRow('Comentario inicio:', visitaUnificada.comentarioInicio!),
          ],
        ],
      ),
    );
  }
  
  Map<String, dynamic> _construirFormulariosDesdeUnificada(
    VisitaClienteUnificadaHive visitaUnificada,
  ) {
    final formularios = <String, dynamic>{};
    
    // Construir sección 1: Tipo de Exhibidor
    if (visitaUnificada.cuestionario?.tipoExhibidor != null) {
      final tipo = visitaUnificada.cuestionario!.tipoExhibidor!;
      formularios['seccion1'] = {
        'poseeAdecuado': tipo.poseeAdecuado,
        if (tipo.tipo != null) 'tipo': tipo.tipo,
        if (tipo.modelo != null) 'modelo': tipo.modelo,
        if (tipo.cantidad != null) 'cantidad': tipo.cantidad,
      };
    }
    
    // Construir sección 2: Estándares de Ejecución
    if (visitaUnificada.cuestionario?.estandaresEjecucion != null) {
      final estandares = visitaUnificada.cuestionario!.estandaresEjecucion!;
      formularios['seccion2'] = {
        'primeraPosicion': estandares.primeraPosicion,
        'planograma': estandares.planograma,
        'portafolioFoco': estandares.portafolioFoco,
        'anclaje': estandares.anclaje,
      };
    }
    
    // Construir sección 3: Disponibilidad
    if (visitaUnificada.cuestionario?.disponibilidad != null) {
      final disponibilidad = visitaUnificada.cuestionario!.disponibilidad!;
      formularios['seccion3'] = {
        'ristras': disponibilidad.ristras,
        'max': disponibilidad.max,
        'familiar': disponibilidad.familiar,
        'dulce': disponibilidad.dulce,
        'galleta': disponibilidad.galleta,
      };
    }
    
    // Construir sección 4: Compromisos
    if (visitaUnificada.compromisos.isNotEmpty) {
      formularios['seccion4'] = {
        'compromisos': visitaUnificada.compromisos.map((c) => {
          'tipo': c.tipo,
          'detalle': c.detalle,
          'cantidad': c.cantidad,
          'fechaFormateada': c.fechaPlazo,
        }).toList(),
      };
    }
    
    // Construir sección 5: Comentarios
    if (visitaUnificada.retroalimentacion?.isNotEmpty == true ||
        visitaUnificada.reconocimiento?.isNotEmpty == true) {
      formularios['seccion5'] = {
        if (visitaUnificada.retroalimentacion?.isNotEmpty == true)
          'retroalimentacion': visitaUnificada.retroalimentacion,
        if (visitaUnificada.reconocimiento?.isNotEmpty == true)
          'reconocimiento': visitaUnificada.reconocimiento,
      };
    }
    
    return formularios;
  }
  
  Widget _buildBotonesAccionConsulta(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: Text(
              'Volver a Rutinas',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dianaRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            icon: const Icon(Icons.home, color: AppColors.dianaRed),
            label: Text(
              'Ir al Inicio',
              style: GoogleFonts.poppins(
                color: AppColors.dianaRed,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.dianaRed),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
