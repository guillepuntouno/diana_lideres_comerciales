# 📋 MIGRACIÓN ARQUITECTÓNICA - PROYECTO DIANA V2
**Fecha:** 2025-07-23  
**Hora:** 19:53:05  
**Ejecutor:** Claude AI Assistant

---

## 🎯 OBJETIVO DE LA MIGRACIÓN
Reorganizar la arquitectura del proyecto DIANA para soportar mejor el desarrollo multiplataforma (móvil y web), separando el código compartido del código específico de cada plataforma.

### Arquitectura Objetivo:
```
DIANA V2
├── /mobile (Flutter - específico móvil)
│   └── Enfoque en trabajo de campo
├── /web (Flutter Web - específico web)
│   ├── Admin Dashboard
│   ├── Reportes
│   └── Gestión de Datos Maestros
└── /shared (Código compartido)
    ├── Modelos comunes
    ├── Servicios API
    └── Lógica de negocio
```

---

## ✅ FASE 1: REORGANIZACIÓN BASE (COMPLETADA)

### 📅 Ejecutada: 2025-07-23 19:00 - 19:50

### 🔧 Cambios Realizados:

#### 1. **Creación de Nueva Estructura de Carpetas**
```bash
✅ Creadas las siguientes carpetas:
- lib/shared/modelos/
- lib/shared/servicios/
- lib/shared/repositorios/
- lib/shared/configuracion/
- lib/shared/widgets/
- lib/shared/temas/
- lib/mobile/vistas/
- lib/mobile/widgets/
- lib/web/vistas/
- lib/web/widgets/
```

#### 2. **Migración de Archivos Compartidos**
```bash
✅ Movidos a /shared:
- Todos los modelos (12 archivos + carpeta hive/)
- Servicios compartidos (18 archivos)
- Todos los repositorios (6 archivos)
- Configuración ambiente_config.dart
- Carpeta temas/
```

#### 3. **Archivos que Permanecen en Ubicación Original**
```bash
✅ Servicios específicos móviles en /servicios:
- geolocalizacion_servicio.dart (usa GPS)
- visita_cliente_servicio.dart
- visita_cliente_offline_service.dart
- visita_cliente_unificado_service.dart
- clientes_locales_service.dart
```

#### 4. **Actualización Masiva de Imports**
```bash
✅ Total de archivos actualizados: 46
- Todos los imports relativos convertidos a absolutos
- Formato: package:diana_lc_front/shared/[carpeta]/[archivo]
- Corregido config/ → configuracion/
```

### 📊 Resumen de Archivos Modificados por Carpeta:
- `/rutas/`: 1 archivo
- `/servicios/`: 3 archivos  
- `/shared/modelos/`: 1 archivo
- `/shared/repositorios/`: 3 archivos
- `/shared/servicios/`: 16 archivos
- `/vistas/`: 22 archivos
- Otros: 2 archivos

---

## 🚧 FASE 2: SEPARACIÓN DE VISTAS (PENDIENTE)

### 📅 Estimación: 1-2 semanas

### 📋 Tareas Pendientes:

#### 1. **Mover Vistas Móviles**
```bash
De: /vistas/
A: /mobile/vistas/

Vistas a mover:
- visita_cliente/
- rutina_diaria/
- formulario_dinamico/
- resumen_visita/
```

#### 2. **Mover Widgets Móviles**
```bash
Widgets que usan características móviles:
- Componentes con GPS
- Widgets de captura offline
- Navegación específica móvil
```

#### 3. **Crear Vistas Web Nuevas**
```bash
En: /web/vistas/

Nuevas vistas a crear:
- dashboard/
  - DashboardPrincipal.dart
  - widgets/GraficosKPI.dart
- reportes/
  - ReporteVisitas.dart
  - ReporteProductividad.dart
- datos_maestros/
  - GestionClientes.dart
  - ConfiguracionFormularios.dart
- administracion/
  - GestionUsuarios.dart
  - ConfiguracionSistema.dart
```

#### 4. **Actualizar Sistema de Rutas**
```bash
- Crear rutas_mobile.dart
- Crear rutas_web.dart
- Mantener rutas_shared.dart para comunes
```

