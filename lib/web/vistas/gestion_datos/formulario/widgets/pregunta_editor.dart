import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class PreguntaEditor extends StatefulWidget {
  final Map<String, dynamic> pregunta;
  final Function(Map<String, dynamic>) onPreguntaActualizada;
  final VoidCallback onEditarOpciones;
  final VoidCallback? onSiguientePregunta;

  const PreguntaEditor({
    Key? key,
    required this.pregunta,
    required this.onPreguntaActualizada,
    required this.onEditarOpciones,
    this.onSiguientePregunta,
  }) : super(key: key);

  @override
  State<PreguntaEditor> createState() => _PreguntaEditorState();
}

class _PreguntaEditorState extends State<PreguntaEditor> {
  late TextEditingController _nombreController;
  late TextEditingController _etiquetaController;
  late TextEditingController _placeholderController;
  late TextEditingController _validacionController;
  late TextEditingController _ponderacionController;
  late TextEditingController _seccionController;
  
  late String _tipoEntrada;
  late bool _obligatorio;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
  }

  @override
  void didUpdateWidget(PreguntaEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pregunta['id'] != widget.pregunta['id']) {
      // Solo reinicializar si es una pregunta diferente
      _inicializarControladores();
    }
  }

  void _inicializarControladores() {
    // Limpiar listeners anteriores si existen
    try {
      _nombreController.removeListener(_onTextChanged);
      _etiquetaController.removeListener(_onTextChanged);
      _placeholderController.removeListener(_onTextChanged);
      _validacionController.removeListener(_onTextChanged);
      _ponderacionController.removeListener(_onTextChanged);
      _seccionController.removeListener(_onTextChanged);
      
      // Dispose controladores anteriores si existen
      _nombreController.dispose();
      _etiquetaController.dispose();
      _placeholderController.dispose();
      _validacionController.dispose();
      _ponderacionController.dispose();
      _seccionController.dispose();
    } catch (_) {
      // Ignorar si es la primera vez
    }
    
    // Crear nuevos controladores
    _nombreController = TextEditingController(text: widget.pregunta['name'] ?? '');
    _etiquetaController = TextEditingController(text: widget.pregunta['etiqueta'] ?? '');
    _placeholderController = TextEditingController(text: widget.pregunta['placeholder'] ?? '');
    _validacionController = TextEditingController(text: widget.pregunta['validacion'] ?? '');
    _ponderacionController = TextEditingController(
      text: widget.pregunta['ponderacion']?.toString() ?? '0',
    );
    _seccionController = TextEditingController(text: widget.pregunta['section'] ?? 'General');
    
    _tipoEntrada = widget.pregunta['tipoEntrada'] ?? 'text';
    _obligatorio = widget.pregunta['obligatorio'] ?? false;
    
    // Agregar listeners
    _nombreController.addListener(_onTextChanged);
    _etiquetaController.addListener(_onTextChanged);
    _placeholderController.addListener(_onTextChanged);
    _validacionController.addListener(_onTextChanged);
    _ponderacionController.addListener(_onTextChanged);
    _seccionController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nombreController.removeListener(_onTextChanged);
    _etiquetaController.removeListener(_onTextChanged);
    _placeholderController.removeListener(_onTextChanged);
    _validacionController.removeListener(_onTextChanged);
    _ponderacionController.removeListener(_onTextChanged);
    _seccionController.removeListener(_onTextChanged);
    _nombreController.dispose();
    _etiquetaController.dispose();
    _placeholderController.dispose();
    _validacionController.dispose();
    _ponderacionController.dispose();
    _seccionController.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _actualizarPregunta();
    });
  }

  void _actualizarPregunta() {
    final preguntaActualizada = {
      ...widget.pregunta,
      'name': _nombreController.text,
      'etiqueta': _etiquetaController.text,
      'placeholder': _placeholderController.text,
      'validacion': _validacionController.text,
      'ponderacion': double.tryParse(_ponderacionController.text) ?? 0,
      'section': _seccionController.text,
      'tipoEntrada': _tipoEntrada,
      'obligatorio': _obligatorio,
    };
    
    widget.onPreguntaActualizada(preguntaActualizada);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header moderno
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Pregunta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C2120),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Defina el tipo y propiedades de la pregunta',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFDE1327),
                          const Color(0xFFDE1327).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDE1327).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pregunta ${widget.pregunta['orden'] ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
                  // Campos principales
                  _buildSeccion(
                    'Información Básica',
                    Icons.info_outline_rounded,
                    [
                      // Etiqueta
                      TextFormField(
                        controller: _etiquetaController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1C2120),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Etiqueta de la Pregunta',
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: '¿Cuál es su pregunta?',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFDE1327),
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.quiz_outlined,
                            color: Color(0xFF757575),
                          ),
                          suffixIcon: _etiquetaController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () {
                                    _etiquetaController.clear();
                                    _actualizarPregunta();
                                  },
                                  color: Colors.grey[600],
                                )
                              : null,
                          helperText: 'Este texto será visible para el usuario',
                          helperStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Nombre y Sección
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombreController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1C2120),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Identificador del Campo',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: 'nombre_campo',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDE1327),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.tag_rounded,
                                  color: Color(0xFF757575),
                                ),
                                helperText: 'Sin espacios, solo letras y números',
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _seccionController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1C2120),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Sección',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: 'General',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDE1327),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.folder_outlined,
                                  color: Color(0xFF757575),
                                ),
                                helperText: 'Agrupa preguntas relacionadas',
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          
                  const SizedBox(height: 32),
                  
                  // Configuración del tipo
                  _buildSeccion(
                    'Tipo de Respuesta',
                    Icons.input_rounded,
                    [
                      // Tipo de entrada
                      DropdownButtonFormField<String>(
                        value: _tipoEntrada,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1C2120),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tipo de Entrada',
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFDE1327),
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.input_rounded,
                            color: Color(0xFF757575),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF757575),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'text',
                            child: Row(
                              children: [
                                Icon(Icons.text_fields_rounded, size: 20, color: Color(0xFF1976D2)),
                                SizedBox(width: 12),
                                Text('Texto'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'radio',
                            child: Row(
                              children: [
                                Icon(Icons.radio_button_checked, size: 20, color: Color(0xFF4CAF50)),
                                SizedBox(width: 12),
                                Text('Opción única'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_drop_down_circle_rounded, size: 20, color: Color(0xFFFF9800)),
                                SizedBox(width: 12),
                                Text('Lista desplegable'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'checkbox',
                            child: Row(
                              children: [
                                Icon(Icons.check_box_rounded, size: 20, color: Color(0xFF9C27B0)),
                                SizedBox(width: 12),
                                Text('Opción múltiple'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                  setState(() {
                    _tipoEntrada = value!;
                    // Si cambia a texto, limpiar opciones
                    if (_tipoEntrada == 'text') {
                      widget.pregunta['opciones'] = [];
                    }
                  });
                  _actualizarPregunta();
                },
              ),
              const SizedBox(height: 16),
              
                      // Botón para editar opciones (si aplica)
                      if (['radio', 'select', 'checkbox'].contains(_tipoEntrada)) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: widget.onEditarOpciones,
                            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                            label: Text(
                              'Editar Opciones (${(widget.pregunta['opciones'] as List?)?.length ?? 0})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
              
                      // Placeholder (solo para texto)
                      if (_tipoEntrada == 'text') ...[
                const SizedBox(height: 16),
                        TextFormField(
                          controller: _placeholderController,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1C2120),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Texto de Ayuda (Placeholder)',
                            labelStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: 'Ej: Ingrese su respuesta aquí...',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFDE1327),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.text_format_rounded,
                              color: Color(0xFF757575),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
              ],
            ],
          ),
          
                  const SizedBox(height: 32),
                  
                  // Validaciones y configuración
                  _buildSeccion(
                    'Validaciones y Puntuación',
                    Icons.rule_rounded,
                    [
                      // Obligatorio
                      Container(
                        decoration: BoxDecoration(
                          color: _obligatorio ? const Color(0xFFFF5252).withOpacity(0.08) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _obligatorio ? const Color(0xFFFF5252) : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Campo Obligatorio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C2120),
                            ),
                          ),
                          subtitle: Text(
                            'El usuario debe responder esta pregunta',
                            style: TextStyle(
                              fontSize: 14,
                              color: _obligatorio ? const Color(0xFFD32F2F) : Colors.grey[600],
                            ),
                          ),
                          value: _obligatorio,
                          onChanged: (value) {
                            setState(() {
                              _obligatorio = value;
                            });
                            _actualizarPregunta();
                          },
                          activeColor: const Color(0xFFFF5252),
                          activeTrackColor: const Color(0xFFFF8A80),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _obligatorio ? const Color(0xFFFF5252).withOpacity(0.1) : const Color(0xFFE0E0E0).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _obligatorio ? Icons.priority_high_rounded : Icons.help_outline_rounded,
                              color: _obligatorio ? const Color(0xFFFF5252) : Colors.grey[600],
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
              
                      // Ponderación y Validación
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ponderacionController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1C2120),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Ponderación',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDE1327),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: Color(0xFF757575),
                                ),
                                suffixText: 'pts',
                                suffixStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                helperText: 'Peso para cálculos',
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _validacionController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1C2120),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Validación',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: 'email, number, etc.',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDE1327),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFF757575),
                                ),
                                helperText: 'Tipo de validación',
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          
                  const SizedBox(height: 32),
                  
                  // Vista previa
                  _buildVistaPrevia(),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de siguiente pregunta
                  if (widget.onSiguientePregunta != null)
                    Center(
                      child: Container(
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          label: const Text(
                            'Agregar Siguiente Pregunta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE1327),
                            elevation: 2,
                            shadowColor: const Color(0xFFDE1327).withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // Validar que la pregunta esté completa
                            if (_etiquetaController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor complete la etiqueta de la pregunta'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            if (_nombreController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor complete el nombre del campo'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            // Confirmar si desea agregar otra pregunta
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF4CAF50),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Pregunta Configurada',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  '¿Desea agregar otra pregunta al formulario?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    child: const Text(
                                      'No, terminar',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onSiguientePregunta!();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Sí, agregar otra',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, IconData icon, List<Widget> campos) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDE1327).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFDE1327),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...campos,
        ],
      ),
    );
  }

  Widget _buildVistaPrevia() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1976D2).withOpacity(0.05),
            const Color(0xFF2196F3).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility_outlined,
                  color: const Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Vista Previa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Etiqueta
          Row(
            children: [
              Text(
                _etiquetaController.text.isNotEmpty 
                    ? _etiquetaController.text 
                    : 'Pregunta sin título',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (_obligatorio)
                Text(
                  ' *',
                  style: TextStyle(color: Colors.red[700]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Campo según tipo
          _buildCampoVistaPrevia(),
        ],
      ),
    );
  }

  Widget _buildCampoVistaPrevia() {
    switch (_tipoEntrada) {
      case 'radio':
        final opciones = widget.pregunta['opciones'] as List? ?? [];
        return Column(
          children: opciones.isEmpty
              ? [Text('Sin opciones configuradas', style: TextStyle(color: Colors.grey[500]))]
              : opciones.map((opcion) => RadioListTile<String>(
                  title: Text(opcion['etiqueta'] ?? ''),
                  value: opcion['valor'] ?? '',
                  groupValue: null,
                  onChanged: null,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )).toList(),
        );
        
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: _placeholderController.text.isNotEmpty 
                ? _placeholderController.text 
                : 'Seleccione una opción',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [],
          onChanged: null,
        );
        
      case 'checkbox':
        final opciones = widget.pregunta['opciones'] as List? ?? [];
        return Column(
          children: opciones.isEmpty
              ? [Text('Sin opciones configuradas', style: TextStyle(color: Colors.grey[500]))]
              : opciones.map((opcion) => CheckboxListTile(
                  title: Text(opcion['etiqueta'] ?? ''),
                  value: false,
                  onChanged: null,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  controlAffinity: ListTileControlAffinity.leading,
                )).toList(),
        );
        
      case 'text':
      default:
        return TextFormField(
          decoration: InputDecoration(
            hintText: _placeholderController.text.isNotEmpty 
                ? _placeholderController.text 
                : 'Ingrese su respuesta',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          enabled: false,
        );
    }
  }
}