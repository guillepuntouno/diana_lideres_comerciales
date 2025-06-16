// lib/servicios/visita_cliente_servicio.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/visita_cliente_modelo.dart';
import 'sesion_servicio.dart';

class VisitaClienteServicio {
  static final VisitaClienteServicio _instance =
      VisitaClienteServicio._internal();
  factory VisitaClienteServicio() => _instance;
  VisitaClienteServicio._internal();

  // URL base del servidor
  //static const String _baseUrl = 'http://localhost:60148/api/visitas';
  static const String _baseUrl =
      'https://guillermosofnux-001-site1.stempurl.com/api/visitas';

  // Headers comunes para las peticiones
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Crear una nueva visita con check-in inicial
  /// POST /api/visitas
  Future<VisitaClienteModelo> crearVisitaConCheckIn({
    required String claveVisita,
    required String liderClave,
    required String clienteId,
    required String clienteNombre,
    required String planId,
    required String dia,
    required CheckInModelo checkIn,
  }) async {
    try {
      print('🏁 Creando visita con check-in: $claveVisita');

      final body = {
        'claveVisita': claveVisita,
        'liderClave': liderClave,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'planId': planId,
        'dia': dia,
        'checkIn': checkIn.toJson(),
      };

      print('📤 Enviando datos: ${jsonEncode(body)}');

      final response = await http
          .post(Uri.parse(_baseUrl), headers: _headers, body: jsonEncode(body))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout al crear visita');
            },
          );

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📄 Cuerpo: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Verificar si hay mensaje de error
        if (data is Map && data.containsKey('mensaje')) {
          throw Exception('Error del servidor: ${data['mensaje']}');
        }

