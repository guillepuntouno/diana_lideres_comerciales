import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/visita_cliente_hive.dart';
import 'package:diana_lc_front/shared/servicios/resultados_dia_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/servicios/offline_sync_manager.dart';
import 'widgets/kpi_semaforo_card.dart';
import 'widgets/cliente_rutina_tile.dart';
import 'widgets/offline_banner.dart';
import 'widgets/tab_rutinas.dart';
import 'widgets/filtros_rutina.dart';
import 'widgets/selector_plan_semanal.dart';

/// Colores corporativos
class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

/// Enum para las plantillas/rutinas disponibles
enum TipoRutina {
  todas('Todas las actividades', 'todas'),
  visitasClientes('Visitas a Clientes', 'visitas'),
  administrativas('Actividades Administrativas', 'administrativas'),
  formularios('Formularios Capturados', 'formularios');

  final String titulo;
  final String plantillaId;
  
  const TipoRutina(this.titulo, this.plantillaId);
}

/// Pantalla principal de Rutinas/Resultados
class PantallaRutinasResultados extends StatefulWidget {
  const PantallaRutinasResultados({Key? key}) : super(key: key);

  @override
  State<PantallaRutinasResultados> createState() => _PantallaRutinasResultadosState();
}

class _PantallaRutinasResultadosState extends State<PantallaRutinasResultados> {
  final ResultadosDiaService _service = ResultadosDiaService();
  
  String? _liderClave;
  String _diaSeleccionado = '';
  TipoRutina _rutinaSeleccionada = TipoRutina.todas;
  String? _rutaFiltro;
  String? _clienteFiltro;
  
  List<PlanTrabajoUnificadoHive> _planesDisponibles = [];
  PlanTrabajoUnificadoHive? _planSeleccionado;
  DiaPlanHive? _diaPlan;
  Map<String, dynamic> _kpis = {};
  
  bool _cargando = true;
  bool _isOffline = false;
  String? _error;
  
