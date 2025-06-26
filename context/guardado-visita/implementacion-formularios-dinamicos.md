# Implementación de Formularios Dinámicos en Plan Unificado

## 📅 Fecha de implementación: 26/01/2025

## 🎯 Objetivo
Agregar soporte para persistir formularios dinámicos en la misma estructura `PlanTrabajoUnificadoHive`, manteniendo retrocompatibilidad con el flujo existente de check-in/out, retroalimentación y reconocimiento.

## 🔧 Cambios realizados

### 1. **Nuevo modelo FormularioDiaHive**
Archivo: `lib/modelos/hive/plan_trabajo_unificado_hive.dart`

```dart
@HiveType(typeId: 40)
class FormularioDiaHive extends HiveObject {
  @HiveField(0) String formularioId;
  @HiveField(1) String clienteId;
  @HiveField(2) Map<String, dynamic> respuestas;
  @HiveField(3) DateTime fechaCaptura;
}
```

### 2. **Extensión de DiaPlanHive**
Se agregó el campo de formularios:
```dart
@HiveField(11, defaultValue: [])
List<FormularioDiaHive> formularios;
```

### 3. **Registro del adapter**
Archivo: `lib/servicios/hive_service.dart`
```dart
if (!Hive.isAdapterRegistered(40)) {
  Hive.registerAdapter(FormularioDiaHiveAdapter());
}
```

### 4. **Nuevos métodos en VisitaClienteUnificadoService**
Archivo: `lib/servicios/visita_cliente_unificado_service.dart`

- `guardarResultadoFormularioDinamico()`: Guarda un formulario dinámico
- `obtenerFormulariosCliente()`: Obtiene todos los formularios de un cliente
- `obtenerFormulario()`: Obtiene un formulario específico

### 5. **Serialización para sincronización**
Se creó el método `toJsonParaSincronizacion()` en `PlanTrabajoUnificadoHive` que incluye los formularios dentro de cada cliente:

```dart
'clientes': dia.clientes.map((visita) {
  final formulariosCliente = dia.formularios
      .where((f) => f.clienteId == visita.clienteId)
      .map((f) => f.toJson())
      .toList();
  
  return {
    'clienteId': visita.clienteId,
    'formularios': formulariosCliente,
    // ... resto de campos
  };
})
```

### 6. **Integración en pantalla de formulario**
Archivo: `lib/vistas/formulario_dinamico/pantalla_formulario_dinamico.dart`

El método `_guardarEnAPI()` ahora guarda en ambas estructuras:
1. La estructura antigua (cuestionario, compromisos, retro/reco)
2. La nueva estructura de formularios dinámicos

```dart
// Guardar en estructura antigua (retrocompatible)
await _visitaUnificadoService.actualizarFormulariosEnPlanUnificado(...);

// Guardar también como formulario dinámico
await _visitaUnificadoService.guardarResultadoFormularioDinamico(
  formularioId: 'formulario-visita-v1',
  respuestas: respuestasDinamicas,
);
```

## 🔄 Flujo de datos actualizado

```
PlanTrabajoUnificadoHive
└── dias : Map<String, DiaPlanHive>
    └── "Lunes" : DiaPlanHive
        ├── clientes : List<VisitaClienteUnificadaHive>
        │   └── [0] VisitaClienteUnificadaHive
        │       ├── checkIn/checkOut (sin cambios)
        │       ├── cuestionario (estructura antigua - retrocompatible)
        │       ├── compromisos (estructura antigua - retrocompatible)
        │       └── retroalimentacion/reconocimiento (sin cambios)
        └── formularios : List<FormularioDiaHive> ← NUEVO
            └── [0] FormularioDiaHive
                ├── formularioId: "formulario-visita-v1"
                ├── clienteId: "12345"
                ├── respuestas: Map<String,dynamic>
                └── fechaCaptura: DateTime
```

## ✅ Retrocompatibilidad garantizada

1. **Planes antiguos**: Se abren sin errores. `dia.formularios` devuelve lista vacía por el `defaultValue: []`
2. **Flujo existente**: Check-in/out, retro/reco funcionan sin cambios
3. **Doble guardado**: Los datos se guardan en ambas estructuras temporalmente
4. **Sincronización**: El servidor recibe todo en un solo JSON unificado

## 🚀 Próximos pasos

1. **Migración gradual**: Una vez que el backend soporte la nueva estructura, se puede dejar de guardar en la estructura antigua
2. **Formularios múltiples**: El sistema ya soporta múltiples formularios por cliente/día
3. **Plantillas dinámicas**: Se pueden agregar diferentes tipos de formularios con distintos `formularioId`

## 📊 Ejemplo de JSON sincronizado

```json
{
  "id": "123456_SEM01_2025",
  "semana": {
    "numero": 1,
    "estatus": "enviado"
  },
  "diasTrabajo": [{
    "dia": "Lunes",
    "clientes": [{
      "clienteId": "12345",
      "checkIn": { /* ... */ },
      "checkOut": { /* ... */ },
      "formularios": [{
        "formularioId": "formulario-visita-v1",
        "clienteId": "12345",
        "respuestas": {
          "tipoExhibidor": { /* ... */ },
          "estandaresEjecucion": { /* ... */ },
          "disponibilidad": { /* ... */ },
          "compromisos": [ /* ... */ ],
          "retroalimentacion": "...",
          "reconocimiento": "..."
        },
        "fechaCaptura": "2025-01-26T15:30:00Z"
      }],
      "cuestionario": { /* estructura antigua */ },
      "compromisos": [ /* estructura antigua */ ],
      "retroalimentacion": "...",
      "reconocimiento": "...",
      "estatus": "completada"
    }]
  }]
}
```

## ⚠️ Notas importantes

- **No se modificó** la lógica de negocio existente
- **No se eliminaron** campos ni modelos existentes
- **No se requiere** migración de datos
- Los TypeAdapters se generan con `flutter pub run build_runner build`
- El campo `formularios` está en `DiaPlanHive`, no en `VisitaClienteUnificadaHive`