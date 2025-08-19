import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:intl/intl.dart';

class PantallaDetalleEvaluacionV2 extends StatelessWidget {
  final ResultadoExcelenciaHive evaluacion;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  PantallaDetalleEvaluacionV2({
    super.key,
    required this.evaluacion,
  });

  Color _getColorPorPonderacion(double ponderacion) {
    if (ponderacion >= 8.0) return const Color(0xFF10B981); // Verde esmeralda
    if (ponderacion >= 6.0) return const Color(0xFFF59E0B); // Ámbar
    return const Color(0xFFEF4444); // Rojo suave
  }

  String _getTextoEstatus(double ponderacion) {
    if (ponderacion >= 8.0) return 'Excelente';
    if (ponderacion >= 6.0) return 'Regular';
    return 'Necesita Mejora';
  }

  IconData _getIconoEstatus(double ponderacion) {
    if (ponderacion >= 8.0) return Icons.emoji_events_outlined;
    if (ponderacion >= 6.0) return Icons.trending_up_outlined;
    return Icons.priority_high_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorPorPonderacion(evaluacion.ponderacionFinal);
    final textoEstatus = _getTextoEstatus(evaluacion.ponderacionFinal);
    final icono = _getIconoEstatus(evaluacion.ponderacionFinal);

    // Agrupar respuestas por categoría
    final respuestasPorCategoria = <String, List<RespuestaEvaluacionHive>>{};
    for (final respuesta in evaluacion.respuestas) {
      final categoria = respuesta.categoria ?? 'General';
      respuestasPorCategoria.putIfAbsent(categoria, () => []).add(respuesta);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          // TODO: Ajuste temporal para demo 19 de agosto 2025
          // Se debe crear boxes diferentes para evaluacion_desempeno y programa_excelencia
          // Mientras tanto, ocultamos el texto problemático
          'Resultado Programa de Excelencia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Compartir evaluación
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header con resultado principal
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Ícono y estado
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icono,
                            size: 40,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Puntuación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              evaluacion.ponderacionFinal.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                                height: 1,
                              ),
                            ),
                            Text(
                              ' / 10',
                              style: TextStyle(
                                fontSize: 24,
                                color: const Color(0xFF6B7280),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            textoEstatus,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Tipo de formulario
                        Text(
                          // TODO: Ajuste temporal para demo 19 de agosto 2025
                          // Mismo ajuste que en las tarjetas
                          (evaluacion.tipoFormulario.contains('Evaluacion de desempe') ||
                           evaluacion.tipoFormulario.contains('Evaluación de desempe') ||
                           evaluacion.tipoFormulario.toLowerCase().contains('evaluaci') &&
                           evaluacion.tipoFormulario.toLowerCase().contains('desempe'))
                              ? 'Resultado Programa de Excelencia'
                              : evaluacion.tipoFormulario,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Separador
                  Container(
                    height: 8,
                    color: const Color(0xFFF3F4F6),
                  ),
                ],
              ),
            ),
          ),
          
          // Información del evaluado
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Información del Evaluado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoItem(
                    icon: Icons.badge_outlined,
                    label: 'Nombre',
                    value: evaluacion.liderNombre,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: evaluacion.liderCorreo,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    icon: Icons.route_outlined,
                    label: 'Ruta',
                    value: evaluacion.ruta,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    icon: Icons.business_outlined,
                    label: 'Centro',
                    value: evaluacion.centroDistribucion,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    icon: Icons.flag_outlined,
                    label: 'País',
                    value: evaluacion.pais,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha',
                    value: _dateFormat.format(evaluacion.fechaCaptura),
                  ),
                  if (evaluacion.fechaHoraInicio != null && 
                      evaluacion.fechaHoraFin != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.timer_outlined,
                      label: 'Duración',
                      value: '${evaluacion.fechaHoraFin!.difference(evaluacion.fechaHoraInicio!).inMinutes} minutos',
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Título de respuestas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Respuestas por Categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ),
          
          // Respuestas agrupadas
          SliverList(
            delegate: SliverChildListDelegate(
              respuestasPorCategoria.entries.map((entry) {
                final categoria = entry.key;
                final respuestas = entry.value;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      childrenPadding: EdgeInsets.zero,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              categoria,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${respuestas.length} preguntas',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        ...respuestas.map((respuesta) {
                          final tienePuntaje = respuesta.ponderacion != null && 
                                              respuesta.ponderacion! > 0;
                          
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pregunta
                                Text(
                                  respuesta.preguntaTitulo,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Respuesta
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: tienePuntaje
                                            ? const Color(0xFFD1FAE5)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        tienePuntaje 
                                            ? Icons.check_circle_outline
                                            : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: tienePuntaje
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        respuesta.respuesta != null 
                                            ? respuesta.respuesta.toString()
                                            : 'Sin respuesta',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: respuesta.respuesta != null
                                              ? const Color(0xFF111827)
                                              : const Color(0xFF9CA3AF),
                                          fontWeight: respuesta.respuesta != null
                                              ? FontWeight.w400
                                              : FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                    if (respuesta.ponderacion != null && 
                                        respuesta.ponderacion! > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${respuesta.ponderacion!.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Observaciones si existen
          if (evaluacion.observaciones != null && 
              evaluacion.observaciones!.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFBAE6FD),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notes,
                            color: Color(0xFF3B82F6),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      evaluacion.observaciones!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E40AF),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Espaciado final
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}