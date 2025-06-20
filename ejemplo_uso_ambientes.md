# Configuración de Ambientes

## Cómo cambiar entre ambientes

### 1. Ubicación del archivo de configuración
```
lib/configuracion/ambiente_config.dart
```

### 2. Ambientes disponibles:

**DESARROLLO (localhost):**
```dart
static const Ambiente _ambienteActual = Ambiente.desarrollo;
```

**QA:**
```dart
static const Ambiente _ambienteActual = Ambiente.qa;
```

**PRE-PRODUCCIÓN:**
```dart
static const Ambiente _ambienteActual = Ambiente.preproduccion;
```

**PRODUCCIÓN:**
```dart
static const Ambiente _ambienteActual = Ambiente.produccion;
```

## URLs configuradas por ambiente

### Desarrollo (DEV)
- **Base URL:** `http://localhost:60148/api`
- **Líderes:** `http://localhost:60148/api/lideres`
- **Planes:** `http://localhost:60148/api/planes`
- **Visitas:** `http://localhost:60148/api/visitas`

### QA
- **Base URL:** `https://guillermosofnux-001-site1.stempurl.com/api`
- **Líderes:** `https://guillermosofnux-001-site1.stempurl.com/api/lideres`
- **Planes:** `https://guillermosofnux-001-site1.stempurl.com/api/planes`
- **Visitas:** `https://guillermosofnux-001-site1.stempurl.com/api/visitas`

### Pre-Producción
- **Base URL:** `https://guillermosofnux-001-site1.stempurl.com/api`
- **Líderes:** `https://guillermosofnux-001-site1.stempurl.com/api/lideres`
- **Planes:** `https://guillermosofnux-001-site1.stempurl.com/api/planes`
- **Visitas:** `https://guillermosofnux-001-site1.stempurl.com/api/visitas`

### Producción
- **Base URL:** `https://guillermosofnux-001-site1.stempurl.com/api`
- **Líderes:** `https://guillermosofnux-001-site1.stempurl.com/api/lideres`
- **Planes:** `https://guillermosofnux-001-site1.stempurl.com/api/planes`
- **Visitas:** `https://guillermosofnux-001-site1.stempurl.com/api/visitas`

## Servicios actualizados

✅ **LiderComercialServicio** - `/lib/servicios/lider_comercial_servicio.dart`
✅ **PlanTrabajoServicio** - `/lib/servicios/plan_trabajo_servicio.dart`  
✅ **VisitaClienteServicio** - `/lib/servicios/visita_cliente_servicio.dart`
✅ **VisitasApiService** - `/lib/servicios/visitas_api_service.dart`

## Métodos de utilidad disponibles

```dart
// Verificar ambiente actual
AmbienteConfig.esDevelopment     // true si está en desarrollo
AmbienteConfig.esQA              // true si está en QA
AmbienteConfig.esPreproduccion   // true si está en pre-producción
AmbienteConfig.esProduccion      // true si está en producción

// Obtener información del ambiente
AmbienteConfig.nombreAmbiente    // "Desarrollo", "QA", "Pre-Producción" o "Producción"
AmbienteConfig.baseUrl           // URL base según el ambiente
```

## Pasos para hacer el cambio

1. Abrir el archivo: `lib/configuracion/ambiente_config.dart`
2. Cambiar la línea 9: `static const Ambiente _ambienteActual = Ambiente.qa;`
3. Por el ambiente deseado:
   - `Ambiente.desarrollo` para DEV
   - `Ambiente.qa` para QA
   - `Ambiente.preproduccion` para Pre-Producción
   - `Ambiente.produccion` para Producción
4. Guardar el archivo
5. Hacer hot reload o reiniciar la aplicación

¡Listo! Todos los endpoints ahora apuntarán automáticamente al ambiente seleccionado.