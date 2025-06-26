# Explicación del Plan Unificado - Estructura y Almacenamiento en Hive

## 📋 Resumen Ejecutivo

Este documento detalla el descubrimiento crítico sobre cómo se almacenan y gestionan los planes unificados en Hive, incluyendo la solución a un problema de persistencia de datos que impedía que los formularios, compromisos y retroalimentación se guardaran correctamente.

## 🔍 El Problema Identificado

Los datos del formulario dinámico (cuestionario, compromisos, retroalimentación y reconocimiento) se estaban capturando correctamente pero no aparecían en el plan unificado al consultarlo. El problema radicaba en cómo se manejaban las referencias de objetos en las listas de Hive.

## 📦 Estructura de Almacenamiento en Hive

### 1. **Caja Principal**
- **Nombre**: `planes_trabajo_unificado`
- **Tipo**: `Box<PlanTrabajoUnificadoHive>`
- **Acceso**: `HiveService().planesTrabajoUnificadosBox`
- **Clave**: Formato `"{liderClave}_SEM{numeroSemana}_{año}"` (ej: "123456_SEM01_2025")

### 2. **Jerarquía de Datos**

```
📦 Box: planes_trabajo_unificado
│
└── 📄 PlanTrabajoUnificadoHive (key: "123456_SEM01_2025")
    ├── 📊 Metadatos del Plan
    │   ├── id: String
    │   ├── liderClave: String
    │   ├── liderNombre: String
    │   ├── semana: String
    │   ├── numeroSemana: int
    │   ├── anio: int
    │   ├── centroDistribucion: String
    │   ├── fechaInicio: String
    │   ├── fechaFin: String
    │   ├── estatus: String
    │   ├── sincronizado: bool
    │   ├── fechaCreacion: DateTime
    │   ├── fechaModificacion: DateTime
    │   └── fechaUltimaSincronizacion: DateTime?
    │
    └── 📁 dias: Map<String, DiaPlanHive>
        │
        └── 📅 DiaPlanHive (key: "Lunes", "Martes", etc.)
            ├── 📊 Configuración del Día
            │   ├── dia: String
            │   ├── tipo: String ("gestion_cliente", "administrativo", etc.)
            │   ├── objetivoId: String?
            │   ├── objetivoNombre: String?
            │   ├── tipoActividadAdministrativa: String?
            │   ├── rutaId: String?
            │   ├── rutaNombre: String?
            │   ├── configurado: bool
            │   ├── fechaModificacion: DateTime
            │   └── clienteIds: List<String>
            │
            ├── 👥 clientes: List<VisitaClienteUnificadaHive>
            │   │
            │   └── 🧑 VisitaClienteUnificadaHive
            │       ├── 📊 Datos Básicos
            │       │   ├── clienteId: String
            │       │   ├── estatus: String ("pendiente", "en_proceso", "terminado")
            │       │   └── fechaModificacion: DateTime?
            │       │
            │       ├── ⏰ Check-in/Check-out
            │       │   ├── horaInicio: String?
            │       │   ├── horaFin: String?
            │       │   ├── ubicacionInicio: UbicacionUnificadaHive?
            │       │   │   ├── lat: double
            │       │   │   └── lon: double
            │       │   └── comentarioInicio: String?
            │       │
            │       ├── 📋 cuestionario: CuestionarioHive?
            │       │   ├── tipoExhibidor: TipoExhibidorHive?
            │       │   │   ├── poseeAdecuado: bool
            │       │   │   ├── tipo: String?
            │       │   │   ├── modelo: String?
            │       │   │   └── cantidad: int?
            │       │   │
            │       │   ├── estandaresEjecucion: EstandaresEjecucionHive?
            │       │   │   ├── primeraPosicion: bool
            │       │   │   ├── planograma: bool
            │       │   │   ├── portafolioFoco: bool
            │       │   │   └── anclaje: bool
            │       │   │
            │       │   └── disponibilidad: DisponibilidadHive?
            │       │       ├── ristras: bool
            │       │       ├── max: bool
            │       │       ├── familiar: bool
            │       │       ├── dulce: bool
            │       │       └── galleta: bool
            │       │
            │       ├── 📝 compromisos: List<CompromisoHive>
            │       │   └── CompromisoHive
            │       │       ├── tipo: String
            │       │       ├── detalle: String
            │       │       ├── cantidad: int
            │       │       └── fechaPlazo: String
            │       │
            │       ├── 💬 retroalimentacion: String?
            │       └── 🏆 reconocimiento: String?
            │
            └── 📄 formularios: List<FormularioDiaHive>
                └── FormularioDiaHive
                    ├── formularioId: String
                    ├── clienteId: String
                    ├── respuestas: Map<String, dynamic>
                    └── fechaCaptura: DateTime
```

## 🔧 El Descubrimiento Crítico

### El Problema
En el método `actualizarFormulariosEnPlanUnificado`, se obtenía una referencia a la visita del cliente usando un loop:

```dart
// Código problemático
VisitaClienteUnificadaHive? visitaCliente;
for (var visita in diaPlan.clientes) {
  if (visita.clienteId == clienteId) {
    visitaCliente = visita;  // <-- Referencia que podría no persistir cambios
    break;
  }
}
```

### La Solución
La modificación clave fue obtener el índice y reasignar el objeto modificado:

```dart
// Código corregido
final index = diaPlan.clientes.indexWhere((v) => v.clienteId == clienteId);
final visitaCliente = diaPlan.clientes[index];

// ... modificaciones al objeto ...

// CRUCIAL: Reasignar el objeto modificado
diaPlan.clientes[index] = visitaCliente;
```

