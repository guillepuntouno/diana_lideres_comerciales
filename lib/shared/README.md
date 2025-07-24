# 📦 Shared - Código Compartido

Esta carpeta contiene todo el código que es compartido entre las versiones móvil y web de DIANA.

## Estructura:

- **modelos/**: Modelos de datos y entidades compartidas
- **servicios/**: Lógica de negocio y servicios API
- **repositorios/**: Capa de acceso a datos
- **configuracion/**: Configuraciones globales (ambientes, constantes)
- **widgets/**: Widgets reutilizables en ambas plataformas

## Reglas:
1. Solo código que NO dependa de características específicas de plataforma
2. Evitar imports de Flutter que sean específicos de móvil o web
3. Usar abstracciones cuando sea necesario diferenciar comportamiento por plataforma