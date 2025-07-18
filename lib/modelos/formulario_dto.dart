import 'package:hive/hive.dart';

part 'formulario_dto.g.dart';

/// ------------------------------------------------------------
/// ENUMS
/// ------------------------------------------------------------

@HiveType(typeId: 30)
enum CanalType {
  @HiveField(0)
  DETALLE,
  @HiveField(1)
  MAYOREO,
  @HiveField(2)
  EXCELENCIA,
}

@HiveType(typeId: 31)
enum FormStatus {
  @HiveField(0)
  ACTIVO,
  @HiveField(1)
  INACTIVO,
}

/// ------------------------------------------------------------
/// OPCIONES & PREGUNTAS
/// ------------------------------------------------------------

@HiveType(typeId: 32)
class OpcionDTO extends HiveObject {
  @HiveField(0)
  String valor;
  @HiveField(1)
  String etiqueta;
  @HiveField(2)
  int puntuacion;

  OpcionDTO({required this.valor, required this.etiqueta, required this.puntuacion});
  
  /// Constructor factory para crear desde JSON
  factory OpcionDTO.fromJson(Map<String, dynamic> json) {
    return OpcionDTO(
      valor: json['valor'] ?? '',
      etiqueta: json['etiqueta'] ?? '',
      puntuacion: json['puntuacion'] ?? 0,
    );
  }
  
  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'valor': valor,
      'etiqueta': etiqueta,
      'puntuacion': puntuacion,
    };
  }
}

@HiveType(typeId: 33)
class PreguntaDTO extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String tipoEntrada; // select, radio, checkbox, text
  @HiveField(2)
  int orden;
  @HiveField(3)
  String section;
  @HiveField(4)
  List<OpcionDTO> opciones;
  @HiveField(5)
  dynamic value;
  @HiveField(6)
  String etiqueta; // Descripción de la pregunta que se muestra al usuario

  PreguntaDTO({
    required this.name,
    required this.tipoEntrada,
    required this.orden,
    required this.section,
    required this.opciones,
    required this.etiqueta,
    this.value,
  });
  
  /// Constructor factory para crear desde JSON
  factory PreguntaDTO.fromJson(Map<String, dynamic> json) {
    return PreguntaDTO(
      name: json['name'] ?? '',
      tipoEntrada: json['tipoEntrada'] ?? 'radio',
      orden: json['orden'] ?? 0,
      section: json['section'] ?? '',
      etiqueta: json['etiqueta'] ?? '',
      opciones: (json['opciones'] as List<dynamic>?)
          ?.map((o) => OpcionDTO.fromJson(o))
          .toList() ?? [],
      value: json['value'],
    );
  }
  
  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tipoEntrada': tipoEntrada,
      'orden': orden,
      'section': section,
      'etiqueta': etiqueta,
      'opciones': opciones.map((o) => o.toJson()).toList(),
      'value': value,
    };
  }
}

/// ------------------------------------------------------------
/// PLANTILLA (CATÁLOGO)
/// ------------------------------------------------------------

@HiveType(typeId: 34)
class FormularioPlantillaDTO extends HiveObject {
  @HiveField(0)
  String plantillaId; // UID backend
  @HiveField(1)
  String nombre;
  @HiveField(2)
  String version; // v1.0, v1.1
  @HiveField(3)
  FormStatus estatus; // ACTIVO / INACTIVO
  @HiveField(4)
  CanalType canal; // DETALLE / MAYOREO / EXCELENCIA
  @HiveField(5)
  List<PreguntaDTO> questions;
  @HiveField(6)
  DateTime? fechaCreacion;
  @HiveField(7)
  DateTime? fechaActualizacion;

  FormularioPlantillaDTO({
    required this.plantillaId,
    required this.nombre,
    required this.version,
    required this.estatus,
    required this.canal,
    required this.questions,
    this.fechaCreacion,
    this.fechaActualizacion,
  });
}

/// ------------------------------------------------------------
/// RESPUESTAS (RESULTADOS POR CLIENTE)
/// ------------------------------------------------------------

@HiveType(typeId: 35)
class RespuestaPreguntaDTO extends HiveObject {
  @HiveField(0)
  String questionName;
  @HiveField(1)
  dynamic value; // respuesta capturada
  @HiveField(2)
  int puntuacion; // puntuación obtenida de la opción seleccionada

  RespuestaPreguntaDTO({required this.questionName, required this.value, required this.puntuacion});
}

