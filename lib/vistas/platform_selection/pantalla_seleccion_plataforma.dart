import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:diana_lc_front/core/auth/platform_navigation.dart';
import 'package:diana_lc_front/shared/servicios/auth_guard.dart';

class PantallaSeleccionPlataforma extends StatefulWidget {
  const PantallaSeleccionPlataforma({super.key});

  @override
  State<PantallaSeleccionPlataforma> createState() => _PantallaSeleccionPlataformaState();
}

class _PantallaSeleccionPlataformaState extends State<PantallaSeleccionPlataforma> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handlePlatformSelection();
  }

  Future<void> _handlePlatformSelection() async {
    try {
      print('🚀 PantallaSeleccionPlataforma: Iniciando proceso de selección');
      
      // Obtener token y datos del usuario
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthGuard.tokenKey);
      final userDataString = prefs.getString(AuthGuard.userKey);
      
      if (token == null || userDataString == null) {
        print('❌ No se encontraron datos de autenticación');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      final userData = jsonDecode(userDataString);
      print('📋 Datos del usuario recuperados');
      
      // Agregar family_name del token si no está en userData
      final familyName = AuthGuard.getFamilyNameFromToken(token);
      if (familyName != null && userData['family_name'] == null) {
        userData['family_name'] = familyName;
        print('🔧 Agregando family_name del token: $familyName');
      }
      
      // Desactivar el loading antes de mostrar el diálogo
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Pequeño delay para asegurar que la UI esté lista
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        print('🎯 Iniciando navegación por plataforma');
        await PlatformNavigation.handlePostLoginNavigation(
          context,
          userData,
          token,
        );
      }
    } catch (e) {
      print('❌ Error en selección de plataforma: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al procesar la autenticación';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Volver al login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
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
                'Preparando tu experiencia...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Si no está loading y no hay error, mostrar una pantalla vacía
    // El diálogo se mostrará encima
    return const Scaffold(
      body: Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}