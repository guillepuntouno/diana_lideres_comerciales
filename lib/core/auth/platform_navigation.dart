import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_utils.dart';
import 'platform_pref.dart';
import '../widgets/platform_picker_dialog.dart';

class PlatformNavigation {
  static Future<void> handlePostLoginNavigation(
    BuildContext context,
    Map<String, dynamic> userData,
    String token,
  ) async {
    try {
      print('🚀 Iniciando navegación post-login');
      print('📋 Datos del usuario: $userData');
      
      // Extraer rol del usuario - puede venir en diferentes campos
      final rol = userData['rol'] ?? 
                  userData['family_name'] ?? 
                  userData['custom:rol'] ?? 
                  userData['cognito:groups']?.toString() ?? 
                  '';
      print('👤 Rol detectado: $rol');
      print('📋 Datos completos del usuario: ${userData.keys.join(', ')}');
      
      // Debug: Imprimir todos los valores posibles de rol
      print('🔍 Buscando rol en diferentes campos:');
      print('  - userData["rol"]: ${userData['rol']}');
      print('  - userData["family_name"]: ${userData['family_name']}');
      print('  - userData["custom:rol"]: ${userData['custom:rol']}');
      print('  - userData["cognito:groups"]: ${userData['cognito:groups']}');
      
      // Mapear el rol a RolCanonico
      final rolCanonico = RoleUtils.mapRol(rol);
      if (rolCanonico == null) {
        print('⚠️ Rol no reconocido: $rol -> fallback a /home');
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
      
      print('✅ Rol canónico: $rolCanonico');
      
      // Obtener plataformas permitidas para el rol
      final plataformasPermitidas = RoleUtils.plataformasParaRol(rolCanonico);
      print('📱 Plataformas permitidas: $plataformasPermitidas');
      
      // Obtener la clave única del usuario
      final userKey = RoleUtils.getUserKey(userData);
      
      // Verificar si hay un parámetro de plataforma en la URL (deep link)
      final platformParam = await _getPlatformFromDeepLink();
      
      if (plataformasPermitidas.length == 1) {
        // Solo una plataforma disponible (LÍDER) -> ir directo a móvil
        print('🎯 Rol LÍDER detectado -> navegando directo a móvil');
        _navigateToMobile(context);
      } else {
        // Múltiples plataformas disponibles
        
        // 1. Verificar si hay un parámetro de plataforma válido
        if (platformParam != null && plataformasPermitidas.contains(platformParam)) {
          print('🔗 Plataforma desde deep link: $platformParam');
          _navigateToPlatform(context, platformParam);
          return;
        }
        
        // 2. Verificar si hay una preferencia guardada
        final savedPlatform = await PlatformPreferences.loadPlatformChoice(userKey);
        if (savedPlatform != null && plataformasPermitidas.contains(savedPlatform)) {
          print('💾 Plataforma guardada encontrada: $savedPlatform');
          _navigateToPlatform(context, savedPlatform);
          return;
        }
        
        // 3. Mostrar selector de plataforma
        print('🎨 Mostrando selector de plataforma');
        // Pequeño delay para asegurar que el contexto esté listo
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (context.mounted) {
          await _showPlatformPicker(context, userKey, rol);
        } else {
          print('⚠️ Context no está montado, navegando a home por defecto');
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('❌ Error en navegación post-login: $e');
      // Fallback a home en caso de error
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
  
  static Future<AppPlatform?> _getPlatformFromDeepLink() async {
    try {
      // Obtener el URI actual si existe
      final uri = Uri.base;
      print('🔗 URI actual: $uri');
      
      // Buscar el parámetro 'platform' en la query
      final platformParam = uri.queryParameters['platform'];
      
      if (platformParam != null) {
        print('📍 Parámetro platform encontrado: $platformParam');
        
        // Convertir el string a AppPlatform
        switch (platformParam.toLowerCase()) {
          case 'mobile':
            return AppPlatform.mobile;
          case 'web':
            return AppPlatform.web;
          default:
            print('⚠️ Valor de platform no válido: $platformParam');
            return null;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error al obtener platform desde deep link: $e');
      return null;
    }
  }
  
  static Future<void> _showPlatformPicker(
    BuildContext context,
    String userKey,
    String rol,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PlatformPickerDialog(
          roleDescription: 'Como $rol, puedes acceder a ambas plataformas',
          onPlatformSelected: (platform, remember) async {
            print('📌 Plataforma seleccionada: $platform, recordar: $remember');
            
            if (remember) {
              await PlatformPreferences.savePlatformChoice(userKey, platform);
            }
            
            // Log telemetría
            _logPlatformSelection(userKey, rol, platform, remember);
            
            // Usar el contexto del Navigator para la navegación
            if (Navigator.of(context).mounted) {
              _navigateToPlatform(Navigator.of(context).context, platform);
            }
          },
        );
      },
    );
  }
  
  static void _navigateToPlatform(BuildContext context, AppPlatform platform) {
    switch (platform) {
      case AppPlatform.mobile:
        _navigateToMobile(context);
        break;
      case AppPlatform.web:
        _navigateToWeb(context);
        break;
    }
  }
  
  static void _navigateToMobile(BuildContext context) {
    print('📱 Navegando a aplicación móvil');
    Navigator.of(context).pushReplacementNamed('/home');
  }
  
  static void _navigateToWeb(BuildContext context) {
    print('💻 Navegando a aplicación web');
    Navigator.of(context).pushReplacementNamed('/administracion');
  }
  
  static void _logPlatformSelection(
    String userKey,
    String rol,
    AppPlatform platform,
    bool remembered,
  ) {
    // TODO: Implementar logging/telemetría
    print('📊 Telemetría: Usuario=$userKey, Rol=$rol, Plataforma=${platform.name}, Recordado=$remembered');
  }
  
  // Método para limpiar la preferencia de plataforma (para usar en configuración)
  static Future<void> clearPlatformPreference(String userKey) async {
    await PlatformPreferences.clearPlatformChoice(userKey);
  }
}