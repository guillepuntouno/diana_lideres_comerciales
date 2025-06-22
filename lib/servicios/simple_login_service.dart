import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configuracion/ambiente_config.dart';
import '../modelos/lider_comercial_modelo.dart';

class SimpleLoginService {
  String get _baseUrl => AmbienteConfig.baseUrl;

  Future<LiderComercial?> login(String clave) async {
    try {
      final url = Uri.parse('$_baseUrl/lideres/$clave');
      
      print('= Intentando login en: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar al servidor');
            },
          );

      print('=á Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && data.containsKey('mensaje')) {
          // El backend regresó que no hay data
          return null;
        }

        return LiderComercial.fromJson(data);
      } else if (response.statusCode == 404) {
        print('L Usuario no encontrado');
        return null;
      } else {
        print('L Error del servidor: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('L Error en login: $e');
      return null;
    }
  }
}