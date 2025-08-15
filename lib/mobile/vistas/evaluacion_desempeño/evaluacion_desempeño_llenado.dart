import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class EvaluacionDesempenioLlenado extends StatefulWidget {
  const EvaluacionDesempenioLlenado({Key? key}) : super(key: key);

  @override
  State<EvaluacionDesempenioLlenado> createState() => _EvaluacionDesempenioLlenadoState();
}

class _EvaluacionDesempenioLlenadoState extends State<EvaluacionDesempenioLlenado> {
  late Map<String, dynamic> _evaluationData;
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _textControllers = {};
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
  
  void _loadFormForChannel() {
    final channel = _evaluationData['channel']?.toString().toLowerCase() ?? 'detalle';
    
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
  
  void _submitEvaluation() {
    // Validate that all radio questions have been answered
    bool allRadioAnswered = true;
    for (var section in _formSections) {
      for (var question in section['questions']) {
        if (question['type'] == 'radio' && !_responses.containsKey(question['name'])) {
          allRadioAnswered = false;
          break;
        }
      }
    }
    
    if (!allRadioAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor responda todas las preguntas de Sí/No',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Build response array
    List<Map<String, dynamic>> responseArray = [];
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
    
    // Build final payload
    final payload = {
      'channel': _evaluationData['channel'],
      'country': _evaluationData['country'],
      'leader': _evaluationData['leaderName'],
      'advisor': _evaluationData['advisorName'],
      'responses': responseArray,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Print payload to console
    print('=== PAYLOAD DE EVALUACIÓN ===');
    print(const JsonEncoder.withIndent('  ').convert(payload));
    print('===========================');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Evaluación finalizada exitosamente (PoC)',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF38A169),
      ),
    );
    
    // Return to previous screen
    Navigator.pop(context);
  }
}