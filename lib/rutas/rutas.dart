// lib/rutas/rutas.dart

import 'package:diana_lc_front/vistas/menu_principal/vista_configuracion_plan.dart';
import 'package:flutter/material.dart';
import '../vistas/login/pantalla_login.dart';
import '../vistas/menu_principal/pantalla_menu_principal.dart';
import '../vistas/menu_principal/vista_programar_dia.dart';
import '../vistas/menu_principal/vista_asignacion_clientes.dart';
import '../vistas/planes_trabajo/vista_planes_trabajo.dart';
import '../vistas/planes_trabajo/rutina_diaria.dart';
import '../vistas/visita_cliente/pantalla_visita_cliente.dart';

final Map<String, WidgetBuilder> rutas = {
  '/login': (BuildContext context) => const PantallaLogin(),
  '/home': (context) => const PantallaMenuPrincipal(),
  '/plan_configuracion': (context) => const VistaProgramacionSemana(),
  '/programar_dia': (context) => const VistaProgramarDia(),
  '/asignacion_clientes': (context) => const VistaAsignacionClientes(),
  '/vista_planes_trabajo':
      (context) => const VistaPlanesTrabajo(), // CORREGIDO: Agregué el /
  '/rutina_diaria': (context) => const PantallaRutinaDiaria(),
  '/visita_cliente': (context) => const PantallaVisitaCliente(),
};
