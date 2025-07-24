// lib/mobile/vistas/resumen/pantalla_resumen_visita.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:diana_lc_front/shared/modelos/activity_model.dart';
import 'package:diana_lc_front/shared/modelos/visita_cliente_modelo.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/servicios/visita_cliente_unificado_service.dart';
import 'package:diana_lc_front/shared/servicios/clientes_servicio.dart';
import 'package:diana_lc_front/shared/modelos/formulario_dto.dart';

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
  final ClientesServicio _clientesServicio = ClientesServicio();
  
  bool _isLoading = true;
  VisitaClienteUnificadaHive? _visitaUnificada;
  bool _modoConsulta = false;
  Map<String, dynamic>? _infoCliente;
  List<FormularioDiaHive> _formulariosCliente = [];
  
  // Formulario dinámico
  FormularioPlantillaDTO? _formularioDinamico;
  Map<String, dynamic>? _respuestasFormulario;
  
  @override
  void initState() {
    super.initState();
    // No llamar _cargarDatos aquí porque ModalRoute no está disponible
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Llamar _cargarDatos solo una vez cuando las dependencias estén listas
    if (_isLoading) {
      _cargarDatos();
    }
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
        print('🔍 Cargando datos de resumen:');
        print('   Plan ID: $planId');
        print('   Día: $dia');
        print('   Cliente ID: $clienteId');
        
        _visitaUnificada = await _visitaUnificadoService.obtenerVisitaDesdeplan(
          planId: planId,
          dia: dia,
          clienteId: clienteId,
        );
        
        print('📊 Visita unificada cargada: ${_visitaUnificada != null}');
        if (_visitaUnificada != null) {
          print('   Estatus: ${_visitaUnificada!.estatus}');
          print('   Hora inicio: ${_visitaUnificada!.horaInicio}');
          print('   Hora fin: ${_visitaUnificada!.horaFin}');
          print('   Cuestionario: ${_visitaUnificada!.cuestionario != null}');
          print('   Compromisos: ${_visitaUnificada!.compromisos.length}');
          print('   Retroalimentación: ${_visitaUnificada!.retroalimentacion}');
          print('   Reconocimiento: ${_visitaUnificada!.reconocimiento}');
        }
        
        // Cargar formularios dinámicos del cliente
        _formulariosCliente = await _visitaUnificadoService.obtenerFormulariosCliente(
          planId: planId,
          dia: dia,
          clienteId: clienteId,
        );
        print('📝 Formularios cargados: ${_formulariosCliente.length}');
        
        // Usar información del cliente que viene en los argumentos
        // No intentar cargar desde API en modo consulta
        _infoCliente = {
          'nombre': args['clienteNombre'] ?? 'Cliente $clienteId',
          'direccion': '',
          'asesor': '',
        };
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
    
    // Obtener datos del formulario dinámico si existen
    if (args['formularioDinamico'] != null) {
      final formularioDinamico = args['formularioDinamico'] as Map<String, dynamic>;
      _formularioDinamico = formularioDinamico['plantilla'] as FormularioPlantillaDTO?;
      _respuestasFormulario = formularioDinamico['respuestas'] as Map<String, dynamic>?;
    }
    
    // En modo consulta, los formularios ya vienen en la estructura unificada
    // No necesitamos construirlos manualmente

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
      body: _modoConsulta
          ? (_visitaUnificada != null
              ? _buildModoConsulta()
              : _buildErrorNoData())
          : _buildModoNormal(actividad, visita, formularios, duracion),
    );
  }

  Widget _buildModoConsulta() {
    // Si la visita está pendiente, mostrar mensaje apropiado
    if (_visitaUnificada!.estatus == 'pendiente') {
      return _buildVisitaPendiente();
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header moderno sin el ojo
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _visitaUnificada!.estatus == 'terminado'
                      ? AppColors.dianaGreen
                      : AppColors.dianaYellow,
                  _visitaUnificada!.estatus == 'terminado'
                      ? AppColors.dianaGreen.withOpacity(0.8)
                      : AppColors.dianaYellow.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Botón de regreso
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Contenido central
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _visitaUnificada!.estatus == 'terminado'
                                ? Icons.check_circle_outline
                                : Icons.access_time,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _infoCliente?['nombre'] ?? 'Cliente ${_visitaUnificada!.clienteId}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatearEstatus(_visitaUnificada!.estatus),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la visita
                _buildSeccionModerna(
                  titulo: 'Información de la Visita',
                  icono: Icons.info_outline,
                  contenido: _buildInfoVisitaContent(),
                ),
                
                // Cuestionario si existe
                if (_visitaUnificada!.cuestionario != null) ...[
                  const SizedBox(height: 16),
                  _buildSeccionModerna(
                    titulo: 'Evaluación Realizada',
                    icono: Icons.assignment_turned_in,
                    contenido: _buildCuestionarioContent(),
                  ),
                ],
                
                // Compromisos si existen
                if (_visitaUnificada!.compromisos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSeccionModerna(
                    titulo: 'Compromisos Acordados',
                    icono: Icons.handshake,
                    contenido: _buildCompromisosContent(),
                  ),
                ],
                
                // Formularios dinámicos si existen
                if (_formulariosCliente.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSeccionModerna(
                    titulo: 'Formularios Dinámicos',
                    icono: Icons.dynamic_form,
                    contenido: _buildFormulariosDinamicosContent(),
                  ),
                ],
                
                // Retroalimentación y reconocimiento
                if (_visitaUnificada!.retroalimentacion != null ||
                    _visitaUnificada!.reconocimiento != null) ...[
                  const SizedBox(height: 16),
                  _buildSeccionModerna(
                    titulo: 'Retroalimentación y Reconocimiento',
                    icono: Icons.comment,
                    contenido: _buildComentariosContent(),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dianaRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

          // Mostrar formulario dinámico si existe
          if (_formularioDinamico != null && _respuestasFormulario != null) ...[
            _buildFormularioDinamicoResumen(),
          ] else ...[
            // Mostrar formularios estáticos originales
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
          ],

          // Comentarios siempre se muestran (estático)
          if (formularios['comentarios'] != null)
            _buildComentarios(formularios['comentarios']),
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

  Widget _buildFormularioDinamicoResumen() {
    if (_formularioDinamico == null || _respuestasFormulario == null) {
      return const SizedBox.shrink();
    }

    // Agrupar preguntas por sección
    Map<String, List<PreguntaDTO>> preguntasPorSeccion = {};
    for (var pregunta in _formularioDinamico!.questions) {
      if (!preguntasPorSeccion.containsKey(pregunta.section)) {
        preguntasPorSeccion[pregunta.section] = [];
      }
      preguntasPorSeccion[pregunta.section]!.add(pregunta);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: preguntasPorSeccion.entries.map((entry) {
        final seccion = entry.key;
        final preguntas = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist, size: 18, color: AppColors.dianaRed),
                  const SizedBox(width: 8),
                  Text(
                    seccion,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Mostrar respuestas de cada pregunta
              ...preguntas.map((pregunta) {
                final respuesta = _respuestasFormulario![pregunta.name];
                if (respuesta == null) return const SizedBox.shrink();
                
                return _buildRespuestaDinamica(pregunta, respuesta);
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRespuestaDinamica(PreguntaDTO pregunta, dynamic respuesta) {
    switch (pregunta.tipoEntrada) {
      case 'SI_NO':
        return _buildRespuestaBool(pregunta.etiqueta, respuesta as bool);
        
      case 'SELECCION_UNICA':
        return _buildRespuestaTexto(pregunta.etiqueta, respuesta as String);
        
      case 'SELECCION_MULTIPLE':
        final valores = (respuesta as List).cast<String>().join(', ');
        return _buildRespuestaTexto(pregunta.etiqueta, valores);
        
      case 'NUMERO':
        return _buildRespuestaTexto(pregunta.etiqueta, respuesta.toString());
        
      case 'TEXTO':
        return _buildRespuestaTexto(pregunta.etiqueta, respuesta as String);
        
      default:
        return const SizedBox.shrink();
    }
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
  
  Widget _buildSeccionModerna({
    required String titulo,
    required IconData icono,
    required Widget contenido,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, size: 24, color: AppColors.dianaRed),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: contenido,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoVisitaContent() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final dia = args?['dia'] ?? '';
    
    return Column(
      children: [
        _buildInfoItem(
          'Cliente ID',
          _visitaUnificada!.clienteId,
          Icons.badge,
        ),
        if (_infoCliente?['direccion'] != null)
          _buildInfoItem(
            'Dirección',
            _infoCliente!['direccion'],
            Icons.location_on,
          ),
        if (_infoCliente?['asesor'] != null)
          _buildInfoItem(
            'Asesor',
            _infoCliente!['asesor'],
            Icons.person,
          ),
        if (dia.isNotEmpty)
          _buildInfoItem(
            'Día programado',
            dia,
            Icons.calendar_today,
          ),
        if (_visitaUnificada!.horaInicio != null)
          _buildInfoItem(
            'Hora de inicio',
            _formatearHora(DateTime.parse(_visitaUnificada!.horaInicio!)),
            Icons.access_time,
          ),
        if (_visitaUnificada!.horaFin != null)
          _buildInfoItem(
            'Hora de fin',
            _formatearHora(DateTime.parse(_visitaUnificada!.horaFin!)),
            Icons.timer_off,
          ),
        if (_visitaUnificada!.horaInicio != null && _visitaUnificada!.horaFin != null)
          _buildInfoItem(
            'Duración',
            _calcularDuracionVisita(),
            Icons.timelapse,
          ),
        if (_visitaUnificada!.comentarioInicio != null && _visitaUnificada!.comentarioInicio!.isNotEmpty)
          _buildInfoItem(
            'Comentario de inicio',
            _visitaUnificada!.comentarioInicio!,
            Icons.note,
          ),
      ],
    );
  }
  
  Widget _buildCuestionarioContent() {
    final cuestionario = _visitaUnificada!.cuestionario!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo de Exhibidor
        if (cuestionario.tipoExhibidor != null) ...[
          _buildSubseccion(
            'Tipo de Exhibidor',
            Icons.store_mall_directory,
            [
              _buildCheckItem(
                'Posee exhibidor adecuado',
                cuestionario.tipoExhibidor!.poseeAdecuado,
              ),
              if (cuestionario.tipoExhibidor!.tipo != null)
                _buildInfoSimple('Tipo', cuestionario.tipoExhibidor!.tipo!),
              if (cuestionario.tipoExhibidor!.modelo != null)
                _buildInfoSimple('Modelo', cuestionario.tipoExhibidor!.modelo!),
              if (cuestionario.tipoExhibidor!.cantidad != null)
                _buildInfoSimple('Cantidad', '${cuestionario.tipoExhibidor!.cantidad}'),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Estándares de Ejecución
        if (cuestionario.estandaresEjecucion != null) ...[
          _buildSubseccion(
            'Estándares de Ejecución',
            Icons.checklist,
            [
              _buildCheckItem(
                'Primera posición',
                cuestionario.estandaresEjecucion!.primeraPosicion,
              ),
              _buildCheckItem(
                'Planograma',
                cuestionario.estandaresEjecucion!.planograma,
              ),
              _buildCheckItem(
                'Portafolio foco',
                cuestionario.estandaresEjecucion!.portafolioFoco,
              ),
              _buildCheckItem(
                'Anclaje',
                cuestionario.estandaresEjecucion!.anclaje,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Disponibilidad
        if (cuestionario.disponibilidad != null) ...[
          _buildSubseccion(
            'Disponibilidad de Productos',
            Icons.inventory,
            [
              _buildCheckItem('Ristras', cuestionario.disponibilidad!.ristras),
              _buildCheckItem('Max', cuestionario.disponibilidad!.max),
              _buildCheckItem('Familiar', cuestionario.disponibilidad!.familiar),
              _buildCheckItem('Dulce', cuestionario.disponibilidad!.dulce),
              _buildCheckItem('Galleta', cuestionario.disponibilidad!.galleta),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildCompromisosContent() {
    return Column(
      children: _visitaUnificada!.compromisos.asMap().entries.map((entry) {
        final index = entry.key;
        final compromiso = entry.value;
        
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
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.dianaGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dianaGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      compromiso.tipo,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                compromiso.detalle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cantidad: ${compromiso.cantidad}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    compromiso.fechaPlazo,
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
    );
  }

  Widget _buildComentariosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_visitaUnificada!.retroalimentacion != null) ...[
          _buildComentarioCard(
            titulo: 'Retroalimentación',
            contenido: _visitaUnificada!.retroalimentacion!,
            icono: Icons.feedback,
            color: AppColors.dianaYellow,
          ),
          if (_visitaUnificada!.reconocimiento != null)
            const SizedBox(height: 12),
        ],
        if (_visitaUnificada!.reconocimiento != null)
          _buildComentarioCard(
            titulo: 'Reconocimiento',
            contenido: _visitaUnificada!.reconocimiento!,
            icono: Icons.star,
            color: AppColors.dianaGreen,
          ),
      ],
    );
  }

  Widget _buildComentarioCard({
    required String titulo,
    required String contenido,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.mediumGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.mediumGray),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubseccion(String titulo, IconData icono, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: AppColors.dianaRed),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.dianaGreen : Colors.grey.shade300,
            ),
            child: Icon(
              value ? Icons.check : Icons.close,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSimple(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.mediumGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearEstatus(String estatus) {
    switch (estatus) {
      case 'terminado':
        return 'Visita Completada';
      case 'en_proceso':
        return 'Visita en Proceso';
      default:
        return 'Visita Pendiente';
    }
  }

  String _formatearHora(DateTime fecha) {
    return DateFormat('hh:mm a').format(fecha);
  }

  String _calcularDuracionVisita() {
    if (_visitaUnificada!.horaInicio == null || _visitaUnificada!.horaFin == null) {
      return 'N/A';
    }
    
    final inicio = DateTime.parse(_visitaUnificada!.horaInicio!);
    final fin = DateTime.parse(_visitaUnificada!.horaFin!);
    final duracion = fin.difference(inicio);
    
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);
    
    if (horas > 0) {
      return '${horas}h ${minutos}min';
    } else {
      return '${minutos} minutos';
    }
  }

  // Mantener el método existente para el modo normal
  Widget _buildModoNormal(
    ActivityModel? actividad,
    VisitaClienteModelo? visita,
    Map<String, dynamic>? formularios,
    Duration? duracion,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderExito(actividad, duracion),
          const SizedBox(height: 24),
          _buildInfoCliente(actividad, visita),
          const SizedBox(height: 24),
          if (formularios != null) _buildResumenFormulario(formularios),
          const SizedBox(height: 24),
          if (formularios?['compromisos']?['compromisos'] != null)
            _buildCompromisos(formularios!['compromisos']['compromisos']),
          const SizedBox(height: 32),
          _buildBotonesAccion(context),
        ],
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
  
  Widget _buildFormulariosDinamicosContent() {
    return Column(
      children: _formulariosCliente.map((formulario) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Formulario: ${formulario.formularioId}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                  Text(
                    _formatearFechaCorta(formulario.fechaCaptura),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildRespuestasFormulario(formulario.respuestas),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  List<Widget> _buildRespuestasFormulario(Map<String, dynamic> respuestas) {
    List<Widget> widgets = [];
    
    respuestas.forEach((pregunta, respuesta) {
      if (respuesta != null && respuesta.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatearPregunta(pregunta),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (respuesta is bool)
                  Row(
                    children: [
                      Icon(
                        respuesta ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: respuesta ? AppColors.dianaGreen : AppColors.dianaRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        respuesta ? 'Sí' : 'No',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  )
                else if (respuesta is List)
                  ...respuesta.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 16, color: AppColors.mediumGray),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList()
                else
                  Text(
                    respuesta.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.darkGray,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    });
    
    return widgets;
  }
  
  String _formatearPregunta(String key) {
    // Convertir keys del formulario a texto legible
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ')
        .trim();
  }
  
  String _formatearFechaCorta(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }
  
  Widget _buildErrorNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppColors.dianaYellow,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron datos de la visita',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Es posible que la visita aún no haya sido iniciada o no exista en el plan.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Regresar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVisitaPendiente() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.dianaRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalle de Visita',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pending_actions,
                  size: 64,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _infoCliente?['nombre'] ?? 'Cliente ${_visitaUnificada!.clienteId}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Visita Pendiente',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mediumGray,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Esta visita aún no ha sido iniciada',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Día programado: ${args?['dia'] ?? "No especificado"}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.mediumGray.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    'Volver a Resultados',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dianaRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
