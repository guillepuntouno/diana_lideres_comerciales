#!/bin/bash
echo "Generando adaptadores de Hive..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""
echo "Proceso completado."
echo "Si hay errores, ejecuta: flutter pub get"