import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/reporte_acuerdos_provider.dart';
import 'widgets/compromiso_tile.dart';
import 'widgets/estadisticas_card.dart';
import 'widgets/filtros_compromisos.dart';

class ReporteAcuerdosScreen extends ConsumerWidget {
  const ReporteAcuerdosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compromisos = ref.watch(compromisosFilteredProvider);
    final estadisticas = ref.watch(estadisticasCompromisosProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reporte de acuerdos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C2120),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1C2120)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // No mostrar el encabezado ya que tiene información redundante
          
          // Tarjeta de estadísticas
          EstadisticasCard(estadisticas: estadisticas),
          
          // Barra de búsqueda
          _buildSearchBar(context, ref),
          
          // Filtros
          const FiltrosCompromisos(),
          
          // Lista de compromisos
          Expanded(
            child: compromisos.isEmpty
                ? _buildEmptyState()
                : _buildCompromisosList(compromisos),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reporteAcuerdosNotifierProvider.notifier);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: notifier.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Buscar por tipo, detalle, cliente o ruta...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFDE1327)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDE1327), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCompromisosList(List<dynamic> compromisos) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: compromisos.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CompromisoTile(compromiso: compromisos[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron compromisos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los compromisos aparecerán aquí cuando\nse registren en las visitas a clientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}