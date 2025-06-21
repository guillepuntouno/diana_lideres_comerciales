# Reglas de Negocio – Proyecto DIANA: Líderes Comerciales

## 🎯 Objetivo del Sistema

El sistema movil tiene como propósito centralizar, digitalizar y optimizar la gestión comercial en campo de la fuerza de ventas de DIANA. Esto incluye:

- Registrar y monitorear las visitas de los líderes comerciales a los puntos de venta (PDV).
- Evaluar al personal de ventas mediante formularios estructurados.
- Capturar información en tiempo real (incluso sin conexión).
- Facilitar la trazabilidad de compromisos y retroalimentación a los asesores.

---

## 🧩 Funcionalidades Principales (Nivel de negocio)

### 1. Inicio de Ruta
- El asesor comercial debe registrar manualmente el inicio de su ruta.
- Debe capturarse geolocalización del punto de partida.
- La app debe permitir iniciar ruta aun sin conexión (modo offline).

### 2. Agenda Dinámica de Visitas
- Cada líder tiene una lista de visitas asignadas para el día.
- Cada visita requiere check-in (al llegar) y check-out (al salir), ambos con geolocalización.
- Las visitas pueden ser validadas manual o automáticamente según cumplimiento.
- Si un líder no cumple con sus visitas programadas, debe quedar trazado en el sistema.

### 3. Formularios Personalizados (Encuestas o Checklists)
- Cada canal (detalle, mayoreo, etc.) puede tener formularios distintos.
- Los formularios deben poder editarse desde el panel web sin actualizar la app.
- Cada formulario puede contener campos de texto, foto, opciones múltiples, escalas, etc.
- Las respuestas deben registrarse por usuario, fecha, cliente y ubicación.

### 4. Retroalimentación y Compromisos
- Al finalizar una visita, el líder puede capturar compromisos establecidos con el asesor.
- Los compromisos deben tener una fecha límite y trazabilidad.
- Puede agregarse evidencia como fotos o notas.

### 5. Reportes y KPIs
- Se debe registrar: visitas completadas, pendientes, canceladas y nivel de cumplimiento.
- Debe medirse desempeño por asesor, canal, cliente y zona.
- Toda la información debe ser exportable a Excel y visualizable desde Snowflake/BI.

---

## 🛠️ Reglas Técnicas y Consideraciones de Desarrollo

- **Frontend**: Flutter (iOS, Android, Web, Desktop Windows)
- **Backend/API**: AWS Lambda + API Gateway | Modo pruebas / desarrollo se usa una API temporal en NET Framework 4.8 con C#
- **Base de datos**: DynamoDB (estructura no relacional) / desarrollo se usa SQL Server 2022
- **Autenticación**: Cognito con federación a Active Directory
- **Offline Mode**: sincronización en SQLite/Hive local
- **Carga de evidencia**: imágenes se almacenan en S3
- **Sincronización automática**: cuando el dispositivo recupere conectividad

---

## 🔒 Roles y Permisos

- **Líder Comercial**:
  - Ver visitas asignadas
  - Iniciar ruta
  - Capturar formularios
  - Registrar compromisos

- **Administrador Web**:
  - Crear usuarios, rutas, formularios y catálogos
  - Ver reportes y KPIs
  - Descargar data y monitorear ejecución

---

## 📚 Terminología Clave

- **PDV**: Punto de Venta, cliente visitado por el asesor.
- **Ruta**: Conjunto de visitas asignadas a un líder en un día.
- **Check-in/out**: Registro de llegada y salida con ubicación.
- **Compromiso**: Acción acordada entre líder y asesor para mejora.
- **Offline Mode**: Funcionalidad para operar sin conexión, con sincronización posterior.

---

## 🧠 Notas para el agente Claude Code

Este contexto se puede usar para tareas como:

- Refactorizar código según reglas de negocio
- Detectar lógicas mal implementadas (por ejemplo, check-in sin coordenadas)
- Generar pruebas automatizadas con base en reglas
- Explicar archivos Dart o Python de backend


