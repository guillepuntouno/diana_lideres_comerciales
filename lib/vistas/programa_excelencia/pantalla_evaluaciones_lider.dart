import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/vistas/programa_excelencia/pantalla_detalle_evaluacion.dart';
import 'package:intl/intl.dart';

class PantallaEvaluacionesLider extends StatefulWidget {
  const PantallaEvaluacionesLider({super.key});

  @override
  State<PantallaEvaluacionesLider> createState() => _PantallaEvaluacionesLiderState();
}

class _PantallaEvaluacionesLiderState extends State<PantallaEvaluacionesLider> {
  List<ResultadoExcelenciaHive> _evaluaciones = [];
  bool _isLoading = true;
  String _filtroEstatus = 'todos';
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  Future<void> _cargarEvaluaciones() async {
    setState(() => _isLoading = true);
    
    try {
      final box = await Hive.openBox<ResultadoExcelenciaHive>('resultados_excelencia');
      
      List<ResultadoExcelenciaHive> evaluaciones = box.values.toList();
      
      // Ordenar por fecha más reciente
      evaluaciones.sort((a, b) => b.fechaCaptura.compareTo(a.fechaCaptura));
      
      setState(() {
        _evaluaciones = evaluaciones;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar evaluaciones: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar evaluaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ResultadoExcelenciaHive> get _evaluacionesFiltradas {
    if (_filtroEstatus == 'todos') {
      return _evaluaciones;
    }
    return _evaluaciones.where((e) => e.estatus == _filtroEstatus).toList();
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluaciones de Desempeño'),
        backgroundColor: const Color(0xFFDE1327),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filtroEstatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todas'),
              ),
              const PopupMenuItem(
                value: 'completada',
                child: Text('Completadas'),
              ),
              const PopupMenuItem(
                value: 'pendiente',
                child: Text('Pendientes'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 4),
                  Text(_filtroEstatus == 'todos' ? 'Todas' : _filtroEstatus),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarEvaluaciones,
              child: _evaluacionesFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay evaluaciones disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _evaluacionesFiltradas.length,
                      itemBuilder: (context, index) {
                        final evaluacion = _evaluacionesFiltradas[index];
                        final color = _getColorPorPonderacion(evaluacion.ponderacionFinal);
                        final textoEstatus = _getTextoEstatus(evaluacion.ponderacionFinal);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: color.withOpacity(0.3), width: 1),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaDetalleEvaluacion(
                                    evaluacion: evaluacion,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              evaluacion.ponderacionFinal.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                            Text(
                                              'pts',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              evaluacion.tipoFormulario,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              evaluacion.liderNombre,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              textoEstatus,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            evaluacion.estatus,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${evaluacion.ruta} - ${evaluacion.centroDistribucion}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _dateFormat.format(evaluacion.fechaCaptura),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (evaluacion.syncStatus == 'pending')
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.cloud_off_outlined,
                                              size: 16,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sin sincronizar',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.cloud_done_outlined,
                                              size: 16,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sincronizado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (evaluacion.observaciones != null && 
                                      evaluacion.observaciones!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.notes,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              evaluacion.observaciones!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}