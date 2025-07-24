import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'hive_service.dart';
import 'package:diana_lc_front/shared/modelos/hive/visita_cliente_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/lider_comercial_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/user_hive.dart';
import 'package:diana_lc_front/shared/configuracion/ambiente_config.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  noConnection,
}

class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;
  OfflineSyncManager._internal();

  final HiveService _hiveService = HiveService();
  final Connectivity _connectivity = Connectivity();
  
  // Stream controllers para notificar cambios de estado
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  final StreamController<String> _syncMessageController = StreamController<String>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  // Estado actual
  SyncStatus _currentStatus = SyncStatus.idle;
  bool _isConnected = false;
  Timer? _periodicSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Configuración
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  /// Streams públicos para escuchar cambios
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  Stream<String> get syncMessageStream => _syncMessageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Getters para estado actual
  SyncStatus get currentStatus => _currentStatus;
  bool get isConnected => _isConnected;
  DateTime? get lastSyncDate => _hiveService.getLastSyncDate();

  /// Inicializa el manager
  Future<void> initialize() async {
    try {
      // Verificar que HiveService esté inicializado
      if (!_hiveService.isInitialized) {
        print('⚠️ HiveService no está inicializado, intentando inicializar...');
        await _hiveService.initialize();
      }
      
      // Verificar conexión inicial
      await _checkConnectivity();
      
      // Escuchar cambios de conexión
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ Error en stream de conectividad: $error');
        },
      );

      // Iniciar sincronización periódica si hay conexión
      if (_isConnected) {
        _startPeriodicSync();
      }

      print('✅ OfflineSyncManager inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando OfflineSyncManager: $e');
      _updateStatus(SyncStatus.error, 'Error de inicialización: $e');
      rethrow; // Re-lanzar para que el caller maneje el error
    }
  }

  /// Maneja cambios en la conectividad
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasConnected = _isConnected;
    await _checkConnectivity();
    
    if (!wasConnected && _isConnected) {
      // Se recuperó la conexión, iniciar sincronización
      print('🔄 Conexión recuperada, iniciando sincronización automática');
      _startPeriodicSync();
      await performFullSync();
    } else if (wasConnected && !_isConnected) {
      // Se perdió la conexión
      print('📡 Conexión perdida, entrando en modo offline');
      _stopPeriodicSync();
      _updateStatus(SyncStatus.noConnection, 'Sin conexión a internet');
    }
  }

  /// Verifica el estado de conectividad
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final previousStatus = _isConnected;
      
      // Primero verificar si hay interfaz de red disponible
      _isConnected = !connectivityResults.contains(ConnectivityResult.none) && connectivityResults.isNotEmpty;
      
      // Si hay interfaz, hacer ping real al servidor para confirmar
      if (_isConnected) {
        _isConnected = await _pingServer();
      }
      
      // Notificar cambio de estado si es diferente
      if (previousStatus != _isConnected) {
        _connectionStatusController.add(_isConnected);
        print('📡 Estado de conexión: ${_isConnected ? "CONECTADO" : "SIN CONEXIÓN"}');
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      print('❌ Error verificando conectividad: $e');
    }
  }

  /// Hace ping al servidor para verificar conectividad real
  Future<bool> _pingServer() async {
    try {
      final response = await http.get(
        Uri.parse('${AmbienteConfig.baseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_connectionTimeout);
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('🔍 Ping al servidor falló: $e');
      return false;
    }
  }

  /// Inicia la sincronización periódica
  void _startPeriodicSync() {
    _stopPeriodicSync(); // Asegurar que no hay timer previo
    
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_isConnected && _currentStatus != SyncStatus.syncing) {
        performFullSync();
      }
    });
    
    print('⏰ Sincronización periódica iniciada (cada ${_syncInterval.inMinutes} min)');
  }

  /// Detiene la sincronización periódica
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    print('⏸️ Sincronización periódica detenida');
  }

  /// Actualiza el estado y notifica a los listeners
  void _updateStatus(SyncStatus status, String message) {
    _currentStatus = status;
    _syncStatusController.add(status);
    _syncMessageController.add(message);
    
    print('🔄 Sync Status: $status - $message');
  }

  /// Realiza sincronización completa
  Future<bool> performFullSync() async {
    if (!_isConnected) {
      _updateStatus(SyncStatus.noConnection, 'Sin conexión a internet');
      return false;
    }

    if (_currentStatus == SyncStatus.syncing) {
      print('⚠️ Sincronización ya en progreso, saltando...');
      return false;
    }

    try {
      _updateStatus(SyncStatus.syncing, 'Iniciando sincronización completa');

      // 1. Sincronizar datos locales pendientes hacia el servidor
      await _syncLocalToServer();

      // 2. Descargar datos actualizados del servidor
      await _syncServerToLocal();

      // 3. Actualizar timestamp de última sincronización
      await _hiveService.updateLastSyncDate();

      _updateStatus(SyncStatus.success, 'Sincronización completa exitosa');
      return true;

    } catch (e) {
      _updateStatus(SyncStatus.error, 'Error en sincronización: $e');
      print('❌ Error en sincronización completa: $e');
      return false;
    }
  }

  /// Sincroniza datos locales hacia el servidor
  Future<void> _syncLocalToServer() async {
    _updateStatus(SyncStatus.syncing, 'Enviando datos locales al servidor');

    // Sincronizar visitas pendientes
    final visitasPendientes = _hiveService.getPendingSyncItems<VisitaClienteHive>(HiveService.visitaClienteBox);
    for (final visita in visitasPendientes) {
      await _syncVisitaToServer(visita);
    }

    // Sincronizar planes de trabajo pendientes
    final planesPendientes = _hiveService.getPendingSyncItems<PlanTrabajoHive>(HiveService.planTrabajoBox);
    for (final plan in planesPendientes) {
      await _syncPlanTrabajoToServer(plan);
    }

    print('✅ Datos locales sincronizados con el servidor');
  }

  /// Sincroniza datos del servidor hacia local
  Future<void> _syncServerToLocal() async {
    _updateStatus(SyncStatus.syncing, 'Descargando datos del servidor');

    try {
      // Obtener timestamp de última sincronización
      final lastSync = _hiveService.getLastSyncDate();
      final timestamp = lastSync?.toIso8601String() ?? '';

      // Construir URL con parámetros de sincronización
      final url = '${AmbienteConfig.baseUrl}/sync/data?lastSync=$timestamp';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      ).timeout(_connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processSyncData(data);
        print('✅ Datos del servidor sincronizados localmente');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error sincronizando datos del servidor: $e');
      rethrow;
    }
  }

  /// Procesa los datos recibidos del servidor
  Future<void> _processSyncData(Map<String, dynamic> data) async {
    try {
      // Procesar líderes comerciales
      if (data['lideresComerciales'] != null) {
        final lideres = data['lideresComerciales'] as List;
        for (final liderData in lideres) {
          final lider = LiderComercialHive.fromJson(liderData);
          lider.syncStatus = 'synced';
          await _hiveService.lideresComerciales.put(lider.id, lider);
        }
      }

      // Procesar otros tipos de datos según sea necesario
      print('✅ Datos procesados y guardados localmente');
      
    } catch (e) {
      print('❌ Error procesando datos del servidor: $e');
      rethrow;
    }
  }

  /// Sincroniza una visita específica al servidor
  Future<void> _syncVisitaToServer(VisitaClienteHive visita) async {
    try {
      final url = '${AmbienteConfig.baseUrl}/visitas';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode(visita.toJson()),
      ).timeout(_connectionTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Marcar como sincronizado
        visita.syncStatus = 'synced';
        visita.lastUpdated = DateTime.now();
        await visita.save();
        print('✅ Visita ${visita.visitaId} sincronizada');
      } else {
        throw Exception('Error sincronizando visita: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error sincronizando visita ${visita.visitaId}: $e');
      // Mantener como pending para reintento
    }
  }

  /// Sincroniza un plan de trabajo específico al servidor
  Future<void> _syncPlanTrabajoToServer(PlanTrabajoHive plan) async {
    try {
      final url = '${AmbienteConfig.baseUrl}/planes-trabajo';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode(plan.toJson()),
      ).timeout(_connectionTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Marcar como sincronizado
        plan.syncStatus = 'synced';
        plan.lastUpdated = DateTime.now();
        await plan.save();
        print('✅ Plan ${plan.id} sincronizado');
      } else {
        throw Exception('Error sincronizando plan: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error sincronizando plan ${plan.id}: $e');
      // Mantener como pending para reintento
    }
  }

  /// Obtiene el token de autenticación
  Future<String> _getAuthToken() async {
    // Implementar lógica para obtener token de autenticación
    // Por ahora retorna un token dummy
    return _hiveService.getSyncMetadata<String>('auth_token') ?? '';
  }

  /// Guarda el token de autenticación
  Future<void> saveAuthToken(String token) async {
    await _hiveService.saveSyncMetadata('auth_token', token);
  }

  /// Fuerza una verificación manual de conectividad
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Obtiene estadísticas de sincronización
  Map<String, dynamic> getSyncStats() {
    final visitasPendientes = _hiveService.getPendingSyncItems<VisitaClienteHive>(HiveService.visitaClienteBox).length;
    final planesPendientes = _hiveService.getPendingSyncItems<PlanTrabajoHive>(HiveService.planTrabajoBox).length;
    
    return {
      'isConnected': _isConnected,
      'currentStatus': _currentStatus.toString(),
      'lastSyncDate': lastSyncDate?.toIso8601String(),
      'pendingVisitas': visitasPendientes,
      'pendingPlanes': planesPendientes,
      'totalPending': visitasPendientes + planesPendientes,
    };
  }

  /// Limpia todos los datos y resetea el estado
  Future<void> reset() async {
    _stopPeriodicSync();
    await _hiveService.clearAllBoxes();
    _updateStatus(SyncStatus.idle, 'Manager reiniciado');
    print('🔄 OfflineSyncManager reiniciado');
  }

  /// Libera recursos
  void dispose() {
    _stopPeriodicSync();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _syncMessageController.close();
    _connectionStatusController.close();
    print('🗑️ OfflineSyncManager disposed');
  }
}

/// Estado detallado de sincronización para UI
class SyncState {
  final SyncStatus status;
  final String message;
  final bool isConnected;
  final DateTime? lastSyncDate;
  final int pendingItems;

  const SyncState({
    required this.status,
    required this.message,
    required this.isConnected,
    this.lastSyncDate,
    required this.pendingItems,
  });

  bool get isIdle => status == SyncStatus.idle;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasError => status == SyncStatus.error;
  bool get isSuccess => status == SyncStatus.success;
  bool get hasConnection => isConnected;
  bool get hasPendingItems => pendingItems > 0;

  String get statusText {
    switch (status) {
      case SyncStatus.idle:
        return 'Listo';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.success:
        return 'Sincronizado';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.noConnection:
        return 'Sin conexión';
    }
  }

  String get lastSyncText {
    if (lastSyncDate == null) return 'Nunca';
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncDate!);
    
    if (difference.inMinutes < 1) {
      return 'Hace menos de 1 minuto';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }
}