import 'package:hive/hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/cliente_hive.dart';

class ClienteRepository {
  static const String _boxName = 'clientes';
  late Box<ClienteHive> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<ClienteHive>(_boxName);
    } else {
      _box = await Hive.openBox<ClienteHive>(_boxName);
    }
  }

  // Guardar cliente
  Future<void> guardarCliente(ClienteHive cliente) async {
    await _box.put(cliente.id, cliente);
  }

  // Guardar múltiples clientes
  Future<void> guardarClientes(List<ClienteHive> clientes) async {
    final Map<String, ClienteHive> clientesMap = {
      for (var cliente in clientes) cliente.id: cliente
    };
    await _box.putAll(clientesMap);
  }

  // Obtener todos los clientes activos
  List<ClienteHive> obtenerTodos() {
    return _box.values.where((cliente) => cliente.activo).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  // Obtener clientes por ruta
  List<ClienteHive> obtenerPorRuta(String rutaId) {
    return _box.values
        .where((cliente) => cliente.rutaId == rutaId && cliente.activo)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  // Obtener clientes por IDs
  List<ClienteHive> obtenerPorIds(List<String> ids) {
    return ids
        .map((id) => _box.get(id))
        .where((cliente) => cliente != null && cliente.activo)
        .cast<ClienteHive>()
        .toList();
  }

  // Obtener cliente por ID
  ClienteHive? obtenerPorId(String id) {
    return _box.get(id);
  }

  // Buscar clientes por nombre
  List<ClienteHive> buscarPorNombre(String query) {
    final queryLower = query.toLowerCase();
    return _box.values
        .where((cliente) =>
            cliente.activo &&
            cliente.nombre.toLowerCase().contains(queryLower))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  // Obtener clientes por segmento
  List<ClienteHive> obtenerPorSegmento(String segmento) {
    return _box.values
        .where((cliente) => cliente.segmento == segmento && cliente.activo)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  // Eliminar todos los clientes
  Future<void> limpiar() async {
    await _box.clear();
  }

  // Obtener fecha de última actualización
  DateTime? obtenerFechaUltimaActualizacion() {
    if (_box.isEmpty) return null;
    
    return _box.values
        .map((cliente) => cliente.fechaModificacion)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // Contar clientes por ruta
  Map<String, int> contarClientesPorRuta() {
    final Map<String, int> contador = {};
    
    for (var cliente in _box.values.where((c) => c.activo)) {
      contador[cliente.rutaId] = (contador[cliente.rutaId] ?? 0) + 1;
    }
    
    return contador;
  }
}