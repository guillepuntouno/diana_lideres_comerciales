import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenFromUrl = _getTokenFromUrl();
  print('tokenFromUrl MAIN: $tokenFromUrl');
  if (tokenFromUrl != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_token', tokenFromUrl);
    _clearUrlFragment();
  }
  runApp(DianaApp());
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

