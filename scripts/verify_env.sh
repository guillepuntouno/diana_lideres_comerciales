#!/bin/bash
# Script de verificación previa al build para AWS Amplify

echo "=== Verificación del entorno Flutter ==="

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado"
    exit 1
fi

echo "✅ Flutter encontrado: $(flutter --version --machine | head -1)"

# Verificar Dart
if ! command -v dart &> /dev/null; then
    echo "❌ Dart no está instalado"
    exit 1
fi

echo "✅ Dart encontrado: $(dart --version)"

# Verificar pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ pubspec.yaml no encontrado"
    exit 1
fi

echo "✅ pubspec.yaml encontrado"

# Verificar dependencias críticas
echo "=== Verificando dependencias críticas ==="
flutter pub deps | grep -E "(hive|build_runner|hive_generator)" || echo "⚠️  Algunas dependencias de Hive no están disponibles"

# Crear directorios necesarios
mkdir -p .dart_tool
mkdir -p build

echo "=== Entorno verificado correctamente ==="