@HiveType(typeId: 36)
class FormularioRespuestaDTO extends HiveObject {
  @HiveField(0)
  String respuestaId; // UID local o backend
  @HiveField(1)
  String plantillaId; // referencia a FormularioPlantillaDTO
  @HiveField(2)
  String planVisitaId;
  @HiveField(3)
  String rutaId;
  @HiveField(4)
  String clientId;
  @HiveField(5)
  List<RespuestaPreguntaDTO> respuestas;
  @HiveField(6)
  int puntuacionTotal;
  @HiveField(7)
  String colorKPI; // verde, amarillo, rojo
  @HiveField(8)
  bool offline; // true si aún no se ha sincronizado
  @HiveField(9)
  DateTime fechaCreacion;
  @HiveField(10)
  DateTime? fechaSincronizacion;

  FormularioRespuestaDTO({
    required this.respuestaId,
    required this.plantillaId,
    required this.planVisitaId,
    required this.rutaId,
    required this.clientId,
    required this.respuestas,
    required this.puntuacionTotal,
    required this.colorKPI,
    required this.offline,
    required this.fechaCreacion,
    this.fechaSincronizacion,
  });
}

/// ------------------------------------------------------------
/// REGISTRO DE ADAPTERS
/// ------------------------------------------------------------

void registerFormularioAdapters() {
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(CanalTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(FormStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(32)) {
    Hive.registerAdapter(OpcionDTOAdapter());
  }
  if (!Hive.isAdapterRegistered(33)) {
    Hive.registerAdapter(PreguntaDTOAdapter());
  }
  if (!Hive.isAdapterRegistered(34)) {
    Hive.registerAdapter(FormularioPlantillaDTOAdapter());
  }
  if (!Hive.isAdapterRegistered(35)) {
    Hive.registerAdapter(RespuestaPreguntaDTOAdapter());
  }
  if (!Hive.isAdapterRegistered(36)) {
    Hive.registerAdapter(FormularioRespuestaDTOAdapter());
  }
}

/// ------------------------------------------------------------
/// SERVICIOS DE DOMINIO (ABSTRACCIONES)
/// ------------------------------------------------------------

/// Provee operaciones para obtener y actualizar el catálogo local de plantillas
abstract class PlantillaService {
  /// Obtiene todas las plantillas almacenadas localmente
  Future<List<FormularioPlantillaDTO>> getAllPlantillas();

  /// Devuelve todas las plantillas activas por canal.
  Future<List<FormularioPlantillaDTO>> getPlantillasByCanal(CanalType canal);
  
  /// Obtiene una plantilla específica por ID
  Future<FormularioPlantillaDTO?> getPlantillaById(String plantillaId);
  
  /// Guarda o actualiza una plantilla en el almacenamiento local
  Future<void> savePlantilla(FormularioPlantillaDTO plantilla);
  
  /// Guarda múltiples plantillas (útil para sincronización)
  Future<void> savePlantillas(List<FormularioPlantillaDTO> plantillas);
  
  /// Elimina una plantilla específica
  Future<void> deletePlantilla(String plantillaId);
  
  /// Limpia todas las plantillas (útil para re-sincronización completa)
  Future<void> clearAllPlantillas();
}

/// Gestiona la captura y sincronización de respuestas
abstract class CapturaFormularioService {
  /// Guarda respuesta en Hive (offline-ready).
  Future<void> saveRespuesta(FormularioRespuestaDTO respuesta);
  
  /// Obtiene una respuesta específica por ID
  Future<FormularioRespuestaDTO?> getRespuestaById(String respuestaId);

  /// Devuelve el historial de formularios respondidos por clientId.
  Future<List<FormularioRespuestaDTO>> getRespuestasPorCliente(String clientId);
  
  /// Devuelve respuestas por plantilla
  Future<List<FormularioRespuestaDTO>> getRespuestasPorPlantilla(String plantillaId);
  
  /// Devuelve respuestas pendientes de sincronizar
  Future<List<FormularioRespuestaDTO>> getRespuestasPendientes();

  /// Marca una respuesta como sincronizada
  Future<void> marcarComoSincronizada(String respuestaId);
  
  /// Intenta subir respuestas con offline == true cuando haya red.
  Future<void> syncRespuestasPendientes();
  
  /// Elimina una respuesta específica
  Future<void> deleteRespuesta(String respuestaId);
  
  /// Obtiene estadísticas de respuestas
  Future<Map<String, dynamic>> getEstadisticas();
}