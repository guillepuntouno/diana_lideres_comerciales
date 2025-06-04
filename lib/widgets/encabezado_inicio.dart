import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EncabezadoInicio extends StatelessWidget {
  final String nombreUsuario;

  const EncabezadoInicio({super.key, required this.nombreUsuario});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFB01020), // rojo más oscuro arriba
                Color(0xFFDE1327), // rojo DIANA abajo
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: SizedBox(
              height: 100,
              child: Image.asset('assets/logo_diana.png', fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 24), // Espacio debajo del header
      ],
    );
  }
}
