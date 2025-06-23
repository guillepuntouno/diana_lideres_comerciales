import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando DIANA con funcionalidad offline...');
  print('📝 Para probar login, usa tu usuario del sistema o datos offline');
  
  // Verificar si hay token en la URL (de AWS Cognito)
  final tokenFromUrl = _getTokenFromUrl();
  print('tokenFromUrl MAIN: $tokenFromUrl');
  bool hasNewToken = false;
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
  final hash = html.window.location.hash;
  if (hash.isEmpty) return null;
  final fragment = hash.substring(1); // remove #
  final params = Uri.splitQueryString(fragment);
  return params['id_token'];
}

void _clearUrlFragment() {
  html.window.history.replaceState(null, '', html.window.location.pathname!);
}