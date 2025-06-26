# Documentación - Pantalla Debug Hive

## 🔎 Propósito de la pantalla

La **PantallaDebugHive** es una herramienta de desarrollo y depuración que permite:
- Visualizar datos almacenados localmente en Hive
- Probar endpoints del API de planes unificados
- Gestionar y limpiar datos locales
- Validar la sincronización entre Hive y el servidor
- Facilitar el testing durante el desarrollo

## 🧱 Secciones actuales

### 1. **Planes Trabajo** 
- Muestra los planes de trabajo semanales almacenados en Hive
- Permite expandir cada plan para ver detalles (ID, fechas, días de trabajo)
- Incluye botón de eliminación individual
- Box Hive: `planes_trabajo_semanal`

### 2. **Planes Unificados (Webservice)**
- Contiene tarjetas para probar operaciones CRUD del API:
  - **GET /planes?userId** - Consultar planes por usuario
  - **POST /planes** - Crear nuevo plan
  - **PUT /planes/{id}** - Actualizar plan existente
  - **DELETE /planes/{id}** - Eliminar plan
- Cada tarjeta es interactiva y ejecuta peticiones reales al servidor

### 3. **Visitas**
- Lista las visitas a clientes registradas
- Muestra información de check-in/check-out, ubicación y formularios
- Estado de sincronización visible
- Box Hive: `visitas_clientes`

### 4. **Clientes**
- Visualiza el catálogo de clientes almacenados
- Información básica: nombre, ID, ruta, dirección
- Box Hive: `clientes`

### 5. **Objetivos**
- Muestra los objetivos/formularios disponibles
- Incluye tipo, orden y estado activo
- Box Hive: `objetivos`

### 6. **Config**
- Información del usuario y líder comercial actual
- Estadísticas de la base de datos local
- Opciones para eliminar datos de usuario/líder

## 🧩 Detalles técnicos implementados

### Construcción de URLs
```dart
// Patrón usado en todas las tarjetas
String _construirUrl() {
  return '${AmbienteConfig.baseUrl}/planes';
}
```
- Se usa `AmbienteConfig.baseUrl` que ya incluye el ambiente (dev/qa/prod)
- Las URLs se construyen dinámicamente con parámetros del usuario

### Obtención de datos iniciales
1. **Token JWT**: Se obtiene de `SharedPreferences` con la clave `'id_token'`
2. **userId**: Se obtiene del box Hive `'users'` usando `user.clave`
3. **Carga automática**: Al iniciar cada tarjeta, se cargan estos valores

