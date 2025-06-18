import 'package:flutter/material.dart';
import 'rutas/rutas.dart';
import 'temas/tema_diana.dart';
import 'package:diana_lc_front/vistas/login/pantalla_login.dart'; // Importa PantallaLogin

class DianaApp extends StatelessWidget {
  const DianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diana - Líderes Comerciales',
      debugShowCheckedModeBanner: false,
      theme: temaDiana,
      home: const PantallaLogin(),
      routes: rutas,
    );
  }
}
