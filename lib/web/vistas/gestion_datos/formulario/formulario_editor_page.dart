import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/providers/formularios_provider.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/widgets/metadatos_form.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/widgets/preguntas_builder.dart';

class FormularioEditorPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? formulario;

  const FormularioEditorPage({
    Key? key,
    this.formulario,
  }) : super(key: key);

  @override
  ConsumerState<FormularioEditorPage> createState() => _FormularioEditorPageState();
}

class _FormularioEditorPageState extends ConsumerState<FormularioEditorPage> {
  late Map<String, dynamic> _formularioEnEdicion;
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
  }

  void _inicializarFormulario() {
    if (widget.formulario != null) {
      // Editar existente
      _formularioEnEdicion = Map<String, dynamic>.from(widget.formulario!);
    } else {
      // Nuevo formulario
      _formularioEnEdicion = {
        'id': '',
        'nombre': '',
        'version': 'v1.0',
        'tipo': 'evaluacion',
        'activa': true,
        'esPlantilla': true,
        'preguntas': [],
        'capturado': false,
        'syncStatus': 'pending',
      };
    }
    
    // Guardar en el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(formularioEditProvider.notifier).state = _formularioEnEdicion;
      ref.read(wizardStepProvider.notifier).state = 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.formulario == null;
    
    return Scaffold(
        appBar: AppBar(
          title: Text(esNuevo ? 'Nuevo Formulario' : 'Editar Formulario'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Indicador de pasos
            _buildStepIndicator(),
            
            // Contenido del wizard
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                  ref.read(wizardStepProvider.notifier).state = index;
                },
                children: [
                  MetadatosForm(
                    formulario: _formularioEnEdicion,
                    onFormularioActualizado: _actualizarFormulario,
                  ),
                  PreguntasBuilder(
                    preguntas: List<Map<String, dynamic>>.from(
                      _formularioEnEdicion['preguntas'] ?? [],
                    ),
                    onPreguntasActualizadas: _actualizarPreguntas,
                  ),
                ],
              ),
            ),
            
            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildStep(0, 'Datos Generales', Icons.description),
          Expanded(
            child: Container(
              height: 1,
              color: _currentStep >= 1 ? Theme.of(context).primaryColor : Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          _buildStep(1, 'Preguntas', Icons.quiz),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white)
                : Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            )
          else
            const SizedBox(),
          
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              if (_currentStep < 1)
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _validarPasoActual() ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } : null,
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _guardarFormulario,
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _validarPasoActual() {
    switch (_currentStep) {
      case 0:
        // Validar metadatos
        return _formularioEnEdicion['nombre']?.isNotEmpty == true &&
               _formularioEnEdicion['version']?.isNotEmpty == true;
      case 1:
        // Validar preguntas
        return (_formularioEnEdicion['preguntas'] as List?)?.isNotEmpty == true;
      default:
        return false;
    }
  }

  void _actualizarFormulario(Map<String, dynamic> metadatos) {
    setState(() {
      _formularioEnEdicion.addAll(metadatos);
    });
    ref.read(formularioEditProvider.notifier).state = _formularioEnEdicion;
  }

  void _actualizarPreguntas(List<Map<String, dynamic>> preguntas) {
    setState(() {
      _formularioEnEdicion['preguntas'] = preguntas;
    });
    ref.read(formularioEditProvider.notifier).state = _formularioEnEdicion;
  }

  Future<void> _guardarFormulario() async {
    setState(() => _isLoading = true);

    try {
      bool exito;
      
      if (widget.formulario == null) {
        // Crear nuevo
        exito = await ref.read(formulariosProvider.notifier).crearFormulario(_formularioEnEdicion);
      } else {
        // Actualizar existente
        exito = await ref.read(formulariosProvider.notifier).actualizarFormulario(
          _formularioEnEdicion['id'],
          _formularioEnEdicion,
        );
      }

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.formulario == null 
                  ? 'Formulario creado exitosamente'
                  : 'Formulario actualizado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarBorrador() async {
    setState(() => _isLoading = true);

    try {
      bool exito;
      
      if (widget.formulario == null) {
        // Crear nuevo
        exito = await ref.read(formulariosProvider.notifier).crearFormulario(_formularioEnEdicion);
      } else {
        // Actualizar existente
        exito = await ref.read(formulariosProvider.notifier).actualizarFormulario(
          _formularioEnEdicion['id'],
          _formularioEnEdicion,
        );
      }

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrador guardado'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    // Verificar si hay cambios sin guardar
    if (_hayCambiosSinGuardar()) {
      final resultado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Guardar cambios?'),
          content: const Text('Hay cambios sin guardar. ¿Desea guardarlos antes de salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Descartar'),
            ),
            TextButton(
              onPressed: () async {
                await _guardarBorrador();
                if (mounted) Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      return resultado ?? false;
    }
    return true;
  }

  bool _hayCambiosSinGuardar() {
    // Implementar lógica para detectar cambios
    if (widget.formulario == null) {
      // Es nuevo, verificar si se ha ingresado algo
      return _formularioEnEdicion['nombre']?.isNotEmpty == true ||
             (_formularioEnEdicion['preguntas'] as List?)?.isNotEmpty == true;
    }
    // Para edición, comparar con el original
    // TODO: Implementar comparación detallada
    return false;
  }

  void _mostrarAyuda() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete los datos generales del formulario'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _mostrarVistaPrevia() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vista Previa: ${_formularioEnEdicion['nombre']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Versión: ${_formularioEnEdicion['version']}'),
              const SizedBox(height: 8),
              Text('Tipo: ${_formularioEnEdicion['tipo']}'),
              const Divider(),
              const Text('Preguntas:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(_formularioEnEdicion['preguntas'] as List<Map<String, dynamic>>?)
                  ?.asMap()
                  .entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${e.key + 1}. ${e.value['texto']}'),
                      ))
                  .toList() ?? [],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}