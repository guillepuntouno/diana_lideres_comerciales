# Estructura del Proyecto – Diana Líderes Comerciales

Este proyecto Flutter sigue una arquitectura modular y está organizado en capas funcionales para separar vistas, lógica de negocio, servicios y modelos de datos.

---

## 📂 lib/

### ✅ Archivos raíz
- `main.dart`: Punto de entrada de la aplicación.
- `app.dart`: Configuración global del app (temas, rutas, etc.).

### 📦 base_datos/
- `database_helper.dart`: Abstracción para operaciones SQLite o locales.

### 📦 modelos/
Modelos de dominio que representan entidades clave:
- `visita_cliente_modelo.dart`
- `lider_comercial_modelo.dart`
- `plan_trabajo_modelo.dart`
- `notificacion_modelo.dart`
- `user_dto.dart`, etc.

### 📦 rutas/
- `rutas.dart`: Mapeo y gestión de navegación entre pantallas.

### 📦 servicios/
Servicios encargados de lógica de negocio y acceso a datos remotos o locales:
- `geolocalizacion_servicio.dart`
- `visitas_api_service.dart`
- `sesion_servicio.dart`
- `plan_trabajo_servicio.dart`, etc.

### 📦 temas/
- `tema_diana.dart`: Definición de colores, fuentes y estilos visuales.

### 📦 viewmodels/
- `login_viewmodel.dart`: Lógica de presentación desacoplada de la UI.

### 📦 vistas/
Componentes visuales agrupados por funcionalidad:
- `formulario_dinamico/`
- `menu_principal/`
- `planes_trabajo/`
- `visita_cliente/`
- `resumen/`
- `notificaciones/`
- `login/`

### 📦 widgets/
Widgets reutilizables en toda la app:
- `diana_appbar.dart`
- `encabezado_inicio.dart`
- `footer_clipper.dart`

---

## 📂 android/, ios/, linux/, macos/, windows/
Carpetas generadas por Flutter para soporte multiplataforma. Contienen configuraciones nativas, runners, assets específicos de cada plataforma, y archivos de build.

---

## 📂 assets/
- `logo_diana.png`: Imagen institucional.

---

## 📂 context/
- `reglas_negocio.md`: Archivo con las reglas de negocio cargadas en Claude Code.
- `estructura_proyecto.md`: Esta estructura documentada que estás leyendo.

---

## 📂 test/
- `widget_test.dart`: Test generado por defecto. Aquí se agregarán pruebas unitarias o de widgets.

---

## 📂 web/
Contiene archivos de configuración para la versión web:
- `index.html`
- `manifest.json`
- Íconos y favicon.

---

## 📜 Archivos raíz del proyecto

- `pubspec.yaml`: Configuración del proyecto y dependencias.
- `README.md`: Documentación general.
- `analysis_options.yaml`: Linter y configuración de análisis estático.
- `devtools_options.yaml`: Configuración opcional de herramientas de desarrollo.

---

## 🔄 Consideraciones para Claude Code

Con esta estructura, Claude puede:

- Refactorizar pantallas individuales (`vistas/`) sin romper lógica.
- Generar pruebas para modelos (`modelos/`) o servicios (`servicios/`).
- Aplicar lógica de negocio a formularios dinámicos.
- Usar `reglas_negocio.md` como contexto para modificar `viewmodels/`, `servicios/` o `formulario_dinamico/`.

# Estructura del Proyecto – Diana Líderes Comerciales

Este proyecto Flutter sigue una arquitectura modular y está organizado en capas funcionales para separar vistas, lógica de negocio, servicios y modelos de datos.

---

## 📂 lib/

### ✅ Archivos raíz
- `main.dart`: Punto de entrada de la aplicación.
- `app.dart`: Configuración global del app (temas, rutas, etc.).

### 📦 base_datos/
- `database_helper.dart`: Abstracción para operaciones SQLite o locales.

### 📦 modelos/
Modelos de dominio que representan entidades clave:
- `visita_cliente_modelo.dart`
- `lider_comercial_modelo.dart`
- `plan_trabajo_modelo.dart`
- `notificacion_modelo.dart`
- `user_dto.dart`, etc.

### 📦 rutas/
- `rutas.dart`: Mapeo y gestión de navegación entre pantallas.

### 📦 servicios/
Servicios encargados de lógica de negocio y acceso a datos remotos o locales:
- `geolocalizacion_servicio.dart`
- `visitas_api_service.dart`
- `sesion_servicio.dart`
- `plan_trabajo_servicio.dart`, etc.

### 📦 temas/
- `tema_diana.dart`: Definición de colores, fuentes y estilos visuales.

### 📦 viewmodels/
- `login_viewmodel.dart`: Lógica de presentación desacoplada de la UI.

### 📦 vistas/
Componentes visuales agrupados por funcionalidad:
- `formulario_dinamico/`
- `menu_principal/`
- `planes_trabajo/`
- `visita_cliente/`
- `resumen/`
- `notificaciones/`
- `login/`

### 📦 widgets/
Widgets reutilizables en toda la app:
- `diana_appbar.dart`
- `encabezado_inicio.dart`
- `footer_clipper.dart`

---

## 📂 android/, ios/, linux/, macos/, windows/
Carpetas generadas por Flutter para soporte multiplataforma. Contienen configuraciones nativas, runners, assets específicos de cada plataforma, y archivos de build.

---

## 📂 assets/
- `logo_diana.png`: Imagen institucional.

---

## 📂 context/
- `reglas_negocio.md`: Archivo con las reglas de negocio cargadas en Claude Code.
- `estructura_proyecto.md`: Esta estructura documentada que estás leyendo.

---

## 📂 test/
- `widget_test.dart`: Test generado por defecto. Aquí se agregarán pruebas unitarias o de widgets.

---

## 📂 web/
Contiene archivos de configuración para la versión web:
- `index.html`
- `manifest.json`
- Íconos y favicon.

---

## 📜 Archivos raíz del proyecto

- `pubspec.yaml`: Configuración del proyecto y dependencias.
- `README.md`: Documentación general.
- `analysis_options.yaml`: Linter y configuración de análisis estático.
- `devtools_options.yaml`: Configuración opcional de herramientas de desarrollo.

---

## 🔄 Consideraciones para Claude Code

Con esta estructura, Claude puede:

- Refactorizar pantallas individuales (`vistas/`) sin romper lógica.
- Generar pruebas para modelos (`modelos/`) o servicios (`servicios/`).
- Aplicar lógica de negocio a formularios dinámicos.
- Usar `reglas_negocio.md` como contexto para modificar `viewmodels/`, `servicios/` o `formulario_dinamico/`.


