import 'dart:convert';
import '../modelos/hive/plan_trabajo_unificado_hive.dart';
import '../modelos/visita_cliente_modelo.dart';
import '../repositorios/plan_trabajo_unificado_repository.dart';
import '../servicios/sesion_servicio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitaClienteUnificadoService {
  static final VisitaClienteUnificadoService _instance = VisitaClienteUnificadoService._internal();
  factory VisitaClienteUnificadoService() => _instance;
  VisitaClienteUnificadoService._internal();

  final PlanTrabajoUnificadoRepository _repository = PlanTrabajoUnificadoRepository();

  /// Iniciar visita en el plan unificado
  Future<Map<String, dynamic>> iniciarVisitaEnPlanUnificado({
    required String planId,
    required String dia,
    required String clienteId,
    required CheckInModelo checkIn,
  }) async {
    try {
      print('🏁 Iniciando visita en plan unificado');
      print('   └── Plan ID: $planId');
      print('   └── Día: $dia');
      print('   └── Cliente ID: $clienteId');

      // Obtener el plan
      final plan = _repository.obtenerPlan(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado: $planId');
      }

      // Verificar que el día existe
      if (!plan.dias.containsKey(dia)) {
        throw Exception('Día no encontrado en el plan: $dia');
      }

      final diaPlan = plan.dias[dia]!;

      // Verificar si el cliente ya está en la lista de clientes FOCO
      bool esClienteFoco = diaPlan.clienteIds.contains(clienteId);
      
      // Si no es cliente FOCO, agregarlo a la lista
      if (!esClienteFoco) {
        print('📌 Cliente no es FOCO, agregando a la lista...');
        diaPlan.clienteIds.add(clienteId);
      }

      // Buscar o crear la visita del cliente
      VisitaClienteUnificadaHive? visitaCliente;
      
      // Buscar si ya existe una visita para este cliente
      for (var visita in diaPlan.clientes) {
        if (visita.clienteId == clienteId) {
          visitaCliente = visita;
          break;
        }
      }

      // Si no existe, crear nueva visita
      if (visitaCliente == null) {
        visitaCliente = VisitaClienteUnificadaHive(
          clienteId: clienteId,
          estatus: 'en_proceso',
        );
        diaPlan.clientes.add(visitaCliente);
      }

      // Actualizar datos de check-in
      visitaCliente.horaInicio = checkIn.timestamp.toIso8601String();
      visitaCliente.ubicacionInicio = UbicacionUnificadaHive(
        lat: checkIn.ubicacion.latitud,
        lon: checkIn.ubicacion.longitud,
      );
      visitaCliente.comentarioInicio = checkIn.comentarios;
      visitaCliente.estatus = 'en_proceso';
      visitaCliente.fechaModificacion = DateTime.now();

      // Actualizar el plan
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      
      // Guardar cambios
      await _repository.actualizarPlan(plan);

      print('✅ Visita iniciada exitosamente en plan unificado');
      print('   └── Cliente FOCO: ${esClienteFoco ? "Sí" : "No (agregado ahora)"}');

      return {
        'exitoso': true,
        'planId': planId,
        'clienteId': clienteId,
        'esNuevoClienteFoco': !esClienteFoco,
        'visitaId': '${planId}_${dia}_${clienteId}', // ID compuesto para referencia
      };
    } catch (e) {
      print('❌ Error al iniciar visita en plan unificado: $e');
      return {
        'exitoso': false,
        'error': e.toString(),
      };
    }
  }

  /// Actualizar formularios de la visita en el plan unificado
  Future<bool> actualizarFormulariosEnPlanUnificado({
    required String planId,
    required String dia,
    required String clienteId,
    required Map<String, dynamic> formularios,
  }) async {
    try {
      print('📝 Actualizando formularios en plan unificado');

      final plan = _repository.obtenerPlan(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado: $planId');
      }

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) {
        throw Exception('Día no encontrado en el plan: $dia');
      }

      // Buscar el índice de la visita del cliente
      final index = diaPlan.clientes.indexWhere((v) => v.clienteId == clienteId);
      if (index == -1) {
        throw Exception('Visita no encontrada para el cliente: $clienteId');
      }

      // Obtener la visita actual para modificarla
      final visitaCliente = diaPlan.clientes[index];

      // Convertir formularios a estructura del cuestionario
      if (formularios.containsKey('cuestionario')) {
        final cuestionarioData = formularios['cuestionario'] as Map<String, dynamic>;
        
        print('📋 Convirtiendo cuestionario:');
        print('   └── Tipo exhibidor: ${cuestionarioData['tipoExhibidor']}');
        print('   └── Estándares: ${cuestionarioData['estandaresEjecucion']}');
        print('   └── Disponibilidad: ${cuestionarioData['disponibilidad']}');
        
        visitaCliente.cuestionario = CuestionarioHive(
          tipoExhibidor: _convertirTipoExhibidor(cuestionarioData['tipoExhibidor']),
          estandaresEjecucion: _convertirEstandares(cuestionarioData['estandaresEjecucion']),
          disponibilidad: _convertirDisponibilidad(cuestionarioData['disponibilidad']),
        );
      }

      // Actualizar compromisos si existen
      if (formularios.containsKey('compromisos')) {
        final compromisosList = formularios['compromisos'] as List<dynamic>;
        visitaCliente.compromisos = compromisosList.map((c) => 
          CompromisoHive(
            tipo: c['tipo'] ?? '',
            detalle: c['detalle'] ?? '',
            cantidad: c['cantidad'] ?? 0,
            fechaPlazo: c['fecha'] ?? c['fechaPlazo'] ?? '',
          )
        ).toList();
      }

      // Actualizar retroalimentación y reconocimiento
      if (formularios.containsKey('retroalimentacion')) {
        visitaCliente.retroalimentacion = formularios['retroalimentacion'];
      }
      
      if (formularios.containsKey('reconocimiento')) {
        visitaCliente.reconocimiento = formularios['reconocimiento'];
      }

      visitaCliente.fechaModificacion = DateTime.now();

      // IMPORTANTE: Asignar la visita modificada de vuelta a la lista
      diaPlan.clientes[index] = visitaCliente;

      // Actualizar el plan
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      
      // Verificar datos antes de guardar
      print('📊 Datos de visita antes de guardar:');
      print('   └── Cuestionario: ${visitaCliente.cuestionario != null ? "Sí" : "No"}');
      if (visitaCliente.cuestionario != null) {
        print('       └── Tipo exhibidor: ${visitaCliente.cuestionario!.tipoExhibidor != null ? "Sí" : "No"}');
        print('       └── Estándares: ${visitaCliente.cuestionario!.estandaresEjecucion != null ? "Sí" : "No"}');
        print('       └── Disponibilidad: ${visitaCliente.cuestionario!.disponibilidad != null ? "Sí" : "No"}');
      }
      print('   └── Compromisos: ${visitaCliente.compromisos.length}');
      print('   └── Retroalimentación: ${visitaCliente.retroalimentacion != null ? "Sí (${visitaCliente.retroalimentacion!.length} chars)" : "No"}');
      print('   └── Reconocimiento: ${visitaCliente.reconocimiento != null ? "Sí (${visitaCliente.reconocimiento!.length} chars)" : "No"}');
      
      await _repository.actualizarPlan(plan);

      print('✅ Formularios actualizados exitosamente en plan unificado');
      return true;
    } catch (e) {
      print('❌ Error al actualizar formularios: $e');
      return false;
    }
  }

  /// Finalizar visita con check-out en el plan unificado
  Future<bool> finalizarVisitaEnPlanUnificado({
    required String planId,
    required String dia,
    required String clienteId,
    required CheckOutModelo checkOut,
  }) async {
    try {
      print('🏁 Finalizando visita en plan unificado');

      final plan = _repository.obtenerPlan(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado: $planId');
      }

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) {
        throw Exception('Día no encontrado en el plan: $dia');
      }

      // Buscar la visita del cliente
      VisitaClienteUnificadaHive? visitaCliente;
      for (var visita in diaPlan.clientes) {
        if (visita.clienteId == clienteId) {
          visitaCliente = visita;
          break;
        }
      }

      if (visitaCliente == null) {
        throw Exception('Visita no encontrada para el cliente: $clienteId');
      }

      // Actualizar con check-out
      visitaCliente.horaFin = checkOut.timestamp.toIso8601String();
      visitaCliente.estatus = 'terminado';
      visitaCliente.fechaModificacion = DateTime.now();

      // Actualizar el plan
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      
      await _repository.actualizarPlan(plan);

      print('✅ Visita finalizada exitosamente en plan unificado');
      return true;
    } catch (e) {
      print('❌ Error al finalizar visita: $e');
      return false;
    }
  }

  /// Obtener estado de visita desde el plan unificado
  Future<VisitaClienteUnificadaHive?> obtenerVisitaDesdeplan({
    required String planId,
    required String dia,
    required String clienteId,
  }) async {
    try {
      print('🔍 Obteniendo visita desde plan unificado:');
      print('   Plan ID: $planId');
      print('   Día: $dia');
      print('   Cliente ID: $clienteId');
      
      final plan = _repository.obtenerPlan(planId);
      if (plan == null) {
        print('❌ Plan no encontrado: $planId');
        return null;
      }
      print('✅ Plan encontrado');

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) {
        print('❌ Día no encontrado en el plan: $dia');
        print('   Días disponibles: ${plan.dias.keys.join(", ")}');
        return null;
      }
      print('✅ Día encontrado, clientes: ${diaPlan.clientes.length}');

      for (var visita in diaPlan.clientes) {
        print('   Comparando clienteId: ${visita.clienteId} con $clienteId');
        if (visita.clienteId == clienteId) {
          print('✅ Visita encontrada para cliente $clienteId');
          return visita;
        }
      }

      print('❌ No se encontró visita para el cliente: $clienteId');
      print('   Clientes en el día: ${diaPlan.clientes.map((v) => v.clienteId).join(", ")}');
      return null;
    } catch (e) {
      print('❌ Error al obtener visita: $e');
      return null;
    }
  }

  /// Guardar estado temporal del formulario
  Future<void> guardarEstadoFormularioTemporal({
    required String planId,
    required String dia,
    required String clienteId,
    required Map<String, dynamic> datosFormulario,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clave = 'formulario_temp_${planId}_${dia}_$clienteId';
      
      await prefs.setString(clave, jsonEncode(datosFormulario));
      print('✅ Estado temporal guardado');
    } catch (e) {
      print('❌ Error al guardar estado temporal: $e');
    }
  }

  /// Recuperar estado temporal del formulario
  Future<Map<String, dynamic>?> recuperarEstadoFormularioTemporal({
    required String planId,
    required String dia,
    required String clienteId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clave = 'formulario_temp_${planId}_${dia}_$clienteId';
      
      final datosJson = prefs.getString(clave);
      if (datosJson != null) {
        return jsonDecode(datosJson);
      }
      return null;
    } catch (e) {
      print('❌ Error al recuperar estado temporal: $e');
      return null;
    }
  }

  /// Limpiar estado temporal del formulario
  Future<void> limpiarEstadoFormularioTemporal({
    required String planId,
    required String dia,
    required String clienteId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clave = 'formulario_temp_${planId}_${dia}_$clienteId';
      
      await prefs.remove(clave);
      print('✅ Estado temporal limpiado');
    } catch (e) {
      print('❌ Error al limpiar estado temporal: $e');
    }
  }

  // Métodos auxiliares para conversión
  TipoExhibidorHive? _convertirTipoExhibidor(dynamic data) {
    if (data == null) return null;
    return TipoExhibidorHive(
      poseeAdecuado: data['poseeExhibidorAdecuado'] ?? false,
      tipo: data['tipoExhibidorSeleccionado'],
      modelo: data['modeloExhibidorSeleccionado'],
      cantidad: data['cantidadExhibidores'],
    );
  }

  EstandaresEjecucionHive? _convertirEstandares(dynamic data) {
    if (data == null) return null;
    return EstandaresEjecucionHive(
      primeraPosicion: data['primeraPosition'] ?? false,
      planograma: data['planograma'] ?? false,
      portafolioFoco: data['portafolioFoco'] ?? false,
      anclaje: data['anclaje'] ?? false,
    );
  }

  DisponibilidadHive? _convertirDisponibilidad(dynamic data) {
    if (data == null) return null;
    return DisponibilidadHive(
      ristras: data['ristras'] ?? false,
      max: data['max'] ?? false,
      familiar: data['familiar'] ?? false,
      dulce: data['dulce'] ?? false,
      galleta: data['galleta'] ?? false,
    );
  }

  /// Verificar si un cliente es FOCO en el plan
  Future<bool> esClienteFoco({
    required String planId,
    required String dia,
    required String clienteId,
  }) async {
    try {
      final plan = _repository.obtenerPlan(planId);
      if (plan == null) return false;

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) return false;

      return diaPlan.clienteIds.contains(clienteId);
    } catch (e) {
      print('❌ Error al verificar cliente FOCO: $e');
      return false;
    }
  }

  /// Guardar resultado de formulario dinámico en el plan unificado
  Future<bool> guardarResultadoFormularioDinamico({
    required String planId,
    required String dia,
    required String clienteId,
    required String formularioId,
    required Map<String, dynamic> respuestas,
  }) async {
    try {
      print('📋 Guardando resultado de formulario dinámico');
      print('   └── Plan ID: $planId');
      print('   └── Día: $dia');
      print('   └── Cliente ID: $clienteId');
      print('   └── Formulario ID: $formularioId');

      final plan = _repository.obtenerPlan(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado: $planId');
      }

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) {
        throw Exception('Día no encontrado en el plan: $dia');
      }

      // Buscar si ya existe un formulario para este cliente y plantilla
      final indiceExistente = diaPlan.formularios.indexWhere(
        (f) => f.clienteId == clienteId && f.formularioId == formularioId,
      );

      final nuevoFormulario = FormularioDiaHive(
        formularioId: formularioId,
        clienteId: clienteId,
        respuestas: respuestas,
        fechaCaptura: DateTime.now(),
      );

      if (indiceExistente != -1) {
        // Actualizar formulario existente
        diaPlan.formularios[indiceExistente] = nuevoFormulario;
        print('📝 Formulario actualizado');
      } else {
        // Agregar nuevo formulario
        diaPlan.formularios.add(nuevoFormulario);
        print('📝 Nuevo formulario agregado');
      }

      // Actualizar el plan
      plan.fechaModificacion = DateTime.now();
      plan.sincronizado = false;
      
      await _repository.actualizarPlan(plan);

      print('✅ Resultado de formulario guardado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al guardar resultado de formulario: $e');
      return false;
    }
  }

  /// Obtener todos los formularios de un cliente en un día específico
  Future<List<FormularioDiaHive>> obtenerFormulariosCliente({
    required String planId,
    required String dia,
    required String clienteId,
  }) async {
    try {
      final plan = _repository.obtenerPlan(planId);
      if (plan == null) return [];

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) return [];

      return diaPlan.formularios
          .where((f) => f.clienteId == clienteId)
          .toList();
    } catch (e) {
      print('❌ Error al obtener formularios del cliente: $e');
      return [];
    }
  }

  /// Obtener un formulario específico
  Future<FormularioDiaHive?> obtenerFormulario({
    required String planId,
    required String dia,
    required String clienteId,
    required String formularioId,
  }) async {
    try {
      final plan = _repository.obtenerPlan(planId);
      if (plan == null) return null;

      final diaPlan = plan.dias[dia];
      if (diaPlan == null) return null;

      return diaPlan.formularios.firstWhere(
        (f) => f.clienteId == clienteId && f.formularioId == formularioId,
        orElse: () => null as FormularioDiaHive,
      );
    } catch (e) {
      print('❌ Error al obtener formulario: $e');
      return null;
    }
  }
}