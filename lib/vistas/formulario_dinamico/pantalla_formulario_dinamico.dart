// lib/vistas/formulario_dinamico/pantalla_formulario_dinamico.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../modelos/activity_model.dart';

class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

class PantallaFormularioDinamico extends StatefulWidget {
  const PantallaFormularioDinamico({super.key});

  @override
  State<PantallaFormularioDinamico> createState() =>
      _PantallaFormularioDinamicoState();
}

class _PantallaFormularioDinamicoState
    extends State<PantallaFormularioDinamico> {
  // Datos recibidos de la navegación
  ActivityModel? actividad;
  String? comentarios;
  String? ubicacion;

  // Control del timeline/secciones
  int seccionActual = 0;
  final List<String> nombresSecciones = [
    'Tipo de Exhibidor',
    'Estándares de Ejecución',
    'Disponibilidad',
    'Compromisos',
    'Comentarios',
  ];

  // Estados de completitud por sección
  List<bool> seccionesCompletadas = [false, false, false, false, false];

  // Datos del formulario por sección
  Map<String, dynamic> datosFormulario = {
    'seccion1': {}, // Tipo de Exhibidor
    'seccion2': {}, // Estándares de Ejecución
    'seccion3': {}, // Disponibilidad
    'seccion4': {}, // Compromisos
    'seccion5': {}, // Comentarios
  };

  // Sección 1: Tipo de Exhibidor
  bool? poseeExhibidorAdecuado;
  String? tipoExhibidorSeleccionado;
  String? modeloExhibidorSeleccionado;
  int cantidadExhibidores = 1;
  List<Map<String, dynamic>> exhibidoresAsignados = [];

  // Sección 2: Estándares de Ejecución
  bool? primeraPosition;
  bool? planograma;
  bool? portafolioFoco;
  bool? anclaje;

  // Sección 3: Disponibilidad
  bool? ristras;
  bool? max;
  bool? familiar;
  bool? dulce;
  bool? galleta;

  // Sección 4: Compromisos - Implementación completa
  List<Map<String, dynamic>> compromisos = [];

  // Formulario de compromiso actual
  String? tipoCompromisoSeleccionado;
  String? detalleCompromisoSeleccionado;
  int cantidadCompromiso = 1;
  DateTime? fechaCompromiso;

  // Catálogos de compromisos (simulados - en producción vendrían del backend)
  final Map<String, List<String>> catalogoCompromisos = {
    'Colocación de exhibidor': [
      'Código: 10134 - Bandeja 60cm',
      'Código: 10135 - Cascada 4',
      'Código: 10136 - Multi 6',
    ],
    'Aumento de SKU': [
      'Código: 34567 - Mix de Semillar',
      'Código: 45677 - Pachanga',
      'Código: 56789 - Galletas Premium',
    ],
    'Venta de Innovación': [
      'Código: Picnic MAX',
      'Código: Diana Sport',
      'Código: Familiar Plus',
    ],
    'Refuerzo de categoría': ['Galletas', 'Dulces', 'Familiar', 'Innovación'],
  };

  // Sección 5: Comentarios
  final TextEditingController retroalimentacionController =
      TextEditingController();
  final TextEditingController reconocimientoController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosGuardados();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      actividad = args['actividad'] as ActivityModel?;
      comentarios = args['comentarios'] as String?;
      ubicacion = args['ubicacion'] as String?;

      print('📋 Formulario dinámico iniciado:');
      print('   └── Cliente: ${actividad?.title}');
      print('   └── Comentarios: $comentarios');
      print('   └── Ubicación: $ubicacion');
    }
  }

  Future<void> _cargarDatosGuardados() async {
    if (actividad?.cliente == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          'formulario_${actividad!.cliente}_${DateTime.now().toIso8601String().substring(0, 10)}';
      final datosGuardados = prefs.getString(key);

      if (datosGuardados != null) {
        final datos = jsonDecode(datosGuardados);
        setState(() {
          datosFormulario = Map<String, dynamic>.from(
            datos['formulario'] ?? {},
          );
          seccionesCompletadas = List<bool>.from(
            datos['completadas'] ?? [false, false, false, false, false],
          );
        });
        print('📁 Datos del formulario recuperados');
      }
    } catch (e) {
      print('❌ Error al cargar datos del formulario: $e');
    }
  }

  Future<void> _guardarDatosSeccion() async {
    if (actividad?.cliente == null) return;

    try {
      // Guardar datos de la sección actual
      switch (seccionActual) {
        case 0:
          datosFormulario['seccion1'] = {
            'poseeExhibidorAdecuado': poseeExhibidorAdecuado,
            'tipoExhibidorSeleccionado': tipoExhibidorSeleccionado,
            'modeloExhibidorSeleccionado': modeloExhibidorSeleccionado,
            'cantidadExhibidores': cantidadExhibidores,
            'exhibidoresAsignados': exhibidoresAsignados,
          };
          break;
        case 1:
          datosFormulario['seccion2'] = {
            'primeraPosition': primeraPosition,
            'planograma': planograma,
            'portafolioFoco': portafolioFoco,
            'anclaje': anclaje,
          };
          break;
        case 2:
          datosFormulario['seccion3'] = {
            'ristras': ristras,
            'max': max,
            'familiar': familiar,
            'dulce': dulce,
            'galleta': galleta,
          };
          break;
        case 3:
          datosFormulario['seccion4'] = {
            'compromisos': compromisos,
            'tipoCompromisoSeleccionado': tipoCompromisoSeleccionado,
            'detalleCompromisoSeleccionado': detalleCompromisoSeleccionado,
            'cantidadCompromiso': cantidadCompromiso,
            'fechaCompromiso': fechaCompromiso?.toIso8601String(),
          };
          break;
        case 4:
          datosFormulario['seccion5'] = {
            'retroalimentacion': retroalimentacionController.text,
            'reconocimiento': reconocimientoController.text,
          };
          break;
      }

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key =
          'formulario_${actividad!.cliente}_${DateTime.now().toIso8601String().substring(0, 10)}';
      final datosCompletos = {
        'actividad': actividad!.toJson(),
        'comentarios': comentarios,
        'ubicacion': ubicacion,
        'formulario': datosFormulario,
        'completadas': seccionesCompletadas,
        'fechaGuardado': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(datosCompletos));
      print('💾 Sección $seccionActual guardada correctamente');
    } catch (e) {
      print('❌ Error al guardar sección: $e');
    }
  }

  bool _validarSeccionActual() {
    switch (seccionActual) {
      case 0: // Tipo de Exhibidor
        return poseeExhibidorAdecuado != null;
      case 1: // Estándares de Ejecución
        return primeraPosition != null &&
            planograma != null &&
            portafolioFoco != null &&
            anclaje != null;
      case 2: // Disponibilidad
        return ristras != null &&
            max != null &&
            familiar != null &&
            dulce != null &&
            galleta != null;
      case 3: // Compromisos
        return true; // Los compromisos son opcionales, pero si hay formulario abierto debe completarse
      // TODO: Agregar validación si hay un compromiso en progreso sin guardar
      case 4: // Comentarios
        return retroalimentacionController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _avanzarSeccion() async {
    if (!_validarSeccionActual()) {
      _mostrarError('Por favor complete todos los campos obligatorios');
      return;
    }

    // Marcar sección como completada y guardar
    setState(() {
      seccionesCompletadas[seccionActual] = true;
    });

    await _guardarDatosSeccion();

    if (seccionActual < nombresSecciones.length - 1) {
      setState(() {
        seccionActual++;
      });
    } else {
      // Formulario completado
      await _finalizarFormulario();
    }
  }

  Future<void> _finalizarFormulario() async {
    print('✅ Formulario completado para cliente: ${actividad?.cliente}');

    // Mostrar confirmación
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Formulario Completado',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'La evaluación ha sido completada exitosamente.\n¿Desea finalizar la visita?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Revisar',
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
      Navigator.pop(context, true); // Regresar a rutinas con visita completada
    }
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
      ),
    );
  }

  @override
  void dispose() {
    retroalimentacionController.dispose();
    reconocimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.dianaRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Evaluación del desarrollo en campo',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              actividad?.title ?? 'Cliente',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Timeline de secciones
          _buildTimeline(),

          // Contenido de la sección actual
          Expanded(child: _buildContenidoSeccion()),

          // Botones de navegación
          _buildBotonesNavegacion(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Indicadores de secciones
          Row(
            children: List.generate(nombresSecciones.length, (index) {
              bool isCompleted = seccionesCompletadas[index];
              bool isCurrent = index == seccionActual;
              bool isAccessible = index <= seccionActual;

              return Expanded(
                child: GestureDetector(
                  onTap:
                      isAccessible
                          ? () {
                            setState(() {
                              seccionActual = index;
                            });
                          }
                          : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? AppColors.dianaGreen
                                    : isCurrent
                                    ? AppColors.dianaRed
                                    : AppColors.mediumGray.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border:
                                isCurrent
                                    ? Border.all(
                                      color: AppColors.dianaRed,
                                      width: 3,
                                    )
                                    : null,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check
                                : Icons.radio_button_unchecked,
                            color:
                                isCompleted || isCurrent
                                    ? Colors.white
                                    : AppColors.mediumGray,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Secc ${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color:
                                isCurrent
                                    ? AppColors.dianaRed
                                    : AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Nombre de la sección actual
          Text(
            nombresSecciones[seccionActual],
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoSeccion() {
    switch (seccionActual) {
      case 0:
        return _buildSeccionTipoExhibidor();
      case 1:
        return _buildSeccionEstandares();
      case 2:
        return _buildSeccionDisponibilidad();
      case 3:
        return _buildSeccionCompromisos();
      case 4:
        return _buildSeccionComentarios();
      default:
        return const Center(child: Text('Sección no encontrada'));
    }
  }

  Widget _buildSeccionTipoExhibidor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreguntaSiNo(
            'Posee Exhibidor adecuado:',
            poseeExhibidorAdecuado,
            (valor) => setState(() => poseeExhibidorAdecuado = valor),
          ),

          if (poseeExhibidorAdecuado == false) ...[
            const SizedBox(height: 24),
            _buildTarjetaFormulario([
              _buildDropdown(
                'Tipo de Exhibidor',
                tipoExhibidorSeleccionado,
                ['Por Bandeja', 'Cascada', 'Multicategoría'],
                (valor) => setState(() {
                  tipoExhibidorSeleccionado = valor;
                  modeloExhibidorSeleccionado = null; // Reset modelo
                }),
              ),

              if (tipoExhibidorSeleccionado != null) ...[
                const SizedBox(height: 16),
                _buildDropdown(
                  'Modelo de Exhibidor',
                  modeloExhibidorSeleccionado,
                  _getModelosPorTipo(tipoExhibidorSeleccionado!),
                  (valor) =>
                      setState(() => modeloExhibidorSeleccionado = valor),
                ),
              ],

              if (modeloExhibidorSeleccionado != null) ...[
                const SizedBox(height: 16),
                _buildCantidadSelector(),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionEstandares() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildTarjetaFormulario([
        _buildPreguntaSiNo(
          'Primera posición:',
          primeraPosition,
          (valor) => setState(() => primeraPosition = valor),
        ),

        const SizedBox(height: 16),
        _buildPreguntaSiNo(
          'Planograma:',
          planograma,
          (valor) => setState(() => planograma = valor),
        ),

        const SizedBox(height: 16),
        _buildPreguntaSiNo(
          'Portafolio Foco:',
          portafolioFoco,
          (valor) => setState(() => portafolioFoco = valor),
        ),

        const SizedBox(height: 16),
        _buildPreguntaSiNo(
          'Anclaje:',
          anclaje,
          (valor) => setState(() => anclaje = valor),
        ),
      ]),
    );
  }

  Widget _buildSeccionDisponibilidad() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildTarjetaFormulario([
        _buildPreguntaSiNo(
          'Ristras:',
          ristras,
          (valor) => setState(() => ristras = valor),
        ),

        const SizedBox(height: 16),
        _buildPreguntaSiNo('Max:', max, (valor) => setState(() => max = valor)),

        const SizedBox(height: 16),
        _buildPreguntaSiNo(
          'Familiar:',
          familiar,
          (valor) => setState(() => familiar = valor),
        ),

        const SizedBox(height: 16),
        _buildPreguntaSiNo(
          'Dulce:',
          dulce,
          (valor) => setState(() => dulce = valor),
        ),

        const SizedBox(height: 16),
        _buildPreguntaSiNo(
          'Galleta:',
          galleta,
          (valor) => setState(() => galleta = valor),
        ),
      ]),
    );
  }

  Widget _buildSeccionCompromisos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado contextual mejorado (ficha del cliente)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.dianaRed.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.dianaRed.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dianaRed.withOpacity(0.1),
                  blurRadius: 12,
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dianaRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actividad?.title ?? 'Cliente',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${actividad?.cliente ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.mediumGray.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route, size: 16, color: AppColors.mediumGray),
                      const SizedBox(width: 8),
                      Text(
                        '${actividad?.asesor ?? 'Ruta'} - ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Título de la sección en español
          Text(
            'Compromisos',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),

          const SizedBox(height: 16),

          // Formulario de compromiso
          _buildTarjetaFormulario([
            // Tipo de compromiso
            _buildDropdownCompromisos(
              'Tipo de compromiso',
              tipoCompromisoSeleccionado,
              catalogoCompromisos.keys.toList(),
              (valor) {
                setState(() {
                  tipoCompromisoSeleccionado = valor;
                  detalleCompromisoSeleccionado = null; // Reset detalle
                });
              },
            ),

            const SizedBox(height: 16),

            // Detalle (dependiente del tipo)
            if (tipoCompromisoSeleccionado != null) ...[
              _buildDropdownCompromisos(
                'Detalle',
                detalleCompromisoSeleccionado,
                catalogoCompromisos[tipoCompromisoSeleccionado!] ?? [],
                (valor) {
                  setState(() {
                    detalleCompromisoSeleccionado = valor;
                  });
                },
              ),

              const SizedBox(height: 16),
            ],

            // Cantidad y Fecha en fila
            Row(
              children: [
                // Cantidad
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cantidad',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.mediumGray.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed:
                                  cantidadCompromiso > 1
                                      ? () {
                                        setState(() {
                                          cantidadCompromiso--;
                                        });
                                      }
                                      : null,
                              icon: const Icon(Icons.remove, size: 20),
                              padding: const EdgeInsets.all(8),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                cantidadCompromiso.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  cantidadCompromiso++;
                                });
                              },
                              icon: const Icon(Icons.add, size: 20),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Fecha
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha compromiso',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _seleccionarFechaCompromiso,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.mediumGray.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.mediumGray,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fechaCompromiso != null
                                      ? '${fechaCompromiso!.day.toString().padLeft(2, '0')}/${fechaCompromiso!.month.toString().padLeft(2, '0')}/${fechaCompromiso!.year}'
                                      : 'DD/MM/AAAA',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color:
                                        fechaCompromiso != null
                                            ? AppColors.darkGray
                                            : AppColors.mediumGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Botón Agregar Compromiso
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _agregarCompromisoCompleto,
                icon: const Icon(Icons.add, color: AppColors.darkGray),
                label: Text(
                  '+ Agregar Compromiso',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.mediumGray.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Lista de compromisos agregados
          if (compromisos.isNotEmpty) ...[
            Text(
              'Compromisos Asignados',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),

            const SizedBox(height: 12),

            ...compromisos.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> compromiso = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.dianaGreen.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.dianaGreen.withOpacity(0.05),
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.dianaGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${compromiso['tipo']} · ${compromiso['detalle']} · CANT: ${compromiso['cantidad']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: AppColors.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Fecha: ${compromiso['fechaFormateada']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.mediumGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          compromisos.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Compromiso eliminado',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: AppColors.dianaRed,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.mediumGray,
                        size: 20,
                      ),
                      tooltip: 'Eliminar compromiso',
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionComentarios() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildTarjetaFormulario([
        Text(
          'Retroalimentación',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: retroalimentacionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escriba su retroalimentación...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Reconocimiento',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reconocimientoController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escriba el reconocimiento...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    );
  }

  // Widgets auxiliares
  Widget _buildTarjetaFormulario(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPreguntaSiNo(
    String pregunta,
    bool? valor,
    Function(bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pregunta,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        valor == true
                            ? AppColors.dianaGreen
                            : AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          valor == true
                              ? AppColors.dianaGreen
                              : AppColors.mediumGray.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'SÍ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color:
                            valor == true ? Colors.white : AppColors.darkGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        valor == false
                            ? AppColors.dianaRed
                            : AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          valor == false
                              ? AppColors.dianaRed
                              : AppColors.mediumGray.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'NO',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color:
                            valor == false ? Colors.white : AppColors.darkGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? valor,
    List<String> opciones,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: valor,
          items:
              opciones.map((opcion) {
                return DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion, style: GoogleFonts.poppins()),
                );
              }).toList(),
          onChanged: (nuevoValor) {
            if (nuevoValor != null) {
              onChanged(nuevoValor);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCantidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad de exhibidores',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed:
                  cantidadExhibidores > 1
                      ? () {
                        setState(() {
                          cantidadExhibidores--;
                        });
                      }
                      : null,
              icon: const Icon(Icons.remove),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.mediumGray.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cantidadExhibidores.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  cantidadExhibidores++;
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotonesNavegacion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (seccionActual > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    seccionActual--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.mediumGray),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Anterior',
                  style: GoogleFonts.poppins(
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            flex: seccionActual == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _avanzarSeccion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                seccionActual == nombresSecciones.length - 1
                    ? 'FINALIZAR'
                    : 'SIGUIENTE',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getModelosPorTipo(String tipo) {
    switch (tipo) {
      case 'Por Bandeja':
        return ['Bandeja 4', 'Bandeja 5', 'Bandeja 6'];
      case 'Cascada':
        return ['Cascada 4', 'Cascada 5', 'Cascada 6'];
      case 'Multicategoría':
        return ['Multi 4', 'Multi 5', 'Multi 6'];
      default:
        return [];
    }
  }

  Widget _buildDropdownCompromisos(
    String label,
    String? valor,
    List<String> opciones,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.mediumGray.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valor,
              hint: Text(
                'Seleccionar...',
                style: GoogleFonts.poppins(
                  color: AppColors.mediumGray,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.mediumGray,
              ),
              items:
                  opciones.map((opcion) {
                    return DropdownMenuItem(
                      value: opcion,
                      child: Text(
                        opcion,
                        style: GoogleFonts.poppins(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (nuevoValor) {
                if (nuevoValor != null) {
                  onChanged(nuevoValor);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFechaCompromiso() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate:
          fechaCompromiso ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(), // No permite fechas pasadas
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Seleccionar fecha del compromiso',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldLabelText: 'Fecha',
      fieldHintText: 'dd/mm/aaaa',
      errorFormatText: 'Formato de fecha inválido',
      errorInvalidText: 'Fecha fuera de rango',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.dianaRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGray,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.dianaRed),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        fechaCompromiso = fechaSeleccionada;
      });
    }
  }

  void _agregarCompromisoCompleto() {
    // Validaciones en español
    if (tipoCompromisoSeleccionado == null) {
      _mostrarError('Seleccione el tipo de compromiso');
      return;
    }

    if (detalleCompromisoSeleccionado == null) {
      _mostrarError('Seleccione el detalle del compromiso');
      return;
    }

    if (fechaCompromiso == null) {
      _mostrarError('Seleccione la fecha del compromiso');
      return;
    }

    if (cantidadCompromiso < 1) {
      _mostrarError('La cantidad debe ser mayor a 0');
      return;
    }

    // Crear el compromiso
    final nuevoCompromiso = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tipo': tipoCompromisoSeleccionado!,
      'detalle': detalleCompromisoSeleccionado!,
      'cantidad': cantidadCompromiso,
      'fecha': fechaCompromiso!.toIso8601String(),
      'fechaFormateada':
          '${fechaCompromiso!.day.toString().padLeft(2, '0')}/${fechaCompromiso!.month.toString().padLeft(2, '0')}/${fechaCompromiso!.year}',
      'clienteId': actividad?.cliente,
      'rutaId': actividad?.asesor,
      'status': 'PENDIENTE',
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      compromisos.add(nuevoCompromiso);

      // Limpiar formulario
      tipoCompromisoSeleccionado = null;
      detalleCompromisoSeleccionado = null;
      cantidadCompromiso = 1;
      fechaCompromiso = null;
    });

    // Feedback al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Compromiso agregado correctamente',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.dianaGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    print('✅ Compromiso agregado:');
    print('   └── Tipo: $tipoCompromisoSeleccionado');
    print('   └── Detalle: $detalleCompromisoSeleccionado');
    print('   └── Cantidad: $cantidadCompromiso');
    print('   └── Fecha: ${fechaCompromiso!.toIso8601String()}');
    print('   └── Cliente: ${actividad?.cliente}');
    print('   └── Ruta: ${actividad?.asesor}');
  }
}
