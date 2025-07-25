// lib/web/vistas/evaluacion_desempeno/pantalla_evaluacion_desempeno.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PantallaEvaluacionDesempeno extends StatefulWidget {
  final Map<String, dynamic> liderData;
  final Map<String, dynamic> rutaData;
  final String pais;
  final String centroDistribucion;

  const PantallaEvaluacionDesempeno({
    Key? key,
    required this.liderData,
    required this.rutaData,
    required this.pais,
    required this.centroDistribucion,
  }) : super(key: key);

  @override
  State<PantallaEvaluacionDesempeno> createState() => _PantallaEvaluacionDesempenoState();
}

class _PantallaEvaluacionDesempenoState extends State<PantallaEvaluacionDesempeno> {
  String? _tipoEvaluacionSeleccionada;
  
  final List<Map<String, String>> _tiposEvaluacion = [
    {"id": "desempeno", "nombre": "Evaluación de Desempeño"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Evaluación de Desempeño',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C2120),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado minimalista con información del líder
              Container(
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.liderData['nombre'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.liderData['correo'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Información en línea
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        _buildInfoText('País', widget.pais),
                        _buildInfoText('Centro', widget.centroDistribucion),
                        _buildInfoText('Ruta', widget.rutaData['nombre']),
                        _buildInfoText('Canal', widget.rutaData['canalVenta']),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Sección de evaluación minimalista
              Text(
                'Tipo de cuestionario',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8F8E8E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  value: _tipoEvaluacionSeleccionada,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  hint: Text(
                    'Seleccionar evaluación',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1C2120),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _tipoEvaluacionSeleccionada = value;
                    });
                  },
                  items: _tiposEvaluacion.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo['id'],
                      child: Text(tipo['nombre']!),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botón INICIAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _tipoEvaluacionSeleccionada == null 
                      ? null 
                      : () => _iniciarEvaluacion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE1327),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'INICIAR',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
  
  Widget _buildInfoText(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF8F8E8E),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C2120),
          ),
        ),
      ],
    );
  }
  
  void _iniciarEvaluacion() {
    // Aquí se implementaría la navegación al formulario de evaluación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Iniciando evaluación de desempeño para ${widget.liderData['nombre']}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF38A169),
      ),
    );
    
    // TODO: Navegar a la pantalla de evaluación con el cuestionario seleccionado
  }
}