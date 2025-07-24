// lib/web/vistas/reportes/pantalla_reportes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:diana_lc_front/shared/servicios/plan_trabajo_servicio.dart';
import 'package:diana_lc_front/shared/servicios/visitas_api_service.dart';
import 'package:diana_lc_front/shared/modelos/plan_trabajo_modelo.dart';
import 'package:diana_lc_front/shared/modelos/visita_cliente_modelo.dart';

class PantallaReportes extends StatefulWidget {
  const PantallaReportes({Key? key}) : super(key: key);

  @override
  State<PantallaReportes> createState() => _PantallaReportesState();
}

class _PantallaReportesState extends State<PantallaReportes> {
  final PlanTrabajoServicio _planServicio = PlanTrabajoServicio();
  final VisitasApiService _visitasServicio = VisitasApiService();
  
  String _tipoReporte = 'visitas';
  DateTimeRange? _rangoFechas;
  List<dynamic> _datosReporte = [];
  bool _isLoading = false;
  
  final Map<String, String> _tiposReporte = {
    'visitas': 'Reporte de Visitas',
    'productividad': 'Reporte de Productividad',
    'efectividad': 'Reporte de Efectividad',
    'cumplimiento': 'Reporte de Cumplimiento',
  };

  @override
  void initState() {
    super.initState();
    _rangoFechas = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _generarReporte();
  }

  Future<void> _generarReporte() async {
    setState(() => _isLoading = true);
    
    try {
      switch (_tipoReporte) {
        case 'visitas':
          final visitas = await _visitasServicio.obtenerVisitas(
            fechaInicio: _rangoFechas!.start,
            fechaFin: _rangoFechas!.end,
          );
          setState(() => _datosReporte = visitas);
          break;
        case 'productividad':
          // TODO: Implementar servicio de productividad
          setState(() => _datosReporte = _generarDatosProductividad());
          break;
        case 'efectividad':
          // TODO: Implementar servicio de efectividad
          setState(() => _datosReporte = _generarDatosEfectividad());
          break;
        case 'cumplimiento':
          // TODO: Implementar servicio de cumplimiento
          setState(() => _datosReporte = _generarDatosCumplimiento());
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar reporte: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header con filtros
          _buildHeader(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        
                        // Data table
                        Expanded(
                          child: _buildDataTable(),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reportes',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C2120),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportarReporte,
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generarReporte,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filters row
          Row(
            children: [
              // Report type selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _tipoReporte,
                  underline: const SizedBox(),
                  items: _tiposReporte.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tipoReporte = value);
                      _generarReporte();
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Date range picker
              InkWell(
                onTap: _seleccionarRangoFechas,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_rangoFechas!.start)} - ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.end)}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Quick filters
              _buildQuickFilter('Hoy', () {
                setState(() {
                  _rangoFechas = DateTimeRange(
                    start: DateTime.now(),
                    end: DateTime.now(),
                  );
                });
                _generarReporte();
              }),
              _buildQuickFilter('Esta semana', () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                setState(() {
                  _rangoFechas = DateTimeRange(
                    start: startOfWeek,
                    end: now,
                  );
                });
                _generarReporte();
              }),
              _buildQuickFilter('Este mes', () {
                final now = DateTime.now();
                setState(() {
                  _rangoFechas = DateTimeRange(
                    start: DateTime(now.year, now.month, 1),
                    end: now,
                  );
                });
                _generarReporte();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton(
        onPressed: onTap,
        child: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFDE1327),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final Map<String, dynamic> summary = _calcularResumen();
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total ${_tipoReporte == "visitas" ? "Visitas" : "Registros"}',
            summary['total'].toString(),
            Icons.list_alt,
            const Color(0xFF38A169),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Promedio Diario',
            summary['promedioDiario'].toStringAsFixed(1),
            Icons.trending_up,
            const Color(0xFFF6C343),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Efectividad',
            '${summary['efectividad'].toStringAsFixed(1)}%',
            Icons.speed,
            const Color(0xFFDE1327),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Cumplimiento',
            '${summary['cumplimiento'].toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8F8E8E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _tiposReporte[_tipoReporte] ?? 'Reporte',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF5F5F5),
                  ),
                  columns: _buildColumns(),
                  rows: _buildRows(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    switch (_tipoReporte) {
      case 'visitas':
        return [
          const DataColumn(label: Text('Fecha')),
          const DataColumn(label: Text('Líder')),
          const DataColumn(label: Text('Cliente')),
          const DataColumn(label: Text('Hora Inicio')),
          const DataColumn(label: Text('Hora Fin')),
          const DataColumn(label: Text('Duración')),
          const DataColumn(label: Text('Estado')),
        ];
      case 'productividad':
        return [
          const DataColumn(label: Text('Líder')),
          const DataColumn(label: Text('Visitas Planeadas')),
          const DataColumn(label: Text('Visitas Realizadas')),
          const DataColumn(label: Text('Tiempo Promedio')),
          const DataColumn(label: Text('Efectividad')),
        ];
      case 'efectividad':
        return [
          const DataColumn(label: Text('Periodo')),
          const DataColumn(label: Text('Meta')),
          const DataColumn(label: Text('Alcanzado')),
          const DataColumn(label: Text('Porcentaje')),
          const DataColumn(label: Text('Tendencia')),
        ];
      case 'cumplimiento':
        return [
          const DataColumn(label: Text('Líder')),
          const DataColumn(label: Text('Plan Semanal')),
          const DataColumn(label: Text('Ejecutado')),
          const DataColumn(label: Text('Cumplimiento')),
          const DataColumn(label: Text('Estado')),
        ];
      default:
        return [];
    }
  }

  List<DataRow> _buildRows() {
    return _datosReporte.take(20).map((dato) {
      switch (_tipoReporte) {
        case 'visitas':
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd/MM/yyyy').format(dato['fecha'] ?? DateTime.now()))),
            DataCell(Text(dato['lider'] ?? 'N/A')),
            DataCell(Text(dato['cliente'] ?? 'N/A')),
            DataCell(Text(dato['horaInicio'] ?? '--:--')),
            DataCell(Text(dato['horaFin'] ?? '--:--')),
            DataCell(Text('${dato['duracion'] ?? 0} min')),
            DataCell(_buildEstadoChip(dato['estado'] ?? 'pendiente')),
          ]);
        case 'productividad':
          return DataRow(cells: [
            DataCell(Text(dato['lider'] ?? 'N/A')),
            DataCell(Text(dato['planeadas'].toString())),
            DataCell(Text(dato['realizadas'].toString())),
            DataCell(Text('${dato['tiempoPromedio'] ?? 0} min')),
            DataCell(Text('${dato['efectividad'] ?? 0}%')),
          ]);
        case 'efectividad':
          return DataRow(cells: [
            DataCell(Text(dato['periodo'] ?? 'N/A')),
            DataCell(Text(dato['meta'].toString())),
            DataCell(Text(dato['alcanzado'].toString())),
            DataCell(Text('${dato['porcentaje'] ?? 0}%')),
            DataCell(Icon(
              dato['tendencia'] == 'up' ? Icons.trending_up : Icons.trending_down,
              color: dato['tendencia'] == 'up' ? Colors.green : Colors.red,
            )),
          ]);
        case 'cumplimiento':
          return DataRow(cells: [
            DataCell(Text(dato['lider'] ?? 'N/A')),
            DataCell(Text(dato['planSemanal'].toString())),
            DataCell(Text(dato['ejecutado'].toString())),
            DataCell(Text('${dato['cumplimiento'] ?? 0}%')),
            DataCell(_buildEstadoChip(dato['cumplimiento'] >= 80 ? 'cumplido' : 'pendiente')),
          ]);
        default:
          return const DataRow(cells: []);
      }
    }).toList();
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String texto;
    
    switch (estado.toLowerCase()) {
      case 'completada':
      case 'cumplido':
        color = const Color(0xFF38A169);
        texto = 'Completada';
        break;
      case 'en_proceso':
        color = const Color(0xFFF6C343);
        texto = 'En Proceso';
        break;
      default:
        color = const Color(0xFFDE1327);
        texto = 'Pendiente';
    }
    
    return Chip(
      label: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Future<void> _seleccionarRangoFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
      locale: const Locale('es', 'ES'),
    );
    
    if (picked != null) {
      setState(() => _rangoFechas = picked);
      _generarReporte();
    }
  }

  void _exportarReporte() {
    // TODO: Implementar exportación a Excel/PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de exportación en desarrollo')),
    );
  }

