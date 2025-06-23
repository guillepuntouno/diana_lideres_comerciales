import 'package:flutter/material.dart';
import '../servicios/lider_comercial_servicio.dart';
import '../servicios/sesion_servicio.dart';
import '../modelos/lider_comercial_modelo.dart';
import '../repositorios/lider_comercial_repository.dart';
import '../modelos/hive/lider_comercial_hive.dart';
import '../servicios/offline_sync_manager.dart';
import '../servicios/plan_trabajo_offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../servicios/auth_guard.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final LiderComercialServicio _liderServicio = LiderComercialServicio();
  final LiderComercialRepository _liderRepository = LiderComercialRepository();
  final OfflineSyncManager _syncManager = OfflineSyncManager();
  final PlanTrabajoOfflineService _planOfflineService = PlanTrabajoOfflineService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  bool validarFormulario() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Inicializa el ViewModel
  Future<void> initialize() async {
    print('✅ LoginViewModel inicializado - Verificando autenticación AWS');
    // El sync manager ya no se inicializa aquí porque HiveService se inicializa en main
    // Solo verificamos que esté listo
    try {
      await _syncManager.initialize();
    } catch (e) {
      print('⚠️ OfflineSyncManager no se pudo inicializar: $e');
      // Continuamos sin funcionalidad de sync
    }
    
    // Verificar si ya hay un token válido de AWS
    await _checkExistingAuth();
  }
  
  /// Verifica si ya existe autenticación válida
  Future<void> _checkExistingAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthGuard.tokenKey);
      
      if (token != null && token.isNotEmpty) {
        print('🔑 Token AWS encontrado, verificando validez...');
        
        // Verificar si el token es válido
        final isValid = await AuthGuard.isAuthenticated();
        
        if (isValid) {
          print('✅ Token válido, usuario ya autenticado');
          // El usuario ya está autenticado, podemos redirigir
          _isAuthenticated = true;
          notifyListeners();
        } else {
          print('❌ Token inválido o error de validación');
          
          // Verificar si es error de CORS
          final authError = prefs.getString('auth_error');
          if (authError == 'cors_error') {
            _setError(
              'Error de conexión con el servidor\n\n'
              'No se puede validar tu sesión debido a un problema de configuración (CORS).\n'
              'El servidor está configurado para aceptar conexiones desde el puerto 51052, '
              'pero tu aplicación está ejecutándose en un puerto diferente.\n\n'
              'Por favor, contacta al administrador del sistema.'
            );
            await prefs.remove('auth_error');
          }
          
          // Limpiar el token inválido
          await prefs.remove(AuthGuard.tokenKey);
        }
      }
    } catch (e) {
      print('⚠️ Error verificando autenticación existente: $e');
    }
  }

  // Este método ya no se usa porque el login es a través de AWS Cognito
  // Se mantiene por si se necesita en el futuro para login local/offline
  Future<void> iniciarSesion(BuildContext context) async {
    print('⚠️ El login ahora se maneja a través de AWS Cognito');
    // Redirigir a AWS Cognito se hace desde el botón en la pantalla
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