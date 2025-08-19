import 'package:flutter/material.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:intl/intl.dart';

class EvaluacionCard extends StatefulWidget {
  final ResultadoExcelenciaHive evaluacion;
  final VoidCallback onTap;

  const EvaluacionCard({
    super.key,
    required this.evaluacion,
    required this.onTap,
  });

  @override
  State<EvaluacionCard> createState() => _EvaluacionCardState();
}

class _EvaluacionCardState extends State<EvaluacionCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorPorPonderacion(double ponderacion) {
    if (ponderacion >= 8.0) return const Color(0xFF38A169); // Verde
    if (ponderacion >= 6.0) return const Color(0xFFF6C343); // Amarillo
    return const Color(0xFFE53E3E); // Rojo
  }

  String _getTextoEstatus(double ponderacion) {
    if (ponderacion >= 8.0) return 'Excelente';
    if (ponderacion >= 6.0) return 'Regular';
    return 'Deficiente';
  }

  String _getTiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inDays == 0) {
      if (diferencia.inHours == 0) {
        if (diferencia.inMinutes < 5) return 'Hace un momento';
        return 'Hace ${diferencia.inMinutes} minutos';
      }
      return 'Hace ${diferencia.inHours} horas';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return _dateFormat.format(fecha);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evaluacion = widget.evaluacion;
    final color = _getColorPorPonderacion(evaluacion.ponderacionFinal);
    final textoEstatus = _getTextoEstatus(evaluacion.ponderacionFinal);
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onTap();
            },
            onTapCancel: () => _controller.reverse(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado principal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de puntuación compacto
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              evaluacion.ponderacionFinal.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              'pts',
                              style: TextStyle(
                                fontSize: 10,
                                color: color.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Información principal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // TODO: Ajuste temporal para demo 19 de agosto 2025
                              // Se debe crear boxes diferentes para evaluacion_desempeno y programa_excelencia
                              // en lugar de compartir la misma caja 'resultados_excelencia'
                              // Mientras tanto, ocultamos el texto problemático que viene de evaluación de desempeño
                              // Texto exacto: "Evaluacion de desempeño en campo - Canal Detalle"
                              (evaluacion.tipoFormulario.contains('Evaluacion de desempe') ||
                               evaluacion.tipoFormulario.contains('Evaluación de desempe') ||
                               evaluacion.tipoFormulario.toLowerCase().contains('evaluaci') &&
                               evaluacion.tipoFormulario.toLowerCase().contains('desempe'))
                                  ? 'Resultado Programa de Excelencia'
                                  : evaluacion.tipoFormulario,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    evaluacion.liderNombre,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Estado y tiempo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Chip(
                            label: Text(
                              textoEstatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            backgroundColor: color.withOpacity(0.15),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTiempoRelativo(evaluacion.fechaCaptura),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Sección expandible
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _isExpanded 
                        ? Column(
                            children: [
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              
                              // Ubicación
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                    semanticLabel: 'Ubicación',
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${evaluacion.ruta} - ${evaluacion.centroDistribucion}',
                                      style: theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Observaciones si existen
                              if (evaluacion.observaciones != null && 
                                  evaluacion.observaciones!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.notes,
                                        size: 14,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          evaluacion.observaciones!,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  
                  // Footer con sincronización y botón expandir
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Estado de sincronización
                      Row(
                        children: [
                          Icon(
                            evaluacion.syncStatus == 'pending'
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_done_outlined,
                            size: 16,
                            color: evaluacion.syncStatus == 'pending'
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                            semanticLabel: evaluacion.syncStatus == 'pending'
                                ? 'Sin sincronizar'
                                : 'Sincronizado',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            evaluacion.syncStatus == 'pending'
                                ? 'Sin sincronizar'
                                : 'Sincronizado',
                            style: TextStyle(
                              fontSize: 11,
                              color: evaluacion.syncStatus == 'pending'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      
                      // Botón expandir/colapsar
                      if (evaluacion.observaciones != null || evaluacion.ruta.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  _isExpanded ? 'Ver menos' : 'Ver más',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF1C2120),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                  color: const Color(0xFF1C2120),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}