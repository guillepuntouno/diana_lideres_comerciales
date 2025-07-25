import 'package:flutter/material.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:intl/intl.dart';

class PantallaDetalleEvaluacion extends StatelessWidget {
  final ResultadoExcelenciaHive evaluacion;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  PantallaDetalleEvaluacion({
    super.key,
    required this.evaluacion,
  });

  Color _getColorPorPonderacion(double ponderacion) {
    if (ponderacion >= 8.0) return Colors.green;
    if (ponderacion >= 6.0) return Colors.orange;
    return Colors.red;
  }

  String _getTextoEstatus(double ponderacion) {
    if (ponderacion >= 8.0) return 'Excelente';
    if (ponderacion >= 6.0) return 'Regular';
    return 'Deficiente';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorPorPonderacion(evaluacion.ponderacionFinal);
    final textoEstatus = _getTextoEstatus(evaluacion.ponderacionFinal);

    // Agrupar respuestas por categoría
    final respuestasPorCategoria = <String, List<RespuestaEvaluacionHive>>{};
    for (final respuesta in evaluacion.respuestas) {
      final categoria = respuesta.categoria ?? 'Sin categoría';
      respuestasPorCategoria.putIfAbsent(categoria, () => []).add(respuesta);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Evaluación'),
        backgroundColor: const Color(0xFFDE1327),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con información general
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.3), width: 2),
                ),
              ),
              child: Column(
                children: [
                  // Puntuación principal
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          evaluacion.ponderacionFinal.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'puntos',
                          style: TextStyle(
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      textoEstatus,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    evaluacion.tipoFormulario,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Información del evaluado
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de la Evaluación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, 'Evaluado', evaluacion.liderNombre),
                  _buildInfoRow(Icons.email, 'Correo', evaluacion.liderCorreo),
                  _buildInfoRow(Icons.route, 'Ruta', evaluacion.ruta),
                  _buildInfoRow(Icons.business, 'Centro', evaluacion.centroDistribucion),
                  _buildInfoRow(Icons.flag, 'País', evaluacion.pais),
                  _buildInfoRow(Icons.calendar_today, 'Fecha', _dateFormat.format(evaluacion.fechaCaptura)),
                  if (evaluacion.fechaHoraInicio != null && evaluacion.fechaHoraFin != null)
                    _buildInfoRow(
                      Icons.timer,
                      'Duración',
                      '${evaluacion.fechaHoraFin!.difference(evaluacion.fechaHoraInicio!).inMinutes} minutos',
                    ),
                ],
              ),
            ),

            // Respuestas por categoría
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Detalle de Respuestas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            ...respuestasPorCategoria.entries.map((entry) {
              final categoria = entry.key;
              final respuestas = entry.value;
              final puntajeCategoria = respuestas
                  .where((r) => r.ponderacion != null)
                  .fold(0.0, (sum, r) => sum + r.ponderacion!);
              final maxPuntajeCategoria = respuestas.length * 3.0; // Asumiendo máximo 3 puntos por pregunta

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            categoria,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorPorPonderacion(
                              (puntajeCategoria / maxPuntajeCategoria) * 10,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${puntajeCategoria.toStringAsFixed(1)} pts',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getColorPorPonderacion(
                                (puntajeCategoria / maxPuntajeCategoria) * 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: respuestas.map((respuesta) {
                      final tienePuntaje = respuesta.ponderacion != null && respuesta.ponderacion! > 0;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: tienePuntaje
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tienePuntaje ? Icons.check : Icons.close,
                                size: 16,
                                color: tienePuntaje ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    respuesta.preguntaTitulo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          respuesta.respuesta?.toString() ?? 'Sin respuesta',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      if (respuesta.ponderacion != null)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getColorPorPonderacion(
                                              (respuesta.ponderacion! / 3) * 10,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${respuesta.ponderacion!.toStringAsFixed(1)} pts',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getColorPorPonderacion(
                                                (respuesta.ponderacion! / 3) * 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),

            // Observaciones si existen
            if (evaluacion.observaciones != null && evaluacion.observaciones!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evaluacion.observaciones!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}