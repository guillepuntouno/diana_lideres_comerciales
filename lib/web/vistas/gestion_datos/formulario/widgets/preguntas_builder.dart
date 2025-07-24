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

  void _agregarPregunta() {
    final nuevaPregunta = {
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
        title: const Text('Eliminar pregunta'),
        content: const Text('¿Está seguro de eliminar esta pregunta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
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
    return Row(
      children: [
        // Panel izquierdo - Lista de preguntas
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              right: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preguntas (${_preguntas.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: _agregarPregunta,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay preguntas',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Haga clic en "Agregar" para crear una pregunta',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _preguntas.length,
                        onReorder: _moverPregunta,
                        itemBuilder: (context, index) {
                          final pregunta = _preguntas[index];
                          final isSelected = _preguntaSeleccionada == index;
                          
                          return Card(
                            key: ValueKey(index),
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.blue[50] : Colors.white,
                            child: ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                pregunta['etiqueta']?.toString().isNotEmpty == true
                                    ? pregunta['etiqueta']
                                    : 'Pregunta sin título',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    _getIconForType(pregunta['tipoEntrada']),
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getTipoLabel(pregunta['tipoEntrada']),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  if (pregunta['obligatorio'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '*',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
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
                                        Icon(Icons.copy, size: 20),
                                        SizedBox(width: 8),
                                        Text('Duplicar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _preguntaSeleccionada = index;
                                });
                              },
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
          child: _preguntaSeleccionada != null
              ? PreguntaEditor(
                  pregunta: _preguntas[_preguntaSeleccionada!],
                  onPreguntaActualizada: (pregunta) {
                    _actualizarPregunta(_preguntaSeleccionada!, pregunta);
                  },
                  onEditarOpciones: () {
                    _mostrarModalOpciones(_preguntaSeleccionada!);
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Seleccione una pregunta para editar',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O agregue una nueva pregunta desde el panel izquierdo',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
        ),
      ],
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