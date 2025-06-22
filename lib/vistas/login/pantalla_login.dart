import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../widgets/footer_clipper.dart';

class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = LoginViewModel();
        // Inicializar el viewModel
        viewModel.initialize();
        return viewModel;
      },
      child: Consumer<LoginViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: vm.formKey,
                    child: Column(
                      children: [
                        Image.asset('assets/logo_diana.png', height: 320),
                        const SizedBox(height: 32),
                        Text(
                          'Bienvenido',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C2120),
                          ),
                        ),
                        Text(
                          'Líderes Comerciales',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: const Color(0xFF8F8E8E),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Mostrar mensaje de error si existe
                        if (vm.errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vm.errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: vm.clearError,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.red.shade600,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CORREO ELECTRÓNICO',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8F8E8E),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: vm.emailController,
                          enabled: !vm.isLoading,
                          decoration: InputDecoration(
                            hintText: 'LID001@diana.com.sv',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF1C2120),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF8F8E8E).withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su correo';
                            }
                            if (!value.contains('@')) {
                              return 'Correo inválido';
                            }
                            return null;
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1C2120),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                vm.isLoading
                                    ? null
                                    : () => vm.iniciarSesion(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBD59),
                              foregroundColor: const Color(0xFF1C2120),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child:
                                vm.isLoading
                                    ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF1C2120),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'INICIANDO SESIÓN...',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                    : Text(
                                      'INICIAR SESIÓN',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sync, size: 24),
                            SizedBox(width: 20),
                            Icon(Icons.add_circle_outline, size: 24),
                          ],
                        ),
                        const SizedBox(height: 32),
                        ClipPath(
                          clipper: FooterClipper(),
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            color: const Color(0xFFDE1327),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