        final visita = VisitaClienteModelo.fromJson(data);
        print('✅ Visita creada exitosamente');
        return visita;
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al crear visita: $e');
      rethrow;
    }
  }

  /// Obtener una visita específica por clave
  /// GET /api/visitas/{claveVisita}
  Future<VisitaClienteModelo?> obtenerVisita(String claveVisita) async {
    try {
      print('🔍 Obteniendo visita: $claveVisita');

      final response = await http
          .get(Uri.parse('$_baseUrl/$claveVisita'), headers: _headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al obtener visita');
            },
          );

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Verificar si hay mensaje de "no existe"
        if (data is Map && data.containsKey('mensaje')) {
          print('⚠️ ${data['mensaje']}');
          return null;
        }

        final visita = VisitaClienteModelo.fromJson(data);
        print('✅ Visita obtenida exitosamente');
        return visita;
      } else if (response.statusCode == 404) {
        print('📭 Visita no encontrada');
        return null;
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al obtener visita: $e');

      // Para errores de red, devolver null
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Timeout')) {
        return null;
      }

      rethrow;
    }
  }

  /// Actualizar formularios de la visita
  /// PUT /api/visitas/{claveVisita}/formularios
  Future<void> actualizarFormularios(
    String claveVisita,
    Map<String, dynamic> formularios,
  ) async {
    try {
      print('📝 Actualizando formularios para: $claveVisita');
      print('📋 Formularios: ${jsonEncode(formularios)}');

      final body = {'formularios': formularios};

      final response = await http
          .put(
            Uri.parse('$_baseUrl/$claveVisita/formularios'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout al actualizar formularios');
            },
          );

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }

      print('✅ Formularios actualizados exitosamente');
    } catch (e) {
      print('❌ Error al actualizar formularios: $e');
      rethrow;
    }
  }

  /// Finalizar visita con check-out
  /// PUT /api/visitas/{claveVisita}/checkout
  Future<VisitaClienteModelo> finalizarVisitaConCheckOut(
    String claveVisita,
    CheckOutModelo checkOut,
  ) async {
    try {
      print('🏁 Finalizando visita: $claveVisita');

      final response = await http
          .put(
            Uri.parse('$_baseUrl/$claveVisita/checkout'),
            headers: _headers,
            body: jsonEncode(checkOut.toJson()),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout al finalizar visita');
            },
          );

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final visita = VisitaClienteModelo.fromJson(data);
        print('✅ Visita finalizada exitosamente');
        return visita;
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al finalizar visita: $e');
      rethrow;
    }
  }

  /// Cancelar una visita
  /// PUT /api/visitas/{claveVisita}/cancelar
  Future<void> cancelarVisita(String claveVisita, String motivo) async {
    try {
      print('❌ Cancelando visita: $claveVisita');
      print('📝 Motivo: $motivo');

      final body = {'motivo': motivo};

      final response = await http
          .put(
            Uri.parse('$_baseUrl/$claveVisita/cancelar'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al cancelar visita');
            },
          );

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }

      print('✅ Visita cancelada exitosamente');
    } catch (e) {
      print('❌ Error al cancelar visita: $e');
      rethrow;
    }
  }

  /// Obtener todas las visitas de un líder
  /// GET /api/visitas/lider/{liderClave}
  Future<List<VisitaClienteModelo>> obtenerVisitasPorLider(
    String liderClave,
  ) async {
    try {
      print('👥 Obteniendo visitas del líder: $liderClave');

      final response = await http
          .get(Uri.parse('$_baseUrl/lider/$liderClave'), headers: _headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout al obtener visitas del líder');
            },
          );

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('mensaje')) {
          print('⚠️ ${data['mensaje']}');
          return [];
        }

        if (data is List) {
          final visitas =
              data
                  .map((visitaData) => VisitaClienteModelo.fromJson(visitaData))
                  .toList();
          print('✅ ${visitas.length} visitas obtenidas');
          return visitas;
        }

        return [];
      } else if (response.statusCode == 404) {
        print('📭 No hay visitas para este líder');
        return [];
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al obtener visitas: $e');

      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Timeout')) {
        return [];
      }

      rethrow;
    }
  }

  /// Obtener visitas por día específico
  /// GET /api/visitas/lider/{liderClave}/dia/{dia}
  Future<List<VisitaClienteModelo>> obtenerVisitasPorDia(
    String liderClave,
    String dia,
  ) async {
    try {
      print('📅 Obteniendo visitas del día $dia para líder: $liderClave');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/lider/$liderClave/dia/$dia'),
            headers: _headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al obtener visitas del día');
            },
          );

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('mensaje')) {
          return [];
        }

        if (data is List) {
          final visitas =
              data
                  .map((visitaData) => VisitaClienteModelo.fromJson(visitaData))
                  .toList();
          print('✅ ${visitas.length} visitas del día obtenidas');
          return visitas;
        }

        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener visitas del día: $e');
      return [];
    }
  }

  /// Generar clave de visita automáticamente
  String generarClaveVisita({
    required String liderClave,
    required int numeroSemana,
    required String dia,
    required String clienteId,
  }) {
    final clave =
        '${liderClave}_${numeroSemana}_${dia.toLowerCase()}_$clienteId';
    print('🔑 Clave generada: $clave');
    return clave;
  }

  /// Método de conveniencia para crear visita con datos actuales
  Future<VisitaClienteModelo> crearVisitaDesdeActividad({
    required String clienteId,
    required String clienteNombre,
    required String dia,
    required CheckInModelo checkIn,
    String? planId,
  }) async {
    try {
      // Obtener datos de la sesión
      final lider = await SesionServicio.obtenerLiderComercial();
      if (lider == null) {
        throw Exception('No hay sesión activa del líder');
      }

      // Generar clave de visita
      final claveVisita = generarClaveVisita(
        liderClave: lider.clave,
        numeroSemana: _obtenerSemanaActual(),
        dia: dia,
        clienteId: clienteId,
      );

      // Crear visita
      return await crearVisitaConCheckIn(
        claveVisita: claveVisita,
        liderClave: lider.clave,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        planId: planId ?? 'SIN_PLAN',
        dia: dia,
        checkIn: checkIn,
      );
    } catch (e) {
      print('❌ Error al crear visita desde actividad: $e');
      rethrow;
    }
  }

  /// Obtener número de semana actual
  int _obtenerSemanaActual() {
    final ahora = DateTime.now();
    return ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                DateTime(ahora.year, 1, 1).weekday -
                1) /
            7)
        .ceil();
  }

  /// Verificar si una visita ya existe
  Future<bool> existeVisita(String claveVisita) async {
    try {
      final visita = await obtenerVisita(claveVisita);
      return visita != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener estadísticas de visitas
  Future<Map<String, dynamic>> obtenerEstadisticas(String liderClave) async {
    try {
      final visitas = await obtenerVisitasPorLider(liderClave);

      return {
        'total': visitas.length,
        'completadas': visitas.where((v) => v.estatus == 'completada').length,
        'enProceso': visitas.where((v) => v.estatus == 'en_proceso').length,
        'canceladas': visitas.where((v) => v.estatus == 'cancelada').length,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {'total': 0, 'completadas': 0, 'enProceso': 0, 'canceladas': 0};
    }
  }
}
