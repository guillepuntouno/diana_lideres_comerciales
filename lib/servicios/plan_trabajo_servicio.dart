// lib/servicios/plan_trabajo_servicio.dart
// VERSIÓN TEMPORAL - Solo SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/plan_trabajo_modelo.dart';

class PlanTrabajoServicio {
  static final PlanTrabajoServicio _instance = PlanTrabajoServicio._internal();
  factory PlanTrabajoServicio() => _instance;
  PlanTrabajoServicio._internal();

  Future<void> guardarPlanTrabajo(PlanTrabajoModelo plan) async {
    final prefs = await SharedPreferences.getInstance();
    final planesJson = prefs.getString('planes_trabajo') ?? '{}';
    final planes = jsonDecode(planesJson) as Map<String, dynamic>;

    planes[plan.semana] = plan.toJson();
    await prefs.setString('planes_trabajo', jsonEncode(planes));
  }

  Future<PlanTrabajoModelo?> obtenerPlanTrabajo(
    String semana,
    String liderId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final planesJson = prefs.getString('planes_trabajo') ?? '{}';
    final planes = jsonDecode(planesJson) as Map<String, dynamic>;

    if (planes.containsKey(semana)) {
      return PlanTrabajoModelo.fromJson(planes[semana]);
    }

    return null;
  }

  Future<List<PlanTrabajoModelo>> obtenerTodosLosPlanes(String liderId) async {
    final prefs = await SharedPreferences.getInstance();
    final planesJson = prefs.getString('planes_trabajo') ?? '{}';
    final planes = jsonDecode(planesJson) as Map<String, dynamic>;

    return planes.values
        .map((json) => PlanTrabajoModelo.fromJson(json))
        .where((plan) => plan.liderId == liderId)
        .toList();
  }

  Future<List<PlanTrabajoModelo>> obtenerPlanesNoSincronizados(
    String liderId,
  ) async {
    final planes = await obtenerTodosLosPlanes(liderId);
    return planes.where((plan) => !plan.sincronizado).toList();
  }

  Future<void> marcarComoSincronizado(String semana, String liderId) async {
    final plan = await obtenerPlanTrabajo(semana, liderId);
    if (plan != null) {
      plan.sincronizado = true;
      await guardarPlanTrabajo(plan);
    }
  }

  Future<PlanTrabajoModelo> obtenerOCrearPlanSemanaActual({
    required String liderId,
    required String liderNombre,
    required String centroDistribucion,
  }) async {
    DateTime ahora = DateTime.now();

    int numeroSemana =
        ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                    DateTime(ahora.year, 1, 1).weekday -
                    1) /
                7)
            .ceil();
    String semana = 'SEMANA $numeroSemana - ${ahora.year}';

    PlanTrabajoModelo? planExistente = await obtenerPlanTrabajo(
      semana,
      liderId,
    );

    if (planExistente != null) {
      return planExistente;
    }

    DateTime inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    DateTime finSemana = inicioSemana.add(const Duration(days: 4));

    PlanTrabajoModelo nuevoPlan = PlanTrabajoModelo(
      semana: semana,
      fechaInicio:
          '${inicioSemana.day.toString().padLeft(2, '0')}/${inicioSemana.month.toString().padLeft(2, '0')}/${inicioSemana.year}',
      fechaFin:
          '${finSemana.day.toString().padLeft(2, '0')}/${finSemana.month.toString().padLeft(2, '0')}/${finSemana.year}',
      liderId: liderId,
      liderNombre: liderNombre,
      centroDistribucion: centroDistribucion,
      estatus: 'borrador',
    );

    await guardarPlanTrabajo(nuevoPlan);

    return nuevoPlan;
  }

  Future<void> actualizarDiaTrabajo(
    String semana,
    String liderId,
    String dia,
    DiaTrabajoModelo diaTrabajo,
  ) async {
    PlanTrabajoModelo? plan = await obtenerPlanTrabajo(semana, liderId);

    if (plan != null) {
      plan.dias[dia] = diaTrabajo;
      plan.fechaModificacion = DateTime.now();
      await guardarPlanTrabajo(plan);
    }
  }
}
