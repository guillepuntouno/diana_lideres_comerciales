# 📊 RESUMEN EJECUTIVO DE ARQUITECTURA - PROYECTO DIANA V2

## 🎯 DESCRIPCIÓN GENERAL
DIANA es una aplicación móvil empresarial para la gestión de líderes comerciales, que permite registrar y monitorear visitas a puntos de venta, evaluar al personal de ventas mediante formularios dinámicos, y funcionar tanto online como offline para garantizar la operatividad en campo.

---

## 🔧 TECNOLOGÍAS Y DEPENDENCIAS PRINCIPALES

### Frontend
- **Framework**: Flutter 3.7.2+
- **Lenguaje**: Dart
- **Plataformas soportadas**: Android, iOS, Web, Windows

### Dependencias Clave
- **provider** (^6.1.2): Gestión de estado
- **hive** (^2.2.3) + **hive_flutter**: Base de datos local NoSQL para funcionalidad offline
- **sqflite** (^2.2.8+4): Base de datos SQL local (legacy)
- **connectivity_plus** (^6.0.3): Detección de conectividad
- **geolocator** (^10.1.0): Servicios de geolocalización
- **http** (^1.1.0): Comunicación con APIs
- **shared_preferences** (^2.5.3): Almacenamiento de preferencias
- **app_links** (^6.1.1): Deep linking para autenticación

---

## 🏗️ PATRÓN DE ARQUITECTURA

El proyecto implementa una arquitectura **MVVM (Model-View-ViewModel)** adaptada con las siguientes características:

### 1. Separación de Capas
- **Vistas** (`/vistas`): Interfaces de usuario
- **ViewModels** (`/viewmodels`): Lógica de presentación con ChangeNotifier
- **Servicios** (`/servicios`): Lógica de negocio
- **Repositorios** (`/repositorios`): Acceso a datos
- **Modelos** (`/modelos`): Entidades de datos

### 2. Gestión de Estado
- Provider con ChangeNotifier para reactividad

### 3. Navegación
- Sistema de rutas centralizado con AuthGuard para seguridad

---

## 📁 ESTRUCTURA DE CARPETAS DETALLADA

```
lib/
├── app.dart                    # Configuración principal de la aplicación
├── main.dart                   # Punto de entrada, manejo de deep links
├── configuracion/              # Configuraciones del ambiente
│   └── ambiente_config.dart    # Gestión de ambientes (dev, qa, prod)
├── modelos/                    # Entidades de datos
│   ├── hive/                   # Modelos para base de datos local
│   │   ├── visita_hive.dart
│   │   ├── cliente_hive.dart
│   │   ├── plan_trabajo_hive.dart
│   │   └── ... (23 adaptadores en total)
│   └── *.dart                  # DTOs y modelos de negocio
├── vistas/                     # Interfaces de usuario
│   ├── login/                  # Autenticación
│   ├── menu_principal/         # Navegación principal
│   ├── visita_cliente/         # Gestión de visitas
│   ├── formulario_dinamico/    # Formularios configurables
│   ├── planes_trabajo/         # Gestión de planes
│   ├── rutina_diaria/          # Actividades diarias
│   └── debug/                  # Herramientas de desarrollo
├── viewmodels/                 # Lógica de presentación
│   ├── login_viewmodel.dart
│   └── formulario_dinamico_viewmodel.dart
├── servicios/                  # Lógica de negocio
│   ├── hive_service.dart       # Gestión de base de datos local
│   ├── offline_sync_manager.dart # Sincronización offline/online
│   ├── auth_guard.dart         # Seguridad y autenticación
│   ├── geolocalizacion_servicio.dart
│   └── *_servicio.dart         # Servicios específicos
├── repositorios/               # Acceso a datos
│   ├── visitas_repositorio.dart
│   └── planes_trabajo_repositorio.dart
├── rutas/                      # Navegación
│   └── rutas.dart
├── widgets/                    # Componentes reutilizables
│   ├── diana_appbar.dart
│   ├── encabezado_inicio.dart
│   └── connection_status_widget.dart
├── platform/                   # Código específico por plataforma
│   └── platform_bridge.dart
└── temas/                      # Estilos visuales
    └── tema_diana.dart
```

---

## 💾 GESTIÓN DE ESTADO Y DATOS

### Estado Local
1. **Provider + ChangeNotifier**: Patrón principal para gestión de estado reactivo
2. **ViewModels**: Encapsulan la lógica de negocio y notifican cambios a las vistas
3. **SharedPreferences**: Para configuraciones y tokens de sesión
4. **Hive**: Base de datos NoSQL para persistencia de datos de negocio

### Datos Remotos
- **API REST**: Comunicación con backend AWS
- **Base URL**: Configurable por ambiente
- **Autenticación**: JWT con AWS Cognito
- **Sincronización**: Bidireccional con gestión inteligente de conflictos

### Funcionalidad Offline
1. **Modo Offline Completo**: La aplicación funciona sin conexión
2. **Hive Database**: 23 adaptadores para diferentes entidades
3. **OfflineSyncManager**: 
   - Detección automática de conectividad
   - Cola de sincronización para datos pendientes
   - Sincronización periódica cada 5 minutos
   - Estados: idle, syncing, success, error, noConnection

---

## 📱 CLASIFICACIÓN DE PANTALLAS: WEB vs MÓVIL

### 📱 PANTALLAS MÓVIL (Diseñadas para uso en campo)

