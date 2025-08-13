# Configuración de AWS Amplify para Diana Líderes Comerciales

## Información del proyecto
- **Tipo**: Flutter Web Application
- **Framework**: Flutter 3.19.6
- **Directorio de salida**: build/web
- **Comando de build**: flutter build web --release

## Variables de entorno necesarias
```bash
FLUTTER_ROOT=/opt/flutter
FLUTTER_WEB=true
PUB_CACHE=/opt/flutter/.pub-cache
PATH=$PATH:$FLUTTER_ROOT/bin
```

## Problemas comunes y soluciones

### 1. Error "npm ci" cuando debería ejecutar Flutter
**Causa**: Amplify detecta incorrectamente el proyecto como Node.js
**Solución**: 
- Asegurar que no hay archivo package.json en el root
- Usar amplify.yml específico para Flutter
- Configurar las variables de entorno correctamente

### 2. Error en build_runner (Hive adapters)
**Causa**: Falta de dependencias o conflictos en generación de código
**Solución**:
- Ejecutar con --delete-conflicting-outputs
- Continuar el build aunque falle (usar || echo)
- Verificar archivos .g.dart después de la generación

### 3. Error de permisos en Flutter SDK
**Causa**: Instalación en directorio sin permisos
**Solución**:
- Usar /opt/flutter en lugar de /tmp/flutter
- Configurar chown después de la instalación

### 4. Cache de dependencias
**Causa**: Dependencias no se cachean correctamente
**Solución**:
- Configurar PUB_CACHE en ubicación persistente
- Agregar directorios correctos a cache en amplify.yml

## Comandos de verificación manual
```bash
# Verificar Flutter
flutter --version
flutter doctor

# Verificar dependencias
flutter pub get
flutter pub deps

# Generar código Hive
dart run build_runner build --delete-conflicting-outputs

# Build web
flutter build web --release
```

## Archivos importantes
- `amplify.yml`: Configuración principal de build
- `.amplifyignore`: Archivos a ignorar durante el deploy
- `pubspec.yaml`: Dependencias del proyecto
- `scripts/verify_env.sh`: Script de verificación del entorno
