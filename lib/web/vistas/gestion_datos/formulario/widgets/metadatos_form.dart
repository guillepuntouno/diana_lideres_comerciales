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
      child: Container(
        margin: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDE1327).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Color(0xFFDE1327),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información General',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure los datos básicos del formulario',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
            
                    // Nombre del formulario
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C2120),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nombre del Formulario',
                        labelStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'Ej: Evaluación de Cliente',
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFF757575),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1C2120),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Versión',
                              labelStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              hintText: 'v1.0',
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.bookmark_outline,
                                color: Color(0xFF757575),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1C2120),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Tipo de Formulario',
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
                                Icons.category_outlined,
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
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C2120),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        labelStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'Descripción breve del formulario',
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.notes_outlined,
                          color: Color(0xFF757575),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 3,
                    ),
            const SizedBox(height: 24),
            
                    // Estado activo
                    Container(
                      decoration: BoxDecoration(
                        color: _activa ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activa ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                          width: 1.5,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Estado del Formulario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C2120),
                          ),
                        ),
                        subtitle: Text(
                          _activa 
                              ? 'El formulario está activo y disponible para uso' 
                              : 'El formulario está inactivo',
                          style: TextStyle(
                            fontSize: 14,
                            color: _activa ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                        ),
                        value: _activa,
                        onChanged: (value) {
                          setState(() {
                            _activa = value;
                          });
                          _actualizarFormulario();
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _activa ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFF44336).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _activa ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: _activa ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                            size: 24,
                          ),
                        ),
                        activeColor: const Color(0xFF4CAF50),
                        activeTrackColor: const Color(0xFF81C784),
                        inactiveThumbColor: const Color(0xFFF44336),
                        inactiveTrackColor: const Color(0xFFEF9A9A),
                      ),
                    ),
            const SizedBox(height: 32),
            
                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1976D2).withOpacity(0.08),
                            const Color(0xFF2196F3).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1976D2).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información importante',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Una vez que el formulario tenga capturas, no podrá ser editado. '
                                  'En su lugar, deberá crear una nueva versión.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF1565C0),
                                    height: 1.5,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}