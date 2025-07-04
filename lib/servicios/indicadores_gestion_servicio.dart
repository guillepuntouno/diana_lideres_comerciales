// lib/servicios/indicadores_gestion_servicio.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/indicador_gestion_modelo.dart';

class IndicadoresGestionServicio {
  static const String _keyIndicadores = 'indicadores_gestion';
  static const String _keyClienteIndicadores = 'cliente_indicadores';
  
  // Singleton
  static final IndicadoresGestionServicio _instance = IndicadoresGestionServicio._internal();
  factory IndicadoresGestionServicio() => _instance;
  IndicadoresGestionServicio._internal();

  // Cache en memoria
  List<IndicadorGestionModelo>? _indicadoresCache;
  Map<String, ClienteIndicadorModelo> _clienteIndicadoresCache = {};

  /// Obtiene el catálogo de indicadores
  Future<List<IndicadorGestionModelo>> obtenerIndicadores() async {
    // Si ya están en cache, devolverlos
    if (_indicadoresCache != null) {
      return _indicadoresCache!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final indicadoresJson = prefs.getString(_keyIndicadores);
      
      if (indicadoresJson != null) {
        final List<dynamic> decodedList = jsonDecode(indicadoresJson);
        _indicadoresCache = decodedList
            .map((json) => IndicadorGestionModelo.fromJson(json))
            .toList();
      } else {
        // Si no hay indicadores guardados, usar el catálogo inicial
        _indicadoresCache = CatalogoIndicadores.indicadoresIniciales;
        await _guardarIndicadores(_indicadoresCache!);
      }
      
      // Ordenar por el campo orden
      _indicadoresCache!.sort((a, b) => a.orden.compareTo(b.orden));
      
      return _indicadoresCache!;
    } catch (e) {
      print('Error al obtener indicadores: $e');
      // En caso de error, devolver el catálogo inicial
      return CatalogoIndicadores.indicadoresIniciales;
    }
  }

  /// Guarda los indicadores en el almacenamiento local
  Future<void> _guardarIndicadores(List<IndicadorGestionModelo> indicadores) async {
    final prefs = await SharedPreferences.getInstance();
    final indicadoresJson = jsonEncode(
      indicadores.map((i) => i.toJson()).toList()
    );
    await prefs.setString(_keyIndicadores, indicadoresJson);
  }

  /// Guarda los indicadores seleccionados para un cliente
  Future<void> guardarIndicadoresCliente(ClienteIndicadorModelo clienteIndicador) async {
    try {
      // Guardar en cache
      _clienteIndicadoresCache[clienteIndicador.clienteId] = clienteIndicador;
      
      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final clienteIndicadoresJson = prefs.getString(_keyClienteIndicadores) ?? '{}';
      final Map<String, dynamic> clienteIndicadoresMap = jsonDecode(clienteIndicadoresJson);
      
      // Agregar o actualizar el cliente
      clienteIndicadoresMap[clienteIndicador.clienteId] = clienteIndicador.toJson();
      
      // Guardar de vuelta
      await prefs.setString(_keyClienteIndicadores, jsonEncode(clienteIndicadoresMap));
      
      print('Indicadores guardados para cliente ${clienteIndicador.clienteId}');
    } catch (e) {
      print('Error al guardar indicadores del cliente: $e');
      rethrow;
    }
  }

