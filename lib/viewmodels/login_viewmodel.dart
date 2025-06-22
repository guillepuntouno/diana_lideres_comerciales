import 'package:flutter/material.dart';
import '../servicios/lider_comercial_servicio.dart';
import '../servicios/sesion_servicio.dart';
import '../modelos/lider_comercial_modelo.dart';
import '../repositorios/lider_comercial_repository.dart';
import '../modelos/hive/lider_comercial_hive.dart';
import '../servicios/offline_sync_manager.dart';
import '../servicios/plan_trabajo_offline_service.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final LiderComercialServicio _liderServicio = LiderComercialServicio();
  final LiderComercialRepository _liderRepository = LiderComercialRepository();
  final OfflineSyncManager _syncManager = OfflineSyncManager();
  final PlanTrabajoOfflineService _planOfflineService = PlanTrabajoOfflineService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool validarFormulario() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Inicializa el ViewModel
  Future<void> initialize() async {
    print('✅ LoginViewModel inicializado - Usando endpoint real');
    // El sync manager ya no se inicializa aquí porque HiveService se inicializa en main
    // Solo verificamos que esté listo
    try {
      await _syncManager.initialize();
    } catch (e) {
      print('⚠️ OfflineSyncManager no se pudo inicializar: $e');
      // Continuamos sin funcionalidad de sync
    }
  }

  Future<void> iniciarSesion(BuildContext context) async {
    if (!validarFormulario()) return;

    _setLoading(true);
    _setError(null);

    try {
      // Extraer la clave del email (parte antes del @)
      final email = emailController.text.trim();
      final clave = email.split('@')[0].toUpperCase();

      print('🔑 Intentando login con clave: $clave');

      // Primero intentar obtener datos del endpoint
      final liderData = await _liderServicio.obtenerPorClave(clave);

      if (liderData != null) {
        // Convertir los datos del API a nuestro modelo
        final liderComercial = LiderComercial.fromJson(liderData);

        // Guardar en la sesión (SharedPreferences)
        await SesionServicio.guardarLiderComercial(liderComercial);

        // Intentar guardar en Hive para funcionalidad offline
        try {
          final liderHive = LiderComercialHive.fromLiderComercial(liderComercial);
          await _liderRepository.save(liderHive);
          print('💾 Datos guardados en Hive para uso offline');
        } catch (hiveError) {
          print('⚠️ No se pudieron guardar datos en Hive: $hiveError');
          // Continuar sin funcionalidad offline
        }

        // Intentar guardar token de auth
        try {
          await _syncManager.saveAuthToken('${liderComercial.clave}_token');
        } catch (syncError) {
          print('⚠️ No se pudo guardar token de auth: $syncError');
          // Continuar sin funcionalidad de sync
        }

        // Cargar datos para trabajo offline (clientes, objetivos, etc.)
        try {
          await _planOfflineService.cargarDatosIniciales();
          print('📦 Datos offline cargados correctamente');
        } catch (offlineError) {
          print('⚠️ No se pudieron cargar todos los datos offline: $offlineError');
          // Continuar sin algunos datos offline
        }

        print('✅ Login exitoso para: $clave');
        print('📱 Datos guardados en SharedPreferences y Hive');

        // Navegar a la pantalla principal
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Si no hay conexión, intentar buscar en Hive
        try {
          final liderOffline = _liderRepository.getByClave(clave);
          
          if (liderOffline != null) {
            // Convertir de Hive a modelo regular para sesión
            final liderComercial = liderOffline.toLiderComercial();
            await SesionServicio.guardarLiderComercial(liderComercial);

            print('✅ Login offline exitoso para: $clave');
            print('📱 Usando datos almacenados localmente');

            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            _setError('Usuario no encontrado.\n\nVerifica tu conexión a internet o que el usuario esté registrado en el sistema.');
          }
        } catch (hiveError) {
          print('⚠️ Error accediendo a datos offline: $hiveError');
          _setError('Usuario no encontrado.\n\nNo se pudo acceder a los datos offline. Verifica tu conexión a internet.');
        }
      }
    } catch (e) {
      print('❌ Error en login: $e');
      
      // En caso de error, intentar login offline como fallback
      try {
        final email = emailController.text.trim();
        final clave = email.split('@')[0].toUpperCase();
        final liderOffline = _liderRepository.getByClave(clave);
        
        if (liderOffline != null) {
          final liderComercial = liderOffline.toLiderComercial();
          await SesionServicio.guardarLiderComercial(liderComercial);
          
          print('✅ Login offline de respaldo exitoso para: $clave');
          
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _setError('Error de conexión: $e\n\nNo se encontraron datos offline para este usuario.');
        }
      } catch (offlineError) {
        print('⚠️ Error en fallback offline: $offlineError');
        _setError('Error de login: $e\n\nNo fue posible conectar con el servidor ni encontrar datos offline.');
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}