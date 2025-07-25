import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/acuerdos_repository.dart';
import '../../domain/compromiso.dart';

// Provider para el repositorio
final acuerdosRepositoryProvider = Provider<AcuerdosRepository>((ref) {
  return AcuerdosRepository();
});

// Estado para el filtro de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// Estado para el filtro de estado
final statusFilterProvider = StateProvider<String?>((ref) => null);

// Estado para el filtro de tipo
final tipoFilterProvider = StateProvider<String?>((ref) => null);

// Provider para obtener todos los compromisos filtrados
final compromisosFilteredProvider = Provider<List<Compromiso>>((ref) {
  final repository = ref.watch(acuerdosRepositoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);
  final tipoFilter = ref.watch(tipoFilterProvider);
  
  // Obtener todos los compromisos
  var compromisos = repository.obtenerTodosLosCompromisos();
  
  // Aplicar filtro de búsqueda
  if (searchQuery.isNotEmpty) {
    compromisos = compromisos.where((c) {
      return c.detalle.toLowerCase().contains(searchQuery) ||
             c.tipo.toLowerCase().contains(searchQuery) ||
             c.clienteNombre.toLowerCase().contains(searchQuery) ||
             c.clienteId.toLowerCase().contains(searchQuery) ||
             c.rutaId.toLowerCase().contains(searchQuery);
    }).toList();
  }
  
  // Aplicar filtro de estado
  if (statusFilter != null && statusFilter.isNotEmpty) {
    compromisos = compromisos.where((c) => c.status == statusFilter).toList();
  }
  
  // Aplicar filtro de tipo
  if (tipoFilter != null && tipoFilter.isNotEmpty) {
    compromisos = compromisos.where((c) => c.tipo == tipoFilter).toList();
  }
  
  return compromisos;
});

// Provider para obtener los tipos de compromiso disponibles
final tiposCompromisoProvider = Provider<List<String>>((ref) {
  final repository = ref.watch(acuerdosRepositoryProvider);
  return repository.obtenerTiposCompromiso();
});

// Provider para obtener estadísticas
final estadisticasCompromisosProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(acuerdosRepositoryProvider);
  return repository.obtenerEstadisticasCompromisos();
});

// NotifierProvider para manejar las acciones
class ReporteAcuerdosNotifier extends Notifier<void> {
  @override
  void build() {
    // Estado inicial vacío
  }

  void setSearchQuery(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void toggleStatusFilter(String? status) {
    final currentStatus = ref.read(statusFilterProvider);
    ref.read(statusFilterProvider.notifier).state = 
        currentStatus == status ? null : status;
  }

  void toggleTipoFilter(String? tipo) {
    final currentTipo = ref.read(tipoFilterProvider);
    ref.read(tipoFilterProvider.notifier).state = 
        currentTipo == tipo ? null : tipo;
  }

  void clearFilters() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(statusFilterProvider.notifier).state = null;
    ref.read(tipoFilterProvider.notifier).state = null;
  }
}

final reporteAcuerdosNotifierProvider = 
    NotifierProvider<ReporteAcuerdosNotifier, void>(
  ReporteAcuerdosNotifier.new,
);