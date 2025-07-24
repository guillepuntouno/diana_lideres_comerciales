import 'package:flutter/material.dart';
import 'dart:async';

class MetadatosForm extends StatefulWidget {
  final Map<String, dynamic> formulario;
  final Function(Map<String, dynamic>) onFormularioActualizado;

  const MetadatosForm({
    Key? key,
    required this.formulario,
    required this.onFormularioActualizado,
  }) : super(key: key);

  @override
  State<MetadatosForm> createState() => _MetadatosFormState();
}

class _MetadatosFormState extends State<MetadatosForm> {
  late TextEditingController _nombreController;
  late TextEditingController _versionController;
  late TextEditingController _descripcionController;
  late String _tipoSeleccionado;
  late bool _activa;
  Timer? _debounce;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.formulario['nombre'] ?? '');
    _versionController = TextEditingController(text: widget.formulario['version'] ?? 'v1.0');
    _descripcionController = TextEditingController(text: widget.formulario['descripcion'] ?? '');
    // Mapear tipos antiguos a los nuevos
    final tipoOriginal = widget.formulario['tipo']?.toString().toLowerCase() ?? '';
    switch (tipoOriginal) {
      case 'evaluacion':
      case 'evaluación':
      case 'encuesta':
      case 'checklist':
      case 'auditoria':
      case 'detalle':
        _tipoSeleccionado = 'detalle';
        break;
      case 'mayoreo':
        _tipoSeleccionado = 'mayoreo';
        break;
      case 'programa_excelencia':
      case 'programa de excelencia':
        _tipoSeleccionado = 'programa_excelencia';
        break;
      default:
        _tipoSeleccionado = 'detalle';
    }
    _activa = widget.formulario['activa'] ?? true;
    
    // Agregar listeners después de inicializar los controllers
    _nombreController.addListener(_onTextChanged);
    _versionController.addListener(_onTextChanged);
    _descripcionController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nombreController.removeListener(_onTextChanged);
    _versionController.removeListener(_onTextChanged);
    _descripcionController.removeListener(_onTextChanged);
    _nombreController.dispose();
    _versionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _actualizarFormulario();
    });
  }

  void _actualizarFormulario() {
    widget.onFormularioActualizado({
      'nombre': _nombreController.text,
      'version': _versionController.text,
      'descripcion': _descripcionController.text,
      'tipo': _tipoSeleccionado,
      'activa': _activa,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General del Formulario',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure los datos básicos del formulario',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Nombre del formulario
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Formulario *',
                hintText: 'Ej: Evaluación de Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Versión y Tipo en la misma fila
            Row(
              children: [
                // Versión
                Expanded(
                  child: TextFormField(
                    controller: _versionController,
                    decoration: const InputDecoration(
                      labelText: 'Versión',
                      hintText: 'v1.0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bookmark_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La versión es obligatoria';
                      }
                      if (!RegExp(r'^v?\d+\.\d+$').hasMatch(value)) {
                        return 'Formato inválido (ej: v1.0)';
                      }
                      return null;
                    },
                        ),
                ),
                const SizedBox(width: 16),
                
                // Tipo
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tipoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Formulario',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'detalle',
                        child: Text('Detalle'),
                      ),
                      DropdownMenuItem(
                        value: 'mayoreo',
                        child: Text('Mayoreo'),
                      ),
                      DropdownMenuItem(
                        value: 'programa_excelencia',
                        child: Text('Programa de excelencia'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _tipoSeleccionado = value!;
                      });
                      _actualizarFormulario();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción breve del formulario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Estado activo
            Card(
              elevation: 0,
              color: _activa ? Colors.green[50] : Colors.red[50],
              child: SwitchListTile(
                title: const Text('Estado del Formulario'),
                subtitle: Text(
                  _activa 
                      ? 'El formulario está activo y disponible para uso' 
                      : 'El formulario está inactivo',
                  style: TextStyle(
                    color: _activa ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                value: _activa,
                onChanged: (value) {
                  setState(() {
                    _activa = value;
                  });
                  _actualizarFormulario();
                },
                secondary: Icon(
                  _activa ? Icons.check_circle : Icons.cancel,
                  color: _activa ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información importante',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Una vez que el formulario tenga capturas, no podrá ser editado. '
                          'En su lugar, deberá crear una nueva versión.',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
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
}