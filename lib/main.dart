import 'package:flutter/material.dart';
import 'app.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:diana_lc_front/platform/platform_bridge.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando DIANA con funcionalidad offline...');
  print('📝 Para probar login, usa tu usuario del sistema o datos offline');
  
  bool hasNewToken = false;
  String? tokenFromUrl;
  
  // Verificar la plataforma
  try {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Para web, obtener token de la URL
      tokenFromUrl = _getTokenFromUrl();
      print('tokenFromUrl MAIN (Web): $tokenFromUrl');
    } else {
      // Para móvil, verificar si se está abriendo con un deep link
      final appLinks = AppLinks();
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        print('🔗 Initial deep link: $initialLink');
        tokenFromUrl = _extractTokenFromDeepLink(initialLink.toString());
      }
    }
  } catch (e) {
    // Si Platform no está disponible (web), usar el método web
    tokenFromUrl = _getTokenFromUrl();
    print('tokenFromUrl MAIN (Web fallback): $tokenFromUrl');
  }
  
  if (tokenFromUrl != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_token', tokenFromUrl);
    hasNewToken = true;
    
    // DEBUG: Imprimir token JWT para pruebas
    print('🔐 TOKEN JWT OBTENIDO DEL LOGIN:');
    print('=====================================');
    print(tokenFromUrl);
    print('=====================================');
    print('📋 Token guardado en SharedPreferences con clave: id_token');
    print('🔗 Puedes usar este token para probar los endpoints');
    print('=====================================');
    
    _clearUrlFragment();
  }
  
  runApp(DianaApp(hasNewToken: hasNewToken));
}

// 👇 Coloca estas funciones globales o en un helper
String? _getTokenFromUrl() {
  final params = p.getUrlParameters();
  return params['id_token'];
}

void _clearUrlFragment() {
  p.clearUrlFragment();
}

String? _extractTokenFromDeepLink(String deepLink) {
  try {
    print('🔍 Procesando deep link: $deepLink');
    final uri = Uri.parse(deepLink);
    
    // Cognito devuelve el token en el fragmento después del #
    if (uri.fragment.isNotEmpty) {
      print('📍 Fragment encontrado: ${uri.fragment}');
      final params = Uri.splitQueryString(uri.fragment);
      final token = params['id_token'];
      if (token != null) {
        print('✅ Token extraído del fragment');
        return token;
      }
    }
    
    // O puede venir como query parameter
    if (uri.queryParameters.containsKey('id_token')) {
      print('✅ Token extraído de query parameters');
      return uri.queryParameters['id_token'];
    }
    
    print('⚠️ No se encontró token en el deep link');
    return null;
  } catch (e) {
    print('❌ Error extrayendo token del deep link: $e');
    return null;
  }
}