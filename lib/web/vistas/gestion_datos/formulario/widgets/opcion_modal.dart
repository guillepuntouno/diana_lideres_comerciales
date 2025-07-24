import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OpcionModal extends StatefulWidget {
  final List<Map<String, dynamic>> opciones;
  final Function(List<Map<String, dynamic>>) onOpcionesActualizadas;

  const OpcionModal({
    Key? key,
    required this.opciones,
    required this.onOpcionesActualizadas,
  }) : super(key: key);

  @override
  State<OpcionModal> createState() => _OpcionModalState();
}

class _OpcionModalState extends State<OpcionModal> {
  late List<Map<String, dynamic>> _opciones;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _opciones = List<Map<String, dynamic>>.from(widget.opciones);
    
    // Si no hay opciones, agregar una por defecto
    if (_opciones.isEmpty) {
      _agregarOpcion();
    }
  }

  void _agregarOpcion() {
    setState(() {
      _opciones.add({
        'valor': '',
        'etiqueta': '',
        'puntuacion': 0.0,
        'orden': _opciones.length + 1,
      });
    });
  }

  void _eliminarOpcion(int index) {
    if (_opciones.length > 1) {
      setState(() {
        _opciones.removeAt(index);
        _reordenarOpciones();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe mantener al menos una opción'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _reordenarOpciones() {
    for (int i = 0; i < _opciones.length; i++) {
      _opciones[i]['orden'] = i + 1;
    }
  }

  void _moverOpcion(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final opcion = _opciones.removeAt(oldIndex);
      _opciones.insert(newIndex, opcion);
      _reordenarOpciones();
    });
  }

  bool _validarFormulario() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Validar que no haya valores duplicados
    final valores = _opciones.map((o) => o['valor']).toList();
    final valoresUnicos = valores.toSet();
    if (valores.length != valoresUnicos.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los valores de las opciones deben ser únicos'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Editar Opciones'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header con botón agregar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_opciones.length} opciones',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton.icon(
                    onPressed: _agregarOpcion,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Opción'),
                  ),
                ],
              ),
              const Divider(),
              
              // Lista de opciones
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _opciones.length,
                  onReorder: _moverOpcion,
                  itemBuilder: (context, index) {
                    return _buildOpcionItem(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_validarFormulario()) {
              widget.onOpcionesActualizadas(_opciones);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildOpcionItem(int index) {
    final opcion = _opciones[index];
    
    return Card(
      key: ValueKey(index),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono de arrastre
            Icon(Icons.drag_handle, color: Colors.grey[400]),
            const SizedBox(width: 12),
            
            // Número de orden
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Campos de la opción
            Expanded(
              child: Row(
                children: [
                  // Valor
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: opcion['valor'],
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        hintText: 'valor_opcion',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _opciones[index]['valor'] = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Etiqueta
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: opcion['etiqueta'],
                      decoration: const InputDecoration(
                        labelText: 'Etiqueta',
                        hintText: 'Texto visible',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _opciones[index]['etiqueta'] = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Puntuación
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: opcion['puntuacion']?.toString() ?? '0',
                      decoration: const InputDecoration(
                        labelText: 'Puntos',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _opciones[index]['puntuacion'] = 
                              double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Botón eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _eliminarOpcion(index),
              tooltip: 'Eliminar opción',
            ),
          ],
        ),
      ),
    );
  }
}