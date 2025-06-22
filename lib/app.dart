import 'package:flutter/material.dart';
import 'rutas/rutas.dart';
import 'temas/tema_diana.dart';
import 'servicios/hive_service.dart';

class DianaApp extends StatelessWidget {
  const DianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diana - Líderes Comerciales',
      debugShowCheckedModeBanner: false,
      theme: temaDiana,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const _InitializationScreen(),
        ...rutas,
      },
    );
  }
}

class _InitializationScreen extends StatefulWidget {
  const _InitializationScreen();

  @override
  State<_InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<_InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Verificar que HiveService esté inicializado
      final hiveService = HiveService();
      if (!hiveService.isInitialized) {
        await hiveService.initialize();
      }
      
      // Esperar un momento para mostrar el splash
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('⚠️ Error en inicialización: $e');
      // Continuar al login aunque falle la inicialización de Hive
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _SplashScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_diana.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Inicializando DIANA...',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configurando funcionalidad offline',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
