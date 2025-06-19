import 'package:flutter/material.dart';
import 'rutas/rutas.dart';
import 'temas/tema_diana.dart';
import 'servicios/auth_guard.dart';

class DianaApp extends StatelessWidget {
  const DianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diana - Líderes Comerciales',
      debugShowCheckedModeBanner: false,
      theme: temaDiana,
      onGenerateRoute: (settings) => AuthGuard.handleRoute(settings, rutas),
    );
  }
}