  final List<String> _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
  ];

  @override
  void initState() {
    super.initState();
    _inicializar();
    _checkConnectivity();
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

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
    
    // Listener para cambios de conectividad
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
      });
    });
  }

  Future<void> _cargarDatos() async {
    if (_liderClave == null) return;
    
    setState(() => _cargando = true);
    
    try {
      // Si hay conexión, sincronizar primero
      if (!_isOffline) {
        final syncManager = OfflineSyncManager();
        await syncManager.performFullSync();
      }
      
      // Cargar todos los planes del líder
      final box = Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado');
      _planesDisponibles = box.values
          .where((plan) => plan.liderClave == _liderClave)
          .toList()
          ..sort((a, b) => b.numeroSemana.compareTo(a.numeroSemana));
      
      if (_planesDisponibles.isEmpty) {
        setState(() {
          _error = 'No Existen Datos Disponibles';
          _cargando = false;
        });
        return;
      }
      
      // Si no hay plan seleccionado, usar el más reciente
      if (_planSeleccionado == null) {
        _planSeleccionado = _planesDisponibles.first;
      }
      
      // Si hay un día seleccionado, cargar su información
      if (_diaSeleccionado.isNotEmpty && _planSeleccionado!.dias.containsKey(_diaSeleccionado)) {
        _diaPlan = _planSeleccionado!.dias[_diaSeleccionado];
        print('📊 Día seleccionado: $_diaSeleccionado');
        print('   └── Tipo: ${_diaPlan!.tipo}');
        print('   └── Total clientes: ${_diaPlan!.clientes.length}');
        print('   └── Clientes con estado:');
        for (var cliente in _diaPlan!.clientes) {
          print('      - ${cliente.clienteId}: ${cliente.estatus}');
        }
      } else {
        // Seleccionar el primer día con actividades
        final diasConActividades = _planSeleccionado!.dias.entries
            .where((entry) => entry.value.configurado)
            .toList();
        if (diasConActividades.isNotEmpty) {
          _diaSeleccionado = diasConActividades.first.key;
          _diaPlan = diasConActividades.first.value;
          print('📊 Día auto-seleccionado: $_diaSeleccionado');
          print('   └── Total clientes: ${_diaPlan!.clientes.length}');
        }
      }
      
      // Sincronizar estados de visitas reales con el plan
      await _sincronizarEstadosVisitas();
      
      _kpis = _calcularKPIsRutina();
      
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

  Future<void> _sincronizarEstadosVisitas() async {
    if (_diaPlan == null || _diaPlan!.tipo != 'gestion_cliente' || _liderClave == null) return;
    
    try {
      print('🔄 Sincronizando estados de visitas con Hive...');
      
      // Abrir el box de visitas
      final visitasBox = await Hive.openBox<VisitaClienteHive>('visitas_clientes');
      
      // Obtener la fecha del día seleccionado
      final fechaDia = _obtenerFechaDelDia(_diaSeleccionado);
      
      // Iterar sobre cada cliente del día
      for (var cliente in _diaPlan!.clientes) {
        print('🔍 Buscando visita para cliente: ${cliente.clienteId}');
        
        // Buscar visitas de este cliente en la fecha específica
        bool visitaEncontrada = false;
        for (var visita in visitasBox.values) {
          if (visita.clienteId == cliente.clienteId && 
              visita.liderClave == _liderClave &&
              visita.fechaCreacion.year == fechaDia.year &&
              visita.fechaCreacion.month == fechaDia.month &&
              visita.fechaCreacion.day == fechaDia.day) {
            
            print('✅ Visita encontrada en Hive:');
            print('   └── Estado Hive: ${visita.estatus}');
            print('   └── CheckOut: ${visita.checkOut != null}');
            print('   └── Estado actual en plan: ${cliente.estatus}');
            
            // Actualizar el estado del cliente en el plan
            if (visita.estatus == 'completada' || visita.checkOut != null) {
              cliente.estatus = 'completada';
              cliente.horaInicio = visita.checkIn.timestamp.toIso8601String();
              if (visita.checkOut != null) {
                cliente.horaFin = visita.checkOut!.timestamp.toIso8601String();
              }
              cliente.comentarioInicio = visita.checkIn.comentarios;
              
              print('   └── Estado actualizado a: completada');
            } else if (visita.estatus == 'en_proceso') {
              cliente.estatus = 'en_proceso';
              cliente.horaInicio = visita.checkIn.timestamp.toIso8601String();
              cliente.comentarioInicio = visita.checkIn.comentarios;
              
              print('   └── Estado actualizado a: en_proceso');
            }
            
            // Sincronizar formularios capturados
            if (visita.formularios.isNotEmpty) {
              print('   └── Formularios encontrados: ${visita.formularios.length}');
              
              // Convertir los formularios del formato de VisitaClienteHive a FormularioDinamicoHive
              for (var formularioEntry in visita.formularios.entries) {
                final formularioId = formularioEntry.key;
                final formularioData = formularioEntry.value;
                
                // Verificar si ya existe el formulario en el día del plan
                bool formularioExiste = _diaPlan!.formularios.any((f) => 
                  f.clienteId == cliente.clienteId && 
                  f.formularioId == formularioId
                );
                
                if (!formularioExiste) {
                  // Crear un formulario del día para agregarlo al plan
                  final nuevoFormulario = FormularioDiaHive(
                    formularioId: formularioId,
                    clienteId: cliente.clienteId,
                    respuestas: formularioData is Map<String, dynamic> ? formularioData : {},
                    fechaCaptura: visita.fechaCreacion,
                  );
                  
                  _diaPlan!.formularios.add(nuevoFormulario);
                  print('   └── Formulario agregado: $formularioId para cliente ${cliente.clienteId}');
                }
              }
            }
            
            visitaEncontrada = true;
            break;
          }
        }
        
        if (!visitaEncontrada) {
          print('❌ No se encontró visita en Hive para cliente: ${cliente.clienteId}');
        }
      }
      
      print('✅ Sincronización de estados completada');
      print('   └── Total clientes procesados: ${_diaPlan!.clientes.length}');
      print('   └── Clientes con visitas completadas: ${_diaPlan!.clientes.where((c) => c.estatus == 'completada').length}');
      
    } catch (e) {
      print('❌ Error al sincronizar estados de visitas: $e');
    }
  }
  
  DateTime _obtenerFechaDelDia(String nombreDia) {
    final ahora = DateTime.now();
    final diasSemana = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    final diaIndex = diasSemana.indexOf(nombreDia.toLowerCase());
    final diaActualIndex = ahora.weekday - 1;
    
    var diferenciaDias = diaIndex - diaActualIndex;
    
    // Ajustar a la misma semana
    if (diferenciaDias < -3) {
      diferenciaDias += 7;
    } else if (diferenciaDias > 3) {
      diferenciaDias -= 7;
    }
    
    return ahora.add(Duration(days: diferenciaDias));
  }

  Map<String, dynamic> _calcularKPIsRutina() {
    if (_diaPlan == null || _diaPlan!.tipo != 'gestion_cliente') {
      return {
        'clientesPlanificados': 0,
        'visitados': 0,
        'porcentajeCumplimiento': 0,
        'duracionPromedio': 0,
      };
    }
    
    // Filtrar actividades según la rutina seleccionada
    final actividadesFiltradas = _obtenerActividadesFiltradas();
    
    final clientesPlanificados = actividadesFiltradas.length;
    final visitados = actividadesFiltradas.where((v) {
      // Verificar si tiene el formulario correspondiente
      if (_rutinaSeleccionada == TipoRutina.todas) {
        return v.estatus == 'completada';
      }
      
      // Para otras rutinas, verificar si tiene el formulario correspondiente
      final tieneFormulario = _tieneFormularioRutina(v);
      return tieneFormulario;
    }).length;
    
    final porcentajeCumplimiento = clientesPlanificados > 0 
        ? (visitados / clientesPlanificados * 100).round() 
        : 0;
    
    // Calcular duración promedio
    final duraciones = <int>[];
    for (final visita in actividadesFiltradas) {
      if (visita.horaInicio != null && visita.horaFin != null) {
        try {
          final inicio = DateTime.parse(visita.horaInicio!);
          final fin = DateTime.parse(visita.horaFin!);
          final duracion = fin.difference(inicio).inMinutes;
          if (duracion > 0) duraciones.add(duracion);
        } catch (_) {}
      }
    }
    
    final duracionPromedio = duraciones.isNotEmpty
        ? (duraciones.reduce((a, b) => a + b) / duraciones.length).round()
        : 0;
    
    return {
      'clientesPlanificados': clientesPlanificados,
      'visitados': visitados,
      'porcentajeCumplimiento': porcentajeCumplimiento,
      'duracionPromedio': duracionPromedio,
    };
  }

  List<VisitaClienteUnificadaHive> _obtenerActividadesFiltradas() {
    if (_diaPlan == null) return [];
    
    // Si es día administrativo y está seleccionada la pestaña de administrativas o todas
    if (_diaPlan!.tipo == 'administrativo' && 
        (_rutinaSeleccionada == TipoRutina.administrativas || 
         _rutinaSeleccionada == TipoRutina.todas)) {
      return []; // Las actividades administrativas se muestran diferente
    }
    
    var actividades = _diaPlan!.clientes;
    
    // Filtrar por tipo de rutina seleccionada
    switch (_rutinaSeleccionada) {
      case TipoRutina.visitasClientes:
        // Mostrar todas las visitas programadas, no solo las que tienen check-in
        // Esto permite ver tanto las completadas como las pendientes
        break;
      case TipoRutina.formularios:
        // Solo mostrar clientes con formularios capturados
        actividades = actividades.where((a) => 
          _diaPlan!.formularios.any((f) => f.clienteId == a.clienteId)
        ).toList();
        print('🔍 Filtrando por formularios:');
        print('   └── Total formularios en el día: ${_diaPlan!.formularios.length}');
        print('   └── Clientes con formularios: ${actividades.length}');
        break;
      case TipoRutina.administrativas:
        // No mostrar clientes en vista administrativa
        return [];
      case TipoRutina.todas:
        // Mostrar todos
        break;
    }
    
    // Filtrar por ruta si está seleccionada
    if (_rutaFiltro != null && _rutaFiltro!.isNotEmpty) {
      // TODO: Implementar filtro por ruta cuando tengamos esa información
    }
    
    // Filtrar por cliente si está seleccionado
    if (_clienteFiltro != null && _clienteFiltro!.isNotEmpty) {
      actividades = actividades.where((a) => a.clienteId == _clienteFiltro).toList();
    }
    
    return actividades;
  }

  bool _tieneFormularioRutina(VisitaClienteUnificadaHive visita) {
    // Buscar en los formularios del día si existe uno para este cliente
    final formularios = _diaPlan?.formularios ?? [];
    return formularios.any((f) => f.clienteId == visita.clienteId);
  }

  void _cambiarDia(String nuevoDia) async {
    setState(() {
      _diaSeleccionado = nuevoDia;
      _cargando = true;
    });
    
    // Actualizar el día del plan
    if (_planSeleccionado != null && _planSeleccionado!.dias.containsKey(nuevoDia)) {
      _diaPlan = _planSeleccionado!.dias[nuevoDia];
      
      // Sincronizar estados de visitas para el nuevo día
      await _sincronizarEstadosVisitas();
      
      // Recalcular KPIs
      _kpis = _calcularKPIsRutina();
      
      setState(() {
        _cargando = false;
      });
    } else {
      await _cargarDatos();
    }
  }

  void _cambiarRutina(TipoRutina nuevaRutina) {
    setState(() {
      _rutinaSeleccionada = nuevaRutina;
      _kpis = _calcularKPIsRutina();
    });
  }

  void _filtrarPorRuta(String? ruta) {
    setState(() {
      _rutaFiltro = ruta;
      _kpis = _calcularKPIsRutina();
    });
  }

  void _filtrarPorCliente(String? cliente) {
    setState(() {
      _clienteFiltro = cliente;
      _kpis = _calcularKPIsRutina();
    });
  }

  void _cambiarPlan(PlanTrabajoUnificadoHive nuevoPlan) {
    setState(() {
      _planSeleccionado = nuevoPlan;
      _diaSeleccionado = ''; // Resetear día seleccionado
      _diaPlan = null;
      _rutaFiltro = null;
      _clienteFiltro = null;
    });
    
    // Seleccionar el primer día con actividades
    final diasConActividades = nuevoPlan.dias.entries
        .where((entry) => entry.value.configurado)
        .toList();
    if (diasConActividades.isNotEmpty) {
      setState(() {
        _diaSeleccionado = diasConActividades.first.key;
        _diaPlan = diasConActividades.first.value;
        _kpis = _calcularKPIsRutina();
      });
    }
  }

  bool _tieneActividadesParaMostrar() {
    if (_planSeleccionado == null) return false;
    
    // Verificar si hay al menos un día configurado con actividades
    return _planSeleccionado!.dias.values.any((dia) => 
      dia.configurado && (dia.clientes.isNotEmpty || dia.tipo == 'administrativo')
    );
  }

  int _contarRegistrosPendientesSync() {
    try {
      final box = Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado');
      
      // Contar planes no sincronizados
      int planesNoSincronizados = box.values
          .where((plan) => !plan.sincronizado)
          .length;
      
      // Contar actividades completadas pero no sincronizadas
      int actividadesNoSincronizadas = 0;
      
      for (var plan in box.values) {
        // Si el plan está marcado como enviado pero no sincronizado
        if (plan.estatus == 'enviado' && !plan.sincronizado) {
          // Contar todos los días con actividades
          for (var dia in plan.dias.values) {
            actividadesNoSincronizadas += dia.clientes
                .where((cliente) => cliente.estatus == 'completada')
                .length;
          }
        }
      }
      
      return planesNoSincronizados + actividadesNoSincronizadas;
    } catch (e) {
      print('Error contando registros pendientes: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rutinas / Resultados',
          style: GoogleFonts.poppins(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: Column(
          children: [
            // Banner offline si aplica
            if (_isOffline) OfflineBanner(
              registrosPendientes: _contarRegistrosPendientesSync(),
            ),
            
            // Selector de plan semanal
            SelectorPlanSemanal(
              planesDisponibles: _planesDisponibles,
              planSeleccionado: _planSeleccionado,
              onPlanChanged: _cambiarPlan,
            ),
            
            // Tabs de rutinas - Solo mostrar si hay plan seleccionado con actividades
            if (_planSeleccionado != null && _tieneActividadesParaMostrar())
              Container(
                color: Colors.white,
                child: TabRutinas(
                  rutinaSeleccionada: _rutinaSeleccionada,
                  onRutinaChanged: _cambiarRutina,
                ),
              ),
            
            // Contenido principal
            Expanded(
              child: _buildContenido(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.dianaRed),
      );
    }
    
    if (_error != null) {
      return _buildError();
    }
    
    if (_planSeleccionado == null) {
      return _buildSinPlan();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de día
          _buildSelectorDia(),
          
          const SizedBox(height: 16),
          
          // Filtros de ruta y cliente
          _buildFiltros(),
          
          const SizedBox(height: 16),
          
          // KPIs
          _buildKPIs(),
          
          const SizedBox(height: 24),
          
          // Lista de actividades
          _buildListaActividades(),
        ],
      ),
    );
  }

  Widget _buildError() {
    final bool noHayDatos = _error == 'No Existen Datos Disponibles';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noHayDatos ? Icons.inbox : Icons.error_outline,
            size: 64,
            color: noHayDatos ? Colors.grey.shade300 : Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            noHayDatos ? 'Sin Datos' : 'Error',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Ha ocurrido un error',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (noHayDatos) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/plan_configuracion');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Crear Plan de Trabajo',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _cargarDatos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dianaRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSinPlan() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.orange.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Plan de Trabajo',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No hay un plan de trabajo programado para esta semana.\nPrograme primero el Plan de Trabajo.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/plan_configuracion');
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Crear Plan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dianaRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorDia() {
    if (_planSeleccionado == null) return const SizedBox.shrink();
    
    // Obtener solo los días configurados del plan
    final diasConfigurados = _planSeleccionado!.dias.entries
        .where((entry) => entry.value.configurado)
        .map((entry) => entry.key)
        .toList();
    
    if (diasConfigurados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No hay días configurados en este plan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona un día',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: diasConfigurados.length,
            itemBuilder: (context, index) {
              final dia = diasConfigurados[index];
              final diaPlan = _planSeleccionado!.dias[dia]!;
              final isSelected = dia == _diaSeleccionado;
              
              // Contar información del día
              final totalClientes = diaPlan.clientes.length;
              final clientesCompletados = diaPlan.clientes
                  .where((c) => c.estatus == 'completada')
                  .length;
              final tieneFormularios = diaPlan.formularios.isNotEmpty;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _cambiarDia(dia),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.dianaRed : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.dianaRed : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.dianaRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dia.substring(0, 3).toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (diaPlan.tipo == 'gestion_cliente') ...[
                          Text(
                            '$clientesCompletados/$totalClientes',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (tieneFormularios)
                                Icon(
                                  Icons.assignment_turned_in,
                                  size: 12,
                                  color: isSelected ? Colors.white : AppColors.dianaGreen,
                                ),
                              if (diaPlan.clientes.any((c) => c.compromisos.isNotEmpty)) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.handshake,
                                  size: 12,
                                  color: isSelected ? Colors.white : AppColors.dianaYellow,
                                ),
                              ],
                            ],
                          ),
                        ] else if (diaPlan.tipo == 'administrativo') ...[
                          Icon(
                            Icons.business_center,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.mediumGray,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    if (_diaPlan == null || _diaPlan!.tipo != 'gestion_cliente') {
      return const SizedBox.shrink();
    }
    
    // Obtener rutas únicas del día
    final rutasSet = <String>{};
    if (_diaPlan!.rutaNombre != null && _diaPlan!.rutaNombre!.isNotEmpty) {
      rutasSet.add(_diaPlan!.rutaNombre!);
    }
    final rutas = rutasSet.toList()..sort();
    
    // Obtener clientes únicos
    final clientes = _diaPlan!.clientes
        .map((c) => c.clienteId)
        .toSet()
        .toList()
        ..sort();
    
    if (rutas.isEmpty && clientes.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return FiltrosRutina(
      rutaSeleccionada: _rutaFiltro,
      clienteSeleccionado: _clienteFiltro,
      rutasDisponibles: rutas,
      clientesDisponibles: clientes,
      onRutaChanged: (ruta) => _filtrarPorRuta(ruta),
      onClienteChanged: (cliente) => _filtrarPorCliente(cliente),
    );
  }

  Widget _buildKPIs() {
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
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.dianaRed,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Indicadores ${_rutinaSeleccionada.titulo}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KPISemaforoCard(
                  titulo: 'Planificados',
                  valor: _kpis['clientesPlanificados'] ?? 0,
                  color: AppColors.darkGray,
                  icono: Icons.assignment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KPISemaforoCard(
                  titulo: 'Visitados',
                  valor: _kpis['visitados'] ?? 0,
                  color: AppColors.dianaGreen,
                  icono: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: KPISemaforoCard(
                  titulo: 'Cumplimiento',
                  valor: _kpis['porcentajeCumplimiento'] ?? 0,
                  esPorcentaje: true,
                  color: _obtenerColorSemaforo(_kpis['porcentajeCumplimiento'] ?? 0),
                  icono: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KPISemaforoCard(
                  titulo: 'Duración Prom.',
                  valor: _kpis['duracionPromedio'] ?? 0,
                  sufijo: ' min',
                  color: AppColors.dianaYellow,
                  icono: Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _obtenerColorSemaforo(int porcentaje) {
    if (porcentaje >= 80) return AppColors.dianaGreen;
    if (porcentaje >= 60) return AppColors.dianaYellow;
    return AppColors.dianaRed;
  }

  Widget _buildListaActividades() {
    if (_diaPlan == null) return const SizedBox.shrink();
    
    // Si es día administrativo y se seleccionó ver administrativas o todas
    if (_diaPlan!.tipo == 'administrativo' && 
        (_rutinaSeleccionada == TipoRutina.administrativas || 
         _rutinaSeleccionada == TipoRutina.todas)) {
      return _buildActividadAdministrativa();
    }
    
    // Si se seleccionó administrativas pero no es día administrativo
    if (_rutinaSeleccionada == TipoRutina.administrativas && 
        _diaPlan!.tipo != 'administrativo') {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.business_center,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividades administrativas este día',
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
    
    final actividades = _obtenerActividadesFiltradas();
    
    if (actividades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividades con los filtros aplicados',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.mediumGray,
                ),
              ),
              if (_rutaFiltro != null || _clienteFiltro != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _rutaFiltro = null;
                      _clienteFiltro = null;
                    });
                  },
                  child: Text(
                    'Limpiar filtros',
                    style: GoogleFonts.poppins(
                      color: AppColors.dianaRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividades del día',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...actividades.map((actividad) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClienteRutinaTile(
            visita: actividad,
            dia: _diaPlan!,
            rutina: _rutinaSeleccionada,
            onTap: () => _abrirDetalleVisita(actividad),
          ),
        )),
      ],
    );
  }

  void _abrirDetalleVisita(VisitaClienteUnificadaHive visita) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.dianaRed,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cliente ${visita.clienteId}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _diaSeleccionado,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado de la visita
                      _buildDetalleSeccion(
                        'Estado de la Visita',
                        Icons.info_outline,
                        _buildEstadoVisita(visita),
                      ),
                      
                      // Check-in/Check-out
                      if (visita.horaInicio != null || visita.horaFin != null) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Registro de Visita',
                          Icons.access_time,
                          _buildRegistroVisita(visita),
                        ),
                      ],
                      
                      // Formularios capturados
                      if (_diaPlan!.formularios.any((f) => f.clienteId == visita.clienteId)) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Formularios Capturados',
                          Icons.assignment_turned_in,
                          _buildFormulariosCapturados(visita),
                        ),
                      ],
                      
                      // Compromisos
                      if (visita.compromisos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Compromisos',
                          Icons.handshake,
                          _buildCompromisos(visita),
                        ),
                      ],
                      
                      // Indicadores
                      if (visita.indicadorIds != null && visita.indicadorIds!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Indicadores de Gestión',
                          Icons.analytics,
                          _buildIndicadores(visita),
                        ),
                      ],
                      
                      // Retroalimentación
                      if (visita.retroalimentacion != null && visita.retroalimentacion!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Retroalimentación',
                          Icons.feedback,
                          Text(
                            visita.retroalimentacion!,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ],
                      
                      // Reconocimiento
                      if (visita.reconocimiento != null && visita.reconocimiento!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Reconocimiento',
                          Icons.star,
                          Text(
                            visita.reconocimiento!,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cerrar',
                        style: GoogleFonts.poppins(
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActividadAdministrativa() {
    if (_diaPlan == null || _diaPlan!.tipo != 'administrativo') {
      return const SizedBox.shrink();
    }
    
    String tipoActividad = _diaPlan!.tipoActividadAdministrativa ?? 'Sin especificar';
    
    // Parsear JSON si es necesario
    if (tipoActividad.trim().startsWith('{') || tipoActividad.trim().startsWith('[')) {
      try {
        var decoded = jsonDecode(tipoActividad);
        if (decoded is Map) {
          tipoActividad = decoded['nombre'] ?? 
                         decoded['tipo'] ?? 
                         decoded['descripcion'] ?? 
                         'Actividad Administrativa';
        } else {
          tipoActividad = 'Actividad Administrativa';
        }
      } catch (e) {
        // Si falla el parseo, usar el texto original limpio
        tipoActividad = tipoActividad.replaceAll(RegExp(r'[{}"\[\]]'), '');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad del día',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _mostrarDetalleActividadAdministrativa(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
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
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business_center,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipoActividad,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actividad Administrativa',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.mediumGray,
                    ),
                  ],
                ),
                if (_diaPlan!.objetivoNombre != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: AppColors.dianaRed,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Objetivo del día',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              Text(
                                _diaPlan!.objetivoNombre!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleSeccion(String titulo, IconData icono, Widget contenido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: AppColors.dianaRed),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        contenido,
      ],
    );
  }

  Widget _buildEstadoVisita(VisitaClienteUnificadaHive visita) {
    String estado;
    Color color;
    IconData icon;
    
    if (visita.estatus == 'completada') {
      estado = 'COMPLETADA';
      color = AppColors.dianaGreen;
      icon = Icons.check_circle;
    } else if (visita.estatus == 'en_proceso') {
      estado = 'EN PROCESO';
      color = AppColors.dianaYellow;
      icon = Icons.timelapse;
    } else if (visita.estatus == 'cancelada') {
      estado = 'CANCELADA';
      color = Colors.grey;
      icon = Icons.cancel;
    } else {
      estado = 'PENDIENTE';
      color = AppColors.dianaRed;
      icon = Icons.pending;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            estado,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistroVisita(VisitaClienteUnificadaHive visita) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visita.horaInicio != null) ...[
          Row(
            children: [
              Icon(Icons.login, size: 16, color: AppColors.dianaGreen),
              const SizedBox(width: 8),
              Text(
                'Check-in: ${visita.horaInicio}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          if (visita.comentarioInicio != null && visita.comentarioInicio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Comentario: ${visita.comentarioInicio}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
        if (visita.horaFin != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.logout, size: 16, color: AppColors.dianaRed),
              const SizedBox(width: 8),
              Text(
                'Check-out: ${visita.horaFin}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          // Calcular duración
          if (visita.horaInicio != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Duración: ${_calcularDuracion(visita)} minutos',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.mediumGray,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFormulariosCapturados(VisitaClienteUnificadaHive visita) {
    final formularios = _diaPlan!.formularios
        .where((f) => f.clienteId == visita.clienteId)
        .toList();
    
    if (formularios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'No hay formularios capturados',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: formularios.map((formulario) {
        // Determinar el nombre del formulario basado en el ID
        String nombreFormulario = _obtenerNombreFormulario(formulario.formularioId);
        
        // Contar respuestas válidas (no vacías)
        final respuestasValidas = formulario.respuestas.entries
            .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
            .length;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.dianaGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.dianaGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dianaGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in,
                      size: 20,
                      color: AppColors.dianaGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreFormulario,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppColors.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(formulario.fechaCaptura),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$respuestasValidas respuestas capturadas',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.dianaGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.expand_more,
                      color: AppColors.dianaGreen,
                    ),
                    onPressed: () => _mostrarDetalleFormulario(formulario, nombreFormulario),
                  ),
                ],
              ),
              // Mostrar resumen de respuestas del formulario
              if (formulario.respuestas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.list_alt,
                                size: 16,
                                color: AppColors.dianaGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resumen de respuestas:',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._buildRespuestasFormularioResumen(formulario.respuestas, limite: 3),
                          if (formulario.respuestas.length > 3) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '... y ${formulario.respuestas.length - 3} más',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.dianaGreen,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
  
  String _obtenerNombreFormulario(String formularioId) {
    // Mapeo de IDs de formularios a nombres legibles
    switch (formularioId.toLowerCase()) {
      case 'visita_cliente':
      case 'visitacliente':
        return 'Visita a Cliente';
      case 'toma_pedido':
      case 'tomapedido':
        return 'Toma de Pedido';
      case 'encuesta_satisfaccion':
      case 'encuestasatisfaccion':
        return 'Encuesta de Satisfacción';
      case 'relevamiento':
        return 'Relevamiento';
      case 'censo':
        return 'Censo';
      case 'seguimiento':
        return 'Seguimiento';
      default:
        // Si no está mapeado, formatear el ID para que sea más legible
        return formularioId
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    }
  }

  Widget _buildCompromisos(VisitaClienteUnificadaHive visita) {
    return Column(
      children: visita.compromisos.map((compromiso) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: AppColors.dianaYellow,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      compromiso.tipo,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dianaYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cant: ${compromiso.cantidad}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dianaYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                compromiso.detalle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: AppColors.mediumGray),
                  const SizedBox(width: 4),
                  Text(
                    'Fecha plazo: ${compromiso.fechaPlazo}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIndicadores(VisitaClienteUnificadaHive visita) {
    if (visita.indicadorIds == null || visita.indicadorIds!.isEmpty) {
      return Text(
        'No hay indicadores asignados',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.mediumGray,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      children: [
        ...visita.indicadorIds!.map((indicadorId) {
          final resultado = visita.resultadosIndicadores?[indicadorId];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 16,
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Indicador $indicadorId',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (resultado != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dianaGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      resultado,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dianaGreen,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Sin resultado',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        if (visita.comentarioIndicadores != null && visita.comentarioIndicadores!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.comment,
                  size: 16,
                  color: AppColors.mediumGray,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visita.comentarioIndicadores!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  int _calcularDuracion(VisitaClienteUnificadaHive visita) {
    if (visita.horaInicio == null || visita.horaFin == null) return 0;
    try {
      final inicio = DateTime.parse(visita.horaInicio!);
      final fin = DateTime.parse(visita.horaFin!);
      return fin.difference(inicio).inMinutes;
    } catch (_) {
      return 0;
    }
  }

  List<Widget> _buildRespuestasFormulario(Map<String, dynamic> respuestas) {
    List<Widget> widgets = [];
    
    respuestas.forEach((pregunta, respuesta) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatearPregunta(pregunta),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatearRespuesta(respuesta),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }

  List<Widget> _buildRespuestasFormularioResumen(Map<String, dynamic> respuestas, {int limite = 5}) {
    List<Widget> widgets = [];
    int contador = 0;
    
    // Filtrar respuestas no vacías y ordenar por clave
    final respuestasOrdenadas = respuestas.entries
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    for (var entry in respuestasOrdenadas) {
      if (contador >= limite) break;
      
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dianaGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatearPregunta(entry.key),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatearRespuestaCorta(entry.value),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.mediumGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      contador++;
    }
    
    return widgets;
  }

  String _formatearPregunta(String pregunta) {
    // Convertir snake_case o camelCase a texto legible
    return pregunta
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ')
        .trim();
  }

  String _formatearRespuesta(dynamic respuesta) {
    if (respuesta == null) return 'Sin respuesta';
    
    if (respuesta is List) {
      return respuesta.map((item) => '• $item').join('\n');
    } else if (respuesta is Map) {
      return respuesta.entries
          .map((entry) => '${_formatearPregunta(entry.key)}: ${entry.value}')
          .join('\n');
    } else if (respuesta is bool) {
      return respuesta ? 'Sí' : 'No';
    } else {
      return respuesta.toString();
    }
  }

  String _formatearRespuestaCorta(dynamic respuesta) {
    if (respuesta == null) return 'Sin respuesta';
    
    if (respuesta is List) {
      if (respuesta.isEmpty) return 'Lista vacía';
      return respuesta.length == 1 
          ? respuesta.first.toString() 
          : '${respuesta.first} (+${respuesta.length - 1} más)';
    } else if (respuesta is Map) {
      if (respuesta.isEmpty) return 'Sin datos';
      final primerItem = respuesta.entries.first;
      return respuesta.length == 1
          ? '${primerItem.key}: ${primerItem.value}'
          : '${primerItem.key}: ${primerItem.value} (+${respuesta.length - 1} más)';
    } else if (respuesta is bool) {
      return respuesta ? 'Sí' : 'No';
    } else {
      final texto = respuesta.toString();
      return texto.length > 50 ? '${texto.substring(0, 47)}...' : texto;
    }
  }

  void _mostrarDetalleFormulario(FormularioDiaHive formulario, String nombreFormulario) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.dianaGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreFormulario,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(formulario.fechaCaptura),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Respuestas del Formulario',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (formulario.respuestas.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'No hay respuestas registradas',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.mediumGray,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        ..._buildRespuestasFormularioDetalle(formulario.respuestas),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cerrar',
                        style: GoogleFonts.poppins(
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRespuestasFormularioDetalle(Map<String, dynamic> respuestas) {
    List<Widget> widgets = [];
    int index = 0;
    
    respuestas.forEach((pregunta, respuesta) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: index % 2 == 0 ? Colors.white : AppColors.lightGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.dianaGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dianaGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatearPregunta(pregunta),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _formatearRespuesta(respuesta),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.darkGray,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      index++;
    });
    
    return widgets;
  }

  void _mostrarDetalleActividadAdministrativa() {
    if (_diaPlan == null || _diaPlan!.tipo != 'administrativo') return;
    
    String tipoActividad = _diaPlan!.tipoActividadAdministrativa ?? 'Sin especificar';
    
    // Parsear JSON si es necesario
    if (tipoActividad.trim().startsWith('{') || tipoActividad.trim().startsWith('[')) {
      try {
        var decoded = jsonDecode(tipoActividad);
        if (decoded is Map) {
          tipoActividad = decoded['nombre'] ?? 
                         decoded['tipo'] ?? 
                         decoded['descripcion'] ?? 
                         'Actividad Administrativa';
        } else {
          tipoActividad = 'Actividad Administrativa';
        }
      } catch (e) {
        tipoActividad = tipoActividad.replaceAll(RegExp(r'[{}"\[\]]'), '');
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business_center, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actividad Administrativa',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _diaSeleccionado,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de actividad
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tipo de Actividad',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tipoActividad,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Objetivo
                      if (_diaPlan!.objetivoNombre != null) ...[
                        const SizedBox(height: 20),
                        _buildDetalleSeccion(
                          'Objetivo del Día',
                          Icons.flag,
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _diaPlan!.objetivoNombre!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      // Información adicional
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.mediumGray,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Día planificado: $_diaSeleccionado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 16,
                                  color: AppColors.mediumGray,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tipo: Actividad Administrativa',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cerrar',
                        style: GoogleFonts.poppins(
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}