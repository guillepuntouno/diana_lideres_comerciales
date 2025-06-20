enum Ambiente { desarrollo, qa, preproduccion, produccion }

class AmbienteConfig {
  static const Ambiente _ambienteActual =
      Ambiente.desarrollo; // Cambiar aquí para alternar ambientes

  static Ambiente get ambienteActual => _ambienteActual;

  static String get baseUrl {
    switch (_ambienteActual) {
      case Ambiente.desarrollo:
        return 'http://localhost:60148/api';
      case Ambiente.qa:
        return 'https://guillermosofnux-001-site1.stempurl.com/api';
      case Ambiente.preproduccion:
        return 'https://guillermosofnux-001-site1.stempurl.com/api';
      case Ambiente.produccion:
        return 'https://guillermosofnux-001-site1.stempurl.com/api';
    }
  }

  static bool get esDevelopment => _ambienteActual == Ambiente.desarrollo;
  static bool get esQA => _ambienteActual == Ambiente.qa;
  static bool get esPreproduccion => _ambienteActual == Ambiente.preproduccion;
  static bool get esProduccion => _ambienteActual == Ambiente.produccion;

  static String get nombreAmbiente {
    switch (_ambienteActual) {
      case Ambiente.desarrollo:
        return 'Desarrollo';
      case Ambiente.qa:
        return 'QA';
      case Ambiente.preproduccion:
        return 'Pre-Producción';
      case Ambiente.produccion:
        return 'Producción';
    }
  }
}
