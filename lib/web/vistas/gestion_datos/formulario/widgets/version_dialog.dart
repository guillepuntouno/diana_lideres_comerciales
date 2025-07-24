import 'package:flutter/material.dart';

class VersionDialog extends StatefulWidget {
  final String versionActual;
  final Function(String) onVersionSeleccionada;

  const VersionDialog({
    Key? key,
    required this.versionActual,
    required this.onVersionSeleccionada,
  }) : super(key: key);

  @override
  State<VersionDialog> createState() => _VersionDialogState();
}

class _VersionDialogState extends State<VersionDialog> {
  late TextEditingController _versionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Sugerir siguiente versión
    _versionController = TextEditingController(
      text: _sugerirNuevaVersion(widget.versionActual),
    );
  }

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  String _sugerirNuevaVersion(String versionActual) {
    // Extraer número de versión
    final regex = RegExp(r'v?(\d+)\.(\d+)');
    final match = regex.firstMatch(versionActual);
    
    if (match != null) {
      final mayor = int.parse(match.group(1)!);
      final menor = int.parse(match.group(2)!);
      
      // Incrementar versión menor
      return 'v$mayor.${menor + 1}';
    }
    
    return 'v2.0';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicar Formulario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se creará una copia del formulario con una nueva versión.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Versión actual: ${widget.versionActual}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'Nueva versión',
                hintText: 'Ej: v2.0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bookmark_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese una versión';
                }
                if (value == widget.versionActual) {
                  return 'La nueva versión debe ser diferente';
                }
                // Validar formato básico
                if (!RegExp(r'^v?\d+\.\d+$').hasMatch(value)) {
                  return 'Formato inválido. Use v1.0, v2.1, etc.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'La nueva versión se creará en estado inactivo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onVersionSeleccionada(_versionController.text);
            }
          },
          child: const Text('Duplicar'),
        ),
      ],
    );
  }
}