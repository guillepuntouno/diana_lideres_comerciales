/// # Documentación Técnica: Flujo de Ejecución de Visitas
/// 
/// Este documento describe el flujo completo de negocio para la ejecución de visitas a clientes,
/// desde la selección inicial hasta el check-out y finalización, incluyendo toda la persistencia
/// de datos en Hive y las estructuras utilizadas.
///
/// ## 📋 Pantallas involucradas en el flujo
/// 
/// 1. **Rutina Diaria** (`rutina_diaria.dart`)
///    - Punto de entrada para las visitas del día
///    - Lista clientes FOCO y adicionales
///    - Verifica estados de visitas previas
/// 
/// 2. **Visita Cliente** (`pantalla_visita_cliente.dart`)
///    - Realiza el check-in del cliente
///    - Captura ubicación GPS y comentarios iniciales
/// 
/// 3. **Formulario Dinámico** (`pantalla_formulario_dinamico.dart`)
///    - Captura información estructurada en 5 secciones
///    - Guarda progreso incrementalmente
/// 
/// 4. **Resumen Visita** (`pantalla_resumen_visita.dart`)
///    - Muestra el detalle completo de la visita
///    - Permite consultar visitas completadas
///
/// ## 🔄 Flujo de ejecución paso a paso
///
/// ### 1. Selección del cliente (Rutina Diaria)
/// 
/// ```dart
/// // La pantalla carga el plan de trabajo desde Hive
/// final planBox = Hive.box<PlanTrabajoUnificadoHive>('planes_trabajo_unificado');
/// final plan = planBox.values.firstWhere(
///   (p) => p.numeroSemana == semanaActual && p.liderClave == liderClave
/// );
/// 
/// // Para cada día, obtiene los clientes asignados
/// final diaActual = plan.dias[nombreDia]; // Ej: "Lunes"
/// final clientesDelDia = diaActual.clientes; // List<VisitaClienteUnificadaHive>
/// ```
/// 
/// **Verificación de estado de visita:**
/// ```dart
/// // Se verifica si el cliente ya fue visitado
/// final visitaExistente = clientesDelDia.firstWhere(
///   (v) => v.clienteId == clienteId,
///   orElse: () => null
/// );
/// 
/// if (visitaExistente?.estatus == 'completada') {
///   // Navega al resumen en modo consulta
/// } else {
///   // Permite iniciar/continuar visita
/// }
/// ```
///
/// ### 2. Check-in del cliente
/// 
/// **Datos capturados:**
/// - Ubicación GPS (latitud, longitud, precisión)
/// - Comentarios del check-in
/// - Timestamp
/// 
/// **Persistencia en Hive:**
/// ```dart
/// // Se actualiza la visita en el plan unificado
/// final visita = VisitaClienteUnificadaHive(
///   clienteId: clienteId,
///   horaInicio: DateTime.now().toIso8601String(),
///   ubicacionInicio: UbicacionUnificadaHive(
///     lat: latitud,
///     lon: longitud,
///   ),
///   comentarioInicio: comentarios,
///   estatus: 'en_proceso', // Marca la visita como iniciada
/// );
/// 
/// // Actualiza el plan en Hive
/// plan.dias[dia].clientes[indiceCliente] = visita;
/// await plan.save();
/// ```
///
/// ### 3. Captura de formularios
/// 
/// **Estructura del formulario (5 secciones):**
/// 
/// ```dart
/// // 1. Tipo de Exhibidor
/// TipoExhibidorHive(
///   poseeAdecuado: bool,
///   tipo: String?, // "Refrigerador", "Exhibidor", etc.
///   modelo: String?,
///   cantidad: int?,
/// )
/// 
/// // 2. Estándares de Ejecución
/// EstandaresEjecucionHive(
///   primeraPosicion: bool,
///   planograma: bool,
///   portafolioFoco: bool,
///   anclaje: bool,
/// )
/// 
/// // 3. Disponibilidad
/// DisponibilidadHive(
///   ristras: bool,
///   max: bool,
///   familiar: bool,
///   dulce: bool,
///   galleta: bool,
/// )
/// 
/// // 4. Compromisos
/// List<CompromisoHive>(
///   tipo: String, // "Exhibidor", "Producto", etc.
///   detalle: String,
///   cantidad: int,
///   fechaPlazo: String,
/// )
/// 
/// // 5. Comentarios
/// String retroalimentacion;
/// String reconocimiento;
/// ```
/// 
/// **Persistencia progresiva:**
/// ```dart
/// // Después de cada sección completada
/// visita.cuestionario = CuestionarioHive(
///   tipoExhibidor: tipoExhibidor,
///   estandaresEjecucion: estandares,
///   disponibilidad: disponibilidad,
/// );
/// visita.compromisos = listaCompromisos;
/// visita.retroalimentacion = retroalimentacion;
/// visita.reconocimiento = reconocimiento;
/// 
/// await plan.save(); // Persiste cambios en Hive
/// ```
///
/// ### 4. Check-out y finalización
/// 
/// ```dart
/// // Al completar todas las secciones
/// visita.horaFin = DateTime.now().toIso8601String();
/// visita.estatus = 'completada'; // Marca como finalizada
/// visita.fechaModificacion = DateTime.now();
/// 
/// // Calcula duración
/// final duracion = DateTime.parse(visita.horaFin)
///   .difference(DateTime.parse(visita.horaInicio))
///   .inMinutes;
/// ```
///
/// ## 📦 Estructuras de datos en Hive
///
/// ### Cajas (Boxes) utilizadas:
/// 
/// 1. **`planes_trabajo_unificado`**
///    - Tipo: `Box<PlanTrabajoUnificadoHive>`
///    - Contiene: Planes semanales con días y clientes asignados
///    - Clave primaria: `id` (formato: "LIDERCLAVE_SEMXX_YYYY")
/// 
/// 2. **`visitas_clientes`** (legacy, para sincronización)
///    - Tipo: `Box<VisitaClienteHive>`
///    - Contiene: Visitas individuales para sincronización con servidor
///    - Clave primaria: `visitaId`
///
/// ### Modelos principales:
/// 
/// ```dart
/// // Plan de trabajo semanal
/// PlanTrabajoUnificadoHive {
///   String id; // "123456_SEM01_2025"
///   Map<String, DiaPlanHive> dias; // Lunes, Martes, etc.
///   bool sincronizado;
///   DateTime fechaModificacion;
/// }
/// 
/// // Día de trabajo
/// DiaPlanHive {
///   String dia; // "Lunes"
///   List<VisitaClienteUnificadaHive> clientes;
///   String? objetivoId;
///   String? rutaId;
/// }
/// 
/// // Visita a cliente
/// VisitaClienteUnificadaHive {
///   String clienteId;
///   String? horaInicio;
///   String? horaFin;
///   UbicacionUnificadaHive? ubicacionInicio;
///   String? comentarioInicio;
///   CuestionarioHive? cuestionario;
///   List<CompromisoHive> compromisos;
///   String? retroalimentacion;
///   String? reconocimiento;
///   String estatus; // 'pendiente', 'en_proceso', 'completada'
/// }
/// ```
///
/// ## ⚙️ Consideraciones funcionales y técnicas
///
/// ### 1. Criterios para marcar cliente como visitado
/// 
/// Un cliente se considera visitado cuando:
/// ```dart
/// bool clienteVisitado(VisitaClienteUnificadaHive visita) {
///   return visita.estatus == 'completada' && 
///          visita.horaInicio != null && 
///          visita.horaFin != null;
/// }
/// ```
/// 
/// **Estados posibles:**
/// - `pendiente`: Cliente no ha sido visitado
/// - `en_proceso`: Check-in realizado, pero visita no finalizada
/// - `completada`: Check-out realizado, visita finalizada
/// - `cancelada`: Visita cancelada (no implementado actualmente)
///
/// ### 2. Fusión de visitas con plan unificado para sincronización
/// 
/// **Proceso de sincronización (PUT al servidor):**
/// 
/// ```dart
/// // 1. Obtener plan local actualizado
/// final planLocal = await obtenerPlanUnificadoLocal(planId);
/// 
/// // 2. Convertir a formato API
/// final planApi = {
///   'id': planLocal.id,
///   'semana': {
///     'numero': planLocal.numeroSemana,
///     'estatus': planLocal.estatus,
///   },
///   'diasTrabajo': planLocal.dias.entries.map((entry) => {
///     'dia': entry.key,
///     'clientes': entry.value.clientes.map((visita) => {
///       'clienteId': visita.clienteId,
///       'checkIn': {
///         'hora': visita.horaInicio,
///         'ubicacion': visita.ubicacionInicio?.toJson(),
///         'comentarios': visita.comentarioInicio,
///       },
///       'checkOut': visita.horaFin != null ? {
///         'hora': visita.horaFin,
///         'duracionMinutos': calcularDuracion(visita),
///       } : null,
///       'formularios': {
///         'cuestionario': visita.cuestionario?.toJson(),
///         'compromisos': visita.compromisos.map((c) => c.toJson()).toList(),
///         'retroalimentacion': visita.retroalimentacion,
///         'reconocimiento': visita.reconocimiento,
///       },
///       'estatus': visita.estatus,
///     }).toList(),
///   }).toList(),
/// };
/// 
/// // 3. Enviar PUT al servidor
/// await api.put('/planes/${planId}', body: planApi);
/// 
/// // 4. Marcar como sincronizado
/// planLocal.sincronizado = true;
/// planLocal.fechaUltimaSincronizacion = DateTime.now();
/// await planLocal.save();
/// ```
///
/// ### 3. Referencias cruzadas por ID
/// 
/// **Claves de identificación:**
/// - **Plan ID**: `"{liderClave}_SEM{numero}_YYYY"` (ej: "123456_SEM01_2025")
/// - **Cliente ID**: ID único del cliente en el sistema
/// - **Visita ID**: Generado localmente, formato: `"VIS-{timestamp}-{clienteId}"`
/// 
/// **Relaciones:**
/// ```
/// PlanTrabajoUnificado (1) ---> (*) Días
///                                    |
///                                    v
///                              (*) Visitas/Clientes
///                                    |
///                                    v
///                              (1) Cuestionario
///                                    |
///                                    v
///                              (*) Compromisos
/// ```
///
/// ### 4. Validaciones importantes
/// 
/// 1. **Check-in sin check-out previo**: No permitir nuevo check-in si hay visita `en_proceso`
/// 2. **Formulario incompleto**: Advertir si se intenta check-out sin completar todas las secciones
/// 3. **Tiempo mínimo de visita**: Validar duración mínima (configurable, ej: 5 minutos)
/// 4. **Geolocalización**: Validar que la ubicación esté dentro del rango esperado del cliente
///
/// ### 5. Sincronización offline/online
/// 
/// **Estrategia de sincronización:**
/// 1. Todos los cambios se guardan primero en Hive local
/// 2. Se marca `needsSync: true` en el plan modificado
/// 3. `OfflineSyncManager` intenta sincronizar cuando hay conexión
/// 4. En caso de conflictos, prevalece la versión local más reciente
/// 5. Después de sincronización exitosa, se actualiza `fechaUltimaSincronizacion`
///
/// ### 6. Recuperación ante fallos
/// 
/// **Escenarios manejados:**
/// - App cerrada durante visita: Al reabrir, detecta visitas `en_proceso` y permite continuar
/// - Pérdida de conexión: Todos los datos se guardan localmente hasta recuperar conexión
/// - Cierre inesperado en formulario: SharedPreferences guarda progreso por sección
///
/// ## 🔍 Queries útiles para debugging
/// 
/// ```dart
/// // Obtener todas las visitas de un día
/// final visitas = plan.dias[dia].clientes
///   .where((v) => v.estatus != 'pendiente')
///   .toList();
/// 
/// // Contar visitas completadas
/// final completadas = plan.dias.values
///   .expand((dia) => dia.clientes)
///   .where((v) => v.estatus == 'completada')
///   .length;
/// 
/// // Buscar visitas sin sincronizar
/// final pendientesSync = planBox.values
///   .where((p) => !p.sincronizado && p.fechaModificacion.isAfter(
///     p.fechaUltimaSincronizacion ?? DateTime(2000)
///   ));
/// ```
///
/// ## 📌 Notas adicionales
/// 
/// - Los timestamps se manejan en formato ISO 8601 para compatibilidad
/// - Las ubicaciones GPS incluyen precisión para validación de calidad
/// - Los compromisos tienen fecha límite para seguimiento posterior
/// - El sistema soporta múltiples visitas al mismo cliente en diferentes días
/// - La retroalimentación y reconocimiento son campos de texto libre opcionales
///
/// ---
/// Última actualización: 26/01/2025
/// Versión del documento: 1.0
///
/// ## 📝 Historial de cambios
///
/// ### 26/01/2025 - 15:30 (Sesión de depuración)
/// 
/// **Problema reportado:**
/// - No se visualizaban datos guardados en HIVE en la pantalla debug_hive.dart
/// - La pantalla resumen_visita.dart se quedaba en ciclo infinito
/// - Los datos del formulario no aparecían en el plan unificado
///
/// **Cambios realizados:**
///
/// 1. **pantalla_resumen_visita.dart**
///    - Corregido ciclo infinito causado por llamar `_cargarDatos()` en `initState()`
///    - Movido a `didChangeDependencies()` para acceso correcto a `ModalRoute.of(context)`
///    - Agregada verificación para ejecutar solo una vez
///
/// 2. **pantalla_debug_hive.dart**
///    - Actualizado método `_planToJson()` para incluir todos los campos del cuestionario:
///      - ubicacionInicio, comentarioInicio
///      - cuestionario completo (tipoExhibidor, estandaresEjecucion, disponibilidad)
///      - compromisos con todos sus campos
///      - retroalimentacion y reconocimiento
///    - Agregado botón "Crear Plan de Prueba" para facilitar testing
///    - Implementado método `_crearPlanDePrueba()` que genera plan con datos de ejemplo
///
/// 3. **visita_cliente_unificado_service.dart**
///    - Corregido mapeo de campos en `_convertirTipoExhibidor()`:
///      - `poseeAdecuado` → `poseeExhibidorAdecuado`
///      - `tipo` → `tipoExhibidorSeleccionado`
///      - `modelo` → `modeloExhibidorSeleccionado`
///      - `cantidad` → `cantidadExhibidores`
///    - Corregido campo en `_convertirEstandares()`: `primeraPosicion` → `primeraPosition`
///    - Agregado manejo de campo `fecha` en compromisos
///    - Agregados logs de depuración para rastrear guardado
///
/// 4. **pantalla_formulario_dinamico.dart**
///    - Agregado null safety en preparación de formularios
///    - Agregados logs de depuración para ver datos antes de guardar
///    - Corregida extracción de compromisos con verificación null
///
/// **Causa raíz identificada:**
/// - Los planes unificados no se estaban creando automáticamente
/// - La rutina diaria no pasaba metadata con planId en la actividad
/// - Por eso la caja 'planes_trabajo_unificado' aparecía vacía
///
/// **Solución implementada:**
/// - Agregado botón de prueba para crear planes manualmente
/// - Los datos ahora se guardan correctamente cuando existe un plan
/// - La visualización en debug muestra todos los campos del formulario
///
/// **Pendiente:**
/// - Modificar rutina_diaria.dart para crear/usar planes unificados automáticamente
/// - Agregar metadata del plan en las actividades para el flujo completo
///
/// ### 26/01/2025 - 16:15 (Solución de sincronización de planes)
///
/// **Problema identificado:**
/// - Existían dos tipos de planes separados:
///   - `PlanTrabajoSemanalHive`: Usado para configuración del plan
///   - `PlanTrabajoUnificadoHive`: Usado para seguimiento de visitas
/// - No había sincronización entre ambos tipos
///
/// **Solución implementada:**
///
/// 1. **plan_trabajo_offline_service.dart**
///    - Agregado método `sincronizarConPlanUnificado()` que:
///      - Crea un PlanTrabajoUnificadoHive desde un PlanTrabajoSemanalHive
///      - Preserva visitas existentes al actualizar
///      - Sincroniza cambios de configuración
///    - Llamado automáticamente en:
///      - `guardarConfiguracionDia()`: Después de configurar un día
///      - `enviarPlan()`: Integrado en vista_configuracion_plan.dart
///
/// 2. **vista_configuracion_plan.dart**
///    - Agregada sincronización después de enviar plan (línea 470-474)
///    - Asegura que el plan unificado esté listo para la rutina diaria
///
/// 3. **rutina_diaria.dart**
///    - Actualizada metadata de actividades para incluir:
///      - `planId`: ID del plan unificado
///      - `dia`: Día actual o simulado
///    - Aplicado tanto a clientes FOCO como adicionales
///
/// **Flujo actualizado:**
/// 1. Configurar plan → PlanTrabajoSemanalHive
/// 2. Enviar plan → Sincronizar → PlanTrabajoUnificadoHive
/// 3. Rutina diaria → Usa PlanTrabajoUnificadoHive
/// 4. Visitas → Se guardan en PlanTrabajoUnificadoHive
///
/// **Resultado:**
/// - Los planes ahora aparecen en la pestaña "Planes Unificados (Local)"
/// - Las visitas se guardan correctamente con todos sus datos
/// - No hay pérdida de información entre configuración y ejecución
///
/// ### 26/01/2025 - 16:30 (Documentación completa del flujo)
///
/// **Resumen técnico de la solución:**
///
/// El sistema ahora mantiene dos estructuras de datos sincronizadas:
///
/// ```
/// PlanTrabajoSemanalHive (Configuración)     PlanTrabajoUnificadoHive (Ejecución)
///          |                                            |
///          ├─ id: "123456_SEM01_2025"                 ├─ id: "123456_SEM01_2025"
///          ├─ dias: Map<String, DiaTrabajoHive>        ├─ dias: Map<String, DiaPlanHive>
///          │    └─ clienteIds: List<String>            │    ├─ clienteIds: List<String>
///          │                                           │    └─ clientes: List<VisitaClienteUnificadaHive>
///          └─ estatus: "enviado"                       └─ estatus: "enviado"
/// ```
///
/// **Método de sincronización:**
/// ```dart
/// sincronizarConPlanUnificado(String semana, String liderClave) {
///   1. Obtiene PlanTrabajoSemanalHive
///   2. Busca/crea PlanTrabajoUnificadoHive con mismo ID
///   3. Para cada día:
///      - Copia configuración (objetivo, ruta, etc.)
///      - Convierte clienteIds a VisitaClienteUnificadaHive
///      - Preserva visitas existentes (no pendientes)
///   4. Guarda en caja 'planes_trabajo_unificado'
/// }
/// ```
///
/// **Puntos de sincronización:**
/// - Al enviar plan (vista_configuracion_plan.dart:470)
/// - Al configurar día (plan_trabajo_offline_service.dart:220)
/// - Manual desde debug con botón "Crear Plan de Prueba"
///
/// **Metadata en actividades:**
/// ```dart
/// metadata: {
///   'esFoco': true/false,
///   'planId': '123456_SEM01_2025',
///   'dia': 'Lunes',
///   'clienteData': {...} // Solo para no FOCO
/// }
/// ```
///
/// **Verificación:**
/// 1. Configurar y enviar plan en "Configuración Plan"
/// 2. Ir a Debug → Planes Unificados (Local)
/// 3. Debe aparecer el plan con estructura completa
/// 4. Al hacer visitas, los datos se guardan en este plan
///
/// ### 26/01/2025 - 16:40 (Corrección de errores de compilación)
///
/// **Errores corregidos:**
///
/// 1. **pantalla_debug_hive.dart:1088**
///    - Error: `userId` no existe en UserHive
///    - Solución: Cambiado a `user.clave`
///    - Error: `displayName` no existe en UserHive
///    - Solución: Cambiado a `user.nombreCompleto`
///
/// 2. **plan_trabajo_offline_service.dart:438**
///    - Error: String? no puede asignarse a String
///    - Solución: Agregado valor por defecto `diaSemanal.tipo ?? 'visita'`
///
/// 3. **plan_trabajo_offline_service.dart:456-457**
///    - Error: int? no puede asignarse a int
///    - Solución: Agregados valores por defecto:
///      - `numeroSemana ?? 1`
///      - `anio ?? DateTime.now().year`
///
/// 4. **plan_trabajo_offline_service.dart:481**
///    - Error: String? no puede asignarse a String
///    - Solución: Agregado valor por defecto `diaSemanal.tipo ?? 'visita'`
///
/// **Nota técnica:**
/// Los errores se debían a diferencias entre los modelos nullable de Hive
/// y los requisitos non-nullable del plan unificado. Se agregaron valores
/// por defecto apropiados para mantener la integridad de datos.