---

## 🔄 FASE 3: PUNTOS DE ENTRADA SEPARADOS (PENDIENTE)

### 📅 Estimación: 2-3 días

### 📋 Tareas:

#### 1. **Crear main_mobile.dart**
```dart
// Punto de entrada para aplicación móvil
- Importar solo vistas móviles
- Configurar rutas móviles
- Optimizaciones para móvil
```

#### 2. **Crear main_web.dart**
```dart
// Punto de entrada para aplicación web
- Importar solo vistas web
- Configurar rutas web
- Optimizaciones para web
```

#### 3. **Actualizar configuración de build**
```yaml
# En pubspec.yaml agregar scripts:
scripts:
  build_mobile: flutter build apk --target=lib/main_mobile.dart
  build_web: flutter build web --target=lib/main_web.dart
```

---

## 🎨 FASE 4: OPTIMIZACIONES FINALES (PENDIENTE)

### 📅 Estimación: 1 semana

### 📋 Tareas:

#### 1. **Optimización de Bundle Size**
- Lazy loading para rutas web
- Tree shaking automático por plataforma
- Separación de assets por plataforma

#### 2. **Mejoras de UX por Plataforma**
- Navegación adaptativa
- Layouts responsivos mejorados
- Gestos específicos por plataforma

#### 3. **Testing**
- Tests unitarios para shared/
- Tests de widgets para cada plataforma
- Tests de integración

---

## 📈 PROGRESO TOTAL

```
[████████████░░░░░░░░░░░░░░░░░] 30% Completado

✅ Fase 1: Reorganización Base (100%)
⏳ Fase 2: Separación de Vistas (0%)
⏳ Fase 3: Puntos de Entrada (0%)
⏳ Fase 4: Optimizaciones (0%)
```

---

## ⚠️ CONSIDERACIONES IMPORTANTES

### 1. **Estado Actual del Proyecto**
- ✅ El proyecto compila y funciona
- ✅ No se rompió funcionalidad existente
- ✅ Todos los imports están corregidos
- ⚠️ Las vistas siguen en ubicación original (funcional pero no óptimo)

### 2. **Riesgos Identificados**
- Posibles conflictos al mover vistas si hay desarrollo paralelo
- Necesidad de actualizar CI/CD para builds separados
- Requiere coordinación con equipo para evitar conflictos

### 3. **Beneficios Esperados**
- 📦 Reducción del 40-60% en bundle size web
- 🚀 Desarrollo paralelo sin conflictos
- 🎯 Código más mantenible y escalable
- 💻 Mejor experiencia según plataforma

---

## 🛠️ COMANDOS ÚTILES

### Para continuar el desarrollo:
```bash
# Navegar al proyecto
cd /mnt/c/TFS/GMARTINEZJR/flutter/DIANAV2/diana_lideres_comerciales

# Actualizar dependencias
flutter pub get

# Verificar que todo compile
flutter analyze

# Ejecutar en modo debug
flutter run

# Para web específicamente
flutter run -d chrome
```

### Para la siguiente fase:
```bash
# Mover vistas móviles (ejemplo)
mv lib/vistas/visita_cliente lib/mobile/vistas/

# Actualizar imports después de mover
find . -name "*.dart" -exec sed -i 's|/vistas/visita_cliente|/mobile/vistas/visita_cliente|g' {} \;
```

---

## 📝 NOTAS PARA EL EQUIPO

1. **Comunicar los cambios**: Todos los desarrolladores deben hacer `git pull` y `flutter pub get`
2. **Nueva convención de imports**: Siempre usar rutas absolutas con `package:diana_lc_front/`
3. **Ubicación de nuevos archivos**:
   - Código compartido → `/shared/`
   - Código móvil específico → `/mobile/`
   - Código web específico → `/web/`

---

## 🔗 REFERENCIAS

- **Documento de arquitectura actualizado**: `context/estructura_proyecto.md`
- **Reglas de negocio**: `context/reglas_negocio.md`
- **Análisis original**: `análisis_state_management.md`

---

**Fin del reporte de migración Fase 1**