1. **PantallaVisitaCliente** (`/visita_cliente`)
   - Usa GPS/geolocalización intensivamente
   - Check-in/check-out con ubicación
   - Captura de datos en tiempo real

2. **PantallaRutinaDiaria** (`/rutina_diaria`)
   - Trabajo en campo con actividades diarias
   - Optimizada para trabajo offline
   - Sincronización inteligente

3. **PantallaFormularioDinamico** (`/formulario_dinamico`)
   - Formularios para evaluación en campo
   - Entrada rápida en dispositivos móviles
   - Manejo de compromisos y retroalimentación

4. **PantallaResumenVisita** (`/resumen_visita`)
   - Cierre de visita en campo
   - Flujo conectado con check-in/check-out

### 💻 PANTALLAS WEB (Mejor experiencia en navegador)

1. **VistaAsignacionClientes** (`/asignacion_clientes`)
   - Gestión de datos maestros
   - Asignaciones masivas de clientes
   - Interfaz tipo tabla/grid

2. **VistaIndicadoresGestion** (`/indicadores_gestion`)
   - Dashboard de KPIs y métricas
   - Visualización de datos complejos
   - Reportes y análisis

3. **VistaProgramacionSemana** (`/plan_configuracion`)
   - Planificación semanal con vista calendario
   - Gestión de rutas y asignaciones
   - Configuración de planes de trabajo

4. **VistaConfiguracionPlanUnificada** (`/configuracion_plan`)
   - Configuración avanzada
   - Manejo de datos maestros
   - Interfaz administrativa

### 🔄 PANTALLAS HÍBRIDAS (Funcionan en ambas plataformas)

1. **PantallaLogin** - Autenticación adaptativa
2. **PantallaMenuPrincipal** - Navegación central
3. **VistaPlanesTrabajo** - Consulta de planes
4. **PantallaNotificaciones** - Sistema de mensajería
5. **PantallaResultadosDia** - Análisis de resultados
6. **PantallaRutinasResultados** - Métricas y seguimiento

---

## 🔐 SEGURIDAD Y AUTENTICACIÓN

1. **AWS Cognito**: Autenticación federada con Active Directory
2. **JWT Tokens**: Manejo seguro de sesiones
3. **AuthGuard**: Middleware para protección de rutas
4. **Deep Linking**: Soporte para autenticación vía URL callbacks
5. **Almacenamiento Seguro**: Tokens en SharedPreferences

---

## 🚀 AMBIENTES DE DESPLIEGUE

| Ambiente | URL | Descripción |
|----------|-----|-------------|
| **Desarrollo** | localhost:8080 | Proxy CORS local |
| **QA** | API Gateway AWS (dev) | Pruebas integradas |
| **Pre-producción** | API Gateway AWS | Validación final |
| **Producción** | API Gateway AWS | Ambiente productivo |

---

## 🎨 CARACTERÍSTICAS ESPECIALES

1. **Geolocalización**: Registro de ubicación en todas las visitas
2. **Formularios Dinámicos**: Configurables desde el backend
3. **Planes de Trabajo Semanales**: Gestión completa de rutas
4. **Notificaciones**: Sistema de alertas y recordatorios
5. **Debug Mode**: Pantalla especial para inspección de datos Hive
6. **Soporte Multiplataforma**: Android, iOS, Web, Windows

---

## 📊 CONSIDERACIONES PARA INTEGRACIÓN WEB

### Estrategia Actual
- **Mobile-first**: La aplicación está optimizada principalmente para móvil
- **Web adaptativo**: Algunas pantallas se adaptan para uso web
- **Separación por rol**: Operación en campo (móvil) vs supervisión (web)

### Recomendaciones para Pantallas Web
1. **Datos Maestros**: Implementar interfaces web dedicadas para:
   - Gestión de catálogos de clientes
   - Configuración de formularios dinámicos
   - Administración de usuarios y permisos

2. **Reportería**: Crear dashboards web para:
   - Análisis de productividad
   - Métricas de cumplimiento
   - Reportes gerenciales

3. **Administración**: Interfaces web para:
   - Configuración del sistema
   - Gestión de planes masivos
   - Monitoreo en tiempo real

### Arquitectura Propuesta para Integración
```
DIANA V2
├── /mobile (Flutter - actual)
│   └── Enfoque en trabajo de campo
├── /web (Flutter Web - expandir)
│   ├── Admin Dashboard
│   ├── Reportes
│   └── Gestión de Datos Maestros
└── /shared
    ├── Modelos comunes
    ├── Servicios API
    └── Lógica de negocio
```

---

## 🔄 PRÓXIMOS PASOS

1. **Evaluar** qué pantallas web necesitan desarrollo dedicado
2. **Identificar** servicios web específicos para datos maestros
3. **Diseñar** arquitectura de microservicios si es necesario
4. **Implementar** Progressive Web App (PWA) para mejor experiencia web
5. **Optimizar** bundle size para carga rápida en web

---

## 📝 NOTAS TÉCNICAS

- El proyecto usa **Flutter 3.7.2+** que tiene soporte completo para web
- **Hive** funciona en web mediante IndexedDB
- La autenticación **AWS Cognito** es compatible con web
- Se requiere configuración CORS para APIs en ambiente web
- El código actual usa `kIsWeb` para detectar plataforma y adaptar comportamiento

Esta arquitectura está diseñada para soportar operaciones comerciales en campo con alta disponibilidad, permitiendo trabajo continuo incluso sin conectividad y garantizando la integridad de los datos mediante sincronización inteligente.