### Headers de autorización
```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

### Manejo de respuestas

#### Códigos exitosos
- **200**: Operación exitosa (GET, DELETE)
- **201**: Recurso creado (POST)
- **204**: Sin contenido (DELETE exitoso)

#### Códigos de error comunes
- **400**: Bad Request - JSON mal formado
- **401**: Unauthorized - Token inválido o expirado
- **404**: Not Found - Recurso no encontrado
- **500**: Error del servidor

### Funcionalidad de JSON
- Editor de JSON con formateo automático
- Validación antes de enviar
- Visualización formateada de respuestas
- JsonEncoder con indentación para mejor legibilidad

### Características especiales

#### Tarjeta DELETE
- Diálogo de confirmación antes de eliminar
- Mensaje personalizado con el ID del plan
- Validación de campos obligatorios

#### Visualización de tokens
- Toggle para mostrar/ocultar token JWT
- Iconos de visibilidad intuitivos
- Protección de información sensible

## 📦 Interacción con Hive

### Boxes utilizados
1. **planes_trabajo_semanal** - Planes de trabajo locales
2. **planes_trabajo_unificado** - Planes unificados (pendiente de implementación)
3. **visitas_clientes** - Registro de visitas
4. **clientes** - Catálogo de clientes
5. **objetivos** - Formularios/objetivos
6. **users** - Información del usuario
7. **lideres_comerciales** - Datos del líder

### Operaciones disponibles
- **Lectura**: ValueListenableBuilder para actualizaciones reactivas
- **Eliminación**: Individual por índice o clear() para limpiar box completo
- **Estadísticas**: Conteo de registros por box

### Sincronización (pendiente)
- Las tarjetas de webservice están preparadas pero falta implementar:
  - Guardar respuestas GET en Hive local
  - Sincronizar cambios POST/PUT/DELETE
  - Manejo de conflictos offline/online

## 🚧 Observaciones pendientes o sugerencias

### Mejoras identificadas

1. **Sincronización bidireccional**
   - Implementar botón "Sincronizar con servidor" en pestaña Planes Unificados
   - Guardar respuestas del GET en el box local `planes_trabajo_unificado`
   - Indicadores visuales de estado de sincronización

2. **Validaciones adicionales**
   - Validar formato de Plan ID antes de enviar
   - Verificar conectividad antes de ejecutar peticiones
   - Manejo de timeouts en peticiones HTTP

3. **UX/UI**
   - Agregar confirmación para operaciones POST/PUT
   - Implementar función de exportación de datos (botón ya existe)
   - Agregar búsqueda/filtrado en listas largas

4. **Gestión de errores**
   - Mejorar mensajes de error para ser más descriptivos
   - Log de errores para debugging
   - Retry automático en errores de red

5. **Funcionalidades faltantes**
   - Completar la sección de sincronización Hive ↔️ API
   - Implementar paginación para listas grandes
   - Agregar timestamps de última sincronización

### Inconsistencias detectadas

1. **Nomenclatura de IDs**
   - En algunos lugares se usa `userId` y en otros `user.clave`
   - Estandarizar el nombre del campo identificador

2. **Manejo de estados**
   - El campo `estatus` vs `estado` no es consistente
   - Definir enum para estados válidos

3. **Formatos de fecha**
   - Mezcla de DateTime y String en diferentes modelos
   - Estandarizar formato ISO 8601

### Recomendaciones de seguridad

1. **Tokens**
   - Implementar refresh token automático
   - Limpiar token al cerrar sesión
   - No mostrar token completo en logs

2. **Datos sensibles**
   - Encriptar datos en Hive para producción
   - Deshabilitar pantalla debug en builds de release
   - Agregar autenticación para acceder a debug

## 📝 Notas de implementación

La pantalla está diseñada como herramienta de desarrollo pero tiene potencial para evolucionar a:
- Panel de administración para supervisores
- Herramienta de soporte técnico
- Monitor de salud del sistema

El patrón de tarjetas HTTP es reutilizable y podría extraerse a un widget genérico para testing de otros endpoints.

---

## 📅 Sesión de trabajo - 26/01/2025 15:45

### 🎯 Cambios implementados

#### 1. **Respuesta JSON copiable en tarjeta GET**
**Problema**: La respuesta JSON del endpoint GET se mostraba como texto estático, impidiendo copiarla fácilmente.

**Solución implementada**:
- Cambié el `Container` con `Text` por un `TextField` con `readOnly: true`
- Agregué un `IconButton` con ícono de copiar junto al título "Body:"
- Implementé funcionalidad de copiado al portapapeles usando `Clipboard.setData()`
- Agregué importación de `flutter/services.dart` para acceder a `Clipboard`
- Se muestra un `SnackBar` confirmando cuando se copia el contenido

**Código modificado en `_mostrarRespuesta()` de `GetPlanesCard`**:
```dart
// Antes: Container con Text simple
Container(
  child: Text(_formatearRespuesta(response.body))
)

