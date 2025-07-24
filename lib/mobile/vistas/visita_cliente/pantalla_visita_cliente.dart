// lib/mobile/vistas/visita_cliente/pantalla_visita_cliente.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:diana_lc_front/shared/modelos/activity_model.dart';
import 'package:diana_lc_front/servicios/geolocalizacion_servicio.dart';
import 'package:diana_lc_front/servicios/visita_cliente_offline_service.dart';
import 'package:diana_lc_front/servicios/visita_cliente_unificado_service.dart';
import 'package:diana_lc_front/shared/modelos/visita_cliente_modelo.dart';

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

  // Estados de geolocalización
  String _ubicacionActual = 'Obteniendo ubicación...';
  bool _cargandoUbicacion = true;
  bool _errorUbicacion = false;
  Position? _posicionActual;

  @override
  void initState() {
    super.initState();
    _inicializarGeolocalizacion();
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

  /// Inicializar proceso simplificado con servicio universal
  Future<void> _inicializarGeolocalizacion() async {
    print('📍 Iniciando geolocalización universal...');
    print('🌐 Plataforma: ${kIsWeb ? "WEB" : "MÓVIL"}');

    setState(() {
      _ubicacionActual =
          kIsWeb
              ? 'Solicitando permisos del navegador...'
              : 'Obteniendo ubicación GPS...';
      _cargandoUbicacion = true;
      _errorUbicacion = false;
    });

    try {
      final GeolocalizacionServicio geoServicio = GeolocalizacionServicio();
      final resultado = await geoServicio.obtenerUbicacion();

      if (resultado.exitoso) {
        // Éxito: guardar datos y actualizar UI
        _posicionActual = Position(
          longitude: resultado.longitud!,
          latitude: resultado.latitud!,
          timestamp: DateTime.now(),
          accuracy: resultado.precision!,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        setState(() {
          _ubicacionActual = resultado.direccion!;
          _cargandoUbicacion = false;
          _errorUbicacion = false;
        });

        print('✅ Geolocalización exitosa');
        print('   └── Ubicación: ${resultado.direccion}');
        print('   └── Precisión: ${resultado.precision} metros');
      } else {
        // Error: manejar según el tipo
        await _manejarErrorGeolocalizacion(resultado);
      }
    } catch (e) {
      print('❌ Error inesperado en geolocalización: $e');
      await _manejarErrorGeneral(e.toString());
    }
  }

  /// Manejar errores de geolocalización
  Future<void> _manejarErrorGeolocalizacion(
    GeolocalizacionResultado resultado,
  ) async {
    setState(() {
      _ubicacionActual = resultado.mensajeError ?? 'Error de ubicación';
      _cargandoUbicacion = false;
      _errorUbicacion = true;
    });

    // Mostrar diálogo según la acción requerida
    if (resultado.accionRequerida != null) {
      _mostrarDialogoErrorConAccion(resultado);
    } else {
      _mostrarError(resultado.mensajeError ?? 'Error de ubicación');
    }
  }

  /// Mostrar diálogo de error con acciones disponibles
  void _mostrarDialogoErrorConAccion(GeolocalizacionResultado resultado) {
    String titulo;
    String mensaje;
    List<Widget> acciones = [];

    switch (resultado.accionRequerida!) {
      case AccionRequerida.abrirConfiguracion:
        titulo = 'Ubicación Deshabilitada';
        mensaje =
            kIsWeb
                ? 'La geolocalización no está disponible en este navegador. Intente con otro navegador o dispositivo.'
                : 'El servicio de ubicación está deshabilitado. Habilítelo en la configuración del sistema.';

        acciones = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          if (!kIsWeb)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await GeolocalizacionServicio().abrirConfiguracion(
                  AccionRequerida.abrirConfiguracion,
                );
                await Future.delayed(const Duration(seconds: 2));
                _inicializarGeolocalizacion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
              ),
              child: const Text(
                'Abrir Configuración',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ];
        break;

      case AccionRequerida.abrirConfiguracionApp:
        titulo = 'Permisos Bloqueados';
        mensaje =
            kIsWeb
                ? 'Los permisos de ubicación están bloqueados en su navegador. Habilítelos en la configuración del sitio.'
                : 'Los permisos han sido denegados permanentemente. Habilítelos en la configuración de la aplicación.';

        acciones = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          if (!kIsWeb)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await GeolocalizacionServicio().abrirConfiguracion(
                  AccionRequerida.abrirConfiguracionApp,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
              ),
              child: const Text(
                'Abrir Configuración',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ];
        break;

      case AccionRequerida.solicitarPermisos:
        titulo = 'Permisos Requeridos';
        mensaje =
            kIsWeb
                ? 'El navegador necesita permisos para acceder a su ubicación. Por favor, conceda los permisos cuando se soliciten.'
                : 'La aplicación necesita permisos de ubicación. Por favor, concédalos cuando se soliciten.';

        acciones = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _inicializarGeolocalizacion(); // Reintentar
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dianaRed,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ];
        break;
    }

    _mostrarDialogoError(titulo, mensaje, acciones);
  }

  /// Manejar errores generales
  Future<void> _manejarErrorGeneral(String error) async {
    setState(() {
      _ubicacionActual = 'Error de ubicación';
      _cargandoUbicacion = false;
      _errorUbicacion = true;
    });

    _mostrarError('Error inesperado: $error');
  }

  /// Mostrar diálogo de error personalizado
  void _mostrarDialogoError(
    String titulo,
    String mensaje,
    List<Widget> acciones,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.location_off, color: Colors.orange),
                const SizedBox(width: 8),
                Text(titulo),
              ],
            ),
            content: Text(mensaje),
            actions: acciones,
          ),
    );
  }

  /// Reintentar obtener ubicación
  Future<void> _reintentarUbicacion() async {
    print('🔄 Reintentando obtención de ubicación...');
    await _inicializarGeolocalizacion();
  }

  /// Realizar check-in con validaciones completas y guardar en servidor
  Future<void> _realizarCheckIn() async {
    // No validar comentarios según requerimiento
    // if (_comentariosController.text.trim().isEmpty) {
    //   _mostrarError('Por favor, agregue un comentario antes del check-in');
    //   return;
    // }

    // Validar que se tenga ubicación
    if (_errorUbicacion || _posicionActual == null) {
      _mostrarError(
        'No se puede realizar check-in sin ubicación válida. '
        'Por favor, habilite la ubicación e intente nuevamente.',
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.dianaRed),
                const SizedBox(height: 16),
                Text(
                  'Realizando check-in...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
    );

    try {
      // Crear CheckIn usando el builder
      // Comentarios automáticos según requerimiento
      final checkIn =
          CheckInBuilder()
              .comentarios('Check-in realizado')
              .ubicacion(
                latitud: _posicionActual!.latitude,
                longitud: _posicionActual!.longitude,
                precision: _posicionActual!.accuracy,
                direccion: _ubicacionActual,
              )
              .build();

      print('🏁 Realizando check-in:');
      print('   └── Cliente: ${actividad!.title}');
      print('   └── ID Cliente: ${actividad!.cliente}');
      print('   └── Comentarios: ${_comentariosController.text}');
      print('   └── Ubicación: $_ubicacionActual');
      print('   └── Precisión: ${_posicionActual!.accuracy} metros');

      // Verificar si tenemos metadata del plan unificado
      final metadata = actividad!.metadata;
      if (metadata != null && metadata['planId'] != null) {
        // Usar el servicio unificado
        print('📊 Usando plan unificado:');
        print('   └── Plan ID: ${metadata['planId']}');
        print('   └── Día: ${metadata['dia']}');
        print('   └── Es FOCO: ${metadata['esFoco']}');

        final visitaUnificadaService = VisitaClienteUnificadoService();
        final resultadoCheckIn = await visitaUnificadaService.iniciarVisitaEnPlanUnificado(
          planId: metadata['planId'],
          dia: metadata['dia'],
          clienteId: actividad!.cliente ?? 'UNKNOWN',
          checkIn: checkIn,
        );

        if (resultadoCheckIn['exitoso'] == true) {
          print('✅ Check-in realizado exitosamente en plan unificado');
          if (resultadoCheckIn['esNuevoClienteFoco'] == true) {
            print('   └── Cliente agregado a lista FOCO');
          }

          // Cerrar loading
          if (mounted) Navigator.of(context).pop();

          // Navegar al formulario dinámico con información del plan unificado
          if (mounted) {
            final resultado = await Navigator.pushNamed(
              context,
              '/formulario_dinamico',
              arguments: {
                'actividad': actividad,
                'checkIn': checkIn,
                'tipoCliente': metadata['canal'] ?? 'DETALLE', // Usar canal o default DETALLE
                'planUnificado': {
                  'planId': metadata['planId'],
                  'dia': metadata['dia'],
                  'clienteId': actividad!.cliente,
                  'visitaId': resultadoCheckIn['visitaId'],
                },
              },
            );

            // Si el formulario se completó exitosamente, regresar con resultado positivo
            if (resultado == true && mounted) {
              Navigator.pop(context, true);
            }
          }
        } else {
          throw Exception(resultadoCheckIn['error'] ?? 'Error desconocido');
        }
      } else {
        // Fallback al servicio tradicional si no hay metadata
        print('⚠️ Sin metadata del plan, usando servicio tradicional');
        
        final VisitaClienteOfflineService visitaServicio = VisitaClienteOfflineService();
        String diaActual = _obtenerDiaActual();
        
        final visita = await visitaServicio.crearVisitaDesdeActividad(
          clienteId: actividad!.cliente ?? 'UNKNOWN',
          clienteNombre: actividad!.title,
          dia: diaActual,
          checkIn: checkIn,
          planId: null,
        );

        print('✅ Check-in realizado exitosamente (modo tradicional)');
        print('   └── Visita ID: ${visita.visitaId}');
        print('   └── Estatus: ${visita.estatus}');

        // Cerrar loading
        if (mounted) Navigator.of(context).pop();

        // Navegar al formulario dinámico con toda la información
        if (mounted) {
          final resultado = await Navigator.pushNamed(
            context,
            '/formulario_dinamico',
            arguments: {
              'actividad': actividad,
              'visita': visita,
              'checkIn': checkIn,
              'tipoCliente': actividad!.metadata?['canal'] ?? 'DETALLE', // Usar canal desde metadata
              'visitaServicio': visitaServicio,
            },
          );

          // Si el formulario se completó exitosamente, regresar con resultado positivo
          if (resultado == true && mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      print('❌ Error al realizar check-in: $e');

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Error al realizar Check-in'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No se pudo realizar el check-in en el servidor.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('¿Qué puedes hacer?'),
                    const Text('• Verifica tu conexión a internet'),
                    const Text('• Intenta nuevamente en unos momentos'),
                    const Text('• El servidor debe estar funcionando'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _realizarCheckIn(); // Reintentar
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dianaRed,
                    ),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        );
      }
    }
  }

  /// Obtener el día actual en español
  String _obtenerDiaActual() {
    final diasSemana = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return diasSemana[DateTime.now().weekday - 1];
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
        duration: const Duration(seconds: 4),
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
            // Información del cliente
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

            // Ubicación y comentarios ocultos según requerimiento
            // Solo mantener funcionalidad interna sin mostrar UI

            const SizedBox(height: 24),

            // Botón CHECK-IN mejorado
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_cargandoUbicacion || _errorUbicacion)
                        ? null
                        : _realizarCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dianaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                child:
                    _cargandoUbicacion
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Obteniendo ubicación...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                        : Text(
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
