import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reporte_acuerdos_provider.dart';

class FiltrosCompromisos extends ConsumerWidget {
  const FiltrosCompromisos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(statusFilterProvider);
    final tipoFilter = ref.watch(tipoFilterProvider);
    final tiposDisponibles = ref.watch(tiposCompromisoProvider);
    final notifier = ref.read(reporteAcuerdosNotifierProvider.notifier);

    final hasFilters = statusFilter != null || tipoFilter != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2120),
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: notifier.clearFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDE1327),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Pendiente',
                  value: 'PENDIENTE',
                  selected: statusFilter == 'PENDIENTE',
                  onSelected: () => notifier.toggleStatusFilter('PENDIENTE'),
                  color: const Color(0xFFEAB308),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Cerrado',
                  value: 'CERRADO',
                  selected: statusFilter == 'CERRADO',
                  onSelected: () => notifier.toggleStatusFilter('CERRADO'),
                  color: const Color(0xFF0FA958),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Cancelado',
                  value: 'CANCELADO',
                  selected: statusFilter == 'CANCELADO',
                  onSelected: () => notifier.toggleStatusFilter('CANCELADO'),
                  color: Colors.red,
                ),
              ],
            ),
          ),
          
          if (tiposDisponibles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Tipo de compromiso',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C2120),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tiposDisponibles.map((tipo) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      label: tipo,
                      value: tipo,
                      selected: tipoFilter == tipo,
                      onSelected: () => notifier.toggleTipoFilter(tipo),
                      color: const Color(0xFFDE1327),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onSelected,
    required Color color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? color : Colors.grey.shade300,
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}