#!/bin/bash
echo "🔨 Ejecutando build_runner para generar código Hive..."
flutter pub run build_runner build --delete-conflicting-outputs
echo "✅ Generación de código completada"