import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../widgets/footer_clipper.dart';
import 'package:diana_lc_front/platform/platform_bridge.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class PantallaLogin extends StatelessWidget {

  const PantallaLogin({super.key});

//ESTE login es de azure preparado para Diana
/*   void redirectToAzureLogin() {
    final loginUri = Uri.https(
      'app-lideres-comerciales.auth.us-east-1.amazoncognito.com',
      '/login',
      {
        'client_id': '18emuo0gi95toqe0q6sidgs5ir',
        'response_type': 'token',
        'scope': 'email openid phone profile',
        'redirect_uri': 'https://main.d35w48mc01xbrz.amplifyapp.com/login',
        'identity_provider': 'AzureAD',
      },
    );
    p.redirectTo(loginUri.toString());
  } */

  // Para desarrollo local - usar este método cuando ejecutes localmente
  void redirectToAzureLogin() {
    print('🔐 redirectToAzureLogin called');
    
    // Obtener el origen actual de la ventana para manejar diferentes puertos
    final currentOrigin = p.getCurrentOrigin();
    print('📍 Current origin: $currentOrigin');
    
    String redirectUri;
    
    // Para móvil usar deep link, para web usar URL completa
    if (currentOrigin == 'app://internal') {
      // Usar deep link para que regrese a la app
      redirectUri = 'dianacallback://login';
      print('📱 Using mobile redirect URI (deep link)');
    } else {
      redirectUri = '$currentOrigin/login';
      print('🌐 Using web redirect URI');
    }
    
    print('🔗 Redirect URI: $redirectUri');
    
    final loginUri = Uri.https(
      'app-lideres-comerciales.auth.us-east-1.amazoncognito.com',
      '/login',
      {
        'client_id': '18emuo0gi95toqe0q6sidgs5ir',
        'response_type': 'token',
        'scope': 'openid email phone profile',
        'redirect_uri': redirectUri,
        'identity_provider': 'AzureAD',
      },
    );
    
    print('🌍 Full login URL: ${loginUri.toString()}');
    print('🚀 Calling p.redirectTo...');
    
    p.redirectTo(loginUri.toString());
    
    print('✅ p.redirectTo called');
  }
  
  // Para producción - descomentar este método cuando hagas deploy
  /*
  void redirectToAzureLogin() {
    final loginUri = Uri.https(
      'app-lideres-comerciales.auth.us-east-1.amazoncognito.com',
      '/login',
      {
        'client_id': '18emuo0gi95toqe0q6sidgs5ir',
        'response_type': 'token',
        'scope': 'openid email phone profile',
        'redirect_uri': 'https://main.d35w48mc01xbrz.amplifyapp.com/login',
        'identity_provider': 'AzureAD',
      },
    );
    p.redirectTo(loginUri.toString());
  }
  */

  /* 
  remi.aguilar
  D:V'jFU#b/3
   */

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
          // Si el usuario ya está autenticado, redirigir al menú principal
          if (vm.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
          }
          
          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Form(
                          key: vm.formKey,
                          child: Column(
                            children: [
                              // Logo responsivo
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxLogoHeight = MediaQuery.of(context).size.height * 0.25;
                                  return Image.asset(
                                    'assets/logo_diana.png',
                                    height: maxLogoHeight.clamp(80.0, 200.0),
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
                            Text(
                              'Modelo de Gestión de Ventas',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C2120),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Inicia sesión con tu cuenta corporativa de Azure AD',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

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
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: vm.isLoading ? null : redirectToAzureLogin,
                                icon: vm.isLoading
                                    ? const SizedBox.shrink()
                                    : const Icon(Icons.login, size: 20),
                                label: vm.isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFBD59),
                                  foregroundColor: const Color(0xFF1C2120),
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 60), // Espacio para el footer
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    color: const Color(0xFFDE1327).withOpacity(0.9),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Esta aplicación es propiedad exclusiva de DIANA ©. Todos los derechos reservados.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}
