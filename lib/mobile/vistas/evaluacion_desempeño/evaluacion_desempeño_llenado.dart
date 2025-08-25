import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:diana_lc_front/shared/servicios/formularios_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/modelos/formulario_evaluacion_dto.dart';
import 'package:diana_lc_front/shared/modelos/pregunta_dto.dart';
import 'package:diana_lc_front/shared/modelos/opcion_dto.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/shared/repositorios/programa_excelencia_local_repository.dart';

class EvaluacionDesempenioLlenado extends StatefulWidget {
  const EvaluacionDesempenioLlenado({Key? key}) : super(key: key);

  @override
  State<EvaluacionDesempenioLlenado> createState() => _EvaluacionDesempenioLlenadoState();
}

class _EvaluacionDesempenioLlenadoState extends State<EvaluacionDesempenioLlenado> {
  late Map<String, dynamic> _evaluationData;
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _textControllers = {};
  
  // Datos dinámicos del formulario
  FormularioEvaluacionDTO? _formulario;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Repositorio para guardar en Hive
  final ProgramaExcelenciaLocalRepository _repository = ProgramaExcelenciaLocalRepository();
  final Uuid _uuid = const Uuid();
  
  // Datos estáticos de respaldo (se mantienen por compatibilidad)
  late List<Map<String, dynamic>> _formSections;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    _evaluationData = args ?? {};
    _loadFormForChannel();
  }
  
  void _loadFormForChannel() async {
    final channel = _evaluationData['channel']?.toString().toLowerCase() ?? 'detalle';
    final country = _evaluationData['country']?.toString().toUpperCase() ?? 'SV';
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('📋 === CARGA DE FORMULARIO EVALUACIÓN DESEMPEÑO ===');
      print('🎯 Canal: $channel');
      print('🌍 País: $country');
      
      // Intentar cargar formulario dinámico con filtrado robusto
      _formulario = await FormulariosService.obtenerFormularioParaCanal(
        channel, 
        paisUI: country,
      );
      
      if (_formulario != null) {
        print('✅ Formulario dinámico cargado: ${_formulario!.nombre}');
        print('🏷️ Tipo: ${_formulario!.tipo}');
        _initializeControllersFromDynamicForm();
      } else {
        print('❌ No se encontró formulario de Evaluación de Desempeño para:');
        print('  - Canal: $channel');
        print('  - País: $country');
        _showNoFormularioError(channel, country);
        return;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar formulario: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar formulario de evaluación';
      });
      
      _showConnectionError(e.toString());
    }
  }
  
  void _loadStaticForm(String channel) {
    if (channel == 'mayoreo') {
      _formSections = _getMayoreoForm();
    } else {
      _formSections = _getDetalleForm();
    }
    
    // Initialize text controllers for multiline fields
    for (var section in _formSections) {
      for (var question in section['questions']) {
        if (question['type'] == 'multiline') {
          _textControllers[question['name']] = TextEditingController();
        }
      }
    }
  }
  
  void _initializeControllersFromDynamicForm() {
    if (_formulario == null) return;
    
    for (var pregunta in _formulario!.preguntas) {
      if (pregunta.tipoEntrada == 'textarea' || pregunta.tipoEntrada == 'text') {
        _textControllers[pregunta.name] = TextEditingController();
      }
    }
  }
  
  List<Map<String, dynamic>> _getDetalleForm() {
    return [
      {
        'section': 'Conocimiento del Producto',
        'questions': [
          {
            'name': 'conoce_productos',
            'label': '¿El asesor conoce bien los productos que vende?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'explica_beneficios',
            'label': '¿Puede explicar los beneficios de cada producto?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'observaciones_producto',
            'label': 'Observaciones sobre conocimiento del producto',
            'type': 'multiline',
          },
        ],
      },
      {
        'section': 'Atención al Cliente',
        'questions': [
          {
            'name': 'saluda_clientes',
            'label': '¿El asesor saluda cordialmente a los clientes?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'escucha_necesidades',
            'label': '¿Escucha las necesidades del cliente antes de ofrecer productos?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'resuelve_dudas',
            'label': '¿Resuelve las dudas del cliente de manera clara?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'comentarios_atencion',
            'label': 'Comentarios sobre la atención al cliente',
            'type': 'multiline',
          },
        ],
      },
      {
        'section': 'Técnicas de Venta',
        'questions': [
          {
            'name': 'identifica_oportunidades',
            'label': '¿Identifica oportunidades de venta cruzada?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'maneja_objeciones',
            'label': '¿Maneja adecuadamente las objeciones del cliente?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'cierra_ventas',
            'label': '¿Cierra ventas de manera efectiva?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'areas_mejora',
            'label': 'Áreas de mejora identificadas',
            'type': 'multiline',
          },
        ],
      },
    ];
  }
  
  List<Map<String, dynamic>> _getMayoreoForm() {
    return [
      {
        'section': 'Gestión de Cuentas Clave',
        'questions': [
          {
            'name': 'conoce_cuentas_clave',
            'label': '¿El asesor conoce bien sus cuentas clave?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 15},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'plan_cuentas',
            'label': '¿Tiene un plan de desarrollo para cada cuenta?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 15},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'seguimiento_pedidos',
            'label': '¿Realiza seguimiento oportuno a los pedidos?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'observaciones_cuentas',
            'label': 'Observaciones sobre gestión de cuentas',
            'type': 'multiline',
          },
        ],
      },
      {
        'section': 'Negociación y Contratos',
        'questions': [
          {
            'name': 'prepara_negociaciones',
            'label': '¿Prepara adecuadamente las negociaciones?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 15},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'conoce_margenes',
            'label': '¿Conoce los márgenes y límites de negociación?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 15},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'documenta_acuerdos',
            'label': '¿Documenta correctamente los acuerdos comerciales?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'comentarios_negociacion',
            'label': 'Comentarios sobre habilidades de negociación',
            'type': 'multiline',
          },
        ],
      },
      {
        'section': 'Análisis y Estrategia',
        'questions': [
          {
            'name': 'analiza_competencia',
            'label': '¿Analiza la competencia en su territorio?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'propone_estrategias',
            'label': '¿Propone estrategias para incrementar ventas?',
            'type': 'radio',
            'options': [
              {'value': 'si', 'label': 'Sí', 'score': 10},
              {'value': 'no', 'label': 'No', 'score': 0},
            ],
          },
          {
            'name': 'plan_accion',
            'label': 'Plan de acción recomendado',
            'type': 'multiline',
          },
        ],
      },
    ];
  }
  
  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDE1327),
        title: Text(
          'Llenado — Evaluación de Desempeño',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeaderInfo(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando formulario...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_errorMessage != null) _buildErrorBanner(),
                        if (_formulario != null)
                          ..._buildDynamicSections()
                        else
                          ..._formSections.map((section) => _buildSection(section)),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de la Evaluación',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildInfoChip('País', _evaluationData['country'] ?? 'N/A'),
              _buildInfoChip('Líder', _evaluationData['leaderName'] ?? 'N/A'),
              _buildInfoChip('Canal', _evaluationData['channel'] ?? 'N/A'),
              _buildInfoChip('Asesor', _evaluationData['advisorName'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8F8E8E),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildDynamicSections() {
    if (_formulario == null) return [];
    
    // Agrupar preguntas por sección
    Map<String, List<PreguntaDTO>> secciones = {};
    
    for (var pregunta in _formulario!.preguntas) {
      final seccion = pregunta.seccion ?? 'General';
      if (!secciones.containsKey(seccion)) {
        secciones[seccion] = [];
      }
      secciones[seccion]!.add(pregunta);
    }
    
    // Construir widgets por sección
    return secciones.entries.map((entry) {
      return _buildDynamicSection(entry.key, entry.value);
    }).toList();
  }
  
  Widget _buildDynamicSection(String sectionName, List<PreguntaDTO> preguntas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDE1327),
            ),
          ),
          const SizedBox(height: 16),
          ...preguntas.map((pregunta) => _buildDynamicQuestion(pregunta)),
        ],
      ),
    );
  }
  
  Widget _buildDynamicQuestion(PreguntaDTO pregunta) {
    switch (pregunta.tipoEntrada.toLowerCase()) {
      case 'radio':
        return _buildDynamicRadioQuestion(pregunta);
      case 'text':
      case 'textarea':
        return _buildDynamicTextQuestion(pregunta);
      default:
        return _buildDynamicTextQuestion(pregunta);
    }
  }
  
  Widget _buildDynamicRadioQuestion(PreguntaDTO pregunta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta.etiqueta,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: pregunta.opciones.map((opcion) {
              return Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    opcion.etiqueta ?? opcion.valor,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  value: opcion.valor,
                  groupValue: _responses[pregunta.name]?['value'],
                  onChanged: (value) {
                    setState(() {
                      _responses[pregunta.name] = {
                        'value': value,
                        'score': opcion.puntuacion ?? 0,
                      };
                    });
                  },
                  activeColor: const Color(0xFFDE1327),
                  contentPadding: EdgeInsets.zero,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDynamicTextQuestion(PreguntaDTO pregunta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta.etiqueta,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textControllers[pregunta.name],
            maxLines: pregunta.tipoEntrada == 'textarea' ? 3 : 1,
            maxLength: 300, // Límite de 300 caracteres según el issue
            decoration: InputDecoration(
              hintText: pregunta.placeholder ?? 'Escriba su respuesta aquí...',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF8F8E8E),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDE1327)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              _responses[pregunta.name] = {
                'value': value,
                'score': 0,
              };
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(Map<String, dynamic> section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section['section'],
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDE1327),
            ),
          ),
          const SizedBox(height: 16),
          ...List<Widget>.from(
            (section['questions'] as List).map((question) {
              if (question['type'] == 'radio') {
                return _buildRadioQuestion(question);
              } else if (question['type'] == 'multiline') {
                return _buildMultilineQuestion(question);
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRadioQuestion(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['label'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List<Widget>.from(
              (question['options'] as List).map((option) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(
                      option['label'],
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: option['value'],
                    groupValue: _responses[question['name']]?['value'],
                    onChanged: (value) {
                      setState(() {
                        _responses[question['name']] = {
                          'value': value,
                          'score': option['score'],
                        };
                      });
                    },
                    activeColor: const Color(0xFFDE1327),
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMultilineQuestion(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['label'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textControllers[question['name']],
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escriba sus observaciones aquí...',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF8F8E8E),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDE1327)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              _responses[question['name']] = {
                'value': value,
                'score': 0,
              };
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitEvaluation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDE1327),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Finalizar evaluación',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Future<void> _submitEvaluation() async {
    // Validar preguntas obligatorias
    bool allRequiredAnswered = true;
    List<String> missingQuestions = [];
    
    if (_formulario != null) {
      // Validación para formulario dinámico
      for (var pregunta in _formulario!.preguntas) {
        if (pregunta.obligatorio && 
            (!_responses.containsKey(pregunta.name) || 
             _responses[pregunta.name]?['value'] == null || 
             _responses[pregunta.name]!['value'].toString().isEmpty)) {
          allRequiredAnswered = false;
          missingQuestions.add(pregunta.etiqueta);
        }
      }
    } else {
      // Validación para formulario estático (compatibilidad)
      for (var section in _formSections) {
        for (var question in section['questions']) {
          if (question['type'] == 'radio' && !_responses.containsKey(question['name'])) {
            allRequiredAnswered = false;
            missingQuestions.add(question['label']);
          }
        }
      }
    }
    
    if (!allRequiredAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missingQuestions.isNotEmpty 
                ? 'Faltan respuestas en: ${missingQuestions.join(", ")}'
                : 'Por favor complete todas las preguntas obligatorias',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Build response array
    List<Map<String, dynamic>> responseArray = [];
    
    if (_formulario != null) {
      // Construir respuestas para formulario dinámico
      for (var pregunta in _formulario!.preguntas) {
        final response = _responses[pregunta.name];
        if (response != null) {
          responseArray.add({
            'questionId': pregunta.id,
            'name': pregunta.name,
            'label': pregunta.etiqueta,
            'type': pregunta.tipoEntrada,
            'selectedValue': response['value'],
            'score': response['score'],
          });
        }
      }
    } else {
      // Construir respuestas para formulario estático (compatibilidad)
      for (var section in _formSections) {
        for (var question in section['questions']) {
          final response = _responses[question['name']];
          if (response != null) {
            responseArray.add({
              'name': question['name'],
              'selectedValue': response['value'],
              'score': response['score'],
            });
          }
        }
      }
    }
    
    // Build final payload
    final payload = {
      'channel': _evaluationData['channel'],
      'country': _evaluationData['country'],
      'leader': _evaluationData['leaderName'],
      'advisor': _evaluationData['advisorName'],
      'advisorId': _evaluationData['advisorId'],
      'formId': _formulario?.id,
      'formName': _formulario?.nombre,
      'isDynamicForm': _formulario != null,
      'responses': responseArray,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Print payload to console
    print('=== PAYLOAD DE EVALUACIÓN ===');
    print(const JsonEncoder.withIndent('  ').convert(payload));
    print('===========================');
    
    try {
      // Obtener líder comercial de la sesión
      LiderComercial? liderComercial;
      try {
        liderComercial = await SesionServicio.obtenerLiderComercial();
      } catch (e) {
        print('⚠️ No se pudo obtener líder comercial: $e');
      }
      
      // Convertir respuestas al formato de Hive
      List<RespuestaEvaluacionHive> respuestasHive = [];
      double ponderacionTotal = 0.0;
      int preguntasConPonderacion = 0;
      
      for (var respuesta in responseArray) {
        final score = respuesta['score'] ?? 0.0;
        if (score > 0) {
          ponderacionTotal += score;
          preguntasConPonderacion++;
        }
        
        respuestasHive.add(RespuestaEvaluacionHive(
          preguntaId: respuesta['questionId']?.toString() ?? respuesta['name'],
          preguntaTitulo: respuesta['label'] ?? respuesta['name'],
          categoria: 'Evaluación de Desempeño',
          tipoPregunta: respuesta['type'] ?? 'radio',
          respuesta: respuesta['selectedValue'],
          ponderacion: score,
          timestampRespuesta: DateTime.now(),
          configuracionPregunta: {
            'formId': _formulario?.id,
            'formName': _formulario?.nombre,
          },
        ));
      }
      
      // Calcular ponderación final - suma total de puntos, no promedio
      final ponderacionFinal = ponderacionTotal;
      
      // Debug logging según issue #28
      print('🔍 Debug Evaluación Desempeño:');
      print('   Total preguntas con ponderación: $preguntasConPonderacion');
      print('   Ponderación final (suma de puntos): $ponderacionFinal');
      print('   Respuestas con score > 0: ${responseArray.where((r) => (r['score'] ?? 0) > 0).length}');
      
      // Crear evaluación de excelencia
      final evaluacion = ResultadoExcelenciaHive(
        id: _uuid.v4(),
        liderClave: liderComercial?.clave ?? _evaluationData['leaderName'] ?? '', // Usar código del líder real
        liderNombre: liderComercial?.nombre ?? _evaluationData['leaderName'] ?? '',
        liderCorreo: '', // Correo del líder no disponible en el modelo actual
        pais: liderComercial?.pais ?? _evaluationData['country'] ?? '',
        ruta: 'Evaluación de Desempeño',
        centroDistribucion: 'Principal',
        tipoFormulario: 'evaluacion_desempeño',
        formularioMaestro: _formulario?.toJson() ?? {},
        respuestas: respuestasHive,
        ponderacionFinal: ponderacionFinal,
        fechaCaptura: DateTime.now(),
        fechaHoraInicio: DateTime.now().subtract(const Duration(minutes: 10)), // Estimado
        fechaHoraFin: DateTime.now(),
        estatus: 'completada',
        syncStatus: 'pending',
        metadatos: {
          'canal': _evaluationData['channel'],
          'asesorCodigo': _evaluationData['advisorId'],
          'asesorNombre': _evaluationData['advisorName'],
          'pais': liderComercial?.pais ?? _evaluationData['country'],
          'liderClave': liderComercial?.clave ?? _evaluationData['leaderName'], // Código real del líder
          'liderNombre': liderComercial?.nombre ?? _evaluationData['leaderName'],
          'isDynamicForm': _formulario != null,
        },
      );
      
      // Guardar en Hive
      await _repository.guardarEvaluacion(evaluacion);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Evaluación guardada exitosamente en dispositivo',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF38A169),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error guardando evaluación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar evaluación: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return; // No cerrar si hay error
    }
    
    // Return to previous screen
    Navigator.pop(context);
  }
  
  void _showNoFormularioError(String canal, String pais) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Formulario No Disponible',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDE1327),
            ),
          ),
          content: Text(
            'No hay formularios activos de Evaluación de Desempeño para el canal "$canal" en "$pais".\n\nPor favor contacte al administrador.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a pantalla anterior
              },
              child: Text(
                'Entendido',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDE1327),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  void _showConnectionError(String error) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Error de Conexión',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDE1327),
            ),
          ),
          content: Text(
            'No se pudo cargar el formulario de evaluación.\n\nError: $error',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Solo cerrar diálogo
              child: Text(
                'Reintentar',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDE1327),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a pantalla anterior
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}