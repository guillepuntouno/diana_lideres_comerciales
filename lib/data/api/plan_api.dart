import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlanApi {
  static const _base = 'https://ln6rw4qcj7.execute-api.us-east-1.amazonaws.com/dev';

  Future<void> postPlan(Map<String, dynamic> planJson) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    
    if (token == null) {
      throw Exception('No se encontró token de autenticación');
    }
    
    // Agregar userId al JSON - el valor viene del CoSEupervisor/clave del líder
    // Este valor ya está en el plan como 'liderClave' pero necesitamos agregarlo también como 'userId'
    if (planJson.containsKey('liderClave')) {
      planJson['userId'] = planJson['liderClave'];
      print('✅ Agregado userId: ${planJson['userId']} (CoSEupervisor del líder)');
    } else {
      print('⚠️ No se encontró liderClave en el JSON del plan');
    }
    
    // DEBUG: Imprimir token JWT para pruebas
    print('🔐 TOKEN JWT PARA PRUEBAS:');
    print('=====================================');
    print(token);
    print('=====================================');
    print('📋 Puedes copiar el token de arriba para usar en tus pruebas');
    print('🔗 Endpoint: $_base/planes');
    print('📝 Method: POST');
    print('=====================================');
    
    // DEBUG: Imprimir JSON del plan
    print('📄 JSON DEL PLAN A ENVIAR:');
    print('=====================================');
    print(jsonEncode(planJson));
    print('=====================================');
    
    final res = await http.post(
      Uri.parse('$_base/planes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(planJson),
    );
    
    if (res.statusCode < 200 || res.statusCode > 299) {
      // Intentar parsear mensaje de error del servidor
      String errorMessage = 'Error ${res.statusCode}';
      try {
        final errorBody = jsonDecode(res.body);
        errorMessage = errorBody['message'] ?? errorBody['error'] ?? res.body;
      } catch (_) {
        errorMessage = res.body.isNotEmpty ? res.body : 'Error desconocido';
      }
      throw Exception(errorMessage);
    }
  }
}