import 'package:diana_lc_front/vistas/menu_principal/vista_configuracion_plan.dart';
import 'package:flutter/material.dart';
import '../vistas/login/pantalla_login.dart';
import '../vistas/menu_principal/pantalla_menu_principal.dart';
import '../vistas/menu_principal/vista_programar_dia.dart';
import '../vistas/menu_principal/vista_asignacion_clientes.dart';

final Map<String, WidgetBuilder> rutas = {
  '/login': (BuildContext context) => PantallaLogin(),
  '/home': (context) => const PantallaMenuPrincipal(),

  // Agrega aquí más rutas según sea necesario
  '/plan_configuracion':
      (context) =>
          const VistaProgramacionSemana(), // Reemplaza con la vista correspondiente

  '/programar_dia':
      (context) =>
          const VistaProgramarDia(), // Reemplaza con la vista correspondiente

  '/asignacion_clientes': (context) => const VistaAsignacionClientes(),
};
