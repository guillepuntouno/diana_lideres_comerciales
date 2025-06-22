# Reglas de Negocio – Proyecto DIANA: Líderes Comerciales

## 🎯 Objetivo del Sistema

El sistema móvil tiene como propósito centralizar, digitalizar y optimizar la gestión comercial en campo de la fuerza de ventas de DIANA. Esto incluye:

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

## 📋 Reglas de Negocio Detalladas

### Autenticación y Sesión

#### R001 - Autenticación de Usuario
- Todo usuario debe autenticarse antes de acceder a las funcionalidades de la aplicación
- Las credenciales deben ser validadas contra el sistema central
- La sesión debe mantenerse activa mientras el usuario esté usando la aplicación

#### R002 - Gestión de Sesión
- La sesión se cierra automáticamente después de un período de inactividad
- El usuario puede cerrar sesión manualmente
- Al cerrar sesión, todos los datos sensibles deben eliminarse de la memoria local

### Geolocalización

#### R003 - Ubicación Requerida
- La aplicación debe solicitar permisos de ubicación al usuario
- Las visitas a clientes requieren confirmación de ubicación
- La ubicación debe registrarse al inicio y fin de cada visita

#### R004 - Precisión de Ubicación
- La ubicación debe tener una precisión mínima de 10 metros
- Si no se puede obtener una ubicación precisa, se debe notificar al usuario
- La aplicación debe funcionar en modo offline con ubicación cached

### Planes de Trabajo

#### R005 - Creación de Planes
- Todo líder comercial debe tener un plan de trabajo diario
- Los planes pueden configurarse con anticipación
- Se permite modificar planes hasta el inicio del día laboral

#### R006 - Asignación de Clientes
- Los clientes se asignan automáticamente basados en criterios geográficos
- El líder puede solicitar cambios en la asignación
- Cada cliente debe tener información de contacto actualizada

#### R007 - Programación de Visitas
- Las visitas deben programarse dentro del horario laboral
- Se debe considerar el tiempo de desplazamiento entre clientes
- Máximo 8 visitas por día laboral

### Visitas a Clientes

#### R008 - Inicio de Visita
- Toda visita debe iniciarse con confirmación de ubicación
- Se debe registrar la hora exacta de inicio
- El formulario de visita debe completarse obligatoriamente

#### R009 - Datos de Visita
- Información del cliente debe ser verificada al inicio
- Se requiere foto del establecimiento
- Comentarios y observaciones son obligatorios

#### R010 - Finalización de Visita
- La visita debe cerrarse formalmente
- Se debe registrar la hora de finalización
- Resumen de la visita debe generarse automáticamente

### Notificaciones

#### R011 - Notificaciones del Sistema
- Recordatorios de visitas programadas
- Alertas de cambios en asignaciones
- Notificaciones de actualizaciones del sistema

#### R012 - Notificaciones de Urgencia
- Cambios críticos en planes de trabajo
- Emergencias o situaciones especiales
- Comunicados importantes de la empresa

### Datos y Sincronización

#### R013 - Sincronización de Datos
- Los datos se sincronizan automáticamente cuando hay conexión
- En modo offline, los datos se almacenan localmente
- La sincronización debe completarse al final del día

#### R014 - Integridad de Datos
- Todos los registros deben incluir timestamp
- Los datos críticos requieren validación antes del envío
- Se mantiene un log de actividades para auditoría

### Seguridad

#### R015 - Protección de Datos
- Los datos del cliente son confidenciales
- No se permite captura de pantalla en secciones sensibles
- Los datos se encriptan antes del almacenamiento

#### R016 - Acceso a Funcionalidades
- Cada funcionalidad requiere permisos específicos
- El acceso se controla por rol de usuario
- Se registra el acceso a funcionalidades críticas

### Reportes y Análisis

#### R017 - Generación de Reportes
- Reportes diarios automáticos al final de la jornada
- Métricas de productividad y eficiencia
- Resúmenes semanales y mensuales

#### R018 - Análisis de Rendimiento
- Seguimiento de KPIs establecidos
- Comparación con objetivos y metas
- Identificación de oportunidades de mejora

### Configuración

#### R019 - Configuración de Usuario
- Cada usuario puede personalizar su interfaz
- Configuración de notificaciones por usuario
- Preferencias de tema y visualización

#### R020 - Configuración de Ambiente
- Distinción entre ambiente de desarrollo, testing y producción
- Configuraciones específicas por ambiente
- Variables de entorno para conexiones a servicios

### Excepciones y Casos Especiales

#### R021 - Manejo de Emergencias
- Protocolo para situaciones de emergencia
- Contactos de emergencia accesibles desde la app
- Modo de emergencia que bypasa ciertas restricciones

#### R022 - Contingencias Técnicas
- Procedimientos para fallas de conectividad
- Backup automático de datos críticos
- Modo degradado para funcionalidad limitada

---

## 🧠 Notas para el agente Claude Code

Este contexto se puede usar para tareas como:

- Refactorizar código según reglas de negocio
- Detectar lógicas mal implementadas (por ejemplo, check-in sin coordenadas)
- Generar pruebas automatizadas con base en reglas
- Explicar archivos Dart o Python de backend

---

**Versión:** 1.0  
**Fecha de última actualización:** Junio 2025  
**Responsable:** Equipo de Desarrollo DIANA


