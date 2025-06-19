import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../vistas/login/pantalla_login.dart';
import '../rutas/rutas.dart';
import '../vistas/menu_principal/pantalla_menu_principal.dart';
import 'package:http/http.dart' as http;

class AuthGuard {
  static const tokenKey = 'id_token';
  static const userKey = 'usuario';

  /// Validación principal
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) return false;

    if (!_isLocallyValid(token)) return false;

    // ✅ Validar con backend (solo si no lo has hecho antes, o expira sesión, etc.)
    final userData = await _validateTokenWithBackend(token);
    print(userData);
    if (userData == null) return false;

    // Guardar usuario (puedes usar otro esquema si prefieres un state manager)
    await prefs.setString(userKey, jsonEncode(userData));

    return true;
  }

  /// Valida exp del token localmente sin necesidad de hacer petición
  static bool _isLocallyValid(String token) {
    try {
      final payloadBase64 = token.split('.')[1];
      final normalized = base64.normalize(payloadBase64);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = json.decode(decoded);

      final expiry = (payload['exp'] ?? 0) * 1000;
      final now = DateTime.now().millisecondsSinceEpoch;
      return now < expiry;
    } catch (_) {
      return false;
    }
  }

  /// Llama a tu backend para verificar el token
  static Future<Map<String, dynamic>?> _validateTokenWithBackend(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/users/64a54c87-9031-4f80-8559-22d920f9228b'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error al validar token con backend: $e');
    }
    return null;
  }

  // 🔀 Centraliza todas las rutas y aplica validación
  static Route<dynamic> handleRoute(RouteSettings settings, Map<String, WidgetBuilder> rutas) {
    final isLoginRoute = settings.name == '/login' || settings.name == '' || settings.name == '/';

    return MaterialPageRoute(
      builder: (context) {
        return FutureBuilder<bool>(
          future: isAuthenticated(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final auth = snapshot.data!;

            if (auth && isLoginRoute) {
              Future.microtask(() => Navigator.of(context).pushReplacementNamed('/home'));
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!auth && !isLoginRoute) {
              return const PantallaLogin();
            }

            final pageBuilder = rutas[settings.name];
            if (pageBuilder != null) return pageBuilder(context);

            return const Scaffold(body: Center(child: Text('Ruta no encontrada')));
          },
        );
      },
      settings: settings,
    );
  }

}
