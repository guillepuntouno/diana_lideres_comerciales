import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool validarFormulario() {
    return formKey.currentState?.validate() ?? false;
  }

  void iniciarSesion(BuildContext context) {
    if (validarFormulario()) {
      Navigator.pushNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
