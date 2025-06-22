import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando DIANA con funcionalidad offline...');
  print('📝 Para probar login, usa tu usuario del sistema o datos offline');
  
  runApp(const DianaApp());
}
