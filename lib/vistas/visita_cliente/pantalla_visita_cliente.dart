// lib/vistas/visita_cliente/pantalla_visita_cliente.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importar el modelo de ActivityModel desde rutinas
// En tu proyecto real, puedes mover este modelo a un archivo compartido
// Por ahora, voy a redefinir los modelos necesarios aquí

enum ActivityType { admin, visita }

enum ActivityStatus { pendiente, enCurso, completada, postergada }

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String? asesor;
  final String? cliente;
  final String? direccion;
  ActivityStatus status;
  DateTime? horaInicio;
  DateTime? horaFin;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.asesor,
    this.cliente,
    this.direccion,
    this.status = ActivityStatus.pendiente,
    this.horaInicio,
    this.horaFin,
  });
}

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
  bool _checkInRealizado = false;
  bool _cuestionarioCompletado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recibir los argumentos de la navegación
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ActivityModel) {
      actividad = args;
      print('📱 Recibida actividad: ${actividad!.title}');
      print('   └── Cliente ID: ${actividad!.cliente}');
      print('   └── Dirección: ${actividad!.direccion}');
    }
  }

  Future<void> _realizarCheckIn() async {
    setState(() {
      _checkInRealizado = true;
    });

    print('📍 Check-in realizado para cliente: ${actividad!.cliente}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Check-in realizado correctamente',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.dianaGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _llenarCuestionario() async {
    print('📋 Iniciando cuestionario para cliente: ${actividad!.cliente}');

    // Simulación de cuestionario completado
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _cuestionarioCompletado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.assignment_turned_in, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Cuestionario completado',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.dianaGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _finalizarVisita() async {
    if (!_checkInRealizado) {
      _mostrarError('Debe realizar el check-in antes de finalizar');
      return;
    }

    if (!_cuestionarioCompletado) {
      _mostrarError('Debe completar el cuestionario antes de finalizar');
      return;
    }

    print('✅ Finalizando visita para cliente: ${actividad!.cliente}');

    // Mostrar confirmación
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Finalizar Visita',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              '¿Está seguro de que desea finalizar la visita al cliente?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: AppColors.mediumGray),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dianaRed,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Finalizar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      print('✅ Visita finalizada correctamente');
      Navigator.pop(context, true); // Retorna true para indicar que se completó
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (actividad == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.mediumGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No se recibieron datos del cliente',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.mediumGray,
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
          'Visita a Cliente',
          style: GoogleFonts.poppins(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightGray, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.dianaRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: AppColors.dianaRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          actividad!.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (actividad!.direccion != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            actividad!.direccion!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (actividad!.cliente != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge,
                          size: 16,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${actividad!.cliente}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (actividad!.asesor != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 16,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ruta: ${actividad!.asesor}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Título de acciones
            Text(
              'Proceso de Visita',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Expanded(
              child: ListView(
                children: [
                  // Check-in
                  _buildActionButton(
                    icon: Icons.location_on,
                    title: 'Check-in en ubicación',
                    subtitle: 'Confirmar llegada al cliente',
                    isCompleted: _checkInRealizado,
                    onTap: _checkInRealizado ? null : _realizarCheckIn,
                  ),

                  const SizedBox(height: 12),

                  // Cuestionario
                  _buildActionButton(
                    icon: Icons.assignment,
                    title: 'Llenar cuestionario',
                    subtitle: 'Evaluación de gestión de cliente',
                    isCompleted: _cuestionarioCompletado,
                    onTap:
                        !_checkInRealizado
                            ? null
                            : (_cuestionarioCompletado
                                ? null
                                : _llenarCuestionario),
                  ),

                  const SizedBox(height: 12),

                  // Finalizar
                  _buildActionButton(
                    icon: Icons.check_circle,
                    title: 'Finalizar visita',
                    subtitle: 'Marcar visita como completada',
                    isCompleted: false,
                    isMainAction: true,
                    onTap:
                        (_checkInRealizado && _cuestionarioCompletado)
                            ? _finalizarVisita
                            : null,
                  ),
                ],
              ),
            ),

            // Botón de cancelar
            const SizedBox(height: 16),
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
                  'Cancelar Visita',
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

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isMainAction = false,
    required VoidCallback? onTap,
  }) {
    Color backgroundColor = Colors.white;
    Color iconColor = AppColors.dianaRed;
    Color textColor = AppColors.darkGray;

    if (isCompleted) {
      backgroundColor = AppColors.dianaGreen.withOpacity(0.1);
      iconColor = AppColors.dianaGreen;
    } else if (onTap == null) {
      backgroundColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade400;
      textColor = Colors.grey.shade600;
    } else if (isMainAction) {
      backgroundColor = AppColors.dianaRed.withOpacity(0.1);
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border:
            isCompleted
                ? Border.all(
                  color: AppColors.dianaGreen.withOpacity(0.3),
                  width: 2,
                )
                : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow:
            onTap != null
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted ? 'Completado' : subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color:
                              isCompleted
                                  ? AppColors.dianaGreen
                                  : AppColors.mediumGray,
                          fontWeight:
                              isCompleted ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null && !isCompleted)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.dianaGreen,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
