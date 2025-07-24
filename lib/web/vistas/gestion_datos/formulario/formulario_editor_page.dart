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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          title: Text(
            esNuevo ? 'Nuevo Formulario' : 'Editar Formulario',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1C2120),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE0E0E0),
            ),
          ),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          _buildStep(0, 'Datos Generales', Icons.description),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1 ? const Color(0xFFDE1327) : const Color(0xFFE0E0E0),
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? const Color(0xFFDE1327) 
                : const Color(0xFFE0E0E0),
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFFDE1327).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? const Color(0xFFDE1327) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1C2120),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              if (_currentStep < 1)
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  label: const Text(
                    'Siguiente',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE1327),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFFDE1327).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  icon: Icon(
                    Icons.save_rounded,
                    color: Colors.white,
                    size: _isLoading ? 0 : 20,
                  ),
                  label: Text(
                    _isLoading ? 'Guardando...' : 'Guardar Formulario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE1327),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFFDE1327).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    // Confirmar antes de guardar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Guardado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.formulario == null
                  ? '¿Está seguro de crear este formulario?'
                  : '¿Está seguro de actualizar este formulario?',
            ),
            const SizedBox(height: 16),
            Text(
              'Información del formulario:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• Nombre: ${_formularioEnEdicion['nombre'] ?? 'Sin nombre'}'),
            Text('• Versión: ${_formularioEnEdicion['version'] ?? 'Sin versión'}'),
            Text('• Tipo: ${_formularioEnEdicion['tipo'] ?? 'Sin tipo'}'),
            Text('• Preguntas: ${(_formularioEnEdicion['preguntas'] as List?)?.length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

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