### ¿Por qué esto es importante?
En Dart, cuando trabajas con objetos Hive y listas, las modificaciones a objetos obtenidos por referencia no siempre se propagan correctamente a la estructura padre. La reasignación explícita garantiza que los cambios persistan.

## 🗺️ Mapeo del Plan Unificado

### 1. **Fuentes de Datos**
El plan unificado se construye desde dos fuentes principales:

- **PlanTrabajoSemanalHive**: Configuración inicial del plan (días, rutas, objetivos)
- **Datos de Ejecución**: Check-ins, formularios, compromisos capturados durante las visitas

### 2. **Proceso de Sincronización**
```
PlanTrabajoSemanalHive → sincronizarConPlanUnificado() → PlanTrabajoUnificadoHive
                                                              ↓
                                                    Caja Hive: planes_trabajo_unificado
```

### 3. **Métodos de Acceso**
- **Crear/Actualizar**: `PlanTrabajoUnificadoRepository.actualizarPlan()`
- **Obtener**: `PlanTrabajoUnificadoRepository.obtenerPlan(planId)`
- **Serializar**: `plan.toJsonCompleto()` - Incluye TODA la estructura

## 📊 Contenido del Plan Unificado

El plan unificado contiene:

1. **Datos de Configuración**
   - Información del líder y semana
   - Configuración de cada día (tipo, objetivo, ruta)
   - Lista de clientes asignados

2. **Datos de Ejecución**
   - Check-in/Check-out con geolocalización
   - Resultados del cuestionario (3 secciones)
   - Compromisos acordados
   - Retroalimentación y reconocimiento
   - Estados de visita y timestamps

3. **Datos de Control**
   - Estado de sincronización
   - Fechas de creación/modificación
   - Versiones para compatibilidad

## 🚀 Implicaciones para Endpoints y Reportes

### Para Endpoints
Sí, el plan unificado está perfectamente estructurado para enviar al backend:

```dart
// El método toJsonCompleto() genera un JSON completo listo para enviar
final jsonParaAPI = planUnificado.toJsonCompleto();

// Estructura lista para PUT /api/planes/{planId}
await http.put(
  Uri.parse('$baseUrl/planes/${planUnificado.id}'),
  body: jsonEncode(jsonParaAPI),
  headers: {'Content-Type': 'application/json'},
);
```

### Para Reportes
El plan unificado es ideal para generar reportes porque:

1. **Datos Completos**: Contiene toda la información de configuración y ejecución
2. **Estructura Navegable**: Fácil acceso por día, cliente, tipo de actividad
3. **Métricas Calculables**:
   - % de visitas completadas
   - Tiempo promedio por visita
   - Compromisos por tipo
   - Cumplimiento de objetivos

### Ejemplo de Análisis para Reportes
```dart
// Contar visitas completadas
final visitasCompletadas = planUnificado.dias.values
  .expand((dia) => dia.clientes)
  .where((v) => v.estatus == 'terminado')
  .length;

// Calcular compromisos totales
final totalCompromisos = planUnificado.dias.values
  .expand((dia) => dia.clientes)
  .expand((v) => v.compromisos)
  .length;

// Analizar cumplimiento por día
final cumplimientoPorDia = planUnificado.dias.map((dia, diaPlan) {
  final total = diaPlan.clientes.length;
  final completadas = diaPlan.clientes.where((v) => v.estatus == 'terminado').length;
  return MapEntry(dia, total > 0 ? (completadas / total * 100) : 0.0);
});
```

## 📝 Conclusiones

1. **Estructura Robusta**: El plan unificado centraliza toda la información necesaria
2. **Problema Resuelto**: La reasignación de objetos garantiza la persistencia correcta
3. **Listo para Producción**: La estructura soporta sincronización, reportes y análisis
4. **Escalable**: Puede extenderse con nuevos tipos de formularios o métricas

---

## 🆕 Modificaciones realizadas en la vista de resultados diarios

### Cambios implementados:

1. **Navegación a detalle de visita**: 
   - Modificada la función `_mostrarDetalleVisita` en `pantalla_resultados_dia.dart` para navegar a `pantalla_resumen_visita.dart` en lugar de mostrar un bottom sheet.
   - Se pasan los parámetros necesarios incluyendo `modoConsulta: true` para indicar que es una consulta desde el plan unificado.

2. **Eliminación de etiqueta "Pendiente"**:
   - Modificado el método `_buildStatusBadge()` en `cliente_resultado_tile.dart` para no mostrar badge cuando el estado es "pendiente".
   - Solo se muestran badges para estados "terminado" (Completada) y "en_proceso" (En proceso).

3. **Limpieza de imports**:
   - Eliminado el import de `detalle_visita_bottom_sheet.dart` ya que no se utiliza más.

### Flujo actual:
1. Usuario ve la lista de visitas en `pantalla_resultados_dia.dart`
2. Al hacer clic en una tarjeta de visita, navega a `pantalla_resumen_visita.dart`
3. La pantalla de resumen recibe los datos en modo consulta y carga la información desde el plan unificado
4. Se muestran todos los detalles de la visita incluyendo cuestionarios, compromisos y comentarios

### Datos pasados a la vista de detalle:
- `modoConsulta`: true (indica que es modo consulta)
- `planId`: ID del líder comercial
- `dia`: Día seleccionado
- `clienteId`: ID del cliente
- `clienteNombre`: Nombre del cliente

---

**Última actualización**: 26/01/2025  
**Autor**: GUILLERMO MARTINEZ 
**Versión**: 1.1