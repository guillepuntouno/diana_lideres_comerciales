import 'package:flutter/material.dart';
import 'rutas/rutas.dart';
import 'temas/tema_diana.dart';
import 'servicios/hive_service.dart';
import 'servicios/auth_guard.dart';

class DianaApp extends StatelessWidget {
  final bool hasNewToken;
  
  const DianaApp({super.key, this.hasNewToken = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diana - Líderes Comerciales',
      debugShowCheckedModeBanner: false,
      theme: temaDiana,
      initialRoute: hasNewToken ? '/token-redirect' : '/splash',
      routes: {
        '/splash': (context) => const _InitializationScreen(),
        '/token-redirect': (context) => const _TokenRedirectScreen(),
      },
      onGenerateRoute: (settings) {
        // Para las rutas especiales, no usar AuthGuard
        if (settings.name == '/splash' || settings.name == '/token-redirect') {
          if (settings.name == '/splash') {
            return MaterialPageRoute(
              builder: (context) => const _InitializationScreen(),
              settings: settings,
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const _TokenRedirectScreen(),
              settings: settings,
            );
          }
        }
        // Para todas las demás rutas, usar AuthGuard
        return AuthGuard.handleRoute(settings, rutas);
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
        // Verificar si hay autenticación válida
        final isAuth = await AuthGuard.isAuthenticated();
        if (isAuth) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
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

class _TokenRedirectScreen extends StatefulWidget {
  const _TokenRedirectScreen();

  @override
  State<_TokenRedirectScreen> createState() => _TokenRedirectScreenState();
}

class _TokenRedirectScreenState extends State<_TokenRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _redirectAfterToken();
  }

  Future<void> _redirectAfterToken() async {
    print('🔄 Procesando token de AWS Cognito...');
    
    // Pequeña espera para asegurar que el token se guardó
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Verificar autenticación
    final isAuth = await AuthGuard.isAuthenticated();
    
    if (mounted) {
      if (isAuth) {
        print('✅ Token válido, redirigiendo al menú principal');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('❌ Token no se pudo validar, redirigiendo al login');
        // El error se mostrará en la pantalla de login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

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
              'Verificando autenticación...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}