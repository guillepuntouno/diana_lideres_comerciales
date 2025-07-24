import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class PreguntaEditor extends StatefulWidget {
  final Map<String, dynamic> pregunta;
  final Function(Map<String, dynamic>) onPreguntaActualizada;
  final VoidCallback onEditarOpciones;

  const PreguntaEditor({
    Key? key,
    required this.pregunta,
    required this.onPreguntaActualizada,
    required this.onEditarOpciones,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editar Pregunta',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure los detalles de la pregunta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Chip(
                label: Text('Pregunta ${widget.pregunta['orden'] ?? 1}'),
                backgroundColor: Colors.blue[100],
                labelStyle: TextStyle(color: Colors.blue[800]),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Campos principales
          _buildSeccion(
            'Información Básica',
            [
              // Etiqueta
              TextFormField(
                controller: _etiquetaController,
                decoration: const InputDecoration(
                  labelText: 'Etiqueta de la Pregunta *',
                  hintText: '¿Cuál es su pregunta?',
                  border: OutlineInputBorder(),
                  helperText: 'Texto que verá el usuario',
                ),
              ),
              const SizedBox(height: 16),
              
              // Nombre y Sección
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Campo *',
                        hintText: 'nombre_campo',
                        border: OutlineInputBorder(),
                        helperText: 'Identificador único (sin espacios)',
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
                      decoration: const InputDecoration(
                        labelText: 'Sección',
                        hintText: 'General',
                        border: OutlineInputBorder(),
                        helperText: 'Agrupa preguntas relacionadas',
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
            [
              // Tipo de entrada
              DropdownButtonFormField<String>(
                value: _tipoEntrada,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Entrada',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.input),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'text',
                    child: Row(
                      children: [
                        Icon(Icons.text_fields, size: 20),
                        SizedBox(width: 8),
                        Text('Texto'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'radio',
                    child: Row(
                      children: [
                        Icon(Icons.radio_button_checked, size: 20),
                        SizedBox(width: 8),
                        Text('Opción única'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'select',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_drop_down_circle, size: 20),
                        SizedBox(width: 8),
                        Text('Lista desplegable'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'checkbox',
                    child: Row(
                      children: [
                        Icon(Icons.check_box, size: 20),
                        SizedBox(width: 8),
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
              if (['radio', 'select', 'checkbox'].contains(_tipoEntrada))
                ElevatedButton.icon(
                  onPressed: widget.onEditarOpciones,
                  icon: const Icon(Icons.list),
                  label: Text(
                    'Editar Opciones (${(widget.pregunta['opciones'] as List?)?.length ?? 0})',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              
              // Placeholder (solo para texto)
              if (_tipoEntrada == 'text') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Texto de Ayuda (Placeholder)',
                    hintText: 'Ej: Ingrese su respuesta aquí...',
                    border: OutlineInputBorder(),
                  ),
                  ),
              ],
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Validaciones y configuración
          _buildSeccion(
            'Validaciones y Puntuación',
            [
              // Obligatorio
              SwitchListTile(
                title: const Text('Campo Obligatorio'),
                subtitle: const Text('El usuario debe responder esta pregunta'),
                value: _obligatorio,
                onChanged: (value) {
                  setState(() {
                    _obligatorio = value;
                  });
                  _actualizarPregunta();
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              
              // Ponderación y Validación
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ponderacionController,
                      decoration: const InputDecoration(
                        labelText: 'Ponderación',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        helperText: 'Peso para cálculos',
                        suffixText: 'pts',
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
                      decoration: const InputDecoration(
                        labelText: 'Validación',
                        hintText: 'email, number, etc.',
                        border: OutlineInputBorder(),
                        helperText: 'Tipo de validación',
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
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> campos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...campos,
      ],
    );
  }

  Widget _buildVistaPrevia() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Vista Previa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
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