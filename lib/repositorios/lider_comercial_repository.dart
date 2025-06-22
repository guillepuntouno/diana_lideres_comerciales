import '../modelos/hive/lider_comercial_hive.dart';
import '../servicios/hive_service.dart';

class LiderComercialRepository {
  static final LiderComercialRepository _instance = LiderComercialRepository._internal();
  factory LiderComercialRepository() => _instance;
  LiderComercialRepository._internal();

  final HiveService _hiveService = HiveService();

  /// Guarda o actualiza un líder comercial
  Future<void> save(LiderComercialHive lider) async {
    try {
      if (!_hiveService.isInitialized) {
        throw Exception('HiveService no ha sido inicializado. Llama a initialize() primero.');
      }
      
      lider.lastUpdated = DateTime.now();
      await _hiveService.lideresComerciales.put(lider.id, lider);
      print('✅ Líder comercial guardado: ${lider.clave}');
    } catch (e) {
      print('❌ Error guardando líder comercial: $e');
      rethrow;
    }
  }

  /// Guarda múltiples líderes comerciales
  Future<void> saveAll(List<LiderComercialHive> lideres) async {
    try {
      final Map<String, LiderComercialHive> lideresMap = {};
      for (final lider in lideres) {
        lider.lastUpdated = DateTime.now();
        lideresMap[lider.id] = lider;
      }
      await _hiveService.lideresComerciales.putAll(lideresMap);
      print('✅ ${lideres.length} líderes comerciales guardados');
    } catch (e) {
      print('❌ Error guardando líderes comerciales: $e');
      rethrow;
    }
  }

  /// Obtiene un líder por ID
  LiderComercialHive? getById(String id) {
    try {
      return _hiveService.lideresComerciales.get(id);
    } catch (e) {
      print('❌ Error obteniendo líder comercial: $e');
      return null;
    }
  }

  /// Obtiene un líder por clave
  LiderComercialHive? getByClave(String clave) {
    try {
      if (!_hiveService.isInitialized) {
        throw Exception('HiveService no ha sido inicializado. Llama a initialize() primero.');
      }
      
      final lideres = _hiveService.lideresComerciales.values
          .where((lider) => lider.clave == clave);
      return lideres.isNotEmpty ? lideres.first : null;
    } catch (e) {
      print('❌ Error obteniendo líder por clave: $e');
      return null;
    }
  }

  /// Obtiene todos los líderes comerciales
  List<LiderComercialHive> getAll() {
    try {
      return _hiveService.lideresComerciales.values.toList();
    } catch (e) {
      print('❌ Error obteniendo todos los líderes: $e');
      return [];
    }
  }

  /// Obtiene líderes por centro de distribución
  List<LiderComercialHive> getByCentroDistribucion(String centroDistribucion) {
    try {
      return _hiveService.lideresComerciales.values
          .where((lider) => lider.centroDistribucion == centroDistribucion)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo líderes por centro: $e');
      return [];
    }
  }

  /// Obtiene líderes por país
  List<LiderComercialHive> getByPais(String pais) {
    try {
      return _hiveService.lideresComerciales.values
          .where((lider) => lider.pais == pais)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo líderes por país: $e');
      return [];
    }
  }

