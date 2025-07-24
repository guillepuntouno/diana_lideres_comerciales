import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diana_lc_front/shared/servicios/formularios_api_service.dart';
import 'package:diana_lc_front/shared/repositorios/formularios_repositorio.dart';
import 'package:diana_lc_front/shared/servicios/offline_sync_manager.dart';

/// Estado de los formularios
class FormulariosState {
  final List<Map<String, dynamic>> formularios;
  final bool isLoading;
  final String? error;
  final String? busqueda;
  final bool? filtroActivo;

  FormulariosState({
    required this.formularios,
    required this.isLoading,
    this.error,
    this.busqueda,
    this.filtroActivo,
  });

  FormulariosState copyWith({
    List<Map<String, dynamic>>? formularios,
    bool? isLoading,
    String? error,
    String? busqueda,
    bool? filtroActivo,
  }) {
    return FormulariosState(
      formularios: formularios ?? this.formularios,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      busqueda: busqueda ?? this.busqueda,
      filtroActivo: filtroActivo ?? this.filtroActivo,
    );
  }
}

/// Notifier principal de formularios
class FormulariosNotifier extends StateNotifier<FormulariosState> {
  final FormulariosApiService _apiService;
  final FormulariosRepositorio _repositorio;
  final OfflineSyncManager _syncManager;

  FormulariosNotifier(
    this._apiService,
    this._repositorio,
    this._syncManager,
  ) : super(FormulariosState(formularios: [], isLoading: false)) {
    cargarFormularios();
  }

  /// Cargar formularios desde API
  Future<void> cargarFormularios() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cargar desde API
      final formulariosApi = await _apiService.obtenerFormularios();
      
      // Aplicar filtros si existen
      final formulariosFiltrados = _aplicarFiltros(formulariosApi);
      
      state = state.copyWith(
        formularios: formulariosFiltrados,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error al cargar formularios: $e');
      state = state.copyWith(
        formularios: [],
        isLoading: false,
        error: 'Error al cargar formularios: $e',
      );
    }
  }

  /// Crear nuevo formulario
  Future<bool> crearFormulario(Map<String, dynamic> formulario) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Generar ID temporal si no tiene
      if (formulario['id'] == null || formulario['id'].isEmpty) {
        formulario['id'] = 'pf-${DateTime.now().millisecondsSinceEpoch}';
      }

      formulario['fechaCreacion'] = DateTime.now().toIso8601String();
      formulario['fechaActualizacion'] = DateTime.now().toIso8601String();

      try {
        // Crear en el servidor
        final formularioCreado = await _apiService.crearFormulario(formulario);
        
        // Recargar lista
        await cargarFormularios();
        
        state = state.copyWith(isLoading: false);
        return true;
      } catch (e) {
        print('❌ Error al crear formulario: $e');
        state = state.copyWith(
          isLoading: false,
          error: 'Error al crear formulario: $e',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al crear formulario: $e',
      );
      return false;
    }
  }

  /// Actualizar formulario existente
  Future<bool> actualizarFormulario(String id, Map<String, dynamic> formulario) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      formulario['fechaActualizacion'] = DateTime.now().toIso8601String();

      try {
        // Actualizar directamente en el servidor
        final formularioActualizado = await _apiService.actualizarFormulario(id, formulario);
        
        // Actualizar lista local
        await cargarFormularios();
        
        state = state.copyWith(isLoading: false);
        return true;
      } catch (e) {
        print('❌ Error al actualizar en servidor: $e');
        state = state.copyWith(
          isLoading: false,
          error: 'Error al actualizar formulario: $e',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar formulario: $e',
      );
      return false;
    }
  }

  /// Eliminar formulario
  Future<bool> eliminarFormulario(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Eliminar en servidor
      final exito = await _apiService.eliminarFormulario(id);
      
      if (exito) {
        await cargarFormularios();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al eliminar formulario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar formulario: $e',
      );
      return false;
    }
  }

  /// Cambiar estado activo/inactivo
  Future<bool> cambiarEstadoFormulario(String id, bool activa) async {
    try {
      // Obtener formulario de la lista actual
      final formulario = state.formularios.firstWhere(
        (f) => f['id'] == id,
        orElse: () => throw Exception('Formulario no encontrado'),
      );

      final formularioActualizado = Map<String, dynamic>.from(formulario);
      formularioActualizado['activa'] = activa;
      
      return await actualizarFormulario(id, formularioActualizado);
    } catch (e) {
      state = state.copyWith(error: 'Error al cambiar estado: $e');
      return false;
    }
  }

  /// Duplicar formulario
  Future<bool> duplicarFormulario(String id, String nuevaVersion) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Obtener formulario original de la lista actual
      final formularioOriginal = state.formularios.firstWhere(
        (f) => f['id'] == id,
        orElse: () => throw Exception('Formulario no encontrado'),
      );

      try {
        // Duplicar en servidor
        final nuevoFormulario = await _apiService.duplicarFormulario(
          formularioOriginal,
          nuevaVersion,
        );
        
        await cargarFormularios();
        state = state.copyWith(isLoading: false);
        return true;
      } catch (e) {
        print('❌ Error al duplicar formulario: $e');
        state = state.copyWith(
          isLoading: false,
          error: 'Error al duplicar formulario: $e',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al duplicar formulario: $e',
      );
      return false;
    }
  }

  /// Aplicar búsqueda
  void buscar(String termino) {
    state = state.copyWith(busqueda: termino);
    cargarFormularios();
  }

  /// Aplicar filtro por estado
  void filtrarPorEstado(bool? activo) {
    state = state.copyWith(filtroActivo: activo);
    cargarFormularios();
  }

  /// Aplicar filtros a la lista
  List<Map<String, dynamic>> _aplicarFiltros(List<Map<String, dynamic>> formularios) {
    var resultado = formularios;

    // Filtrar por búsqueda
    if (state.busqueda != null && state.busqueda!.isNotEmpty) {
      resultado = resultado.where((f) {
        final nombre = f['nombre']?.toString().toLowerCase() ?? '';
        final version = f['version']?.toString().toLowerCase() ?? '';
        final termino = state.busqueda!.toLowerCase();
        return nombre.contains(termino) || version.contains(termino);
      }).toList();
    }

    // Filtrar por estado activo
    if (state.filtroActivo != null) {
      resultado = resultado.where((f) => f['activa'] == state.filtroActivo).toList();
    }

    return resultado;
  }
}

// Providers
final formulariosProvider = StateNotifierProvider<FormulariosNotifier, FormulariosState>((ref) {
  return FormulariosNotifier(
    FormulariosApiService(),
    FormulariosRepositorio(),
    OfflineSyncManager(),
  );
});

// Provider para el formulario en edición
final formularioEditProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Provider para el paso del wizard
final wizardStepProvider = StateProvider<int>((ref) => 0);