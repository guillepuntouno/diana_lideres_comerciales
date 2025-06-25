import 'package:flutter/foundation.dart'; // para kDebugMode

enum Ambiente { desarrollo, qa, preproduccion, produccion }

class AmbienteConfig {
  static const Ambiente _ambienteActual =
      Ambiente.desarrollo; // Cambiar aquí para alternar ambientes

  static Ambiente get ambienteActual => _ambienteActual;

  static String get baseUrl {
    // Si estamos en modo debug *y* el ambiente seleccionado es desarrollo, usar URL local:
    if (kDebugMode && ambienteActual == Ambiente.desarrollo) {
      return 'http://localhost:8080/proxy/dev'; // URL local para desarrollo en debug
    }

    // Caso contrario, devolver según configuración del ambiente:
    switch (_ambienteActual) {
      case Ambiente.desarrollo:
        return 'http://localhost:8080/proxy/dev';
      //return 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev';
      case Ambiente.qa:
        return 'http://localhost:8080/proxy/dev';
      // return 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev';
      case Ambiente.preproduccion:
        return 'http://localhost:8080/proxy/dev';
      //return 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev';
      case Ambiente.produccion:
        return 'http://localhost:8080/proxy/dev';
      //return 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev';
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
