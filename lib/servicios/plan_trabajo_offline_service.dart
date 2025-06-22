import '../modelos/plan_trabajo_modelo.dart';
import '../modelos/lider_comercial_modelo.dart';
import '../modelos/hive/plan_trabajo_semanal_hive.dart';
import '../modelos/hive/dia_trabajo_hive.dart';
import '../modelos/hive/cliente_hive.dart';
import '../modelos/hive/objetivo_hive.dart';
import '../repositorios/plan_trabajo_repository.dart';
import '../repositorios/cliente_repository.dart';
import '../repositorios/objetivo_repository.dart';
import 'hive_service.dart';
import 'plan_trabajo_servicio.dart';
import 'sesion_servicio.dart';

class PlanTrabajoOfflineService {
  static final PlanTrabajoOfflineService _instance = PlanTrabajoOfflineService._internal();
  factory PlanTrabajoOfflineService() => _instance;
  PlanTrabajoOfflineService._internal();

  PlanTrabajoRepository? _planRepository;
  ClienteRepository? _clienteRepository;
  ObjetivoRepository? _objetivoRepository;
  final PlanTrabajoServicio _planServicioHttp = PlanTrabajoServicio();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _planRepository ??= PlanTrabajoRepository();
    _clienteRepository ??= ClienteRepository();
    _objetivoRepository ??= ObjetivoRepository();

    await _planRepository!.init();
    await _clienteRepository!.init();
    await _objetivoRepository!.init();

