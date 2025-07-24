import 'package:flutter/material.dart';
import 'package:diana_lc_front/shared/servicios/simple_login_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/repositorios/lider_comercial_repository.dart';
import 'package:diana_lc_front/shared/modelos/hive/lider_comercial_hive.dart';
import 'package:diana_lc_front/shared/servicios/offline_sync_manager.dart';

class LoginViewModelSimple extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final SimpleLoginService _loginService = SimpleLoginService();
  final LiderComercialRepository _liderRepository = LiderComercialRepository();
  final OfflineSyncManager _syncManager = OfflineSyncManager();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool validarFormulario() {
    return formKey.currentState?.validate() ?? false;
  }

  Future<void> initialize() async {
    print(' SimpleLoginViewModel inicializado');
    await _syncManager.initialize();
  }

  Future<void> iniciarSesion(BuildContext context) async {
    if (!validarFormulario()) return;

    _setLoading(true);
    _setError(null);

    try {
      final email = emailController.text.trim();
      final clave = email.split('@')[0].toUpperCase();

      print('= Intentando login con clave: $clave');

      // Intentar login con el endpoint
      final liderComercial = await _loginService.login(clave);

      if (liderComercial != null) {
        // Guardar en sesión
        await SesionServicio.guardarLiderComercial(liderComercial);

        // Guardar en Hive para offline
        final liderHive = LiderComercialHive.fromLiderComercial(liderComercial);
        await _liderRepository.save(liderHive);

        // Guardar token de auth
        await _syncManager.saveAuthToken('${liderComercial.clave}_token');

        print(' Login exitoso para: $clave');

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Intentar login offline
        final liderOffline = _liderRepository.getByClave(clave);
        
        if (liderOffline != null) {
          final liderComercial = liderOffline.toLiderComercial();
          await SesionServicio.guardarLiderComercial(liderComercial);

          print(' Login offline exitoso para: $clave');

          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _setError('Usuario no encontrado.\n\nVerifica tu conexión a internet.');
        }
      }
    } catch (e) {
      print('L Error en login: $e');
      _setError('Error de conexión: $e');
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