  /// Obtiene los indicadores guardados para un plan y día específico
  Future<Map<String, ClienteIndicadorModelo>> obtenerIndicadoresPorPlan(
    String planVisitaId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clienteIndicadoresJson = prefs.getString(_keyClienteIndicadores) ?? '{}';
      final Map<String, dynamic> todosLosIndicadores = jsonDecode(clienteIndicadoresJson);
      
      final Map<String, ClienteIndicadorModelo> indicadoresPlan = {};
      
      todosLosIndicadores.forEach((clienteId, indicadorJson) {
        final indicador = ClienteIndicadorModelo.fromJson(indicadorJson);
        if (indicador.planVisitaId == planVisitaId) {
          indicadoresPlan[clienteId] = indicador;
        }
      });
      
      return indicadoresPlan;
    } catch (e) {
      print('Error al obtener indicadores del plan: $e');
      return {};
    }
  }

  /// Obtiene los indicadores para un cliente específico
  Future<ClienteIndicadorModelo?> obtenerIndicadoresCliente(
    String clienteId,
    String planVisitaId,
  ) async {
    // Primero buscar en cache
    if (_clienteIndicadoresCache.containsKey(clienteId)) {
      final indicador = _clienteIndicadoresCache[clienteId]!;
      if (indicador.planVisitaId == planVisitaId) {
        return indicador;
      }
    }
    
    // Si no está en cache, buscar en SharedPreferences
    final indicadoresPlan = await obtenerIndicadoresPorPlan(planVisitaId);
    return indicadoresPlan[clienteId];
  }

  /// Cuenta cuántos clientes tienen indicadores asignados
  Future<int> contarClientesConIndicadores(
    String planVisitaId,
    List<String> clienteIds,
  ) async {
    final indicadoresPlan = await obtenerIndicadoresPorPlan(planVisitaId);
    int contador = 0;
    
    for (final clienteId in clienteIds) {
      if (indicadoresPlan.containsKey(clienteId) && 
          indicadoresPlan[clienteId]!.indicadorIds.isNotEmpty) {
        contador++;
      }
    }
    
    return contador;
  }

  /// Verifica si todos los clientes tienen indicadores asignados
  Future<bool> todosLosClientesTienenIndicadores(
    String planVisitaId,
    List<String> clienteIds,
  ) async {
    final clientesConIndicadores = await contarClientesConIndicadores(planVisitaId, clienteIds);
    return clientesConIndicadores == clienteIds.length;
  }

  /// Limpia los indicadores de un plan específico
  Future<void> limpiarIndicadoresPlan(String planVisitaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clienteIndicadoresJson = prefs.getString(_keyClienteIndicadores) ?? '{}';
      final Map<String, dynamic> todosLosIndicadores = jsonDecode(clienteIndicadoresJson);
      
      // Remover indicadores del plan
      todosLosIndicadores.removeWhere((clienteId, indicadorJson) {
        final indicador = ClienteIndicadorModelo.fromJson(indicadorJson);
        return indicador.planVisitaId == planVisitaId;
      });
      
      // Guardar de vuelta
      await prefs.setString(_keyClienteIndicadores, jsonEncode(todosLosIndicadores));
      
      // Limpiar cache
      _clienteIndicadoresCache.removeWhere((clienteId, indicador) {
        return indicador.planVisitaId == planVisitaId;
      });
    } catch (e) {
      print('Error al limpiar indicadores del plan: $e');
    }
  }

  /// Obtiene un resumen de los indicadores para mostrar
  Future<List<Map<String, dynamic>>> obtenerResumenIndicadores(
    String planVisitaId,
    List<String> clienteIds,
  ) async {
    final indicadoresPlan = await obtenerIndicadoresPorPlan(planVisitaId);
    final indicadores = await obtenerIndicadores();
    final resumen = <Map<String, dynamic>>[];
    
    for (final clienteId in clienteIds) {
      if (indicadoresPlan.containsKey(clienteId)) {
        final clienteIndicador = indicadoresPlan[clienteId]!;
        final indicadoresNombres = <String>[];
        
        for (final indicadorId in clienteIndicador.indicadorIds) {
          final indicador = indicadores.firstWhere(
            (i) => i.id == indicadorId,
            orElse: () => IndicadorGestionModelo(
              id: indicadorId,
              nombre: 'Indicador desconocido',
              descripcion: '',
              tipoResultado: 'numero',
            ),
          );
          indicadoresNombres.add(indicador.nombre);
        }
        
        resumen.add({
          'clienteId': clienteId,
          'clienteNombre': clienteIndicador.clienteNombre,
          'indicadores': indicadoresNombres,
          'resultados': clienteIndicador.resultados,
          'comentario': clienteIndicador.comentario,
          'completado': clienteIndicador.completado,
        });
      }
    }
    
    return resumen;
  }

  /// Limpia toda la cache
  void limpiarCache() {
    _indicadoresCache = null;
    _clienteIndicadoresCache.clear();
  }
}