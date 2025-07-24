import 'dart:convert';
import 'package:diana_lc_front/shared/modelos/plan_trabajo_modelo.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_semanal_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/dia_trabajo_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/cliente_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/objetivo_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/repositorios/plan_trabajo_repository.dart';
import 'package:diana_lc_front/shared/repositorios/cliente_repository.dart';
import 'package:diana_lc_front/shared/repositorios/objetivo_repository.dart';
import 'package:diana_lc_front/shared/repositorios/plan_trabajo_unificado_repository.dart';
import 'hive_service.dart';
import 'plan_trabajo_servicio.dart';
import 'sesion_servicio.dart';
import 'indicadores_gestion_servicio.dart';

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

    try {
      // Asegurar que HiveService esté inicializado primero
      final hiveService = HiveService();
      if (!hiveService.isInitialized) {
        print('⚠️ HiveService no inicializado, inicializando ahora...');
        await hiveService.initialize();
      }

      _planRepository ??= PlanTrabajoRepository();
      _clienteRepository ??= ClienteRepository();
      _objetivoRepository ??= ObjetivoRepository();

      await _planRepository!.init();
      await _clienteRepository!.init();
      await _objetivoRepository!.init();

      _isInitialized = true;
      print('✅ PlanTrabajoOfflineService inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar PlanTrabajoOfflineService: $e');
      _isInitialized = false;
      rethrow;
    }
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

    // Obtener el plan existente para verificar si ya hay datos del día
    final planExistente = _planRepository!.obtenerPlanPorSemana(liderClave, semana);
    DiaTrabajoHive? diaExistente;
    if (planExistente != null && planExistente.dias.containsKey(dia.dia)) {
      diaExistente = planExistente.dias[dia.dia];
    }

    // Si es una actividad administrativa
    if (dia.objetivo == 'Actividad administrativa') {
      if (diaExistente != null && diaExistente.configurado) {
        // Parsear actividades administrativas existentes
        List<Map<String, dynamic>> actividadesExistentes = [];
        
        if (diaExistente.tipoActividadAdministrativa != null && diaExistente.tipoActividadAdministrativa!.isNotEmpty) {
          try {
            if (diaExistente.tipoActividadAdministrativa!.startsWith('[')) {
              actividadesExistentes = List<Map<String, dynamic>>.from(
                jsonDecode(diaExistente.tipoActividadAdministrativa!)
              );
            } else {
              actividadesExistentes = [{
                'tipo': diaExistente.tipoActividadAdministrativa!,
                'objetivo': 'Actividad administrativa',
                'estatus': 'pendiente',
                'fechaCompletado': null
              }];
            }
          } catch (e) {
            actividadesExistentes = [{
              'tipo': diaExistente.tipoActividadAdministrativa!,
              'objetivo': 'Actividad administrativa',
              'estatus': 'pendiente',
              'fechaCompletado': null
            }];
          }
        }
        
        // Agregar nueva actividad
        actividadesExistentes.add({
          'tipo': dia.tipoActividad ?? '',
          'objetivo': 'Actividad administrativa',
          'estatus': 'pendiente',
          'fechaCompletado': null
        });
        
        // Actualizar el día existente
        diaExistente.tipoActividadAdministrativa = jsonEncode(actividadesExistentes);
        diaExistente.fechaModificacion = DateTime.now();
        
        // Si ya tiene gestión de cliente, cambiar tipo a mixto
        if (diaExistente.tipo == 'gestion_cliente' && diaExistente.clienteIds.isNotEmpty) {
          diaExistente.tipo = 'mixto';
          diaExistente.objetivoId = 'Múltiples objetivos';
          diaExistente.objetivoNombre = 'Múltiples objetivos';
        }
        
        await _planRepository!.actualizarDia(liderClave, semana, diaExistente);
      } else {
        // Crear nuevo día administrativo
        final diaHive = DiaTrabajoHive(
          dia: dia.dia,
          objetivoId: dia.objetivo,
          objetivoNombre: dia.objetivo,
          tipo: 'administrativo',
          clienteIds: [],
          rutaId: null,
          rutaNombre: null,
          tipoActividadAdministrativa: jsonEncode([{
            'tipo': dia.tipoActividad,
            'objetivo': 'Actividad administrativa',
            'estatus': 'pendiente',
            'fechaCompletado': null
          }]),
          objetivoAbordaje: null,
          configurado: true,
        );
        
        await _planRepository!.actualizarDia(liderClave, semana, diaHive);
      }
      
    } else if (dia.objetivo == 'Gestión de cliente') {
      if (diaExistente != null && diaExistente.configurado) {
        // Combinar IDs de clientes
        final clienteIdsExistentes = Set<String>.from(diaExistente.clienteIds);
        final clienteIdsNuevos = dia.clientesAsignados.map((c) => c.clienteId).toSet();
        clienteIdsExistentes.addAll(clienteIdsNuevos);
        
        // Actualizar el día existente
        diaExistente.clienteIds = clienteIdsExistentes.toList();
        if (dia.rutaId != null) diaExistente.rutaId = dia.rutaId;
        if (dia.rutaNombre != null) diaExistente.rutaNombre = dia.rutaNombre;
        diaExistente.fechaModificacion = DateTime.now();
        
        // El campo comentario ya contiene los objetivos de abordaje en formato JSON
        if (dia.comentario != null) {
          diaExistente.objetivoAbordaje = dia.comentario;
        }
        
        // Si ya tiene actividades administrativas, cambiar tipo a mixto
        if (diaExistente.tipo == 'administrativo' && 
            diaExistente.tipoActividadAdministrativa != null && 
            diaExistente.tipoActividadAdministrativa!.isNotEmpty) {
          diaExistente.tipo = 'mixto';
          diaExistente.objetivoId = 'Múltiples objetivos';
          diaExistente.objetivoNombre = 'Múltiples objetivos';
        } else if (diaExistente.tipo != 'mixto') {
          // Si no es mixto, actualizar como gestión de cliente normal
          diaExistente.tipo = 'gestion_cliente';
          diaExistente.objetivoId = dia.objetivo;
          diaExistente.objetivoNombre = dia.objetivo;
        }
        
        await _planRepository!.actualizarDia(liderClave, semana, diaExistente);
      } else {
        // Crear nuevo día de gestión cliente
        final clienteIds = dia.clientesAsignados.map((c) => c.clienteId).toList();
        
        final diaHive = DiaTrabajoHive(
          dia: dia.dia,
          objetivoId: dia.objetivo,
          objetivoNombre: dia.objetivo,
          tipo: 'gestion_cliente',
          clienteIds: clienteIds,
          rutaId: dia.rutaId,
          rutaNombre: dia.rutaNombre,
          tipoActividadAdministrativa: null,
          objetivoAbordaje: dia.comentario,
          configurado: true,
        );
        
        await _planRepository!.actualizarDia(liderClave, semana, diaHive);
      }
    }
    
    // Sincronizar con el plan unificado después de actualizar el día
    await sincronizarConPlanUnificado(semana, liderClave);
    print('✅ Día sincronizado con plan unificado');
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
    final finSemana = inicioSemana.add(Duration(days: 5));
    
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
  
  /// Sincroniza un PlanTrabajoSemanalHive con un PlanTrabajoUnificadoHive
  /// Esto asegura que cuando se crea/actualiza un plan semanal, también se cree/actualice el plan unificado
  Future<void> sincronizarConPlanUnificado(String semana, String liderClave) async {
    try {
      print('🔄 Iniciando sincronización de plan semanal con plan unificado...');
      
      // Obtener el plan semanal
      final planSemanal = _planRepository!.obtenerPlanPorSemana(liderClave, semana);
      if (planSemanal == null) {
        print('❌ No se encontró plan semanal para sincronizar');
        return;
      }
      
      // Crear repositorio del plan unificado
      final planUnificadoRepo = PlanTrabajoUnificadoRepository();
      
      // Inicializar servicio de indicadores
      final indicadoresServicio = IndicadoresGestionServicio();
      
      // Buscar si ya existe un plan unificado
      PlanTrabajoUnificadoHive? planUnificado = planUnificadoRepo.obtenerPlan(planSemanal.id);
      
      if (planUnificado == null) {
        print('📝 Creando nuevo plan unificado desde plan semanal...');
        
        // Crear nuevo plan unificado
        final dias = <String, DiaPlanHive>{};
        
        for (var entry in planSemanal.dias.entries) {
          final nombreDia = entry.key;
          final diaSemanal = entry.value;
          
          // Convertir clientes asignados
          final clientesUnificados = <VisitaClienteUnificadaHive>[];
          
          // Generar ID del plan para buscar indicadores
          final planVisitaId = '${semana}_${nombreDia}_${diaSemanal.rutaId ?? ''}';
          
          for (var clienteId in diaSemanal.clienteIds) {
            // Buscar indicadores guardados para este cliente
            final indicadorCliente = await indicadoresServicio.obtenerIndicadoresCliente(
              clienteId,
              planVisitaId,
            );
            
            clientesUnificados.add(VisitaClienteUnificadaHive(
              clienteId: clienteId,
              estatus: 'pendiente',
              fechaModificacion: DateTime.now(),
              indicadorIds: indicadorCliente?.indicadorIds,
              comentarioIndicadores: indicadorCliente?.comentario,
              resultadosIndicadores: indicadorCliente?.resultados,
            ));
          }
          
          // Determinar el tipo correcto basado en el contenido
          String tipoFinal = diaSemanal.tipo ?? 'visita';
          if (diaSemanal.tipo == 'mixto' || 
              (diaSemanal.tipoActividadAdministrativa != null && 
               diaSemanal.tipoActividadAdministrativa!.isNotEmpty && 
               diaSemanal.clienteIds.isNotEmpty)) {
            tipoFinal = 'mixto';
          }
          
          dias[nombreDia] = DiaPlanHive(
            dia: nombreDia,
            tipo: tipoFinal,
            objetivoId: diaSemanal.objetivoId,
            objetivoNombre: diaSemanal.objetivoNombre,
            tipoActividadAdministrativa: diaSemanal.tipoActividadAdministrativa,
            rutaId: diaSemanal.rutaId,
            rutaNombre: diaSemanal.rutaNombre,
            clienteIds: List<String>.from(diaSemanal.clienteIds),
            clientes: clientesUnificados,
            configurado: diaSemanal.configurado,
            formularios: [],
          );
        }
        
        planUnificado = PlanTrabajoUnificadoHive(
          id: planSemanal.id,
          liderClave: planSemanal.liderClave,
          liderNombre: planSemanal.liderNombre,
          semana: planSemanal.semana,
          numeroSemana: planSemanal.numeroSemana ?? 1,
          anio: planSemanal.anio ?? DateTime.now().year,
          centroDistribucion: planSemanal.centroDistribucion,
          fechaInicio: planSemanal.fechaInicio,
          fechaFin: planSemanal.fechaFin,
          estatus: planSemanal.estatus,
          dias: dias,
          sincronizado: false,
          fechaCreacion: DateTime.now(),
          fechaModificacion: DateTime.now(),
        );
        
        await planUnificadoRepo.crearPlan(planUnificado);
        print('✅ Plan unificado creado exitosamente');
        
      } else {
        print('🔄 Actualizando plan unificado existente...');
        
        // Actualizar el plan unificado existente
        // Preservar las visitas existentes pero actualizar la configuración
        for (var entry in planSemanal.dias.entries) {
          final nombreDia = entry.key;
          final diaSemanal = entry.value;
          final diaUnificado = planUnificado!.dias[nombreDia];
          
          if (diaUnificado != null) {
            // Actualizar configuración pero preservar visitas existentes
            diaUnificado.tipo = diaSemanal.tipo ?? 'visita';
            diaUnificado.objetivoId = diaSemanal.objetivoId;
            diaUnificado.objetivoNombre = diaSemanal.objetivoNombre;
            diaUnificado.tipoActividadAdministrativa = diaSemanal.tipoActividadAdministrativa;
            diaUnificado.rutaId = diaSemanal.rutaId;
            diaUnificado.rutaNombre = diaSemanal.rutaNombre;
            diaUnificado.configurado = diaSemanal.configurado;
            
            // Actualizar lista de clienteIds
            diaUnificado.clienteIds = List<String>.from(diaSemanal.clienteIds);
            
            // Generar ID del plan para buscar indicadores
            final planVisitaId = '${semana}_${nombreDia}_${diaSemanal.rutaId ?? ''}';
            
            // Agregar nuevos clientes que no existan
            for (var clienteId in diaSemanal.clienteIds) {
              final existeCliente = diaUnificado.clientes.any((v) => v.clienteId == clienteId);
              if (!existeCliente) {
                // Buscar indicadores guardados para este cliente
                final indicadorCliente = await indicadoresServicio.obtenerIndicadoresCliente(
                  clienteId,
                  planVisitaId,
                );
                
                diaUnificado.clientes.add(VisitaClienteUnificadaHive(
                  clienteId: clienteId,
                  estatus: 'pendiente',
                  fechaModificacion: DateTime.now(),
                  indicadorIds: indicadorCliente?.indicadorIds,
                  comentarioIndicadores: indicadorCliente?.comentario,
                  resultadosIndicadores: indicadorCliente?.resultados,
                ));
              } else {
                // Actualizar indicadores para clientes existentes
                final visitaExistente = diaUnificado.clientes.firstWhere((v) => v.clienteId == clienteId);
                final indicadorCliente = await indicadoresServicio.obtenerIndicadoresCliente(
                  clienteId,
                  planVisitaId,
                );
                
                if (indicadorCliente != null) {
                  visitaExistente.indicadorIds = indicadorCliente.indicadorIds;
                  visitaExistente.comentarioIndicadores = indicadorCliente.comentario;
                  visitaExistente.resultadosIndicadores = indicadorCliente.resultados;
                }
              }
            }
            
            // Remover clientes que ya no están asignados
            diaUnificado.clientes.removeWhere((visita) => 
              !diaSemanal.clienteIds.contains(visita.clienteId) && 
              visita.estatus == 'pendiente'
            );
          }
        }
        
        // Actualizar metadata
        planUnificado.estatus = planSemanal.estatus;
        planUnificado.fechaModificacion = DateTime.now();
        planUnificado.sincronizado = false;
        
        await planUnificadoRepo.actualizarPlan(planUnificado);
        print('✅ Plan unificado actualizado exitosamente');
      }
      
    } catch (e) {
      print('❌ Error en sincronización con plan unificado: $e');
      // No lanzar error para no interrumpir el flujo principal
    }
  }
}