  Map<String, dynamic> _calcularResumen() {
    final diasEnRango = _rangoFechas!.end.difference(_rangoFechas!.start).inDays + 1;
    
    return {
      'total': _datosReporte.length,
      'promedioDiario': _datosReporte.length / diasEnRango,
      'efectividad': 85.5, // TODO: Calcular real
      'cumplimiento': 92.3, // TODO: Calcular real
    };
  }

  // Métodos temporales para generar datos de ejemplo
  List<Map<String, dynamic>> _generarDatosProductividad() {
    return List.generate(10, (index) => {
      'lider': 'Líder ${index + 1}',
      'planeadas': 20 + index,
      'realizadas': 18 + index,
      'tiempoPromedio': 45 + index * 2,
      'efectividad': 85 + index,
    });
  }

  List<Map<String, dynamic>> _generarDatosEfectividad() {
    return List.generate(10, (index) => {
      'periodo': 'Semana ${index + 1}',
      'meta': 100,
      'alcanzado': 80 + index * 2,
      'porcentaje': 80 + index * 2,
      'tendencia': index % 2 == 0 ? 'up' : 'down',
    });
  }

  List<Map<String, dynamic>> _generarDatosCumplimiento() {
    return List.generate(10, (index) => {
      'lider': 'Líder ${index + 1}',
      'planSemanal': 25,
      'ejecutado': 20 + index,
      'cumplimiento': 80 + index,
    });
  }
}