  /// Busca líderes por nombre
  List<LiderComercialHive> searchByNombre(String query) {
    try {
      final queryLower = query.toLowerCase();
      return _hiveService.lideresComerciales.values
          .where((lider) => lider.nombre.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      print('❌ Error buscando líderes por nombre: $e');
      return [];
    }
  }

  /// Obtiene rutas de un líder específico
  List<RutaHive> getRutasByLider(String liderClave) {
    try {
      final lider = getByClave(liderClave);
      return lider?.rutas ?? [];
    } catch (e) {
      print('❌ Error obteniendo rutas del líder: $e');
      return [];
    }
  }

  /// Obtiene una ruta específica de un líder
  RutaHive? getRutaById(String liderClave, String rutaId) {
    try {
      final rutas = getRutasByLider(liderClave);
      final rutasFiltradas = rutas.where((ruta) => ruta.id == rutaId);
      return rutasFiltradas.isNotEmpty ? rutasFiltradas.first : null;
    } catch (e) {
      print('❌ Error obteniendo ruta específica: $e');
      return null;
    }
  }

  /// Obtiene negocios de una ruta específica
  List<NegocioHive> getNegociosByRuta(String liderClave, String rutaId) {
    try {
      final ruta = getRutaById(liderClave, rutaId);
      return ruta?.negocios ?? [];
    } catch (e) {
      print('❌ Error obteniendo negocios de la ruta: $e');
      return [];
    }
  }

  /// Obtiene todos los negocios de un líder
  List<NegocioHive> getAllNegociosByLider(String liderClave) {
    try {
      final rutas = getRutasByLider(liderClave);
      final List<NegocioHive> todosLosNegocios = [];
      
      for (final ruta in rutas) {
        todosLosNegocios.addAll(ruta.negocios);
      }
      
      return todosLosNegocios;
    } catch (e) {
      print('❌ Error obteniendo todos los negocios del líder: $e');
      return [];
    }
  }

  /// Busca negocios por nombre en todas las rutas de un líder
  List<NegocioHive> searchNegociosByNombre(String liderClave, String query) {
    try {
      final negocios = getAllNegociosByLider(liderClave);
      final queryLower = query.toLowerCase();
      
      return negocios
          .where((negocio) => negocio.nombre.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      print('❌ Error buscando negocios por nombre: $e');
      return [];
    }
  }

  /// Obtiene negocios por canal
  List<NegocioHive> getNegociosByCanal(String liderClave, String canal) {
    try {
      final negocios = getAllNegociosByLider(liderClave);
      return negocios
          .where((negocio) => negocio.canal == canal)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo negocios por canal: $e');
      return [];
    }
  }

  /// Obtiene un negocio específico por clave
  NegocioHive? getNegocioByClave(String liderClave, String negocioClave) {
    try {
      final negocios = getAllNegociosByLider(liderClave);
      final negociosFiltrados = negocios
          .where((negocio) => negocio.clave == negocioClave);
      return negociosFiltrados.isNotEmpty ? negociosFiltrados.first : null;
    } catch (e) {
      print('❌ Error obteniendo negocio por clave: $e');
      return null;
    }
  }

  /// Agrega una nueva ruta a un líder
  Future<void> agregarRuta(String liderClave, RutaHive nuevaRuta) async {
    try {
      final lider = getByClave(liderClave);
      if (lider != null) {
        lider.rutas.add(nuevaRuta);
        lider.syncStatus = 'pending';
        await save(lider);
        print('✅ Ruta agregada al líder: $liderClave');
      } else {
        throw Exception('Líder no encontrado: $liderClave');
      }
    } catch (e) {
      print('❌ Error agregando ruta: $e');
      rethrow;
    }
  }

  /// Remueve una ruta de un líder
  Future<void> removerRuta(String liderClave, String rutaId) async {
    try {
      final lider = getByClave(liderClave);
      if (lider != null) {
        lider.rutas.removeWhere((ruta) => ruta.id == rutaId);
        lider.syncStatus = 'pending';
        await save(lider);
        print('✅ Ruta removida del líder: $liderClave');
      } else {
        throw Exception('Líder no encontrado: $liderClave');
      }
    } catch (e) {
      print('❌ Error removiendo ruta: $e');
      rethrow;
    }
  }

  /// Actualiza una ruta específica
  Future<void> actualizarRuta(String liderClave, RutaHive rutaActualizada) async {
    try {
      final lider = getByClave(liderClave);
      if (lider != null) {
        final index = lider.rutas.indexWhere((ruta) => ruta.id == rutaActualizada.id);
        if (index >= 0) {
          lider.rutas[index] = rutaActualizada;
          lider.syncStatus = 'pending';
          await save(lider);
          print('✅ Ruta actualizada para líder: $liderClave');
        } else {
          throw Exception('Ruta no encontrada en el líder');
        }
      } else {
        throw Exception('Líder no encontrado: $liderClave');
      }
    } catch (e) {
      print('❌ Error actualizando ruta: $e');
      rethrow;
    }
  }

  /// Elimina un líder comercial
  Future<void> delete(String id) async {
    try {
      await _hiveService.lideresComerciales.delete(id);
      print('✅ Líder comercial eliminado: $id');
    } catch (e) {
      print('❌ Error eliminando líder comercial: $e');
      rethrow;
    }
  }

  /// Elimina todos los líderes comerciales
  Future<void> deleteAll() async {
    try {
      await _hiveService.lideresComerciales.clear();
      print('✅ Todos los líderes comerciales eliminados');
    } catch (e) {
      print('❌ Error eliminando todos los líderes: $e');
      rethrow;
    }
  }

  /// Marca un líder como sincronizado
  Future<void> markAsSynced(String id) async {
    try {
      final lider = getById(id);
      if (lider != null) {
        lider.syncStatus = 'synced';
        lider.lastUpdated = DateTime.now();
        await lider.save();
        print('✅ Líder marcado como sincronizado: $id');
      }
    } catch (e) {
      print('❌ Error marcando líder como sincronizado: $e');
      rethrow;
    }
  }

  /// Obtiene estadísticas de líderes comerciales
  Map<String, dynamic> getEstadisticas() {
    try {
      final lideres = getAll();
      
      // Contar por país
      final Map<String, int> porPais = {};
      for (final lider in lideres) {
        porPais[lider.pais] = (porPais[lider.pais] ?? 0) + 1;
      }
      
      // Contar por centro de distribución
      final Map<String, int> porCentro = {};
      for (final lider in lideres) {
        porCentro[lider.centroDistribucion] = (porCentro[lider.centroDistribucion] ?? 0) + 1;
      }
      
      // Contar rutas y negocios totales
      int totalRutas = 0;
      int totalNegocios = 0;
      for (final lider in lideres) {
        totalRutas += lider.rutas.length;
        for (final ruta in lider.rutas) {
          totalNegocios += ruta.negocios.length;
        }
      }
      
      return {
        'total_lideres': lideres.length,
        'por_pais': porPais,
        'por_centro_distribucion': porCentro,
        'total_rutas': totalRutas,
        'total_negocios': totalNegocios,
        'promedio_rutas_por_lider': lideres.isNotEmpty ? totalRutas / lideres.length : 0.0,
        'promedio_negocios_por_lider': lideres.isNotEmpty ? totalNegocios / lideres.length : 0.0,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Obtiene todos los centros de distribución únicos
  List<String> getCentrosDistribucion() {
    try {
      final centros = _hiveService.lideresComerciales.values
          .map((lider) => lider.centroDistribucion)
          .toSet()
          .toList();
      centros.sort();
      return centros;
    } catch (e) {
      print('❌ Error obteniendo centros de distribución: $e');
      return [];
    }
  }

  /// Obtiene todos los países únicos
  List<String> getPaises() {
    try {
      final paises = _hiveService.lideresComerciales.values
          .map((lider) => lider.pais)
          .toSet()
          .toList();
      paises.sort();
      return paises;
    } catch (e) {
      print('❌ Error obteniendo países: $e');
      return [];
    }
  }

  /// Obtiene todos los canales únicos
  List<String> getCanales() {
    try {
      final Set<String> canales = {};
      for (final lider in _hiveService.lideresComerciales.values) {
        for (final ruta in lider.rutas) {
          for (final negocio in ruta.negocios) {
            canales.add(negocio.canal);
          }
        }
      }
      final listaCanales = canales.toList();
      listaCanales.sort();
      return listaCanales;
    } catch (e) {
      print('❌ Error obteniendo canales: $e');
      return [];
    }
  }

  /// Verifica si existe un líder con la clave dada
  bool existeLiderConClave(String clave) {
    try {
      return getByClave(clave) != null;
    } catch (e) {
      print('❌ Error verificando existencia de líder: $e');
      return false;
    }
  }

  /// Actualiza solo la información básica del líder (sin rutas)
  Future<void> actualizarInfoBasica(String liderClave, {
    String? nombre,
    String? centroDistribucion,
    String? pais,
  }) async {
    try {
      final lider = getByClave(liderClave);
      if (lider != null) {
        if (nombre != null) lider.nombre = nombre;
        if (centroDistribucion != null) lider.centroDistribucion = centroDistribucion;
        if (pais != null) lider.pais = pais;
        
        lider.syncStatus = 'pending';
        await save(lider);
        print('✅ Información básica actualizada para líder: $liderClave');
      } else {
        throw Exception('Líder no encontrado: $liderClave');
      }
    } catch (e) {
      print('❌ Error actualizando información básica: $e');
      rethrow;
    }
  }
}