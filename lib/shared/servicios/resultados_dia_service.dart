import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:intl/intl.dart';

/// Servicio de solo lectura para consultar resultados del día desde el plan unificado
class ResultadosDiaService {
  final _hiveService = HiveService();
  
  /// Obtiene el plan unificado actual basado en la semana actual
  PlanTrabajoUnificadoHive? obtenerPlanActual(String liderClave) {
    try {
      final hoy = DateTime.now();
      final numeroSemana = _obtenerNumeroSemana(hoy);
      final key = '${liderClave}_SEM${numeroSemana.toString().padLeft(2, '0')}_${hoy.year}';
      
      print('🔍 Buscando plan con key: $key');
      return _hiveService.planesTrabajoUnificadosBox.get(key);
    } catch (e) {
      print('❌ Error obteniendo plan actual: $e');
      return null;
    }
  }
  
  /// Obtiene los datos de un día específico
  DiaPlanHive? obtenerDia(String liderClave, String nombreDia) {
    try {
      final plan = obtenerPlanActual(liderClave);
      if (plan == null) {
        print('⚠️ No se encontró plan para el líder: $liderClave');
        return null;
      }
      
      final dia = plan.dias[nombreDia];
      if (dia == null) {
        print('⚠️ No hay datos para el día: $nombreDia');
        return null;
      }
      
      print('✅ Datos del día $nombreDia obtenidos exitosamente');
      print('   └── Clientes planificados: ${dia.clienteIds.length}');
      print('   └── Visitas registradas: ${dia.clientes.length}');
      
      return dia;
    } catch (e) {
      print('❌ Error obteniendo día: $e');
      return null;
    }
  }
  
  /// Calcula el número de semana del año
  int _obtenerNumeroSemana(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    final weekNumber = ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
    return weekNumber;
  }
  
  /// Obtiene el nombre del día en español
  String obtenerNombreDia(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[fecha.weekday - 1];
  }
  
  /// Calcula KPIs para un día específico
  Map<String, dynamic> calcularKPIs(DiaPlanHive? dia) {
    if (dia == null) {
      return {
        'clientesPlanificados': 0,
        'visitados': 0,
        'porcentajeCumplimiento': 0,
        'compromisosGenerados': 0,
        'duracionPromedio': 0,
        'clientesEnProceso': 0,
        'clientesPendientes': 0,
      };
    }
    
    final clientesPlanificados = dia.clienteIds.length;
    final visitados = dia.clientes.where((v) => v.estatus == 'terminado').length;
    final enProceso = dia.clientes.where((v) => v.estatus == 'en_proceso').length;
    final pendientes = dia.clientes.where((v) => v.estatus == 'pendiente').length;
    
    final porcentajeCumplimiento = clientesPlanificados > 0 
        ? (visitados / clientesPlanificados * 100).round() 
        : 0;
    
    final compromisosGenerados = dia.clientes
        .where((v) => v.estatus == 'terminado')
        .expand((v) => v.compromisos)
        .length;
    
    // Calcular duración promedio
    final duraciones = <int>[];
    for (final visita in dia.clientes) {
      if (visita.horaInicio != null && visita.horaFin != null) {
        try {
          final inicio = DateTime.parse(visita.horaInicio!);
          final fin = DateTime.parse(visita.horaFin!);
          final duracion = fin.difference(inicio).inMinutes;
          if (duracion > 0) duraciones.add(duracion);
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }
    }
    
    final duracionPromedio = duraciones.isNotEmpty 
        ? duraciones.reduce((a, b) => a + b) ~/ duraciones.length 
        : 0;
    
    return {
      'clientesPlanificados': clientesPlanificados,
      'visitados': visitados,
      'porcentajeCumplimiento': porcentajeCumplimiento,
      'compromisosGenerados': compromisosGenerados,
      'duracionPromedio': duracionPromedio,
      'clientesEnProceso': enProceso,
      'clientesPendientes': pendientes,
    };
  }
  
  /// Obtiene información del cliente desde Hive o devuelve datos por defecto
  Map<String, String> obtenerInfoCliente(String clienteId) {
    try {
      // Intentar obtener de la caja de clientes si existe
      final clientesBox = _hiveService.clientesBox;
      final cliente = clientesBox.values.firstWhere(
        (c) => c.id == clienteId,
        orElse: () => null as dynamic,
      );
      
      if (cliente != null) {
        return {
          'nombre': cliente.nombre,
          'direccion': cliente.direccion,
          'telefono': cliente.telefono ?? 'Sin teléfono',
          'asesor': cliente.asesorNombre ?? 'Sin asesor',
        };
      }
    } catch (e) {
      print('⚠️ Error obteniendo cliente de Hive: $e');
    }
    
    // Datos por defecto si no se encuentra
    return {
      'nombre': 'Cliente $clienteId',
      'direccion': 'Sin dirección registrada',
      'telefono': 'Sin teléfono',
      'asesor': 'Sin asesor asignado',
    };
  }
  
  /// Calcula la puntuación del cuestionario (0-100)
  int calcularPuntuacionCuestionario(CuestionarioHive? cuestionario) {
    if (cuestionario == null) return 0;
    
    int puntos = 0;
    int totalPosible = 0;
    
    // Tipo exhibidor (25 puntos)
    if (cuestionario.tipoExhibidor != null) {
      totalPosible += 25;
      if (cuestionario.tipoExhibidor!.poseeAdecuado == true) {
        puntos += 25;
      }
    }
    
    // Estándares de ejecución (40 puntos - 10 por cada uno)
    if (cuestionario.estandaresEjecucion != null) {
      totalPosible += 40;
      final ee = cuestionario.estandaresEjecucion!;
      if (ee.primeraPosicion == true) puntos += 10;
      if (ee.planograma == true) puntos += 10;
      if (ee.portafolioFoco == true) puntos += 10;
      if (ee.anclaje == true) puntos += 10;
    }
    
    // Disponibilidad (35 puntos - 7 por cada uno)
    if (cuestionario.disponibilidad != null) {
      totalPosible += 35;
      final d = cuestionario.disponibilidad!;
      if (d.ristras == true) puntos += 7;
      if (d.max == true) puntos += 7;
      if (d.familiar == true) puntos += 7;
      if (d.dulce == true) puntos += 7;
      if (d.galleta == true) puntos += 7;
    }
    
    return totalPosible > 0 ? (puntos * 100 ~/ totalPosible) : 0;
  }
}