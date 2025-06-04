import 'package:flutter/material.dart';
import '../../widgets/encabezado_inicio.dart';

class VistaInicio extends StatelessWidget {
  const VistaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          EncabezadoInicio(nombreUsuario: 'Guillermo'),
          SizedBox(height: 20),
          Center(
            child: Text('Pantalla Inicio', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
