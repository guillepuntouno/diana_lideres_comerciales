import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

String getCurrentUrl() {
  return 'app://internal';
}

String getCurrentOrigin() {
  return 'app://internal';
}

String? getCurrentPathname() {
  return '/';
}

String getCurrentHash() {
  return '';
}

void redirectTo(String url) async {
  print('🔗 Mobile redirectTo called with URL: $url');
  
  // For mobile, launch the URL in an external browser
  final uri = Uri.parse(url);
  
  try {
    print('🔍 Checking if can launch URL...');
    if (await canLaunchUrl(uri)) {
      print('✅ Can launch URL, opening browser...');
      
      // Usar platformDefault para mejor manejo de deep links
      // Esto permite que el sistema operativo decida la mejor forma de manejar la URL
      final result = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      print('🌐 Launch result: $result');
      
      // En Android, a veces necesitamos un pequeño delay
      await Future.delayed(const Duration(milliseconds: 100));
      
    } else {
      print('❌ Cannot launch URL: $url');
    }
  } catch (e) {
    print('❌ Error launching URL: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}

void replaceState(String url) {
  // No-op on mobile as there's no browser history
  print('Mobile replaceState requested: $url');
}

String? getLocalStorage(String key) {
  // On mobile, we'll use SharedPreferences synchronously
  // Note: This is a simplified implementation. In production,
  // you might want to handle this differently
  return null;
}

Future<void> setLocalStorage(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> removeLocalStorage(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}

Map<String, String> getUrlParameters() {
  // Mobile apps don't have URL fragments
  return {};
}

void clearUrlFragment() {
  // No-op on mobile as there's no URL fragment
}