import 'package:flutter/material.dart';
import 'package:diana_lc_front/shared/servicios/offline_sync_manager.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  final OfflineSyncManager _syncManager = OfflineSyncManager();
  bool _isConnected = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  String _syncMessage = '';
  DateTime? _lastSyncDate;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    _listenToChanges();
  }

  void _initializeStatus() {
    setState(() {
      _isConnected = _syncManager.isConnected;
      _syncStatus = _syncManager.currentStatus;
      _lastSyncDate = _syncManager.lastSyncDate;
    });
  }

  void _listenToChanges() {
    // Escuchar cambios de conectividad
    _syncManager.connectionStatusStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // Escuchar cambios de estado de sincronización
    _syncManager.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
          _lastSyncDate = _syncManager.lastSyncDate;
        });
      }
    });

    // Escuchar mensajes de sincronización
    _syncManager.syncMessageStream.listen((message) {
      if (mounted) {
        setState(() {
          _syncMessage = message;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono de estado
          _buildStatusIcon(),
          const SizedBox(width: 12),
          
          // Información de estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _getStatusColor(),
                      ),
                    ),
                    if (_syncStatus == SyncStatus.syncing) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_lastSyncDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Última sincronización: ${_formatLastSync()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (_syncMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _syncMessage,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Botón de acción
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    
    if (!_isConnected) {
      iconData = Icons.wifi_off_rounded;
    } else {
      switch (_syncStatus) {
        case SyncStatus.syncing:
          iconData = Icons.sync_rounded;
        case SyncStatus.success:
          iconData = Icons.cloud_done_rounded;
        case SyncStatus.error:
          iconData = Icons.error_outline_rounded;
        case SyncStatus.noConnection:
          iconData = Icons.wifi_off_rounded;
        case SyncStatus.idle:
        default:
          iconData = Icons.wifi_rounded;
      }
    }

    return Icon(
      iconData,
      color: _getStatusColor(),
      size: 24,
    );
  }

  Widget _buildActionButton() {
    if (_syncStatus == SyncStatus.syncing) {
      return const SizedBox.shrink(); // No mostrar botón durante sincronización
    }

    return InkWell(
      onTap: _onActionButtonPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getActionIcon(),
              size: 16,
              color: _getStatusColor(),
            ),
            const SizedBox(width: 4),
            Text(
              _getActionText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!_isConnected) {
      return Colors.orange.shade700;
    }

    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue.shade600;
      case SyncStatus.success:
        return Colors.green.shade600;
      case SyncStatus.error:
        return Colors.red.shade600;
      case SyncStatus.noConnection:
        return Colors.orange.shade700;
      case SyncStatus.idle:
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText() {
    if (!_isConnected) {
      return 'Sin conexión';
    }

    switch (_syncStatus) {
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.success:
        return 'Sincronizado';
      case SyncStatus.error:
        return 'Error de sincronización';
      case SyncStatus.noConnection:
        return 'Sin conexión';
      case SyncStatus.idle:
      default:
        return 'Conectado';
    }
  }

  IconData _getActionIcon() {
    if (!_isConnected || _syncStatus == SyncStatus.error) {
      return Icons.refresh_rounded;
    }
    return Icons.sync_rounded;
  }

  String _getActionText() {
    if (!_isConnected || _syncStatus == SyncStatus.error) {
      return 'Reintentar';
    }
    return 'Sincronizar';
  }

  void _onActionButtonPressed() async {
    try {
      if (!_isConnected) {
        // Verificar conectividad
        await _syncManager.checkConnectivity();
      } else {
        // Realizar sincronización manual
        await _syncManager.performFullSync();
      }
    } catch (e) {
      print('Error en acción manual: $e');
      // Mostrar snackbar de error si es necesario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatLastSync() {
    if (_lastSyncDate == null) return 'Nunca';

    final now = DateTime.now();
    final difference = now.difference(_lastSyncDate!);

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

/// Widget compacto para mostrar solo el estado de conexión
class CompactConnectionStatusWidget extends StatefulWidget {
  const CompactConnectionStatusWidget({super.key});

  @override
  State<CompactConnectionStatusWidget> createState() => _CompactConnectionStatusWidgetState();
}

class _CompactConnectionStatusWidgetState extends State<CompactConnectionStatusWidget> {
  final OfflineSyncManager _syncManager = OfflineSyncManager();
  bool _isConnected = false;
  SyncStatus _syncStatus = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    _listenToChanges();
  }

  void _initializeStatus() {
    setState(() {
      _isConnected = _syncManager.isConnected;
      _syncStatus = _syncManager.currentStatus;
    });
  }

  void _listenToChanges() {
    _syncManager.connectionStatusStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    _syncManager.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                size: 16,
                color: _getStatusColor(),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
              ),
              if (_syncStatus == SyncStatus.syncing) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!_isConnected) {
      return Colors.orange.shade700;
    }

    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue.shade600;
      case SyncStatus.success:
        return Colors.green.shade600;
      case SyncStatus.error:
        return Colors.red.shade600;
      case SyncStatus.noConnection:
        return Colors.orange.shade700;
      case SyncStatus.idle:
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon() {
    if (!_isConnected) {
      return Icons.wifi_off_rounded;
    }

    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.success:
        return Icons.cloud_done_rounded;
      case SyncStatus.error:
        return Icons.error_outline_rounded;
      case SyncStatus.noConnection:
        return Icons.wifi_off_rounded;
      case SyncStatus.idle:
      default:
        return Icons.wifi_rounded;
    }
  }

  String _getStatusText() {
    if (!_isConnected) {
      return 'Offline';
    }

    switch (_syncStatus) {
      case SyncStatus.syncing:
        return 'Sync...';
      case SyncStatus.success:
        return 'Online';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.noConnection:
        return 'Offline';
      case SyncStatus.idle:
      default:
        return 'Online';
    }
  }
}