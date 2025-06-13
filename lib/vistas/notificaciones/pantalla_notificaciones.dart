// lib/vistas/notificaciones/pantalla_notificaciones.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../modelos/notificacion_modelo.dart';
import '../../servicios/notificaciones_servicio.dart';

class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  List<NotificacionModelo> _notificaciones = [];
  bool _cargando = true;
  String _filtroActual = 'todas'; // 'todas', 'no_leidas', 'leidas'

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);

    try {
      List<NotificacionModelo> notificaciones;

      switch (_filtroActual) {
        case 'no_leidas':
          notificaciones = await NotificacionesServicio.obtenerNoLeidas();
          break;
        case 'leidas':
          final todas = await NotificacionesServicio.obtenerNotificaciones();
          notificaciones = todas.where((n) => n.leida).toList();
          break;
        default:
          notificaciones = await NotificacionesServicio.obtenerNotificaciones();
      }

      setState(() {
        _notificaciones = notificaciones;
        _cargando = false;
      });

      print('📱 Notificaciones cargadas: ${_notificaciones.length}');
    } catch (e) {
      print('❌ Error al cargar notificaciones: $e');
      setState(() => _cargando = false);
    }
  }

  Future<void> _marcarComoLeida(NotificacionModelo notificacion) async {
    if (notificacion.leida) return;

    await NotificacionesServicio.marcarComoLeida(notificacion.id);
    await _cargarNotificaciones();
  }

  Future<void> _marcarTodasComoLeidas() async {
    await NotificacionesServicio.marcarTodasComoLeidas();
    await _cargarNotificaciones();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Todas las notificaciones marcadas como leídas',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dianaGreen,
        ),
      );
    }
  }

  Future<void> _eliminarNotificacion(NotificacionModelo notificacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Eliminar Notificación',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              '¿Estás seguro de que quieres eliminar esta notificación?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: AppColors.mediumGray),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dianaRed,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Eliminar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await NotificacionesServicio.eliminarNotificacion(notificacion.id);
      await _cargarNotificaciones();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notificación eliminada',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dianaRed,
          ),
        );
      }
    }
  }

  Future<void> _limpiarTodas() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Limpiar Todas las Notificaciones',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              '¿Estás seguro de que quieres eliminar todas las notificaciones? Esta acción no se puede deshacer.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: AppColors.mediumGray),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dianaRed,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Limpiar Todo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await NotificacionesServicio.cancelarTodas();
      await _cargarNotificaciones();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Todas las notificaciones eliminadas',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dianaRed,
          ),
        );
      }
    }
  }

  void _onTapNotificacion(NotificacionModelo notificacion) async {
    // Marcar como leída
    await _marcarComoLeida(notificacion);

    // Navegar según el tipo de notificación
    if (notificacion.accionUrl != null && notificacion.datos != null) {
      Navigator.pushNamed(
        context,
        notificacion.accionUrl!,
        arguments: notificacion.datos,
      );
    } else {
      // Mostrar detalles en un diálogo
      _mostrarDetalleNotificacion(notificacion);
    }
  }

  void _mostrarDetalleNotificacion(NotificacionModelo notificacion) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              notificacion.titulo,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notificacion.mensaje, style: GoogleFonts.poppins()),
                const SizedBox(height: 16),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(notificacion.fechaCreacion)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.poppins(color: AppColors.dianaRed),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.poppins(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.darkGray),
            onSelected: (value) {
              switch (value) {
                case 'marcar_todas':
                  _marcarTodasComoLeidas();
                  break;
                case 'limpiar_todas':
                  _limpiarTodas();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'marcar_todas',
                    child: Text(
                      'Marcar todas como leídas',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'limpiar_todas',
                    child: Text(
                      'Limpiar todas',
                      style: GoogleFonts.poppins(color: AppColors.dianaRed),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),

          // Lista de notificaciones
          Expanded(
            child:
                _cargando
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.dianaRed,
                      ),
                    )
                    : _notificaciones.isEmpty
                    ? _buildEstadoVacio()
                    : RefreshIndicator(
                      onRefresh: _cargarNotificaciones,
                      color: AppColors.dianaRed,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) {
                          final notificacion = _notificaciones[index];
                          return _NotificacionTile(
                            notificacion: notificacion,
                            onTap: () => _onTapNotificacion(notificacion),
                            onDelete: () => _eliminarNotificacion(notificacion),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildChipFiltro('Todas', 'todas'),
          const SizedBox(width: 8),
          _buildChipFiltro('No leídas', 'no_leidas'),
          const SizedBox(width: 8),
          _buildChipFiltro('Leídas', 'leidas'),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String label, String filtro) {
    final isSelected = _filtroActual == filtro;

    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : AppColors.darkGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filtroActual = filtro);
          _cargarNotificaciones();
        }
      },
      selectedColor: AppColors.dianaRed,
      backgroundColor: AppColors.lightGray,
      showCheckmark: false,
    );
  }

  Widget _buildEstadoVacio() {
    String mensaje;
    String submensaje;

    switch (_filtroActual) {
      case 'no_leidas':
        mensaje = 'No hay notificaciones sin leer';
        submensaje = '¡Genial! Estás al día';
        break;
      case 'leidas':
        mensaje = 'No hay notificaciones leídas';
        submensaje = 'Las notificaciones que veas aparecerán aquí';
        break;
      default:
        mensaje = 'No hay notificaciones';
        submensaje =
            'Cuando completes visitas o tengas compromisos, aparecerán aquí';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submensaje,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificacionTile extends StatelessWidget {
  final NotificacionModelo notificacion;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificacionTile({
    required this.notificacion,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData icono;
    Color colorIcono;

    switch (notificacion.tipo) {
      case 'visita_completada':
        icono = Icons.check_circle;
        colorIcono = AppColors.dianaGreen;
        break;
      case 'compromisos_creados':
        icono = Icons.assignment_turned_in;
        colorIcono = AppColors.dianaYellow;
        break;
      case 'sincronizacion_error':
        icono = Icons.error;
        colorIcono = AppColors.dianaRed;
        break;
      default:
        icono = Icons.notification_important;
        colorIcono = AppColors.mediumGray;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notificacion.leida ? Colors.white : AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              notificacion.leida
                  ? Colors.grey.shade200
                  : AppColors.dianaRed.withOpacity(0.3),
          width: notificacion.leida ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorIcono.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: colorIcono, size: 24),
            ),
            if (!notificacion.leida)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.dianaRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notificacion.titulo,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: notificacion.leida ? FontWeight.w500 : FontWeight.bold,
            color: AppColors.darkGray,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notificacion.mensaje,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.mediumGray,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              notificacion.tiempoRelativo,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.mediumGray),
          onPressed: onDelete,
          tooltip: 'Eliminar notificación',
        ),
        onTap: onTap,
      ),
    );
  }
}
