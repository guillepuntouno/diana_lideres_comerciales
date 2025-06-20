import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/lider_comercial_modelo.dart';

class SesionServicio {
  static const String _keyLiderComercial = 'lider_comercial';
  static const String _keyUsuarioLogueado = 'usuario_logueado';

  // Guardar datos del líder comercial
  static Future<void> guardarLiderComercial(LiderComercial lider) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(lider.toJson());
    await prefs.setString(_keyLiderComercial, jsonString);
    await prefs.setBool(_keyUsuarioLogueado, true);
  }

  // Obtener datos del líder comercial
  static Future<LiderComercial?> obtenerLiderComercial() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyLiderComercial);

    if (jsonString != null) {
      final jsonData = jsonDecode(jsonString);
      return LiderComercial.fromJson(jsonData);
    }

    return null;
  }

  // Verificar si hay una sesión activa
  static Future<bool> estaLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUsuarioLogueado) ?? false;
  }

  // Cerrar sesión
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLiderComercial);
    await prefs.setBool(_keyUsuarioLogueado, false);
  }
}
