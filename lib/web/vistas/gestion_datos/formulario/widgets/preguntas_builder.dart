import 'package:flutter/material.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/widgets/pregunta_editor.dart';
import 'package:diana_lc_front/web/vistas/gestion_datos/formulario/widgets/opcion_modal.dart';

class PreguntasBuilder extends StatefulWidget {
  final List<Map<String, dynamic>> preguntas;
  final Function(List<Map<String, dynamic>>) onPreguntasActualizadas;

  const PreguntasBuilder({
    Key? key,
    required this.preguntas,
    required this.onPreguntasActualizadas,
  }) : super(key: key);

  @override
  State<PreguntasBuilder> createState() => _PreguntasBuilderState();
}

class _PreguntasBuilderState extends State<PreguntasBuilder> {
  late List<Map<String, dynamic>> _preguntas;
  int? _preguntaSeleccionada;

  @override
  void initState() {
    super.initState();
    _preguntas = List<Map<String, dynamic>>.from(widget.preguntas);
  }

  void _agregarPregunta() async {
    // Si hay una pregunta seleccionada, verificar si está completa
    if (_preguntaSeleccionada != null) {
      final preguntaActual = _preguntas[_preguntaSeleccionada!];
      if (preguntaActual['etiqueta']?.toString().isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete la pregunta actual antes de agregar una nueva'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final nuevaPregunta = {
      'id': 'p-${DateTime.now().millisecondsSinceEpoch}',
      'name': '',
      'etiqueta': '',
      'tipoEntrada': 'text',
      'orden': _preguntas.length + 1,
      'section': 'General',
      'opciones': [],
      'obligatorio': false,
      'ponderacion': 0.0,
      'placeholder': '',
      'validacion': '',
    };

    setState(() {
      _preguntas.add(nuevaPregunta);
      _preguntaSeleccionada = _preguntas.length - 1;
    });
    
    widget.onPreguntasActualizadas(_preguntas);
  }

  void _eliminarPregunta(int index) {
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
                color: const Color(0xFFFF5252).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFD32F2F),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar pregunta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Está seguro de eliminar esta pregunta? Esta acción no se puede deshacer.',
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
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _preguntas.removeAt(index);
                _reordenarPreguntas();
                if (_preguntaSeleccionada == index) {
                  _preguntaSeleccionada = null;
                } else if (_preguntaSeleccionada != null && _preguntaSeleccionada! > index) {
                  _preguntaSeleccionada = _preguntaSeleccionada! - 1;
                }
              });
              widget.onPreguntasActualizadas(_preguntas);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _duplicarPregunta(int index) {
    final preguntaOriginal = _preguntas[index];
    final preguntaDuplicada = Map<String, dynamic>.from(preguntaOriginal);
    
    // Modificar nombre para evitar duplicados
    preguntaDuplicada['name'] = '${preguntaOriginal['name']}_copia';
    preguntaDuplicada['etiqueta'] = '${preguntaOriginal['etiqueta']} (Copia)';
    preguntaDuplicada['orden'] = _preguntas.length + 1;
    
    // Duplicar opciones si existen
    if (preguntaDuplicada['opciones'] != null) {
      preguntaDuplicada['opciones'] = (preguntaDuplicada['opciones'] as List)
          .map((opcion) => Map<String, dynamic>.from(opcion))
          .toList();
    }

    setState(() {
      _preguntas.add(preguntaDuplicada);
      _preguntaSeleccionada = _preguntas.length - 1;
    });
    
    widget.onPreguntasActualizadas(_preguntas);
  }

  void _moverPregunta(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final pregunta = _preguntas.removeAt(oldIndex);
      _preguntas.insert(newIndex, pregunta);
      _reordenarPreguntas();
      
      // Actualizar índice seleccionado
      if (_preguntaSeleccionada == oldIndex) {
        _preguntaSeleccionada = newIndex;
      } else if (_preguntaSeleccionada != null) {
        if (_preguntaSeleccionada! > oldIndex && _preguntaSeleccionada! <= newIndex) {
          _preguntaSeleccionada = _preguntaSeleccionada! - 1;
        } else if (_preguntaSeleccionada! < oldIndex && _preguntaSeleccionada! >= newIndex) {
          _preguntaSeleccionada = _preguntaSeleccionada! + 1;
        }
      }
    });
    
    widget.onPreguntasActualizadas(_preguntas);
  }

  void _reordenarPreguntas() {
    for (int i = 0; i < _preguntas.length; i++) {
      _preguntas[i]['orden'] = i + 1;
    }
  }

  void _actualizarPregunta(int index, Map<String, dynamic> preguntaActualizada) {
    // No usar setState aquí para evitar recrear widgets
    _preguntas[index] = preguntaActualizada;
    widget.onPreguntasActualizadas(_preguntas);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Panel izquierdo - Lista de preguntas
            Container(
              width: 400,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(
                  right: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
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
                              'Preguntas del Formulario',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_preguntas.length} ${_preguntas.length == 1 ? 'pregunta' : 'preguntas'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _agregarPregunta,
                            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                            label: const Text(
                              'Nueva',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDE1327),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              
                  // Lista de preguntas
                  Expanded(
                    child: _preguntas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDE1327).withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.quiz_outlined,
                                    size: 48,
                                    color: const Color(0xFFDE1327).withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Sin preguntas aún',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C2120),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Agregue su primera pregunta para comenzar',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: _preguntas.length,
                            onReorder: _moverPregunta,
                            itemBuilder: (context, index) {
                              final pregunta = _preguntas[index];
                              final isSelected = _preguntaSeleccionada == index;
                              
                              return Container(
                                key: ValueKey(index),
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFDE1327).withOpacity(0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFDE1327) : const Color(0xFFE0E0E0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: const Color(0xFFDE1327).withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        _preguntaSeleccionada = index;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? const Color(0xFFDE1327)
                                                  : const Color(0xFFE0E0E0),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : const Color(0xFF757575),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pregunta['etiqueta']?.toString().isNotEmpty == true
                                                      ? pregunta['etiqueta']
                                                      : 'Pregunta sin título',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    color: const Color(0xFF1C2120),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF1976D2).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              _getIconForType(pregunta['tipoEntrada']),
                                                              size: 14,
                                                              color: const Color(0xFF1976D2),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Flexible(
                                                              child: Text(
                                                                _getTipoLabel(pregunta['tipoEntrada']),
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(0xFF1976D2),
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    if (pregunta['obligatorio'] == true) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFF5252).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'Obligatorio',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Color(0xFFD32F2F),
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              size: 20,
                                              color: Colors.grey[600],
                                            ),
                                            onSelected: (value) {
                                              switch (value) {
                                                case 'duplicate':
                                                  _duplicarPregunta(index);
                                                  break;
                                                case 'delete':
                                                  _eliminarPregunta(index);
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'duplicate',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.copy_outlined, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Duplicar'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
                            
            // Panel derecho - Editor de pregunta
            Expanded(
              child: Container(
                color: Colors.white,
                child: _preguntaSeleccionada != null
                    ? PreguntaEditor(
                        key: ValueKey(_preguntas[_preguntaSeleccionada!]['id']),
                        pregunta: _preguntas[_preguntaSeleccionada!],
                        onPreguntaActualizada: (pregunta) {
                          _actualizarPregunta(_preguntaSeleccionada!, pregunta);
                        },
                        onEditarOpciones: () {
                          _mostrarModalOpciones(_preguntaSeleccionada!);
                        },
                        onSiguientePregunta: _agregarPregunta,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDE1327).withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.touch_app_outlined,
                                size: 64,
                                color: const Color(0xFFDE1327).withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Seleccione una pregunta para editar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C2120),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'O agregue una nueva pregunta desde el panel izquierdo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalOpciones(int index) {
    final pregunta = _preguntas[index];
    final opciones = List<Map<String, dynamic>>.from(pregunta['opciones'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) => OpcionModal(
        opciones: opciones,
        onOpcionesActualizadas: (nuevasOpciones) {
          setState(() {
            _preguntas[index]['opciones'] = nuevasOpciones;
          });
          widget.onPreguntasActualizadas(_preguntas);
        },
      ),
    );
  }

  IconData _getIconForType(String? tipo) {
    switch (tipo) {
      case 'radio':
        return Icons.radio_button_checked;
      case 'select':
        return Icons.arrow_drop_down_circle;
      case 'checkbox':
        return Icons.check_box;
      case 'text':
      default:
        return Icons.text_fields;
    }
  }

  String _getTipoLabel(String? tipo) {
    switch (tipo) {
      case 'radio':
        return 'Opción única';
      case 'select':
        return 'Lista desplegable';
      case 'checkbox':
        return 'Opción múltiple';
      case 'text':
      default:
        return 'Texto';
    }
  }
}