import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../modelos/hive/lider_comercial_hive.dart';
import '../modelos/hive/visita_cliente_hive.dart';
import '../modelos/hive/plan_trabajo_hive.dart';
import '../modelos/hive/user_hive.dart';
import '../modelos/hive/objetivo_hive.dart';
import '../modelos/hive/cliente_hive.dart';
import '../modelos/hive/plan_trabajo_semanal_hive.dart';
import '../modelos/hive/dia_trabajo_hive.dart';
import '../modelos/hive/plan_trabajo_unificado_hive.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;
  
  // Nombres de las cajas
  static const String userBox = 'users';
  static const String liderComercialBox = 'lideres_comerciales';
  static const String visitaClienteBox = 'visitas_clientes';
  static const String planTrabajoBox = 'planes_trabajo';
  static const String rutaBox = 'rutas';
  static const String negocioBox = 'negocios';
  static const String syncMetadataBox = 'sync_metadata';
  static const String objetivoBox = 'objetivos';
  static const String clienteBox = 'clientes';
  static const String planTrabajoSemanalBox = 'planes_trabajo_semanal';
  static const String planTrabajoUnificadoBox = 'planes_trabajo_unificado';

  /// Inicializa Hive y registra todos los adaptadores
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar Hive Flutter
      await Hive.initFlutter();

      // Registrar adaptadores de modelos Hive
      _registerAdapters();

      // Abrir todas las cajas necesarias
      await _openBoxes();

      _isInitialized = true;
      print('✅ HiveService inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando HiveService: $e');
      rethrow;
    }
  }

  /// Registra todos los adaptadores de modelos Hive
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LiderComercialHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RutaHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NegocioHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(VisitaClienteHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CheckInHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(CheckOutHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(UbicacionHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(PlanTrabajoHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(VisitaPlanificadaHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(UserHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ObjetivoHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(ClienteHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(PlanTrabajoSemanalHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(DiaTrabajoHiveAdapter());
    }
    // Registrar adaptadores del modelo unificado
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(PlanTrabajoUnificadoHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(DiaPlanHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(VisitaClienteUnificadaHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(CuestionarioHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(TipoExhibidorHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(EstandaresEjecucionHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(DisponibilidadHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(CompromisoHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(UbicacionUnificadaHiveAdapter());
    }
  }

  /// Abre todas las cajas necesarias con tipos específicos
  Future<void> _openBoxes() async {
    // Abrir cajas con tipos específicos
    if (!Hive.isBoxOpen(userBox)) {
      await Hive.openBox<UserHive>(userBox);
      print('📦 Caja "$userBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(liderComercialBox)) {
      await Hive.openBox<LiderComercialHive>(liderComercialBox);
      print('📦 Caja "$liderComercialBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(visitaClienteBox)) {
      await Hive.openBox<VisitaClienteHive>(visitaClienteBox);
      print('📦 Caja "$visitaClienteBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(planTrabajoBox)) {
      await Hive.openBox<PlanTrabajoHive>(planTrabajoBox);
      print('📦 Caja "$planTrabajoBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(rutaBox)) {
      await Hive.openBox<RutaHive>(rutaBox);
      print('📦 Caja "$rutaBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(negocioBox)) {
      await Hive.openBox<NegocioHive>(negocioBox);
      print('📦 Caja "$negocioBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(syncMetadataBox)) {
      await Hive.openBox(syncMetadataBox);  // Esta puede ser dynamic
      print('📦 Caja "$syncMetadataBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(objetivoBox)) {
      await Hive.openBox<ObjetivoHive>(objetivoBox);
      print('📦 Caja "$objetivoBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(clienteBox)) {
      await Hive.openBox<ClienteHive>(clienteBox);
      print('📦 Caja "$clienteBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(planTrabajoSemanalBox)) {
      await Hive.openBox<PlanTrabajoSemanalHive>(planTrabajoSemanalBox);
      print('📦 Caja "$planTrabajoSemanalBox" abierta correctamente');
    }
    
    if (!Hive.isBoxOpen(planTrabajoUnificadoBox)) {
      await Hive.openBox<PlanTrabajoUnificadoHive>(planTrabajoUnificadoBox);
      print('📦 Caja "$planTrabajoUnificadoBox" abierta correctamente');
    }
  }

  /// Obtiene una caja específica
  Box<T> getBox<T>(String boxName) {
    if (!_isInitialized) {
      throw Exception('HiveService no ha sido inicializado. Llama a initialize() primero.');
    }
    
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('La caja "$boxName" no está abierta.');
    }
    
    return Hive.box<T>(boxName);
  }

  /// Obtiene la caja de usuarios
  Box<UserHive> get usersBox => getBox<UserHive>(userBox);

  /// Obtiene la caja de líderes comerciales
  Box<LiderComercialHive> get lideresComerciales => getBox<LiderComercialHive>(liderComercialBox);

  /// Obtiene la caja de visitas a clientes
  Box<VisitaClienteHive> get visitasClientes => getBox<VisitaClienteHive>(visitaClienteBox);

  /// Obtiene la caja de planes de trabajo
  Box<PlanTrabajoHive> get planesTrabajoBox => getBox<PlanTrabajoHive>(planTrabajoBox);

  /// Obtiene la caja de metadatos de sincronización
  Box get syncMetadata => getBox(syncMetadataBox);
  
  /// Obtiene la caja de objetivos
  Box<ObjetivoHive> get objetivosBox => getBox<ObjetivoHive>(objetivoBox);
  
  /// Obtiene la caja de clientes
  Box<ClienteHive> get clientesBox => getBox<ClienteHive>(clienteBox);
  
  /// Obtiene la caja de planes de trabajo semanales
  Box<PlanTrabajoSemanalHive> get planesTrabajoSemanalesBox => getBox<PlanTrabajoSemanalHive>(planTrabajoSemanalBox);
  
  /// Obtiene la caja de planes de trabajo unificados
  Box<PlanTrabajoUnificadoHive> get planesTrabajoUnificadosBox => getBox<PlanTrabajoUnificadoHive>(planTrabajoUnificadoBox);

  /// Limpia todas las cajas (útil para logout o reset)
  Future<void> clearAllBoxes() async {
    try {
      final boxes = [
        userBox,
        liderComercialBox,
        visitaClienteBox,
        planTrabajoBox,
        rutaBox,
        negocioBox,
        syncMetadataBox,
        objetivoBox,
        clienteBox,
        planTrabajoSemanalBox,
        planTrabajoUnificadoBox,
      ];

      for (String boxName in boxes) {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).clear();
          print('🗑️ Caja "$boxName" limpiada');
        }
      }
      
      print('✅ Todas las cajas han sido limpiadas');
    } catch (e) {
      print('❌ Error limpiando las cajas: $e');
      rethrow;
    }
  }

  /// Cierra todas las cajas
  Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
      _isInitialized = false;
      print('✅ Todas las cajas de Hive han sido cerradas');
    } catch (e) {
      print('❌ Error cerrando las cajas: $e');
      rethrow;
    }
  }

  /// Guarda metadatos de sincronización
  Future<void> saveSyncMetadata(String key, dynamic value) async {
    try {
      await syncMetadata.put(key, {
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error guardando metadatos de sync: $e');
      rethrow;
    }
  }

  /// Obtiene metadatos de sincronización
  T? getSyncMetadata<T>(String key) {
    try {
      final data = syncMetadata.get(key);
      return data != null ? data['value'] as T? : null;
    } catch (e) {
      print('❌ Error obteniendo metadatos de sync: $e');
      return null;
    }
  }

  /// Obtiene la fecha de última sincronización
  DateTime? getLastSyncDate() {
    try {
      final data = syncMetadata.get('last_sync_date');
      if (data != null && data['timestamp'] != null) {
        return DateTime.parse(data['timestamp']);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo fecha de última sincronización: $e');
      return null;
    }
  }

  /// Actualiza la fecha de última sincronización
  Future<void> updateLastSyncDate() async {
    await saveSyncMetadata('last_sync_date', DateTime.now().toIso8601String());
  }

  /// Verifica si HiveService está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtiene estadísticas de las cajas
  Map<String, int> getBoxesStats() {
    if (!_isInitialized) return {};
    
    return {
      'usuarios': Hive.isBoxOpen(userBox) ? Hive.box(userBox).length : 0,
      'lideres_comerciales': Hive.isBoxOpen(liderComercialBox) ? Hive.box(liderComercialBox).length : 0,
      'visitas_clientes': Hive.isBoxOpen(visitaClienteBox) ? Hive.box(visitaClienteBox).length : 0,
      'planes_trabajo': Hive.isBoxOpen(planTrabajoBox) ? Hive.box(planTrabajoBox).length : 0,
    };
  }

  /// Obtiene el espacio usado por las cajas en bytes (aproximado)
  Future<int> getStorageUsage() async {
    try {
      if (!_isInitialized) return 0;
      
      int totalSize = 0;
      final boxes = [userBox, liderComercialBox, visitaClienteBox, planTrabajoBox, syncMetadataBox];
      
      for (String boxName in boxes) {
        if (Hive.isBoxOpen(boxName)) {
          // Estimación aproximada basada en el número de elementos
          final box = Hive.box(boxName);
          totalSize += box.length * 1024; // Aproximadamente 1KB por elemento
        }
      }
      
      return totalSize;
    } catch (e) {
      print('❌ Error calculando uso de almacenamiento: $e');
      return 0;
    }
  }
}

/// Extensión para facilitar operaciones CRUD comunes
extension HiveServiceExtension on HiveService {
  /// Guarda o actualiza un elemento en una caja específica
  Future<void> saveItem<T extends HiveObject>(String boxName, String key, T item) async {
    try {
      final box = getBox<T>(boxName);
      await box.put(key, item);
    } catch (e) {
      print('❌ Error guardando item en $boxName: $e');
      rethrow;
    }
  }

  /// Obtiene un elemento de una caja específica
  T? getItem<T>(String boxName, String key) {
    try {
      final box = getBox<T>(boxName);
      return box.get(key);
    } catch (e) {
      print('❌ Error obteniendo item de $boxName: $e');
      return null;
    }
  }

  /// Elimina un elemento de una caja específica
  Future<void> deleteItem(String boxName, String key) async {
    try {
      final box = getBox(boxName);
      await box.delete(key);
    } catch (e) {
      print('❌ Error eliminando item de $boxName: $e');
      rethrow;
    }
  }

  /// Obtiene todos los elementos de una caja que requieren sincronización
  List<T> getPendingSyncItems<T extends HiveObject>(String boxName) {
    try {
      final box = getBox<T>(boxName);
      return box.values.where((item) {
        // Asumiendo que todos los modelos Hive tienen el campo syncStatus
        return (item as dynamic).syncStatus == 'pending';
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo items pendientes de sync: $e');
      return [];
    }
  }
}