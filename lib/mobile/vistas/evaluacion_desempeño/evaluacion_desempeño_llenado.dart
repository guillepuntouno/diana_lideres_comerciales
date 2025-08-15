import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class EvaluacionDesempenioLlenado extends StatefulWidget {
  const EvaluacionDesempenioLlenado({Key? key}) : super(key: key);

  @override
  State<EvaluacionDesempenioLlenado> createState() => _EvaluacionDesempenioLlenadoState();
}

class _EvaluacionDesempenioLlenadoState extends State<EvaluacionDesempenioLlenado> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _evaluationData;
  
  final TextEditingController _objetivosController = TextEditingController();
  final TextEditingController _logrosController = TextEditingController();
  final TextEditingController _areasDeOportunidadController = TextEditingController();
  final TextEditingController _planDeAccionController = TextEditingController();
  
  String _cumplimientoMetas = '';
  String _habilidadesComunicacion = '';
  String _trabajoEnEquipo = '';
  String _innovacion = '';
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    _evaluationData = args ?? {};
  }
  
  @override
  void dispose() {
    _objetivosController.dispose();
    _logrosController.dispose();
    _areasDeOportunidadController.dispose();
    _planDeAccionController.dispose();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 16),
            _buildFormSection(),
          ],
        ),
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
          _buildInfoRow('Líder:', _evaluationData['leaderName'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('País:', _evaluationData['country'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Asesor:', _evaluationData['advisorName'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Canal:', _evaluationData['channel'] ?? 'N/A'),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8F8E8E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formulario de Evaluación',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('1. Evaluación de Competencias'),
            const SizedBox(height: 16),
            
            _buildRadioGroupField(
              'Cumplimiento de Metas',
              _cumplimientoMetas,
              (value) => setState(() => _cumplimientoMetas = value!),
            ),
            const SizedBox(height: 16),
            
            _buildRadioGroupField(
              'Habilidades de Comunicación',
              _habilidadesComunicacion,
              (value) => setState(() => _habilidadesComunicacion = value!),
            ),
            const SizedBox(height: 16),
            
            _buildRadioGroupField(
              'Trabajo en Equipo',
              _trabajoEnEquipo,
              (value) => setState(() => _trabajoEnEquipo = value!),
            ),
            const SizedBox(height: 16),
            
            _buildRadioGroupField(
              'Innovación y Mejora Continua',
              _innovacion,
              (value) => setState(() => _innovacion = value!),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('2. Objetivos y Logros'),
            const SizedBox(height: 16),
            
            _buildTextAreaField(
              'Objetivos del Período',
              _objetivosController,
              'Describa los objetivos establecidos para este período...',
            ),
            const SizedBox(height: 16),
            
            _buildTextAreaField(
              'Logros Alcanzados',
              _logrosController,
              'Detalle los logros más significativos...',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('3. Desarrollo y Mejora'),
            const SizedBox(height: 16),
            
            _buildTextAreaField(
              'Áreas de Oportunidad',
              _areasDeOportunidadController,
              'Identifique las áreas donde se puede mejorar...',
            ),
            const SizedBox(height: 16),
            
            _buildTextAreaField(
              'Plan de Acción',
              _planDeAccionController,
              'Proponga un plan de acción para el desarrollo...',
            ),
            const SizedBox(height: 32),
            
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFDE1327),
      ),
    );
  }
  
  Widget _buildRadioGroupField(
    String label,
    String groupValue,
    Function(String?) onChanged,
  ) {
    final options = ['Excelente', 'Bueno', 'Regular', 'Necesita Mejorar'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: options.map((option) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: const Color(0xFFDE1327),
                ),
                Text(
                  option,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildTextAreaField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveEvaluation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDE1327),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Guardar Evaluación',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  void _saveEvaluation() {
    if (_formKey.currentState!.validate()) {
      if (_cumplimientoMetas.isEmpty || 
          _habilidadesComunicacion.isEmpty || 
          _trabajoEnEquipo.isEmpty || 
          _innovacion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor complete todas las evaluaciones de competencias',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final payload = {
        'leaderName': _evaluationData['leaderName'],
        'country': _evaluationData['country'],
        'advisorId': _evaluationData['advisorId'],
        'advisorName': _evaluationData['advisorName'],
        'channel': _evaluationData['channel'],
        'evaluationDate': DateTime.now().toIso8601String(),
        'competencies': {
          'cumplimientoMetas': _cumplimientoMetas,
          'habilidadesComunicacion': _habilidadesComunicacion,
          'trabajoEnEquipo': _trabajoEnEquipo,
          'innovacion': _innovacion,
        },
        'objectives': _objetivosController.text,
        'achievements': _logrosController.text,
        'areasOfImprovement': _areasDeOportunidadController.text,
        'actionPlan': _planDeAccionController.text,
      };
      
      print('=== PAYLOAD DE EVALUACIÓN ===');
      print(const JsonEncoder.withIndent('  ').convert(payload));
      print('===========================');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Evaluación guardada exitosamente (PoC)',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF38A169),
        ),
      );
      
      Navigator.pop(context);
    }
  }
}