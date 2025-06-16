// lib/servicios/plan_trabajo_servicio.dart
// VERSIÓN HTTP - Integrado con endpoints del servidor

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/plan_trabajo_modelo.dart';
import 'sesion_servicio.dart';

class PlanTrabajoServicio {
  static final PlanTrabajoServicio _instance = PlanTrabajoServicio._internal();
  factory PlanTrabajoServicio() => _instance;
  PlanTrabajoServicio._internal();

  // URL base del servidor - cambiar según tu configuración
  //static const String _baseUrl = 'http://localhost:60148/api/planes';
  //static const String _baseUrl = 'http://localhost:60148/api/planes';
  static const String _baseUrl =
      'https://guillermosofnux-001-site1.stempurl.com/api/planes';

  // Headers comunes para las peticiones
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Crear un nuevo plan de trabajo (POST)
  /// Se ejecuta cuando se configura el primer día
  Future<String> crearPlanTrabajo(String liderClave) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({'liderClave': liderClave}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['planId']; // Retorna el planId generado
      } else {
        throw Exception(
          'Error al crear plan: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión al crear plan: $e');
    }
  }

  /// Actualizar plan de trabajo por partes (PUT)
  /// Se ejecuta cada vez que se configura un día
  Future<void> actualizarPlanTrabajo(
    String planId,
    Map<String, dynamic> datos,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({'planId': planId, 'datos': datos}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al actualizar plan: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión al actualizar plan: $e');
    }
  }

  /// Obtener plan de trabajo por semana (GET)
  Future<PlanTrabajoModelo?> obtenerPlanTrabajo(
    String semana,
    String liderClave,
  ) async {
    try {
      // Extraer número de semana del formato "SEMANA 23 - 2025"
      final RegExp regex = RegExp(r'SEMANA (\d+) - (\d+)');
      final match = regex.firstMatch(semana);

      if (match == null) {
        throw Exception('Formato de semana inválido: $semana');
      }

      final numeroSemana = match.group(1)!;

      final response = await http.get(
        Uri.parse('$_baseUrl/$liderClave/semana/$numeroSemana'),
        headers: _headers,
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        // Verificar si la respuesta está vacía o no es JSON válido
        if (response.body.isEmpty) {
          print('Respuesta vacía del servidor');
          return null;
        }

        try {
          final data = jsonDecode(response.body);
          print('Parsed data: $data'); // Debug

          // Verificar si el servidor devuelve un mensaje de "no existe"
          if (data is Map && data.containsKey('mensaje')) {
            print('Servidor dice: ${data['mensaje']}');
            return null; // Plan no existe
          }

          return _convertirDesdePlanServidor(data);
        } catch (jsonError) {
          print('Error al parsear JSON: $jsonError');
          print('Contenido recibido: ${response.body}');
          return null; // Tratar como plan no encontrado
        }
      } else if (response.statusCode == 404) {
        print('Plan no encontrado para semana $numeroSemana (404)'); // Debug
        return null;
      } else if (response.statusCode >= 500) {
        print('Error del servidor (${response.statusCode}): ${response.body}');
        return null; // Error del servidor, tratar como plan no encontrado
      } else {
        // Verificar si hay un mensaje de error personalizado
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('mensaje')) {
            print('Error del servidor: ${errorData['mensaje']}');
            return null;
          }
        } catch (e) {
          // Si no se puede parsear como JSON, usar el body completo
          print('Error no parseado del servidor: ${response.body}');
          return null;
        }
        throw Exception(
          'Error al obtener plan: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error en obtenerPlanTrabajo: $e'); // Debug

      // Ser más específico sobre los tipos de error
      if (e.toString().contains('404') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('No existe plan') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('SocketException')) {
        print('Error de red o plan no encontrado, devolviendo null');
        return null;
      }

      // Para otros errores, también devolver null pero logear
      print('Error desconocido, tratando como plan no encontrado: $e');
      return null;
    }
  }

  /// Obtener todos los planes de un líder (GET)
  Future<List<PlanTrabajoModelo>> obtenerTodosLosPlanes(
    String liderClave,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lider/$liderClave'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((planData) => _convertirDesdePlanServidor(planData))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception(
          'Error al obtener planes: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      throw Exception('Error de conexión al obtener planes: $e');
    }
  }

  /// 🆕 NUEVO: Obtener el detalle de un plan específico por líder y semana
  /// Este método es específico para la pantalla de rutina diaria
  Future<Map<String, dynamic>?> obtenerDetallePlan(
    String liderClave,
    int semana,
  ) async {
    try {
      print('🔍 Obteniendo detalle del plan: $liderClave, semana $semana');

      final url = Uri.parse('$_baseUrl/$liderClave/semana/$semana');

      final response = await http
          .get(url, headers: _headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al obtener detalle del plan');
            },
          );

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print(
        '📄 Cuerpo de respuesta: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Verificar si es un mensaje de error del servidor
        if (data.containsKey('mensaje')) {
          print('⚠️ Mensaje del servidor: ${data['mensaje']}');
          return null; // No hay plan para esta semana
        }

        print('✅ Detalle del plan obtenido exitosamente');
        return data;
      } else if (response.statusCode == 404) {
        print('📭 Plan no encontrado para la semana $semana');
        return null;
      } else {
        print('❌ Error HTTP: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Error al obtener detalle del plan: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error en obtenerDetallePlan: $e');

      // Para errores de red, devolver null en lugar de rethrow
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('Timeout')) {
        print('🌐 Error de conectividad, devolviendo null');
        return null;
      }

      rethrow; // Para otros errores, propagar la excepción
    }
  }

  /// 🆕 NUEVO: Método auxiliar para extraer el número de semana de un planId
  int extraerNumeroSemana(String planId) {
    try {
      // Formato esperado: "LID001_SEM24"
      final regex = RegExp(r'SEM(\d+)');
      final match = regex.firstMatch(planId);

      if (match != null) {
        return int.parse(match.group(1)!);
      }

      return 0; // Valor por defecto si no se puede extraer
    } catch (e) {
      print('Error al extraer número de semana de $planId: $e');
      return 0;
    }
  }

  /// 🆕 NUEVO: Método auxiliar para obtener el planId a partir de un PlanTrabajoModelo
  String? obtenerPlanIdDesdePlan(PlanTrabajoModelo plan) {
    try {
      // Extraer número de semana del formato "SEMANA 23 - 2025"
      final RegExp regex = RegExp(r'SEMANA (\d+) - (\d+)');
      final match = regex.firstMatch(plan.semana);

      if (match != null) {
        final numeroSemana = match.group(1)!;
        return '${plan.liderId}_SEM$numeroSemana';
      }

      return null;
    } catch (e) {
      print('Error al obtener planId desde plan: $e');
      return null;
    }
  }

  /// Guardar plan de trabajo completo
  /// Decide si crear (POST) o actualizar (PUT) según si ya existe
  Future<void> guardarPlanTrabajo(PlanTrabajoModelo plan) async {
    try {
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider == null) {
        throw Exception('No hay sesión activa');
      }

      // Intentar obtener el plan existente
      final planExistente = await obtenerPlanTrabajo(plan.semana, lider.clave);

      if (planExistente == null) {
        // Plan no existe, crear nuevo
        final planId = await crearPlanTrabajo(lider.clave);

        // Actualizar con todos los datos del plan
        await actualizarPlanTrabajo(planId, _convertirADatosServidor(plan));
      } else {
        // Plan existe, solo actualizar
        final planId = _generarPlanId(lider.clave, plan.semana);
        await actualizarPlanTrabajo(planId, _convertirADatosServidor(plan));
      }
    } catch (e) {
      throw Exception('Error al guardar plan: $e');
    }
  }

  /// Actualizar un día específico de trabajo
  Future<void> actualizarDiaTrabajo(
    String semana,
    String liderClave,
    String dia,
    DiaTrabajoModelo diaTrabajo,
  ) async {
    try {
      final planId = _generarPlanId(liderClave, semana);

      // Crear estructura de datos para el día
      final datosDia = {dia.toLowerCase(): diaTrabajo.toJson()};

      await actualizarPlanTrabajo(planId, datosDia);
    } catch (e) {
      throw Exception('Error al actualizar día de trabajo: $e');
    }
  }

  /// Crear o obtener plan para una semana específica
  Future<PlanTrabajoModelo> obtenerOCrearPlanSemana({
    required String liderClave,
    required String liderNombre,
    required String centroDistribucion,
    required DateTime fechaInicioSemana,
  }) async {
    // Calcular datos de la semana
    final int numeroSemana =
        ((fechaInicioSemana
                        .difference(DateTime(fechaInicioSemana.year, 1, 1))
                        .inDays +
                    DateTime(fechaInicioSemana.year, 1, 1).weekday -
                    1) /
                7)
            .ceil();

    final String semana = 'SEMANA $numeroSemana - ${fechaInicioSemana.year}';
    final DateTime finSemana = fechaInicioSemana.add(const Duration(days: 4));

    // Intentar obtener plan existente
    PlanTrabajoModelo? planExistente = await obtenerPlanTrabajo(
      semana,
      liderClave,
    );

    if (planExistente != null) {
      return planExistente;
    }

    // Crear nuevo plan
    PlanTrabajoModelo nuevoPlan = PlanTrabajoModelo(
      semana: semana,
      fechaInicio:
          '${fechaInicioSemana.day.toString().padLeft(2, '0')}/${fechaInicioSemana.month.toString().padLeft(2, '0')}/${fechaInicioSemana.year}',
      fechaFin:
          '${finSemana.day.toString().padLeft(2, '0')}/${finSemana.month.toString().padLeft(2, '0')}/${fechaInicioSemana.year}',
      liderId: liderClave,
      liderNombre: liderNombre,
      centroDistribucion: centroDistribucion,
      estatus: 'borrador',
    );

    // Guardar el plan nuevo (esto ejecutará el POST automáticamente)
    await guardarPlanTrabajo(nuevoPlan);

    return nuevoPlan;
  }

  /// Obtener o crear plan para la semana actual
  Future<PlanTrabajoModelo> obtenerOCrearPlanSemanaActual({
    required String liderId,
    required String liderNombre,
    required String centroDistribucion,
  }) async {
    final DateTime ahora = DateTime.now();
    final DateTime inicioSemana = ahora.subtract(
      Duration(days: ahora.weekday - 1),
    );

    return await obtenerOCrearPlanSemana(
      liderClave: liderId,
      liderNombre: liderNombre,
      centroDistribucion: centroDistribucion,
      fechaInicioSemana: inicioSemana,
    );
  }

  // === MÉTODOS AUXILIARES ===

  /// Generar planId como lo hace el servidor: LIDERCLAVE_SEMnumero
  String _generarPlanId(String liderClave, String semana) {
    final RegExp regex = RegExp(r'SEMANA (\d+) - (\d+)');
    final match = regex.firstMatch(semana);

    if (match != null) {
      final numeroSemana = match.group(1)!;
      return '${liderClave}_SEM$numeroSemana';
    }

    throw Exception('Formato de semana inválido para generar planId: $semana');
  }

  /// Convertir datos del servidor a PlanTrabajoModelo
  PlanTrabajoModelo _convertirDesdePlanServidor(Map<String, dynamic> data) {
    print('Convirtiendo datos del servidor: $data'); // Debug

    // El servidor usa tanto "Datos" (mayúscula, vacío) como "datos" (minúscula, real)
    final Map<String, dynamic> datosFlexibles =
        data['datos'] ?? data['Datos'] ?? {};

    // Convertir días si existen
    Map<String, DiaTrabajoModelo> dias = {};
    if (datosFlexibles.isNotEmpty) {
      // La estructura del servidor es: datos.semana.lunes, datos.semana.martes, etc.
      Map<String, dynamic> semanaData = datosFlexibles['semana'] ?? {};

      semanaData.forEach((key, value) {
        if (value is Map<String, dynamic> &&
            [
              'lunes',
              'martes',
              'miércoles',
              'jueves',
              'viernes',
              'sábado',
            ].contains(key.toLowerCase())) {
          // Convertir la estructura del servidor a nuestro DiaTrabajoModelo
          final diaData = Map<String, dynamic>.from(value);

          // Mapear campos del servidor a nuestro modelo
          final diaModelo = DiaTrabajoModelo(
            dia: _capitalizarDia(key),
            objetivo: diaData['objetivo'],
            tipo: diaData['tipo'],
            centroDistribucion: diaData['centroDistribucion'],
            rutaId: diaData['rutaId'],
            rutaNombre: diaData['rutaNombre'],
            clientesAsignados: _convertirClientes(diaData['clientes'] ?? []),
          );

          dias[_capitalizarDia(key)] = diaModelo;
        }
      });
    }

    // Manejar el número de semana de manera segura
    int semana = 0;
    if (data['Semana'] != null) {
      if (data['Semana'] is int) {
        semana = data['Semana'];
      } else if (data['Semana'] is String) {
        semana = int.tryParse(data['Semana']) ?? 0;
      }
    }

    // Manejar fecha de creación de manera segura
    DateTime fechaCreacion = DateTime.now();
    try {
      final fechaStr = data['FechaCreacion'];
      if (fechaStr != null) {
        fechaCreacion = DateTime.parse(fechaStr);
      }
    } catch (e) {
      print('Error parsing fecha creación: $e'); // Debug
      fechaCreacion = DateTime.now();
    }

    final int year = fechaCreacion.year;

    // Calcular inicio y fin de semana de manera segura
    DateTime inicioSemana = DateTime.now();
    DateTime finSemana = DateTime.now();

    if (semana > 0) {
      try {
        final DateTime inicioAno = DateTime(year, 1, 1);
        inicioSemana = inicioAno.add(
          Duration(days: (semana - 1) * 7 - inicioAno.weekday + 1),
        );
        finSemana = inicioSemana.add(const Duration(days: 4));
      } catch (e) {
        print('Error calculando fechas de semana: $e'); // Debug
        inicioSemana = DateTime.now();
        finSemana = inicioSemana.add(const Duration(days: 4));
      }
    }

    // Obtener datos del líder de manera segura
    String liderClave = data['LiderClave'] ?? '';

    // Obtener datos adicionales desde el campo datos si existen
    String liderNombre = datosFlexibles['liderNombre'] ?? 'Líder $liderClave';
    String centroDistribucion =
        datosFlexibles['centroDistribucion'] ?? 'Centro de Distribución';
    String estatus =
        datosFlexibles['estatus'] ?? _determinarEstatus(datosFlexibles, dias);

    return PlanTrabajoModelo(
      semana: 'SEMANA $semana - $year',
      fechaInicio:
          '${inicioSemana.day.toString().padLeft(2, '0')}/${inicioSemana.month.toString().padLeft(2, '0')}/$year',
      fechaFin:
          '${finSemana.day.toString().padLeft(2, '0')}/${finSemana.month.toString().padLeft(2, '0')}/$year',
      liderId: liderClave,
      liderNombre: liderNombre,
      centroDistribucion: centroDistribucion,
      estatus: estatus,
      dias: dias,
      fechaCreacion: fechaCreacion,
      fechaModificacion:
          fechaCreacion, // El servidor no maneja modificación separada
      sincronizado: true, // Viene del servidor, está sincronizado
    );
  }

  /// Convertir clientes del formato del servidor a nuestro modelo
  List<ClienteAsignadoModelo> _convertirClientes(List<dynamic> clientesData) {
    return clientesData.map((clienteData) {
      if (clienteData is Map<String, dynamic>) {
        return ClienteAsignadoModelo(
          clienteId: clienteData['codigo'] ?? clienteData['clienteId'] ?? '',
          clienteNombre:
              clienteData['nombre'] ??
              clienteData['clienteNombre'] ??
              'Cliente ${clienteData['codigo'] ?? ''}',
          clienteDireccion:
              clienteData['direccion'] ?? clienteData['clienteDireccion'] ?? '',
          clienteTipo:
              clienteData['tipo'] ?? clienteData['clienteTipo'] ?? 'detalle',
        );
      }
      return ClienteAsignadoModelo(
        clienteId: clienteData.toString(),
        clienteNombre: 'Cliente $clienteData',
        clienteDireccion: '',
        clienteTipo: 'detalle',
      );
    }).toList();
  }

  /// Determinar estatus basado en si hay días configurados
  String _determinarEstatusPorDias(Map<String, DiaTrabajoModelo> dias) {
    if (dias.isEmpty) return 'borrador';

    bool todosConfigurados = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ].every((dia) => dias.containsKey(dia) && dias[dia]!.objetivo != null);

    return todosConfigurados ? 'enviado' : 'borrador';
  }

  /// Convertir PlanTrabajoModelo a datos para el servidor
  Map<String, dynamic> _convertirADatosServidor(PlanTrabajoModelo plan) {
    Map<String, dynamic> datos = {};

    // Agregar información general del plan
    datos['semana'] = plan.semana;
    datos['fechaInicio'] = plan.fechaInicio;
    datos['fechaFin'] = plan.fechaFin;
    datos['liderNombre'] = plan.liderNombre;
    datos['centroDistribucion'] = plan.centroDistribucion;
    datos['estatus'] = plan.estatus;

    // Agregar días configurados
    plan.dias.forEach((dia, diaModelo) {
      datos[dia.toLowerCase()] = diaModelo.toJson();
    });

    return datos;
  }

  /// Capitalizar nombre del día
  String _capitalizarDia(String dia) {
    final diasMap = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miércoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sábado': 'Sábado',
    };
    return diasMap[dia.toLowerCase()] ?? dia;
  }

  /// Determinar estatus basado en los datos y días configurados
  String _determinarEstatus(
    Map<String, dynamic> datos, [
    Map<String, DiaTrabajoModelo>? dias,
  ]) {
    // Si hay estatus explícito en los datos, usarlo
    if (datos.containsKey('estatus')) {
      return datos['estatus'];
    }

    // Si se pasan los días, determinar basado en configuración
    if (dias != null) {
      if (dias.isEmpty) return 'borrador';

      bool todosConfigurados = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
      ].every((dia) => dias.containsKey(dia) && dias[dia]!.objetivo != null);

      return todosConfigurados ? 'enviado' : 'borrador';
    }

    // Si tiene días configurados en datos, está en borrador, sino vacío
    final tieneDias = datos.keys.any(
      (key) => [
        'lunes',
        'martes',
        'miércoles',
        'jueves',
        'viernes',
        'sábado',
      ].contains(key.toLowerCase()),
    );

    return tieneDias ? 'borrador' : 'borrador';
  }

  // === MÉTODOS DE COMPATIBILIDAD (temporales) ===

  /// Métodos que mantenemos para compatibilidad con código existente
  Future<List<PlanTrabajoModelo>> obtenerPlanesNoSincronizados(
    String liderId,
  ) async {
    // Con HTTP todos están sincronizados, retornamos lista vacía
    return [];
  }

  Future<void> marcarComoSincronizado(String semana, String liderId) async {
    // Con HTTP no es necesario, pero mantenemos el método
    return;
  }
}
