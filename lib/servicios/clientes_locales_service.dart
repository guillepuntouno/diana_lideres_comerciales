import 'package:hive/hive.dart';
import '../modelos/hive/cliente_hive.dart';
import '../modelos/lider_comercial_modelo.dart';
import './hive_service.dart';

class ClientesLocalesService {
  static const String _boxName = 'clientes'; // Usar el nombre correcto de la caja
  static ClientesLocalesService? _instance;
  late Box<ClienteHive> _box;
  bool _initialized = false;
  final HiveService _hiveService = HiveService();

  ClientesLocalesService._internal();

  factory ClientesLocalesService() {
    _instance ??= ClientesLocalesService._internal();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Asegurarse de que HiveService esté inicializado
      if (!_hiveService.isInitialized) {
        await _hiveService.initialize();
      }
      
      // Obtener la caja de clientes del HiveService
      _box = _hiveService.clientesBox;
      _initialized = true;
      print('✅ ClientesLocalesService inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar ClientesLocalesService: $e');
      throw Exception('No se pudo inicializar el servicio de clientes locales');
    }
  }

  /// Guarda una lista de clientes desde el formato JSON del endpoint
  /// Evita duplicados verificando por CODIGO_CLIENTE
  Future<void> guardarClientesDesdeJson(
    List<Map<String, dynamic>> clientesJson, {
    String? rutaId,
    String? rutaNombre,
    String? asesorId,
    String? asesorNombre,
    String? codigoLider,
    String? nombreLider,
    String? emailLider,
    String? centroDistribucion,
  }) async {
    if (!_initialized) await initialize();

    int nuevos = 0;
    int actualizados = 0;
    
    for (var clienteJson in clientesJson) {
      final codigoCliente = clienteJson['CODIGO_CLIENTE']?.toString();
      
      if (codigoCliente == null || codigoCliente.isEmpty) {
        print('⚠️ Cliente sin CODIGO_CLIENTE, omitiendo...');
        continue;
      }

      try {
        final clienteHive = ClienteHive.fromNegocio(
          clienteJson,
          rutaId: rutaId,
          rutaNombre: rutaNombre,
          asesorId: asesorId,
          asesorNombre: asesorNombre,
          codigoLider: codigoLider,
          nombreLider: nombreLider,
          emailLider: emailLider,
          centroDistribucion: centroDistribucion,
        );

        // Verificar si ya existe
        final existente = _box.get(codigoCliente);
        
        if (existente == null) {
          // Cliente nuevo
          await _box.put(codigoCliente, clienteHive);
          nuevos++;
        } else {
          // Cliente existente - actualizar solo si hay cambios
          if (_hayDiferencias(existente, clienteHive)) {
            // Preservar campos que podrían haberse actualizado localmente
            clienteHive.latitud = existente.latitud ?? clienteHive.latitud;
            clienteHive.longitud = existente.longitud ?? clienteHive.longitud;
            clienteHive.telefono = existente.telefono ?? clienteHive.telefono;
            
            await _box.put(codigoCliente, clienteHive);
            actualizados++;
          }
        }
      } catch (e) {
        print('❌ Error al procesar cliente ${clienteJson['NOMBRE_CLIENTE']}: $e');
      }
    }

    print('📊 Resumen de guardado: $nuevos nuevos, $actualizados actualizados');
  }

  /// Guarda clientes desde una lista de objetos Negocio
  Future<void> guardarClientesDesdeNegocios(
    List<Negocio> negocios, {
    String? rutaId,
    String? rutaNombre,
    String? asesorId,
    String? asesorNombre,
    String? codigoLider,
    String? nombreLider,
    String? emailLider,
    String? centroDistribucion,
  }) async {
    if (!_initialized) await initialize();

    int nuevos = 0;
    int actualizados = 0;
    
    for (var negocio in negocios) {
      final codigoCliente = negocio.clave;
      
      if (codigoCliente.isEmpty) {
        print('⚠️ Negocio sin clave, omitiendo...');
        continue;
      }

      try {
        // Verificar si ya existe
        final existente = _box.get(codigoCliente);
        
        final clienteHive = ClienteHive(
          id: negocio.clave,
          nombre: negocio.nombre,
          direccion: negocio.direccion,
          telefono: existente?.telefono, // Preservar teléfono si existe
          rutaId: rutaId ?? existente?.rutaId ?? '',
          rutaNombre: rutaNombre ?? existente?.rutaNombre ?? '',
          asesorId: asesorId ?? existente?.asesorId,
          asesorNombre: asesorNombre ?? existente?.asesorNombre,
          latitud: existente?.latitud,
          longitud: existente?.longitud,
          activo: true,
          tipoNegocio: existente?.tipoNegocio,
          segmento: existente?.segmento,
          pais: existente?.pais,
          centroDistribucion: centroDistribucion ?? existente?.centroDistribucion,
          codigoLider: codigoLider ?? existente?.codigoLider,
          nombreLider: nombreLider ?? existente?.nombreLider,
          emailLider: emailLider ?? existente?.emailLider,
          canalVenta: negocio.canal,
          subcanalVenta: negocio.subcanal,
          estadoRuta: existente?.estadoRuta ?? 'Activo',
          estadoCliente: existente?.estadoCliente ?? 'Activo',
          clasificacionCliente: negocio.clasificacion,
          diaVisita: existente?.diaVisita,
          diaVisitaCod: existente?.diaVisitaCod,
        );
        
        if (existente == null) {
          // Cliente nuevo
          await _box.put(codigoCliente, clienteHive);
          nuevos++;
        } else {
          // Cliente existente - actualizar solo si hay cambios
          if (_hayDiferencias(existente, clienteHive)) {
            await _box.put(codigoCliente, clienteHive);
            actualizados++;
          }
        }
      } catch (e) {
        print('❌ Error al procesar negocio ${negocio.nombre}: $e');
      }
    }

    print('📊 Resumen de guardado: $nuevos nuevos, $actualizados actualizados');
  }

  /// Obtiene un cliente por su código
  ClienteHive? obtenerCliente(String codigoCliente) {
    if (!_initialized) {
      print('⚠️ Servicio no inicializado');
      return null;
    }
    return _box.get(codigoCliente);
  }

  /// Obtiene todos los clientes almacenados
  List<ClienteHive> obtenerTodosLosClientes() {
    if (!_initialized) {
      print('⚠️ Servicio no inicializado');
      return [];
    }
    return _box.values.toList();
  }

  /// Obtiene clientes filtrados por ruta
  List<ClienteHive> obtenerClientesPorRuta(String rutaId) {
    if (!_initialized) {
      print('⚠️ Servicio no inicializado');
      return [];
    }
    return _box.values.where((cliente) => cliente.rutaId == rutaId).toList();
  }

  /// Obtiene clientes filtrados por nombre de ruta
  List<ClienteHive> obtenerClientesPorRutaNombre(String rutaNombre) {
    if (!_initialized) {
      print('⚠️ Servicio no inicializado');
      return [];
    }
    return _box.values.where((cliente) => cliente.rutaNombre == rutaNombre).toList();
  }

  /// Obtiene clientes filtrados por nombre de ruta (búsqueda flexible)
  /// Compara ignorando mayúsculas/minúsculas y espacios extras
  List<ClienteHive> obtenerClientesPorRutaNombreFlexible(String rutaNombre) {
    if (!_initialized) {
      print('⚠️ Servicio no inicializado');
      return [];
    }
    
    final rutaNormalizada = rutaNombre.trim().toLowerCase();
    return _box.values.where((cliente) {
      final rutaCliente = cliente.rutaNombre?.trim().toLowerCase() ?? '';
      return rutaCliente == rutaNormalizada || 
             rutaCliente.contains(rutaNormalizada) ||
             rutaNormalizada.contains(rutaCliente);
    }).toList();
  }

  /// Obtiene clientes filtrados por líder
  List<ClienteHive> obtenerClientesPorLider(String codigoLider) {
    if (!_initialized) {
      print('⚠️ Servicio no inicializado');
      return [];
    }
    return _box.values.where((cliente) => cliente.codigoLider == codigoLider).toList();
  }

  /// Actualiza la ubicación de un cliente
  Future<void> actualizarUbicacionCliente(
    String codigoCliente,
    double latitud,
    double longitud,
  ) async {
    if (!_initialized) await initialize();
    
    final cliente = _box.get(codigoCliente);
    if (cliente != null) {
      cliente.latitud = latitud;
      cliente.longitud = longitud;
      cliente.fechaModificacion = DateTime.now();
      await _box.put(codigoCliente, cliente);
      print('✅ Ubicación actualizada para cliente $codigoCliente');
    }
  }

  /// Elimina un cliente específico
  Future<void> eliminarCliente(String codigoCliente) async {
    if (!_initialized) await initialize();
    
    await _box.delete(codigoCliente);
    print('✅ Cliente $codigoCliente eliminado');
  }

  /// Limpia todos los clientes almacenados
  Future<void> limpiarTodos() async {
    if (!_initialized) await initialize();
    
    await _box.clear();
    print('✅ Todos los clientes han sido eliminados');
  }

  /// Verifica si hay diferencias entre dos clientes
  bool _hayDiferencias(ClienteHive cliente1, ClienteHive cliente2) {
    return cliente1.nombre != cliente2.nombre ||
        cliente1.direccion != cliente2.direccion ||
        cliente1.rutaId != cliente2.rutaId ||
        cliente1.asesorId != cliente2.asesorId ||
        cliente1.asesorNombre != cliente2.asesorNombre ||
        cliente1.canalVenta != cliente2.canalVenta ||
        cliente1.subcanalVenta != cliente2.subcanalVenta ||
        cliente1.clasificacionCliente != cliente2.clasificacionCliente ||
        cliente1.estadoCliente != cliente2.estadoCliente ||
        cliente1.activo != cliente2.activo;
  }

  /// Obtiene estadísticas de los clientes almacenados
  Map<String, dynamic> obtenerEstadisticas() {
    if (!_initialized) {
      return {'error': 'Servicio no inicializado'};
    }

    final totalClientes = _box.length;
    final clientesActivos = _box.values.where((c) => c.activo).length;
    final clientesPorRuta = <String, int>{};
    final clientesPorClasificacion = <String, int>{};

    for (var cliente in _box.values) {
      // Por ruta
      clientesPorRuta[cliente.rutaNombre] = 
          (clientesPorRuta[cliente.rutaNombre] ?? 0) + 1;
      
      // Por clasificación
      if (cliente.clasificacionCliente != null) {
        clientesPorClasificacion[cliente.clasificacionCliente!] = 
            (clientesPorClasificacion[cliente.clasificacionCliente!] ?? 0) + 1;
      }
    }

    return {
      'totalClientes': totalClientes,
      'clientesActivos': clientesActivos,
      'clientesInactivos': totalClientes - clientesActivos,
      'clientesPorRuta': clientesPorRuta,
      'clientesPorClasificacion': clientesPorClasificacion,
      'ultimaActualizacion': DateTime.now().toIso8601String(),
    };
  }

  /// Cierra el box de Hive
  Future<void> cerrar() async {
    if (_initialized) {
      await _box.close();
      _initialized = false;
    }
  }
}