import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diana_lc_front/vistas/login/pantalla_login.dart';
import 'package:diana_lc_front/rutas/rutas.dart';
import 'package:diana_lc_front/vistas/menu_principal/pantalla_menu_principal.dart';
import 'package:http/http.dart' as http;
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';

class AuthGuard {
  static const tokenKey = 'id_token';
  static const userKey = 'usuario';

  /// Validación principal
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) return false;

    // Imprimir información del token para debug
    print('🔐 Token JWT recibido');
    _debugPrintTokenInfo(token);

    if (!_isLocallyValid(token)) return false;

    // Intentar validar con el backend
    final userData = await _validateTokenWithBackend(token);
    print('📡 Respuesta del backend: $userData');

    // Si userData es null, es por el error de CORS
    if (userData == null) {
      // Guardar error para mostrar en la UI
      await prefs.setString('auth_error', 'cors_error');
      print('❌ Error de CORS: No se puede validar el token con el backend');
      return false;
    }

    // Limpiar cualquier error previo
    await prefs.remove('auth_error');
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
  static Future<Map<String, dynamic>?> _validateTokenWithBackend(
    String token,
  ) async {
    try {
      final response = await http.get(
        // Uri.parse(
        // 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev/auth/session',
        //),
        Uri.parse('${AmbienteConfig.baseUrl}/auth/session'),
        headers: {'Authorization': 'Bearer $token'},
      );

      /*  
     *******Este codigo hay que colocarlo cuando debes seleccioanr los clientes de un plan de trabajo -> ruta -> dia*****
     final uri = Uri.parse('https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev/clientes');
      final response2 = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'dia': 'Lunes',
          'lider': 'LIDER SE - GRUPO B',
          'ruta': 'RUTASED08',
        }),
      );
      if (response2.statusCode == 200) {
        print(response2.body);
      } */
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error al validar token con backend: $e');
    }
    return null;
  }

  /// Extrae el family_name del token JWT para determinar el perfil del usuario
  static String? getFamilyNameFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadBase64 = parts[1];
      final normalized = base64.normalize(payloadBase64);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = json.decode(decoded);

      return payload['family_name'] as String?;
    } catch (e) {
      print('❌ Error al extraer family_name del token: $e');
      return null;
    }
  }

  /// Determina la ruta de redirección basada en el perfil del usuario
  static String getRedirectRouteByProfile(String? familyName) {
    if (familyName == null) return '/home'; // Fallback por defecto
    
    switch (familyName) {
      case 'GERENTE_MGV':
      case 'GERENTE_DE_DISTRITO_PAIS':
      case 'COORDINADOR_MGV':
        print('👤 Perfil administrativo detectado: $familyName -> /administracion');
        return '/administracion';
      case 'LIDER':
        print('👤 Perfil líder comercial detectado: $familyName -> /home');
        return '/home';
      default:
        print('⚠️ Perfil no reconocido: $familyName -> /home (fallback)');
        return '/home';
    }
  }

  /// Verifica si el usuario actual tiene permisos administrativos
  static Future<bool> _hasAdminPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      
      if (token == null) return false;
      
      final familyName = getFamilyNameFromToken(token);
      final isAdmin = familyName != null && [
        'GERENTE_MGV',
        'GERENTE_DE_DISTRITO_PAIS', 
        'COORDINADOR_MGV'
      ].contains(familyName);
      
      print('🔐 Verificación permisos admin: family_name=$familyName, isAdmin=$isAdmin');
      return isAdmin;
    } catch (e) {
      print('❌ Error verificando permisos admin: $e');
      return false;
    }
  }

  /// Debug: Imprime información del token
  static void _debugPrintTokenInfo(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Token JWT inválido - no tiene 3 partes');
        return;
      }

      final payloadBase64 = parts[1];
      final normalized = base64.normalize(payloadBase64);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = json.decode(decoded);

      print('📋 Contenido del token JWT:');
      print(
        '- Usuario: ${payload['cognito:username'] ?? payload['email'] ?? 'No encontrado'}',
      );
      print('- Email: ${payload['email'] ?? 'No encontrado'}');
      print('- Sub: ${payload['sub'] ?? 'No encontrado'}');
      print('- Family Name: ${payload['family_name'] ?? 'No encontrado'}');
      print(
        '- Expiración: ${DateTime.fromMillisecondsSinceEpoch((payload['exp'] ?? 0) * 1000)}',
      );
      print('- Token completo payload: $payload');
    } catch (e) {
      print('❌ Error al decodificar token: $e');
    }
  }

  // 🔀 Centraliza todas las rutas y aplica validación
  static Route<dynamic> handleRoute(
    RouteSettings settings,
    Map<String, WidgetBuilder> rutas,
  ) {
    final isLoginRoute =
        settings.name == '/login' ||
        settings.name == '' ||
        settings.name == '/';

    return MaterialPageRoute(
      builder: (context) {
        return FutureBuilder<bool>(
          future: isAuthenticated(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final auth = snapshot.data!;

            if (auth && isLoginRoute) {
              Future.microtask(() async {
                // Obtener el token para extraer el family_name
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString(tokenKey);
                
                // Determinar ruta de redirección basada en perfil
                String redirectRoute = '/home'; // Fallback por defecto
                if (token != null) {
                  final familyName = getFamilyNameFromToken(token);
                  redirectRoute = getRedirectRouteByProfile(familyName);
                }
                
                Navigator.of(context).pushReplacementNamed(redirectRoute);
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!auth && !isLoginRoute) {
              return const PantallaLogin();
            }

            // Validación de permisos para rutas administrativas
            if (settings.name == '/administracion') {
              return FutureBuilder<bool>(
                future: _hasAdminPermissions(),
                builder: (context, permissionSnapshot) {
                  if (!permissionSnapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!permissionSnapshot.data!) {
                    print('❌ Acceso denegado a ruta administrativa: ${settings.name}');
                    // Redirigir a home si no tiene permisos administrativos
                    Future.microtask(
                      () => Navigator.of(context).pushReplacementNamed('/home'),
                    );
                    return const Scaffold(
                      body: Center(
                        child: Text('Redirigiendo...'),
                      ),
                    );
                  }
                  
                  final pageBuilder = rutas[settings.name];
                  return pageBuilder?.call(context) ?? 
                    const Scaffold(body: Center(child: Text('Ruta no encontrada')));
                },
              );
            }

            final pageBuilder = rutas[settings.name];
            if (pageBuilder != null) return pageBuilder(context);

            return const Scaffold(
              body: Center(child: Text('Ruta no encontrada')),
            );
          },
        );
      },
      settings: settings,
    );
  }
}
