import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/servicios/resultados_dia_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'widgets/kpi_cards.dart';
import 'widgets/cliente_resultado_tile.dart';

/// Colores corporativos
class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

/// Pantalla principal de resultados del día
class PantallaResultadosDia extends StatefulWidget {
  const PantallaResultadosDia({Key? key}) : super(key: key);

  @override
  State<PantallaResultadosDia> createState() => _PantallaResultadosDiaState();
}

class _PantallaResultadosDiaState extends State<PantallaResultadosDia> {
  final ResultadosDiaService _service = ResultadosDiaService();
  
  String? _liderClave;
  String _diaSeleccionado = '';
  DiaPlanHive? _diaPlan;
  Map<String, dynamic> _kpis = {};
  bool _cargando = true;
  String? _error;
  
  final List<String> _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
  ];

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      // Obtener líder actual
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider == null) {
        setState(() {
          _error = 'No hay sesión activa';
          _cargando = false;
        });
        return;
      }
      
      _liderClave = lider.clave;
      
      // Seleccionar día actual por defecto
      _diaSeleccionado = _service.obtenerNombreDia(DateTime.now());
      
      // Cargar datos
      await _cargarDatos();
    } catch (e) {
      setState(() {
        _error = 'Error al inicializar: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarDatos() async {
    if (_liderClave == null) return;
    
    setState(() => _cargando = true);
    
    try {
      _diaPlan = _service.obtenerDia(_liderClave!, _diaSeleccionado);
      
      // Si no hay plan o no hay datos para el día
      if (_diaPlan == null) {
        setState(() {
          _error = 'No Existen Datos Disponibles';
          _cargando = false;
        });
        return;
      }
      
      _kpis = _service.calcularKPIs(_diaPlan);
      
      setState(() {
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _cargando = false;
      });
    }
  }

  void _cambiarDia(String nuevoDia) {
    setState(() {
      _diaSeleccionado = nuevoDia;
    });
    _cargarDatos();
  }

  void _mostrarDetalleVisita(VisitaClienteUnificadaHive visita) {
    // Obtener información del cliente
    final infoCliente = _service.obtenerInfoCliente(visita.clienteId);
    
    // Generar el ID del plan con el formato correcto
    final hoy = DateTime.now();
    final numeroSemana = _obtenerNumeroSemana(hoy);
    final planId = '${_liderClave}_SEM${numeroSemana.toString().padLeft(2, '0')}_${hoy.year}';
    
    // Navegar a la pantalla de resumen con los datos necesarios
    Navigator.pushNamed(
      context,
      '/resumen_visita',
      arguments: {
        'modoConsulta': true,
        'planId': planId,
        'dia': _diaSeleccionado,
        'clienteId': visita.clienteId,
        'clienteNombre': infoCliente['nombre'] ?? 'Cliente ${visita.clienteId}',
      },
    );
  }
  
  /// Calcula el número de semana del año
  int _obtenerNumeroSemana(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    final weekNumber = ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
    return weekNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.dianaRed,
        elevation: 0,
        title: Text(
          'Resultados del Día',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.dianaRed,
        ),
      );
    }

    if (_error != null) {
      final bool noHayDatos = _error == 'No Existen Datos Disponibles';
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                noHayDatos ? Icons.inbox : Icons.error_outline,
                size: 64,
                color: noHayDatos ? Colors.grey[300] : Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                noHayDatos ? 'Sin Datos' : 'Error al cargar datos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (noHayDatos) ...[  
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/plan_configuracion');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Plan de Trabajo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dianaRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dianaRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // ValueListenableBuilder para reactividad
    return ValueListenableBuilder(
      valueListenable: HiveService().planesTrabajoUnificadosBox.listenable(),
      builder: (context, Box<PlanTrabajoUnificadoHive> box, _) {
        // Recargar datos si la caja cambió
        if (_liderClave != null) {
          _diaPlan = _service.obtenerDia(_liderClave!, _diaSeleccionado);
          _kpis = _service.calcularKPIs(_diaPlan);
        }

        return Column(
          children: [
            // Selector de día
            _buildDiaSelector(),
            
            // KPIs
            KPICards(kpis: _kpis),
            
            // Lista de visitas
            Expanded(
              child: _buildListaVisitas(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiaSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar día',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _diasSemana.map((dia) {
                final seleccionado = dia == _diaSeleccionado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dia),
                    selected: seleccionado,
                    onSelected: (_) => _cambiarDia(dia),
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.dianaRed,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
                      color: seleccionado ? Colors.white : AppColors.darkGray,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaVisitas() {
    if (_diaPlan == null || _diaPlan!.clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay visitas registradas',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las visitas aparecerán aquí cuando se realicen',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar visitas: terminadas primero, luego en proceso, luego pendientes
    final visitasOrdenadas = List<VisitaClienteUnificadaHive>.from(_diaPlan!.clientes)
      ..sort((a, b) {
        final ordenEstatus = {'terminado': 0, 'en_proceso': 1, 'pendiente': 2};
        final ordenA = ordenEstatus[a.estatus] ?? 3;
        final ordenB = ordenEstatus[b.estatus] ?? 3;
        return ordenA.compareTo(ordenB);
      });

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.dianaRed,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: visitasOrdenadas.length,
        itemBuilder: (context, index) {
          final visita = visitasOrdenadas[index];
          return ClienteResultadoTile(
            visita: visita,
            service: _service,
            onTap: () => _mostrarDetalleVisita(visita),
          );
        },
      ),
    );
  }
}