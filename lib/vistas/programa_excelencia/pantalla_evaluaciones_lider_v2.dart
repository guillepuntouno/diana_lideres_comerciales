import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/vistas/programa_excelencia/pantalla_detalle_evaluacion.dart';
import 'package:diana_lc_front/vistas/programa_excelencia/widgets/evaluacion_card.dart';
import 'package:sticky_headers/sticky_headers.dart';

class PantallaEvaluacionesLiderV2 extends StatefulWidget {
  const PantallaEvaluacionesLiderV2({super.key});

  @override
  State<PantallaEvaluacionesLiderV2> createState() => _PantallaEvaluacionesLiderV2State();
}

class _PantallaEvaluacionesLiderV2State extends State<PantallaEvaluacionesLiderV2> 
    with TickerProviderStateMixin {
  List<ResultadoExcelenciaHive> _evaluaciones = [];
  bool _isLoading = true;
  String _filtroEstatus = 'todos';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cargarEvaluaciones();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _cargarEvaluaciones() async {
    setState(() => _isLoading = true);
    
    try {
      final box = await Hive.openBox<ResultadoExcelenciaHive>('resultados_excelencia');
      
      List<ResultadoExcelenciaHive> evaluaciones = box.values.toList();
      evaluaciones.sort((a, b) => b.fechaCaptura.compareTo(a.fechaCaptura));
      
      setState(() {
        _evaluaciones = evaluaciones;
        _isLoading = false;
      });
      
      _fadeController.forward();
    } catch (e) {
      print('Error al cargar evaluaciones: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar evaluaciones: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _cargarEvaluaciones,
            ),
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

  Map<String, List<ResultadoExcelenciaHive>> _agruparPorFecha() {
    final Map<String, List<ResultadoExcelenciaHive>> grupos = {};
    final ahora = DateTime.now();
    
    for (final evaluacion in _evaluacionesFiltradas) {
      final diferencia = ahora.difference(evaluacion.fechaCaptura);
      String grupo;
      
      if (diferencia.inDays == 0) {
        grupo = 'Hoy';
      } else if (diferencia.inDays == 1) {
        grupo = 'Ayer';
      } else if (diferencia.inDays < 7) {
        grupo = 'Esta semana';
      } else if (diferencia.inDays < 30) {
        grupo = 'Este mes';
      } else {
        grupo = 'Anteriores';
      }
      
      grupos.putIfAbsent(grupo, () => []).add(evaluacion);
    }
    
    return grupos;
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay evaluaciones disponibles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filtroEstatus == 'todos' 
                  ? 'No se han realizado evaluaciones aún' 
                  : 'No hay evaluaciones ${_filtroEstatus}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cargarEvaluaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Evaluaciones de Desempeño'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C2120),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1C2120)),
      ),
      body: Column(
        children: [
          // Filtros con Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todas', 'todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completadas', 'completada'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendientes', 'pendiente'),
                ],
              ),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      await _cargarEvaluaciones();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Evaluaciones actualizadas'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: _evaluacionesFiltradas.isEmpty
                        ? _buildEmptyState()
                        : _buildGroupedList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstatus == value;
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroEstatus = value;
          });
          HapticFeedback.lightImpact();
        },
        selectedColor: const Color(0xFFDE1327).withOpacity(0.1),
        backgroundColor: Colors.white,
        checkmarkColor: const Color(0xFFDE1327),
        labelStyle: TextStyle(
          color: isSelected 
              ? const Color(0xFFDE1327) 
              : const Color(0xFF1C2120),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected 
              ? const Color(0xFFDE1327) 
              : Colors.grey.shade300,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }

  Widget _buildGroupedList() {
    final grupos = _agruparPorFecha();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16),
        itemCount: grupos.length,
        itemBuilder: (context, index) {
          final titulo = grupos.keys.elementAt(index);
          final evaluaciones = grupos[titulo]!;
          
          return StickyHeader(
            header: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surface,
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            content: Column(
              children: evaluaciones.map((evaluacion) {
                return EvaluacionCard(
                  evaluacion: evaluacion,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => 
                            PantallaDetalleEvaluacion(evaluacion: evaluacion),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}