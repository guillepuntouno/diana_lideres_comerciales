import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../repositorios/plan_trabajo_unificado_repository.dart';
import '../configuracion/ambiente_config.dart';
import 'sesion_servicio.dart';
import '../modelos/lider_comercial_modelo.dart';
import 'package:intl/intl.dart';

class PlanTrabajoUnificadoService {
  final PlanTrabajoUnificadoRepository _repository = PlanTrabajoUnificadoRepository();
  final String baseUrl = AmbienteConfig.baseUrl;
  
  // Getter público para el repositorio
  PlanTrabajoUnificadoRepository get repository => _repository;

  // Obtener o crear plan para una semana
  Future<PlanTrabajoUnificadoHive> obtenerOCrearPlan(
    String semana,
    String liderClave,
    LiderComercial lider,
  ) async {
    try {
      // Buscar plan existente en repositorio local
      final planes = _repository.obtenerPlanesDelLider(liderClave);
      final planExistente = planes.firstWhere(
        (p) => p.semana == semana,
        orElse: () => null as dynamic,
      );

      if (planExistente != null) {
        print('Plan encontrado localmente: ${planExistente.id}');
        return planExistente;
      }

      // Si no existe, intentar cargar desde servidor
      final planServidor = await _cargarPlanDesdeServidor(semana, liderClave);
      if (planServidor != null) {
        await _repository.crearPlan(planServidor);
        return planServidor;
      }

      // Si no existe en servidor, crear nuevo plan
      final nuevoPlan = _crearNuevoPlan(semana, lider);
      await _repository.crearPlan(nuevoPlan);
      print('Nuevo plan creado: ${nuevoPlan.id}');
      
      return nuevoPlan;
    } catch (e) {
      print('Error en obtenerOCrearPlan: $e');
      // En caso de error, crear plan local
      final planLocal = _crearNuevoPlan(semana, lider);
      await _repository.crearPlan(planLocal);
      return planLocal;
    }
  }

  // Cargar plan desde servidor
  Future<PlanTrabajoUnificadoHive?> _cargarPlanDesdeServidor(
    String semana,
    String liderClave,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/planes-trabajo/semana/$semana/lider/$liderClave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PlanTrabajoUnificadoHive.fromJson(json);
      }

      return null;
    } catch (e) {
      print('Error cargando plan desde servidor: $e');
      return null;
    }
  }

  // Crear nuevo plan vacío
  PlanTrabajoUnificadoHive _crearNuevoPlan(String semana, LiderComercial lider) {
    // Extraer número de semana y año del formato "SEMANA XX - YYYY"
    final partes = semana.split(' ');
    final numeroSemana = int.parse(partes[1]);
    final anio = int.parse(partes[3]);

    // Calcular fechas de inicio y fin
    final inicioAnio = DateTime(anio, 1, 1);
    final diasHastaLunes = (numeroSemana - 1) * 7 + (8 - inicioAnio.weekday) % 7;
    final lunesSemana = inicioAnio.add(Duration(days: diasHastaLunes));
    final viernesSemana = lunesSemana.add(const Duration(days: 4));

    final planId = '${lider.clave}_SEM${numeroSemana}_$anio';

    // Crear días vacíos
    final dias = <String, DiaPlanHive>{};
    final diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    
    for (final dia in diasSemana) {
      dias[dia] = DiaPlanHive(
        dia: dia,
        tipo: 'administrativo',
        configurado: false,
      );
    }

    return PlanTrabajoUnificadoHive(
      id: planId,
      semana: semana,
      numeroSemana: numeroSemana,
      anio: anio,
      liderClave: lider.clave,
      liderNombre: lider.nombre,
      centroDistribucion: lider.centroDistribucion,
      fechaInicio: DateFormat('yyyy-MM-dd').format(lunesSemana),
      fechaFin: DateFormat('yyyy-MM-dd').format(viernesSemana),
      estatus: 'borrador',
      dias: dias,
    );
  }

  // Enviar plan al servidor
  Future<bool> enviarPlan(String planId) async {
    try {
      final plan = _repository.obtenerPlan(planId);
      if (plan == null) throw Exception('Plan no encontrado');

      // Validar que todos los días estén configurados
      if (!plan.estaCompleto) {
        throw Exception('El plan no está completo');
      }

      // Cambiar estado a enviado
      plan.estatus = 'enviado';
      await _repository.actualizarPlan(plan);

      // Intentar sincronizar con servidor
      final sincronizado = await _sincronizarConServidor(plan);
      
      if (sincronizado) {
        await _repository.marcarComoSincronizado(planId);
      }

      return true;
    } catch (e) {
      print('Error enviando plan: $e');
      rethrow;
    }
  }

  // Sincronizar plan con servidor
  Future<bool> _sincronizarConServidor(PlanTrabajoUnificadoHive plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/planes-trabajo/sincronizar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(plan.toJsonParaSincronizacion()),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('Error sincronizando con servidor: $e');
      return false;
    }
  }

  // Sincronizar todos los planes pendientes
  Future<int> sincronizarPlanesPendientes() async {
    try {
      final planesPendientes = _repository.obtenerPlanesPendientesSync();
      int sincronizados = 0;

      for (final plan in planesPendientes) {
        final exito = await _sincronizarConServidor(plan);
        if (exito) {
          await _repository.marcarComoSincronizado(plan.id);
          sincronizados++;
        }
      }

      return sincronizados;
    } catch (e) {
      print('Error sincronizando planes pendientes: $e');
      return 0;
    }
  }

  // Recargar plan desde repositorio
  Future<PlanTrabajoUnificadoHive?> recargarPlan(String planId) async {
    try {
      return _repository.obtenerPlan(planId);
    } catch (e) {
      print('Error recargando plan: $e');
      return null;
    }
  }

  // Obtener plan actual del líder
  PlanTrabajoUnificadoHive? obtenerPlanActual(String liderClave) {
    return _repository.obtenerPlanActual(liderClave);
  }

  // Verificar si un plan puede ser editado
  bool puedeEditarPlan(PlanTrabajoUnificadoHive plan) {
    return plan.puedeEditar();
  }

  // Obtener progreso del plan
  Map<String, dynamic> obtenerProgresoPlan(String planId) {
    return _repository.obtenerProgresoPlan(planId);
  }
}