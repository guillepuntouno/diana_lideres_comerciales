// lib/vistas/visita_cliente/pantalla_visita_cliente.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/activity_model.dart'; // Importar el modelo compartido

class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

class PantallaVisitaCliente extends StatefulWidget {
  const PantallaVisitaCliente({super.key});

  @override
  State<PantallaVisitaCliente> createState() => _PantallaVisitaClienteState();
}

class _PantallaVisitaClienteState extends State<PantallaVisitaCliente> {
  ActivityModel? actividad;
  final TextEditingController _comentariosController = TextEditingController();
  String _ubicacionActual = 'Obteniendo ubicación...';
  bool _cargandoUbicacion = true;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recibir los argumentos de la navegación
    final args = ModalRoute.of(context)?.settings.arguments;
    print('🔍 Argumentos recibidos: $args');
    print('🔍 Tipo de argumentos: ${args.runtimeType}');

    if (args is ActivityModel) {
      actividad = args;
      print('✅ Actividad recibida correctamente:');
      print('   └── ID: ${actividad!.id}');
      print('   └── Título: ${actividad!.title}');
      print('   └── Cliente: ${actividad!.cliente}');
      print('   └── Dirección: ${actividad!.direccion}');
      print('   └── Asesor/Ruta: ${actividad!.asesor}');
    } else {
      print('❌ Error: Los argumentos no son del tipo ActivityModel');
      print('   └── Argumentos recibidos: $args');
    }
  }

  Future<void> _obtenerUbicacion() async {
    // Simulación de obtención de ubicación
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _ubicacionActual = 'Av. Morones Prieto 500 PTE, MTY';
      _cargandoUbicacion = false;
    });

    print('📍 Ubicación obtenida: $_ubicacionActual');
  }

  Future<void> _realizarCheckIn() async {
    if (_comentariosController.text.trim().isEmpty) {
      _mostrarError('Por favor, agregue un comentario antes del check-in');
      return;
    }

    print('📝 Comentarios: ${_comentariosController.text}');
    print('📍 Ubicación: $_ubicacionActual');
    print('🏪 Iniciando check-in para cliente: ${actividad!.cliente}');

    // TODO: Navegar al formulario dinámico
    Navigator.pushNamed(
      context,
      '/formulario_dinamico',
      arguments: {
        'actividad': actividad,
        'comentarios': _comentariosController.text,
        'ubicacion': _ubicacionActual,
      },
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (actividad == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Error',
            style: GoogleFonts.poppins(
              color: AppColors.darkGray,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No se recibieron datos del cliente',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: AppColors.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, regrese e intente nuevamente',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: Text(
                  'Regresar',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dianaRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Visita a cliente',
          style: GoogleFonts.poppins(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente (según boceto)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del cliente
                  Text(
                    actividad!.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),

                  if (actividad!.direccion != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      actividad!.direccion!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],

                  if (actividad!.cliente != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${actividad!.cliente}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  if (actividad!.asesor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ruta: ${actividad!.asesor}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ubicación actual (según boceto)
            Text(
              'Ubicación actual',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color:
                        _cargandoUbicacion
                            ? AppColors.mediumGray
                            : AppColors.dianaRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        _cargandoUbicacion
                            ? Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _ubicacionActual,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              _ubicacionActual,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Comentarios (según boceto)
            Text(
              'Comentarios',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: TextField(
                controller: _comentariosController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escriba sus observaciones sobre la visita...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.mediumGray,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón CHECK-IN (según boceto)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargandoUbicacion ? null : _realizarCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dianaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                child: Text(
                  'CHECK-IN',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón cancelar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.mediumGray.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