    _isInitialized = true;
  }

  // ============ CARGA DE DATOS DURANTE LOGIN ============

  /// Carga todos los datos necesarios durante el login
  Future<void> cargarDatosIniciales() async {
    await initialize();

    try {
      // Cargar objetivos predefinidos (estos son estáticos)
      await _cargarObjetivos();

      // Cargar clientes del líder
      await _cargarClientes();

      // Actualizar fecha de última sincronización
      await HiveService().updateLastSyncDate();
    } catch (e) {
      print('Error cargando datos iniciales: $e');
      // No lanzar error para permitir trabajo offline
    }
  }

  /// Carga los objetivos disponibles
  Future<void> _cargarObjetivos() async {
    // Por ahora, cargar objetivos predefinidos
    // En el futuro, estos podrían venir del servidor
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

    await _objetivoRepository!.guardarObjetivos(objetivos);
  }

  /// Carga los clientes desde los datos del líder
  Future<void> _cargarClientes() async {
    final lider = await SesionServicio.obtenerLiderComercial();
    if (lider == null) return;

    final List<ClienteHive> clientesHive = [];

    // Convertir negocios a clientes
    int rutaIndex = 0;
    for (var ruta in lider.rutas) {
      for (var negocio in ruta.negocios) {
        clientesHive.add(ClienteHive(
          id: negocio.clave, // Usar clave como ID
          nombre: negocio.nombre,
          direccion: '${negocio.canal} - ${negocio.clasificacion}', // Construir dirección desde canal y clasificación
          telefono: null, // No disponible en el modelo
          rutaId: 'RUTA_${rutaIndex}', // Generar ID de ruta
          rutaNombre: ruta.nombre,
          asesorId: 'ASESOR_${rutaIndex}', // Generar ID de asesor
          asesorNombre: ruta.asesor,
          latitud: null, // No disponible en el modelo
          longitud: null, // No disponible en el modelo
          tipoNegocio: negocio.canal,
          segmento: negocio.clasificacion,
        ));
      }
      rutaIndex++;
    }

    await _clienteRepository!.guardarClientes(clientesHive);
  }

  // ============ GESTIÓN DE PLANES ============

  /// Obtiene o crea un plan para la semana especificada
  Future<PlanTrabajoModelo> obtenerOCrearPlan(
    String semana,
    String liderClave,
    LiderComercial lider,
  ) async {
    await initialize();

    // Primero buscar en Hive
    var planHive = _planRepository!.obtenerPlanPorSemana(liderClave, semana);

    if (planHive != null) {
      // Convertir de Hive a modelo
      return _convertirDesdeHive(planHive);
    }

    // Si no existe, crear uno nuevo
    final regex = RegExp(r'SEMANA (\d+) - (\d+)');
    final match = regex.firstMatch(semana);
    final numeroSemana = match?.group(1) != null ? int.parse(match!.group(1)!) : 0;
    final anio = match?.group(2) != null ? int.parse(match!.group(2)!) : DateTime.now().year;

    final (fechaInicio, fechaFin) = _calcularFechasSemana(numeroSemana, anio);

    // Inicializar días vacíos
    final diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final Map<String, DiaTrabajoHive> diasInicio = {};
    
    for (var dia in diasSemana) {
      diasInicio[dia] = DiaTrabajoHive(
        dia: dia,
        configurado: false,
      );
    }
    
    planHive = PlanTrabajoSemanalHive(
      id: _planRepository!.generarId(liderClave, semana),
      semana: semana,
      liderClave: liderClave,
      liderNombre: lider.nombre,
      centroDistribucion: lider.centroDistribucion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      numeroSemana: numeroSemana,
      anio: anio,
      dias: diasInicio,
    );

    await _planRepository!.guardarPlan(planHive);
    return _convertirDesdeHive(planHive);
  }

  /// Guarda la configuración de un día
  Future<void> guardarConfiguracionDia(
    String semana,
    String liderClave,
    DiaTrabajoModelo dia,
  ) async {
    await initialize();

    // Extraer IDs de clientes asignados
    final clienteIds = dia.clientesAsignados.map((c) => c.clienteId).toList();

    // Convertir a Hive
    final diaHive = DiaTrabajoHive(
      dia: dia.dia,
      objetivoId: dia.objetivo,
      objetivoNombre: dia.objetivo,
      tipo: dia.objetivo == 'Gestión de cliente' ? 'gestion_cliente' : 'administrativo',
      clienteIds: clienteIds,
      rutaId: dia.rutaId,
      rutaNombre: dia.rutaNombre,
      tipoActividadAdministrativa: dia.tipoActividad,
      objetivoAbordaje: dia.comentario,
      configurado: true,
    );

    print('Guardando configuración del día:');
    print('- Día: ${diaHive.dia}');
    print('- ObjetivoId: ${diaHive.objetivoId}');
    print('- ObjetivoNombre: ${diaHive.objetivoNombre}');
    print('- Tipo: ${diaHive.tipo}');
    print('- Configurado: ${diaHive.configurado}');
    
    await _planRepository!.actualizarDia(liderClave, semana, diaHive);
  }

  /// Envía el plan (cambia estatus y marca para sincronización)
  Future<void> enviarPlan(String semana, String liderClave) async {
    await initialize();

    final planHive = _planRepository!.obtenerPlanPorSemana(liderClave, semana);
    if (planHive == null) {
      throw Exception('Plan no encontrado');
    }

    // Validar que todos los días estén configurados
    final diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final todosConfigurados = diasSemana.every((dia) => 
      planHive.dias.containsKey(dia) && 
      planHive.dias[dia]!.objetivoId != null
    );

    if (!todosConfigurados) {
      throw Exception('Todos los días deben estar configurados antes de enviar');
    }

    // Cambiar estatus
    await _planRepository!.cambiarEstatus(planHive.id, 'enviado');

    // Intentar sincronizar con el servidor
    try {
      await _sincronizarPlanConServidor(planHive.id);
    } catch (e) {
      print('Error al sincronizar, se mantendrá localmente: $e');
      // No lanzar error, el plan quedará marcado para sincronización posterior
    }
  }

  // ============ SINCRONIZACIÓN ============

  /// Sincroniza un plan específico con el servidor
  Future<void> _sincronizarPlanConServidor(String planId) async {
    final planHive = HiveService().planesTrabajoSemanalesBox.get(planId);
    if (planHive == null) return;

    final planModelo = _convertirDesdeHive(planHive);
    
    // Enviar al servidor
    await _planServicioHttp.guardarPlanTrabajo(planModelo);

    // Marcar como sincronizado
    await _planRepository!.marcarComoSincronizado(planId);
  }

  /// Sincroniza todos los planes pendientes
  Future<void> sincronizarPlanesPendientes() async {
    await initialize();

    final planesPendientes = _planRepository!.obtenerPlanesPendientesSincronizar();
    
    for (var plan in planesPendientes) {
      try {
        await _sincronizarPlanConServidor(plan.id);
      } catch (e) {
        print('Error sincronizando plan ${plan.id}: $e');
      }
    }
  }

  // ============ CONSULTAS ============

  /// Obtiene la lista de objetivos disponibles
  List<ObjetivoHive> obtenerObjetivos() {
    return _objetivoRepository!.obtenerTodos();
  }

  /// Obtiene la lista de clientes por ruta
  List<ClienteHive> obtenerClientesPorRuta(String rutaId) {
    return _clienteRepository!.obtenerPorRuta(rutaId);
  }

  /// Obtiene la fecha de última sincronización
  DateTime? obtenerFechaUltimaSincronizacion() {
    return HiveService().getLastSyncDate();
  }

  /// Obtiene el repositorio de planes (para acceso directo)
  PlanTrabajoRepository getPlanRepository() {
    if (!_isInitialized) {
      throw Exception('PlanTrabajoOfflineService no está inicializado');
    }
    return _planRepository!;
  }

  // ============ CONVERSIONES ============

  /// Convierte de Hive a modelo de negocio
  PlanTrabajoModelo _convertirDesdeHive(PlanTrabajoSemanalHive planHive) {
    final plan = PlanTrabajoModelo(
      semana: planHive.semana,
      fechaInicio: planHive.fechaInicio,
      fechaFin: planHive.fechaFin,
      liderId: planHive.liderClave,
      liderNombre: planHive.liderNombre,
      centroDistribucion: planHive.centroDistribucion,
      estatus: planHive.estatus,
      sincronizado: planHive.sincronizado,
    );

    // Convertir días
    planHive.dias.forEach((nombreDia, diaHive) {
      print('Procesando día $nombreDia: configurado=${diaHive.configurado}, objetivoId=${diaHive.objetivoId}, objetivoNombre=${diaHive.objetivoNombre}');
      
      // Solo procesar días que estén configurados
      if (diaHive.configurado && diaHive.objetivoNombre != null && diaHive.objetivoNombre!.isNotEmpty) {
        // Convertir IDs de clientes a ClienteAsignadoModelo
        final clientesAsignados = diaHive.clienteIds.map((clienteId) {
          final cliente = _clienteRepository!.obtenerPorId(clienteId);
          if (cliente != null) {
            return ClienteAsignadoModelo(
              clienteId: cliente.id,
              clienteNombre: cliente.nombre,
              clienteDireccion: cliente.direccion,
              clienteTipo: cliente.tipoNegocio ?? 'detalle',
            );
          }
          // Si no se encuentra el cliente, crear uno básico
          return ClienteAsignadoModelo(
            clienteId: clienteId,
            clienteNombre: 'Cliente $clienteId',
            clienteDireccion: '',
            clienteTipo: 'detalle',
          );
        }).toList();

        plan.dias[nombreDia] = DiaTrabajoModelo(
          dia: nombreDia,
          objetivo: diaHive.objetivoNombre,
          rutaId: diaHive.rutaId,
          rutaNombre: diaHive.rutaNombre,
          clientesAsignados: clientesAsignados,
          tipoActividad: diaHive.tipoActividadAdministrativa,
          comentario: diaHive.objetivoAbordaje,
        );
        
        print('  -> Día $nombreDia agregado al plan con objetivo: ${diaHive.objetivoNombre}');
      }
    });

    plan.fechaModificacion = planHive.fechaModificacion;
    return plan;
  }

  /// Calcula las fechas de inicio y fin de una semana
  (String, String) _calcularFechasSemana(int numeroSemana, int anio) {
    final primerDiaAno = DateTime(anio, 1, 1);
    final primerLunes = primerDiaAno.add(
      Duration(days: (8 - primerDiaAno.weekday) % 7),
    );
    
    final inicioSemana = primerLunes.add(Duration(days: (numeroSemana - 1) * 7));
    final finSemana = inicioSemana.add(Duration(days: 4));
    
    final formato = 'dd/MM/yyyy';
    return (
      _formatearFecha(inicioSemana, formato),
      _formatearFecha(finSemana, formato),
    );
  }

  String _formatearFecha(DateTime fecha, String formato) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    
    return formato
        .replaceAll('dd', dia)
        .replaceAll('MM', mes)
        .replaceAll('yyyy', anio);
  }
}