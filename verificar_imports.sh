#!/bin/bash

echo "=== Verificando imports problemáticos en el proyecto DIANA ==="
echo ""

echo "1. Buscando imports de carpetas que ya no existen en raíz..."
grep -r "import.*package:diana_lc_front/modelos/" lib/ 2>/dev/null | grep -v "/shared/" | head -5
grep -r "import.*package:diana_lc_front/repositorios/" lib/ 2>/dev/null | grep -v "/shared/" | head -5
grep -r "import.*package:diana_lc_front/servicios/" lib/ 2>/dev/null | grep -v "/shared/" | head -5

echo ""
echo "2. Buscando imports relativos problemáticos..."
grep -r "import.*'\.\./\.\./modelos/" lib/ 2>/dev/null | head -5
grep -r "import.*'\.\./\.\./servicios/" lib/ 2>/dev/null | head -5
grep -r "import.*'\.\./\.\./repositorios/" lib/ 2>/dev/null | head -5

echo ""
echo "3. Verificando que servicios móviles encuentren sus dependencias..."
echo "Servicios en /servicios/ que importan desde shared:"
grep -l "import.*shared/" lib/servicios/*.dart 2>/dev/null

echo ""
echo "4. Archivos que pueden tener problemas..."
# Buscar archivos que importen servicios que se movieron
grep -r "geolocalizacion_servicio" lib/vistas/ 2>/dev/null | grep -v "servicios/geolocalizacion" | head -3

echo ""
echo "=== Verificación completada ==="