import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/lider_comercial_modelo.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_guard.dart';
  

class SesionServicio {
  static const String _keyLiderComercial = 'lider_comercial';
  static const String _keyUsuarioLogueado = 'usuario_logueado';

  // Guardar datos del líder comercial
  static Future<void> guardarLiderComercial(LiderComercial lider) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(lider.toJson());
    await prefs.setString(_keyLiderComercial, jsonString);
    await prefs.setBool(_keyUsuarioLogueado, true);
    print('✅ Líder comercial guardado en sesión: ${lider.clave}');
  }

  // Obtener token de autenticación
  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_token');
  }

  // Obtener datos del líder comercial
  static Future<LiderComercial?> obtenerLiderComercial() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Primero intentar obtener del key 'usuario' (datos del token AWS)
    final userDataString = prefs.getString('usuario');
    if (userDataString != null) {
      try {
        final jsonData = jsonDecode(userDataString);
        return LiderComercial.fromJson(jsonData);
      } catch (e) {
        print('Error parseando datos del usuario AWS: $e');
      }
    }
    
    // Si no hay datos del token, intentar con el key local
    final liderDataString = prefs.getString(_keyLiderComercial);
    if (liderDataString != null) {
      try {
        final jsonData = jsonDecode(liderDataString);
        return LiderComercial.fromJson(jsonData);
      } catch (e) {
        print('Error parseando datos del líder comercial: $e');
      }
    }
    
    print('No se encontró usuario en SharedPreferences');
    return null;
  }

  // Verificar si hay una sesión activa
  static Future<bool> estaLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUsuarioLogueado) ?? false;
  }

  // Cerrar sesión
  static Future<void> cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Si importaste AuthGuard y las constantes son públicas, úsalas así:
    await prefs.remove(AuthGuard.tokenKey);
    await prefs.remove(AuthGuard.userKey);

    // o define aquí las constantes si no quieres importar:
    // await prefs.remove('id_token');
    // await prefs.remove('usuario');

    // Navegación
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

}
