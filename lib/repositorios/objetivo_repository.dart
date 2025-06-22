import 'package:hive/hive.dart';
import '../modelos/hive/objetivo_hive.dart';

class ObjetivoRepository {
  static const String _boxName = 'objetivos';
  late Box<ObjetivoHive> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<ObjetivoHive>(_boxName);
    } else {
      _box = await Hive.openBox<ObjetivoHive>(_boxName);
    }
  }

  // Guardar objetivo
  Future<void> guardarObjetivo(ObjetivoHive objetivo) async {
    await _box.put(objetivo.id, objetivo);
  }

  // Guardar múltiples objetivos
  Future<void> guardarObjetivos(List<ObjetivoHive> objetivos) async {
    final Map<String, ObjetivoHive> objetivosMap = {
      for (var objetivo in objetivos) objetivo.id: objetivo
    };
    await _box.putAll(objetivosMap);
  }

  // Obtener todos los objetivos
  List<ObjetivoHive> obtenerTodos() {
    return _box.values.where((objetivo) => objetivo.activo).toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  // Obtener objetivos por tipo
  List<ObjetivoHive> obtenerPorTipo(String tipo) {
    return _box.values
        .where((objetivo) => objetivo.tipo == tipo && objetivo.activo)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  // Obtener objetivo por ID
  ObjetivoHive? obtenerPorId(String id) {
    return _box.get(id);
  }

  // Eliminar todos los objetivos
  Future<void> limpiar() async {
    await _box.clear();
  }

  // Cargar objetivos predefinidos (para testing o inicialización)
  Future<void> cargarObjetivosPredefinidos() async {
    final objetivos = [
      ObjetivoHive(
        id: '1',
        nombre: 'Gestión de cliente',
        tipo: 'gestion_cliente',
        orden: 1,
      ),
      ObjetivoHive(
        id: '2',
        nombre: 'Actividad administrativa',
        tipo: 'administrativo',
        orden: 2,
      ),
    ];

    await guardarObjetivos(objetivos);
  }

  // Obtener fecha de última actualización
  DateTime? obtenerFechaUltimaActualizacion() {
    if (_box.isEmpty) return null;
    
    return _box.values
        .map((obj) => obj.fechaModificacion)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}