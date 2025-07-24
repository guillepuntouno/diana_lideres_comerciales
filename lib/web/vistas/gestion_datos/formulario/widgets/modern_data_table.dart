import 'package:flutter/material.dart';

class ModernDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> formularios;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool) onSort;
  final Function(BuildContext, Map<String, dynamic>) onEdit;
  final Function(BuildContext, Map<String, dynamic>) onDuplicate;
  final Function(BuildContext, Map<String, dynamic>) onDelete;

  const ModernDataTable({
    Key? key,
    required this.formularios,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF8F9FA),
              ),
              headingRowHeight: 56,
              dataRowHeight: 72,
              horizontalMargin: 24,
              columnSpacing: 32,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              columns: [
                DataColumn(
                  label: const Text(
                    'Nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                  onSort: onSort,
                ),
                DataColumn(
                  label: const Text(
                    'Versión',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                  onSort: onSort,
                ),
                DataColumn(
                  label: const Text(
                    'Tipo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Estado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                ),
                DataColumn(
                  label: const Text(
                    'Última Actualización',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                  onSort: onSort,
                ),
                const DataColumn(
                  label: Text(
                    'Acciones',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C2120),
                    ),
                  ),
                ),
              ],
              rows: formularios.map((formulario) {
                final bool activo = formulario['activa'] ?? false;
                final bool capturado = formulario['capturado'] ?? false;
                
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formulario['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Color(0xFF1C2120),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(formulario['preguntas'] as List?)?.length ?? 0} preguntas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          formulario['version'] ?? 'v1.0',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildTipoChip(formulario['tipo']),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: activo ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activo ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: activo ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: activo ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatFecha(formulario['fechaActualizacion']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1C2120),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatHora(formulario['fechaActualizacion']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: const Color(0xFF1976D2),
                            tooltip: 'Editar',
                            onPressed: () => onEdit(context, formulario),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            color: const Color(0xFF757575),
                            tooltip: 'Duplicar',
                            onPressed: () => onDuplicate(context, formulario),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: const Color(0xFFD32F2F),
                            tooltip: 'Eliminar',
                            onPressed: () => onDelete(context, formulario),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoChip(String? tipo) {
    final tipoLower = tipo?.toLowerCase() ?? 'desconocido';
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (tipoLower) {
      case 'detalle':
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF6A1B9A);
        icon = Icons.inventory_2_outlined;
        label = 'Detalle';
        break;
      case 'mayoreo':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        icon = Icons.warehouse_outlined;
        label = 'Mayoreo';
        break;
      case 'programa_excelencia':
        bgColor = const Color(0xFFE8EAF6);
        textColor = const Color(0xFF283593);
        icon = Icons.star_outline;
        label = 'Excelencia';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        label = 'Sin tipo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return 'Sin fecha';
    final date = DateTime.tryParse(fecha);
    if (date == null) return fecha;
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${meses[date.month - 1]} ${date.year}';
  }

  String _formatHora(String? fecha) {
    if (fecha == null) return '';
    final date = DateTime.tryParse(fecha);
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}