// Después: TextField editable con botón de copiar
TextField(
  controller: bodyController,
  maxLines: null,
  readOnly: true,
  // ... configuración completa
)
```

#### 2. **Nueva pestaña "Planes Unificados (Local)"**

**Cambios en la estructura de pestañas**:
- Renombré "Planes Unificados" → "Planes Unificados (Webservice)"
- Agregué nueva pestaña "Planes Unificados (Local)" después de Webservice
- Actualicé el array `_tabs` y el método `_buildTabContent()`

**Funcionalidades implementadas en la nueva pestaña**:

##### 🔍 **Listado de planes locales**
- Lee datos del HiveBox `'planes_trabajo_unificado'`
- Muestra tarjetas con información básica: ID, semana, fechas, estatus
- Indicador visual de sincronización (verde/naranja)
- Pull-to-refresh con `RefreshIndicator`

##### 🎯 **Vista expandible del plan**
- Al presionar el botón expandir/contraer se muestra:
  - Editor JSON completo del plan
  - Botones de editar/guardar/cancelar
  - Botón de copiar JSON al portapapeles
  - Información de última actualización

##### 🧾 **Editor JSON embebido**
- `TextField` multiline que muestra el JSON formateado
- Modo lectura por defecto, se habilita edición con botón "Editar"
- Validación de JSON al intentar guardar
- Al guardar, actualiza `fechaModificacion` del plan

##### 🗑️ **Eliminación de plan local**
- Botón de eliminar con confirmación mediante `AlertDialog`
- Mensaje específico: "¿Estás seguro de eliminar este plan local? Esta acción no afecta al backend."
- Elimina el registro del box Hive local
- Muestra `SnackBar` de confirmación

#### 3. **Widget _PlanUnificadoLocalCard**
Creé un nuevo `StatefulWidget` que maneja:
- Estado de expansión/contracción
- Estado de edición del JSON
- Conversión del modelo Hive a JSON y viceversa
- Callbacks para actualización y eliminación

#### 4. **Correcciones al modelo PlanTrabajoUnificadoHive**
Durante la implementación encontré discrepancias con el modelo real:

**Errores corregidos**:
- `diasTrabajo` → `dias` (es un Map<String, DiaPlanHive>)
- `fechaActualizacion` → `fechaModificacion`
- `widget.plan.semana.numero` → `widget.plan.numeroSemana` (semana es String, no objeto)
- `widget.plan.semana.estatus` → `widget.plan.estatus`
- `widget.plan.semana.fechaInicio` → `widget.plan.fechaInicio`
- `widget.plan.semana.fechaFin` → `widget.plan.fechaFin`

**Función `_planToJson()` actualizada** para reflejar la estructura correcta:
```dart
{
  'id': widget.plan.id,
  'numeroSemana': widget.plan.numeroSemana,
  'anio': widget.plan.anio,
  'dias': widget.plan.dias.map((key, value) => MapEntry(key, {
    // estructura correcta del día
  })),
  // ... resto de campos
}
```

### 📋 Resumen de archivos modificados
1. `lib/vistas/debug/pantalla_debug_hive.dart`:
   - Importación de `flutter/services.dart`
   - Modificación de `_mostrarRespuesta()` en `GetPlanesCard`
   - Renombrado de pestaña existente
   - Nueva pestaña "Planes Unificados (Local)"
   - Métodos auxiliares `_eliminarPlanUnificado()` y `_actualizarPlanUnificado()`
   - Nuevo widget `_PlanUnificadoLocalCard`

### 🔄 Estado actual
- La pantalla debug ahora tiene 7 pestañas en total
- La respuesta JSON del endpoint GET es completamente copiable
- Los planes unificados locales se pueden visualizar, editar y eliminar
- El código está alineado con la estructura real del modelo Hive

### 🚀 Próximos pasos sugeridos
1. Implementar la actualización real del plan desde el JSON editado (actualmente solo actualiza la fecha)
2. Agregar sincronización entre los datos del webservice y los datos locales
3. Mejorar la validación y aplicación de cambios del JSON editado
4. Considerar agregar búsqueda/filtrado en la lista de planes locales