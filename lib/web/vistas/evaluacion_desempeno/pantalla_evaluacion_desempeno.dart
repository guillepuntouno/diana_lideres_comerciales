// lib/web/vistas/evaluacion_desempeno/pantalla_evaluacion_desempeno.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:uuid/uuid.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/asesores_service.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/modelos/asesor_dto.dart';

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
  bool _evaluacionGuardada = false;
  final HiveService _hiveService = HiveService();
  final _uuid = const Uuid();
  DateTime _fechaHoraInicio = DateTime.now();
  
  // Nuevas variables para datos reales
  LiderComercial? _liderComercial;
  List<AsesorDTO> _asesores = [];
  AsesorDTO? _asesorSeleccionado;
  String? _canalSeleccionado;
  bool _cargandoDatos = true;
  String? _errorMessage;
  
  // Opciones fijas para canal de venta
  final List<String> _canalesVenta = ['Detalle', 'Mayoreo'];
  
  @override
  void initState() {
    super.initState();
    _formulario = widget.rutaData['formularioData'] ?? {};
    _inicializarRespuestas();
    _cargarDatosReales();
  }
  
  Future<void> _cargarDatosReales() async {
    setState(() {
      _cargandoDatos = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener líder comercial de la sesión (Cognito)
      _liderComercial = await SesionServicio.obtenerLiderComercial();
      
      if (_liderComercial == null) {
        throw Exception('No se pudo obtener la información del líder de la sesión');
      }
      
      print('👤 Líder obtenido de Cognito: ${_liderComercial!.nombre} - ${_liderComercial!.clave}');
      
      // Cargar asesores del líder
      _asesores = await AsesoresService.obtenerAsesoresPorLider(
        codigoLider: _liderComercial!.clave,
        pais: _liderComercial!.pais,
      );
      
      print('👥 Asesores cargados: ${_asesores.length}');
      
      setState(() {
        _cargandoDatos = false;
      });
    } catch (e) {
      print('❌ Error al cargar datos reales: $e');
      setState(() {
        _cargandoDatos = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
      
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar datos: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              // Encabezado con información del líder de Cognito
              if (_cargandoDatos)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                )
              else
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
                      // Información del líder (solo lectura)
                      Text(
                        'Información del Líder',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8F8E8E),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                              _liderComercial?.nombre ?? 'Sin nombre',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 24,
                              runSpacing: 8,
                              children: [
                                _buildInfoText('Código', _liderComercial?.clave ?? 'N/A'),
                                _buildInfoText('País', _liderComercial?.pais ?? 'N/A'),
                                _buildInfoText('Centro', _liderComercial?.centroDistribucion ?? 'N/A'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Filtros de selección
                      Text(
                        'Filtros de Evaluación',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8F8E8E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Dropdown de Canal de Venta
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Canal de Venta *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _canalSeleccionado,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: InputBorder.none,
                                ),
                                hint: Text(
                                  'Seleccionar canal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _canalSeleccionado = value;
                                  });
                                },
                                items: _canalesVenta.map((canal) {
                                  return DropdownMenuItem<String>(
                                    value: canal,
                                    child: Text(
                                      canal,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Dropdown de Asesor
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asesor *',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonFormField<AsesorDTO>(
                                value: _asesorSeleccionado,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: InputBorder.none,
                                ),
                                hint: Text(
                                  _asesores.isEmpty ? 'No hay asesores disponibles' : 'Seleccionar asesor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                onChanged: _asesores.isEmpty ? null : (value) {
                                  setState(() {
                                    _asesorSeleccionado = value;
                                  });
                                },
                                items: _asesores.map((asesor) {
                                  return DropdownMenuItem<AsesorDTO>(
                                    value: asesor,
                                    child: Text(
                                      '${asesor.nombre} (${asesor.codigo})',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (_asesores.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'No se encontraron asesores para este líder',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
              
              // Mostrar las preguntas del formulario agrupadas por sección (ocultar si ya se guardó)
              if (!_evaluacionGuardada && _formulario.containsKey('preguntas') && (_formulario['preguntas'] as List).isNotEmpty) ...[
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
              ] else if (!_evaluacionGuardada) ...[
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
                if (!_evaluacionGuardada)
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
                if (_evaluacionGuardada) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _enviarALider(),
                      icon: const Icon(Icons.send),
                      label: Text(
                        'ENVIAR A LÍDER',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38A169),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Volver sin enviar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
    // Validar filtros
    if (_canalSeleccionado == null || _asesorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor seleccione canal de venta y asesor',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
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
      
      // Guardar en HIVE
      await _guardarEnHive();
      
      if (mounted) {
        setState(() {
          _mostrarResultado = true;
          _evaluacionGuardada = true;
          _isLoading = false;
        });
        
        // Mostrar mensaje antes de hacer cualquier otra operación
        if (!mounted) return;
        
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
  
  // Método para enviar evaluación al líder
  void _enviarALider() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.send, color: const Color(0xFF38A169)),
            const SizedBox(width: 12),
            Text(
              'Confirmar envío',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de enviar esta evaluación al líder?',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Líder:', _liderComercial?.nombre ?? 'N/A'),
                  const SizedBox(height: 4),
                  _buildInfoRow('Asesor:', _asesorSeleccionado?.nombre ?? 'N/A'),
                  if (_formulario.containsKey('resultadoKPI')) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow('Puntuación:', '${_puntuacionTotal.toStringAsFixed(0)}/${(_formulario['resultadoKPI']['puntuacionMaxima'] ?? 0).toStringAsFixed(0)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo
              
              // Mostrar loading
              setState(() => _isLoading = true);
              
              try {
                // Aquí iría la lógica para enviar al líder
                await Future.delayed(const Duration(seconds: 2)); // Simulación
                
                if (mounted) {
                  // Mostrar mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Evaluación enviada exitosamente',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF38A169),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // Esperar un momento para que se vea el mensaje
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  // Navegar de vuelta cerrando esta pantalla
                  if (mounted) {
                    // Solo cerrar esta pantalla, el callback en pantalla_administracion.dart
                    // se encargará de recargar los datos
                    Navigator.of(context).pop();
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  // Solo mostrar el SnackBar si el widget sigue montado
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al enviar evaluación: $e',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: Text(
              'Enviar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38A169),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _guardarEnHive() async {
    try {
      // Crear lista de respuestas con información completa
      List<RespuestaEvaluacionHive> respuestasHive = [];
      
      if (_formulario.containsKey('preguntas')) {
        print('=== DEBUG GUARDADO ===');
        print('Total preguntas: ${_formulario['preguntas'].length}');
        print('Respuestas guardadas: ${_respuestas.length}');
        
        for (var pregunta in _formulario['preguntas']) {
          final nombre = pregunta['name'];
          final respuesta = _respuestas[nombre];
          print('Pregunta: $nombre - Respuesta: $respuesta');
          
          // Calcular ponderación para esta respuesta
          double? ponderacion;
          if (respuesta != null && respuesta.toString().isNotEmpty) {
            if (pregunta['type'] == 'select' || pregunta['type'] == 'radio') {
              final opciones = pregunta['opciones'] as List<dynamic>? ?? [];
              for (var opcion in opciones) {
                if (opcion['valor'] == respuesta) {
                  ponderacion = (opcion['puntuacion'] ?? 0).toDouble();
                  break;
                }
              }
            }
          }
          
          // Guardar TODAS las preguntas, incluso las no respondidas
          respuestasHive.add(RespuestaEvaluacionHive(
            preguntaId: pregunta['name'] ?? '',
            preguntaTitulo: pregunta['etiqueta'] ?? pregunta['name'] ?? '',
            categoria: pregunta['section'] ?? 'General',
            tipoPregunta: pregunta['type'] ?? 'text',
            respuesta: respuesta, // Puede ser null si no se respondió
            ponderacion: ponderacion,
            timestampRespuesta: DateTime.now(),
            configuracionPregunta: pregunta,
          ));
        }
      }
      
      // Crear el objeto ResultadoExcelenciaHive con datos reales
      final resultadoExcelencia = ResultadoExcelenciaHive(
        id: _uuid.v4(),
        liderClave: _liderComercial?.clave ?? '',
        liderNombre: _liderComercial?.nombre ?? '',
        liderCorreo: '', // No tenemos el correo en el modelo LiderComercial
        pais: _liderComercial?.pais ?? '',
        ruta: _asesorSeleccionado?.nombre ?? '',
        centroDistribucion: _liderComercial?.centroDistribucion ?? '',
        tipoFormulario: _formulario['nombre'] ?? 'Evaluación de Desempeño',
        formularioMaestro: _formulario,
        respuestas: respuestasHive,
        ponderacionFinal: _puntuacionTotal,
        fechaCaptura: DateTime.now(),
        fechaHoraInicio: _fechaHoraInicio,
        fechaHoraFin: DateTime.now(),
        estatus: 'completada',
        observaciones: null,
        metadatos: {
          'canalVenta': _canalSeleccionado,
          'asesorCodigo': _asesorSeleccionado?.codigo,
          'asesorNombre': _asesorSeleccionado?.nombre,
          'formularioId': widget.rutaData['formularioId'],
        },
      );
      
      // Imprimir el DTO completo antes de guardar
      print('=== DTO RESULTADO EXCELENCIA (ANTES DE GUARDAR) ===');
      print('ID: ${resultadoExcelencia.id}');
      print('Líder Clave: ${resultadoExcelencia.liderClave}');
      print('Líder Nombre: ${resultadoExcelencia.liderNombre}');
      print('Líder Correo: ${resultadoExcelencia.liderCorreo}');
      print('País: ${resultadoExcelencia.pais}');
      print('Ruta: ${resultadoExcelencia.ruta}');
      print('Centro Distribución: ${resultadoExcelencia.centroDistribucion}');
      print('Tipo Formulario: ${resultadoExcelencia.tipoFormulario}');
      print('Ponderación Final: ${resultadoExcelencia.ponderacionFinal}');
      print('Fecha Captura: ${resultadoExcelencia.fechaCaptura}');
      print('Estatus: ${resultadoExcelencia.estatus}');
      print('Total de respuestas: ${resultadoExcelencia.respuestas.length}');
      print('Metadatos: ${resultadoExcelencia.metadatos}');
      print('--- Detalle de Respuestas ---');
      for (var i = 0; i < resultadoExcelencia.respuestas.length; i++) {
        final respuesta = resultadoExcelencia.respuestas[i];
        print('  Respuesta $i:');
        print('    - Pregunta ID: ${respuesta.preguntaId}');
        print('    - Pregunta: ${respuesta.preguntaTitulo}');
        print('    - Categoría: ${respuesta.categoria}');
        print('    - Tipo: ${respuesta.tipoPregunta}');
        print('    - Respuesta: ${respuesta.respuesta}');
        print('    - Ponderación: ${respuesta.ponderacion}');
      }
      print('=== FIN DEL DTO ===');
      print('');
      print('JSON del DTO:');
      print(resultadoExcelencia.toJson());
      print('');
      
      // Guardar en Hive
      final box = _hiveService.resultadosExcelenciaBox;
      await box.put(resultadoExcelencia.id, resultadoExcelencia);
      
      print('✅ Evaluación guardada en Hive con ID: ${resultadoExcelencia.id}');
      
    } catch (e) {
      print('❌ Error al guardar en Hive: $e');
      rethrow;
    }
  }
}