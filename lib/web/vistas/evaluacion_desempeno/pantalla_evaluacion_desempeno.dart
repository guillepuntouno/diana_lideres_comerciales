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
  late Map<String, dynamic> _formulario;
  final Map<String, dynamic> _respuestas = {};
  bool _isLoading = false;
  double _puntuacionTotal = 0;
  bool _mostrarResultado = false;
  
  @override
  void initState() {
    super.initState();
    _formulario = widget.rutaData['formularioData'] ?? {};
    _inicializarRespuestas();
  }
  
  void _inicializarRespuestas() {
    // Inicializar respuestas vacías para cada pregunta
    if (_formulario.containsKey('preguntas')) {
      for (var pregunta in _formulario['preguntas']) {
        _respuestas[pregunta['name']] = '';
      }
    }
  }
  
  // Calcular puntuación total basada en las respuestas
  double _calcularPuntuacion() {
    double puntuacion = 0;
    
    if (_formulario.containsKey('preguntas')) {
      for (var pregunta in _formulario['preguntas']) {
        final respuesta = _respuestas[pregunta['name']];
        if (respuesta != null && respuesta.toString().isNotEmpty) {
          // Buscar la puntuación de la opción seleccionada
          final opciones = pregunta['opciones'] as List<dynamic>? ?? [];
          for (var opcion in opciones) {
            if (opcion['valor'] == respuesta) {
              puntuacion += (opcion['puntuacion'] ?? 0).toDouble();
              break;
            }
          }
        }
      }
    }
    
    return puntuacion;
  }
  
  // Obtener el color según la puntuación y colorimetría
  Color _obtenerColorResultado(double puntuacion) {
    if (!_formulario.containsKey('resultadoKPI')) return Colors.grey;
    
    final colorimetria = _formulario['resultadoKPI']['colorimetria'] ?? {};
    
    // Parsear rangos y determinar color
    for (var entry in colorimetria.entries) {
      final rango = entry.value.toString();
      final partes = rango.split('-');
      if (partes.length == 2) {
        final min = double.tryParse(partes[0]) ?? 0;
        final max = double.tryParse(partes[1]) ?? 0;
        
        if (puntuacion >= min && puntuacion <= max) {
          switch (entry.key) {
            case 'verde':
              return const Color(0xFF38A169);
            case 'amarillo':
              return const Color(0xFFF6C343);
            case 'rojo':
              return const Color(0xFFE53E3E);
            default:
              return Colors.grey;
          }
        }
      }
    }
    
    return Colors.grey;
  }
  
  // Obtener texto descriptivo del resultado
  String _obtenerTextoResultado(double puntuacion) {
    if (!_formulario.containsKey('resultadoKPI')) return '';
    
    final colorimetria = _formulario['resultadoKPI']['colorimetria'] ?? {};
    
    for (var entry in colorimetria.entries) {
      final rango = entry.value.toString();
      final partes = rango.split('-');
      if (partes.length == 2) {
        final min = double.tryParse(partes[0]) ?? 0;
        final max = double.tryParse(partes[1]) ?? 0;
        
        if (puntuacion >= min && puntuacion <= max) {
          switch (entry.key) {
            case 'verde':
              return 'Excelente';
            case 'amarillo':
              return 'Bueno';
            case 'rojo':
              return 'Necesita mejorar';
            default:
              return '';
          }
        }
      }
    }
    
    return '';
  }

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
              
              const SizedBox(height: 24),
              
              // Información del formulario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formulario de Evaluación',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8F8E8E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formulario['nombre'] ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C2120),
                      ),
                    ),
                    if (_formulario['descripcion'] != null && _formulario['descripcion'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formulario['descripcion'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF8F8E8E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Mostrar resultado KPI si está disponible y se ha guardado
              if (_mostrarResultado && _formulario.containsKey('resultadoKPI')) ...[
                _buildResultadoKPI(),
                const SizedBox(height: 32),
              ],
              
              // Mostrar las preguntas del formulario agrupadas por sección
              if (_formulario.containsKey('preguntas') && (_formulario['preguntas'] as List).isNotEmpty) ...[
                Text(
                  'Preguntas de Evaluación',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildPreguntasPorSeccion(),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Este formulario no tiene preguntas configuradas',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF8F8E8E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Botón GUARDAR EVALUACIÓN o FINALIZAR
              if (_formulario.containsKey('preguntas') && (_formulario['preguntas'] as List).isNotEmpty) ...[
                if (!_mostrarResultado)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _guardarEvaluacion(),
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
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'GUARDAR EVALUACIÓN',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                if (_mostrarResultado) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFDE1327)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'FINALIZAR',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: const Color(0xFFDE1327),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
  
  Widget _buildPregunta(Map<String, dynamic> pregunta) {
    final String tipoEntrada = pregunta['tipoEntrada'] ?? 'text';
    final String nombre = pregunta['name'] ?? '';
    final String etiqueta = pregunta['etiqueta'] ?? nombre;
    final bool obligatorio = pregunta['obligatorio'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C2120),
                  ),
                ),
              ),
              if (obligatorio)
                Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCampoRespuesta(pregunta),
        ],
      ),
    );
  }
  
  Widget _buildCampoRespuesta(Map<String, dynamic> pregunta) {
    final String tipoEntrada = pregunta['tipoEntrada'] ?? 'text';
    final String nombre = pregunta['name'] ?? '';
    final List<dynamic> opciones = pregunta['opciones'] ?? [];
    
    switch (tipoEntrada) {
      case 'select':
      case 'dropdown':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _respuestas[nombre]?.toString().isEmpty ?? true ? null : _respuestas[nombre],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
            ),
            hint: Text(
              pregunta['placeholder'] ?? 'Seleccionar opción',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _respuestas[nombre] = value;
              });
            },
            items: opciones.map((opcion) {
              final valor = opcion['valor']?.toString() ?? '';
              return DropdownMenuItem<String>(
                value: valor,
                child: Text(
                  valor,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
          ),
        );
        
      case 'textarea':
        return TextFormField(
          initialValue: _respuestas[nombre]?.toString(),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: pregunta['placeholder'] ?? 'Ingrese su respuesta',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (value) {
            _respuestas[nombre] = value;
          },
        );
        
      case 'number':
        return TextFormField(
          initialValue: _respuestas[nombre]?.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: pregunta['placeholder'] ?? 'Ingrese un número',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            _respuestas[nombre] = value;
          },
        );
        
      case 'radio':
        return Column(
          children: opciones.map((opcion) {
            // En el JSON de ejemplo, las opciones solo tienen 'valor' y 'puntuacion'
            final valor = opcion['valor']?.toString() ?? '';
            return RadioListTile<String>(
              title: Text(
                valor,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              value: valor,
              groupValue: _respuestas[nombre],
              onChanged: (value) {
                setState(() {
                  _respuestas[nombre] = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
        );
        
      case 'checkbox':
        return Column(
          children: opciones.map((opcion) {
            final valor = opcion['valor']?.toString() ?? opcion['etiqueta']?.toString() ?? '';
            final List<String> selectedValues = _respuestas[nombre] is List 
                ? List<String>.from(_respuestas[nombre]) 
                : [];
            
            return CheckboxListTile(
              title: Text(
                opcion['etiqueta']?.toString() ?? '',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              value: selectedValues.contains(valor),
              onChanged: (bool? checked) {
                setState(() {
                  if (checked ?? false) {
                    selectedValues.add(valor);
                  } else {
                    selectedValues.remove(valor);
                  }
                  _respuestas[nombre] = selectedValues;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
        );
        
      default: // text
        return TextFormField(
          initialValue: _respuestas[nombre]?.toString(),
          decoration: InputDecoration(
            hintText: pregunta['placeholder'] ?? 'Ingrese su respuesta',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            _respuestas[nombre] = value;
          },
        );
    }
  }
  
  void _guardarEvaluacion() async {
    // Validar campos obligatorios
    final preguntasObligatorias = (_formulario['preguntas'] as List)
        .where((p) => p['obligatorio'] == true)
        .toList();
    
    for (var pregunta in preguntasObligatorias) {
      final respuesta = _respuestas[pregunta['name']];
      if (respuesta == null || respuesta.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor complete el campo: ${pregunta['etiqueta'] ?? pregunta['name']}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Calcular puntuación si hay KPI
      if (_formulario.containsKey('resultadoKPI')) {
        _puntuacionTotal = _calcularPuntuacion();
      }
      
      // Aquí se implementaría el guardado de la evaluación
      await Future.delayed(const Duration(seconds: 2)); // Simulación
      
      if (mounted) {
        setState(() {
          _mostrarResultado = true;
          _isLoading = false;
        });
        
        // Hacer scroll al inicio para mostrar el resultado
        await Future.delayed(const Duration(milliseconds: 300));
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Evaluación guardada exitosamente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF38A169),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar la evaluación: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Construir preguntas agrupadas por sección
  List<Widget> _buildPreguntasPorSeccion() {
    final preguntas = _formulario['preguntas'] as List;
    final Map<String, List<Map<String, dynamic>>> seccionesMap = {};
    
    // Agrupar preguntas por sección
    for (var pregunta in preguntas) {
      final seccion = pregunta['section'] ?? 'General';
      if (!seccionesMap.containsKey(seccion)) {
        seccionesMap[seccion] = [];
      }
      seccionesMap[seccion]!.add(pregunta);
    }
    
    // Construir widgets por sección
    List<Widget> widgets = [];
    seccionesMap.forEach((seccion, preguntasSeccion) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seccion,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDE1327),
                ),
              ),
              const SizedBox(height: 16),
              ...preguntasSeccion.map((pregunta) => _buildPregunta(pregunta)).toList(),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }
  
  // Widget para mostrar el resultado KPI
  Widget _buildResultadoKPI() {
    final puntuacionMaxima = (_formulario['resultadoKPI']['puntuacionMaxima'] ?? 0).toDouble();
    final porcentaje = puntuacionMaxima > 0 ? (_puntuacionTotal / puntuacionMaxima) * 100 : 0;
    final color = _obtenerColorResultado(_puntuacionTotal);
    final textoResultado = _obtenerTextoResultado(_puntuacionTotal);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assessment,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            'Resultado de la Evaluación',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 24),
          // Círculo de progreso
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: porcentaje / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_puntuacionTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'de ${puntuacionMaxima.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              textoResultado,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${porcentaje.toStringAsFixed(1)}% de efectividad',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}