import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'reporte_programa_excelencia_vm.dart';

/// Pantalla de reporte del Programa de Excelencia
class ReporteProgramaExcelencia extends StatelessWidget {
  const ReporteProgramaExcelencia({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReporteProgramaExcelenciaVM(),
      child: const _ReporteProgramaExcelenciaView(),
    );
  }
}

class _ReporteProgramaExcelenciaView extends StatelessWidget {
  const _ReporteProgramaExcelenciaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteProgramaExcelenciaVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Reporte Programa de Excelencia',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C2120),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        vm.error!,
                        style: GoogleFonts.poppins(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: vm.cargarDatos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildFiltros(context, vm),
                    Expanded(
                      child: _buildTablaReporte(context, vm),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFiltros(BuildContext context, ReporteProgramaExcelenciaVM vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Filtro País
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: vm.filtroPais,
                  decoration: InputDecoration(
                    labelText: 'País',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...vm.paisesDisponibles.map((pais) => DropdownMenuItem(
                          value: pais,
                          child: Text(pais),
                        )),
                  ],
                  onChanged: vm.setFiltroPais,
                ),
              ),
              
              // Filtro Centro Distribución
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: vm.filtroCentroDistribucion,
                  decoration: InputDecoration(
                    labelText: 'Centro Distribución',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...vm.centrosDisponibles.map((centro) => DropdownMenuItem(
                          value: centro,
                          child: Text(centro),
                        )),
                  ],
                  onChanged: vm.setFiltroCentroDistribucion,
                ),
              ),
              
              // Filtro Líder
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  value: vm.filtroLider,
                  decoration: InputDecoration(
                    labelText: 'Líder',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...vm.lideresDisponibles.map((lider) => DropdownMenuItem(
                          value: lider,
                          child: Text(lider.split('-').last), // Mostrar solo el nombre
                        )),
                  ],
                  onChanged: vm.setFiltroLider,
                ),
              ),
              
              // Filtro Canal
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: vm.filtroCanal,
                  decoration: InputDecoration(
                    labelText: 'Canal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...vm.canalesDisponibles.map((canal) => DropdownMenuItem(
                          value: canal,
                          child: Text(canal),
                        )),
                  ],
                  onChanged: vm.setFiltroCanal,
                ),
              ),
              
              // Botón consultar/recargar
              ElevatedButton.icon(
                onPressed: vm.cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Consultar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A169),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Botón limpiar filtros
              TextButton.icon(
                onPressed: vm.limpiarFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDE1327),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTablaReporte(BuildContext context, ReporteProgramaExcelenciaVM vm) {
    final datos = vm.obtenerDatosTabla();
    final totalesPorCanal = vm.obtenerTotalesPorCanal();
    final totalGeneral = vm.obtenerTotalGeneral();

    if (datos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos para mostrar',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o presiona "Consultar" para recargar',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: vm.cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A169),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 56,
          dataRowHeight: 48,
          headingTextStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C2120),
          ),
          dataTextStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF1C2120),
          ),
          columns: const [
            DataColumn(label: Text('Canal')),
            DataColumn(label: Text('Líder')),
            DataColumn(label: Text('Equipo')),
            DataColumn(label: Text('Alineación\nObjetivos'), numeric: true),
            DataColumn(label: Text('Planeación'), numeric: true),
            DataColumn(label: Text('Organización'), numeric: true),
            DataColumn(label: Text('Ejecución'), numeric: true),
            DataColumn(label: Text('Retroalimentación\ny Reconocimiento'), numeric: true),
            DataColumn(label: Text('Logro Objetivos\nde Venta'), numeric: true),
            DataColumn(label: Text('Puntaje\nFinal'), numeric: true),
          ],
          rows: [
            // Filas de datos
            ...datos.map((fila) => DataRow(
                  cells: [
                    DataCell(Text(fila['canal'] ?? '')),
                    DataCell(Text(fila['lider'] ?? '')),
                    DataCell(Text(fila['equipo'] ?? '')),
                    DataCell(Text(_formatearPuntaje(fila['alineacionObjetivos']))),
                    DataCell(Text(_formatearPuntaje(fila['planeacion']))),
                    DataCell(Text(_formatearPuntaje(fila['organizacion']))),
                    DataCell(Text(_formatearPuntaje(fila['ejecucion']))),
                    DataCell(Text(_formatearPuntaje(fila['retroalimentacion']))),
                    DataCell(Text(_formatearPuntaje(fila['logroObjetivos']))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getColorFondo(fila['color']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatearPuntaje(fila['puntajeFinal']),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getColorTexto(fila['color']),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
            
            // Separador
            if (totalesPorCanal.isNotEmpty) ...[
              DataRow(
                cells: List.generate(10, (_) => const DataCell(SizedBox())),
              ),
            ],
            
            // Totales por canal
            ...totalesPorCanal.entries.map((entrada) {
              final canal = entrada.key;
              final totales = entrada.value;
              final color = _getColorPorPuntaje(totales['puntajeFinal'] ?? 0);
              
              return DataRow(
                color: MaterialStateProperty.all(Colors.grey[100]),
                cells: [
                  DataCell(Text('Total $canal', style: const TextStyle(fontWeight: FontWeight.w600))),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  DataCell(Text(_formatearPuntaje(totales['alineacionObjetivos']), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_formatearPuntaje(totales['planeacion']), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_formatearPuntaje(totales['organizacion']), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_formatearPuntaje(totales['ejecucion']), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_formatearPuntaje(totales['retroalimentacion']), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_formatearPuntaje(totales['logroObjetivos']), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColorFondo(color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatearPuntaje(totales['puntajeFinal']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getColorTexto(color),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            
            // Total General
            if (totalGeneral.isNotEmpty) ...[
              DataRow(
                color: MaterialStateProperty.all(const Color(0xFFDE1327).withOpacity(0.1)),
                cells: [
                  const DataCell(Text('TOTAL GENERAL', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  DataCell(Text(_formatearPuntaje(totalGeneral['alineacionObjetivos']), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(_formatearPuntaje(totalGeneral['planeacion']), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(_formatearPuntaje(totalGeneral['organizacion']), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(_formatearPuntaje(totalGeneral['ejecucion']), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(_formatearPuntaje(totalGeneral['retroalimentacion']), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(_formatearPuntaje(totalGeneral['logroObjetivos']), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColorFondo(_getColorPorPuntaje(totalGeneral['puntajeFinal'] ?? 0)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatearPuntaje(totalGeneral['puntajeFinal']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getColorTexto(_getColorPorPuntaje(totalGeneral['puntajeFinal'] ?? 0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatearPuntaje(double? puntaje) {
    if (puntaje == null) return '0';
    return puntaje.toStringAsFixed(1);
  }

  String _getColorPorPuntaje(double puntaje) {
    if (puntaje >= 85) return 'verde';
    if (puntaje >= 60) return 'amarillo';
    return 'rojo';
  }

  Color _getColorFondo(String? color) {
    switch (color) {
      case 'verde':
        return const Color(0xFF38A169).withOpacity(0.2);
      case 'amarillo':
        return const Color(0xFFF6C343).withOpacity(0.2);
      case 'rojo':
        return const Color(0xFFDE1327).withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getColorTexto(String? color) {
    switch (color) {
      case 'verde':
        return const Color(0xFF38A169);
      case 'amarillo':
        return const Color(0xFFD69E2E);
      case 'rojo':
        return const Color(0xFFDE1327);
      default:
        return Colors.grey;
    }
  }
}