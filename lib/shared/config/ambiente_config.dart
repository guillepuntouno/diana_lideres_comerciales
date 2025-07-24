class AmbienteConfig {
  // Por defecto estamos en pre-productivo
  static const bool esProduccion = false;
  
  // Puedes cambiar esta configuración según el ambiente
  static const String ambiente = 'PRE-PRODUCTIVO';
  
  // También puedes usar variables de entorno si lo prefieres
  static bool get esDesarrollo => !esProduccion;
}