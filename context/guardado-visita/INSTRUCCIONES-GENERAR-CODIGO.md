# 🚨 INSTRUCCIONES IMPORTANTES - Generar Código Hive

## ⚠️ Pasos necesarios para completar la implementación

### 1. Ejecutar el generador de código

Abre una terminal en la raíz del proyecto y ejecuta:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Este comando generará el archivo `plan_trabajo_unificado_hive.g.dart` que incluirá:
- `FormularioDiaHiveAdapter`
- Los adapters actualizados para `DiaPlanHive` con el nuevo campo

### 2. Descomentar el registro del adapter

Una vez generado el código, ve al archivo `lib/servicios/hive_service.dart` y descomenta las líneas 128-130:

```dart
if (!Hive.isAdapterRegistered(40)) {
  Hive.registerAdapter(FormularioDiaHiveAdapter());
}
```

### 3. Verificar la generación

Asegúrate de que el archivo `lib/modelos/hive/plan_trabajo_unificado_hive.g.dart` contenga:
- `class FormularioDiaHiveAdapter extends TypeAdapter<FormularioDiaHive>`
- El campo `formularios` en `DiaPlanHiveAdapter`

## 🔍 Solución de problemas

Si el build_runner falla:

1. **Limpiar caché**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Forzar regeneración**:
   ```bash
   flutter pub run build_runner clean
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Verificar dependencias** en `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     build_runner: ^2.0.0
     hive_generator: ^2.0.0
   ```

## ✅ Verificación final

Una vez completados los pasos, la aplicación debería:
1. Compilar sin errores
2. Guardar formularios dinámicos en el plan unificado
3. Mantener retrocompatibilidad con planes existentes

## 📝 Nota

Los cambios realizados son 100% retrocompatibles gracias al `defaultValue: []` en el campo `formularios`, por lo que los planes existentes no se verán afectados.