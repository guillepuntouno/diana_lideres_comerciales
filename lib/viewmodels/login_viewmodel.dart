import 'package:flutter/material.dart';
import '../servicios/lider_comercial_servicio.dart';
import '../servicios/sesion_servicio.dart';
import '../modelos/lider_comercial_modelo.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final LiderComercialServicio _liderServicio = LiderComercialServicio();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool validarFormulario() {
    return formKey.currentState?.validate() ?? false;
  }

  Future<void> iniciarSesion(BuildContext context) async {
    if (!validarFormulario()) return;

    _setLoading(true);
    _setError(null);

    try {
      // Extraer la clave del email (parte antes del @)
      final email = emailController.text.trim();
      final clave = email.split('@')[0].toUpperCase();

      // Llamar a la API
      final data = await _liderServicio.obtenerPorClave(clave);

      if (data != null) {
        // Convertir los datos a nuestro modelo
        final liderComercial = LiderComercial.fromJson(data);

        // Guardar en la sesión
        await SesionServicio.guardarLiderComercial(liderComercial);

        // Navegar a la pantalla principal
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _setError('Usuario no encontrado o credenciales inválidas');
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Timeout')) {
        errorMessage = 'El servidor está tardando en responder. Intente nuevamente.';
      } else if (e.toString().contains('Connection refused') || 
                 e.toString().contains('SocketException')) {
        errorMessage = 'No se puede conectar al servidor. Verifique su conexión.';
      } else {
        errorMessage = 'Error de conexión. Verifique su internet e intente nuevamente.';
      }
      _setError(errorMessage);
      debugPrint('Error en login: $e');
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
