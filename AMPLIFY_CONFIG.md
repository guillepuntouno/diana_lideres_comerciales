# Configuración de AWS Amplify para Diana Líderes Comerciales

## Información del proyecto
- **Tipo**: Flutter Web Application
- **Framework**: Flutter 3.19.6
- **Directorio de salida**: build/web
- **Comando de build**: flutter build web --release

## Variables de entorno necesarias
```bash
FLUTTER_HOME=$HOME/flutter
FLUTTER_WEB=true
PUB_CACHE=$HOME/.pub-cache
PATH=$PATH:$FLUTTER_HOME/bin
```

## Problemas comunes y soluciones

### 1. Error "mkdir: cannot create directory '/opt/flutter': Permission denied"
**Causa**: Amplify no tiene permisos para crear directorios en /opt/
**Solución**: 
- Usar $HOME/flutter en lugar de /opt/flutter
- Usar $HOME/.pub-cache para el cache de pub
- Configurar FLUTTER_HOME en lugar de FLUTTER_ROOT

### 2. Error "npm ci" cuando debería ejecutar Flutter
**Causa**: Detecta incorrectamente el proyecto como Node.js
**Solución**: 
- Asegurar que no hay archivo package.json en el root
- Usar amplify.yml específico para Flutter
- Configurar las variables de entorno correctamente

### 3. Error en build_runner (Hive adapters)
**Causa**: Falta de dependencias o conflictos en generación de código
**Solución**:
- Ejecutar con --delete-conflicting-outputs
- Continuar el build aunque falle (usar || echo)
- Verificar archivos .g.dart después de la generación

### 4. Cache de dependencias
**Causa**: Dependencias no se cachean correctamente
**Solución**:
- Configurar PUB_CACHE en $HOME/.pub-cache (ubicación persistente)
- Agregar directorios correctos a cache en amplify.yml
- Usar $HOME/flutter para Flutter SDK

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
