import 'package:shared_preferences/shared_preferences.dart';
import 'role_utils.dart';

class PlatformPreferences {
  static const String _platformPrefPrefix = 'platform_choice_';
  
  static Future<void> savePlatformChoice(String userKey, AppPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_platformPrefPrefix$userKey';
    await prefs.setString(key, platform.name);
    print('✅ Preferencia de plataforma guardada: $userKey -> ${platform.name}');
  }
  
  static Future<AppPlatform?> loadPlatformChoice(String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_platformPrefPrefix$userKey';
    final platformName = prefs.getString(key);
    
    if (platformName == null) {
      return null;
    }
    
    try {
      return AppPlatform.values.firstWhere((p) => p.name == platformName);
    } catch (e) {
      print('⚠️ Error al cargar preferencia de plataforma: $e');
      return null;
    }
  }
  
  static Future<void> clearPlatformChoice(String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_platformPrefPrefix$userKey';
    await prefs.remove(key);
    print('🗑️ Preferencia de plataforma eliminada para: $userKey');
  }
  
  static Future<void> clearAllPlatformChoices() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_platformPrefPrefix));
    
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    print('🗑️ Todas las preferencias de plataforma han sido eliminadas');
  }
}