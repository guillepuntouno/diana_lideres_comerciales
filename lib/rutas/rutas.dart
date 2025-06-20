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
import '../vistas/formulario_dinamico/pantalla_formulario_dinamico.dart';
import '../vistas/resumen/pantalla_resumen_visita.dart';
import '../vistas/notificaciones/pantalla_notificaciones.dart';

final Map<String, WidgetBuilder> rutas = {
  '/login': (BuildContext context) => const PantallaLogin(),
  '/home': (context) => const PantallaMenuPrincipal(),
  '/plan_configuracion': (context) => const VistaProgramacionSemana(),
  '/programar_dia': (context) => const VistaProgramarDia(),
  '/asignacion_clientes': (context) => const VistaAsignacionClientes(),

  // CORREGIDO: Cambié de /vista_planes_trabajo a /planes_trabajo para que coincida con el menú
  '/planes_trabajo': (context) => const VistaPlanesTrabajo(),

  '/rutina_diaria': (context) => const PantallaRutinaDiaria(),
  '/visita_cliente': (context) => const PantallaVisitaCliente(),
  '/formulario_dinamico': (context) => const PantallaFormularioDinamico(),

  // Rutas de resumen
  '/resumen_visita': (context) => const PantallaResumenVisita(),
  // Rutas de resumen y notificaciones
  '/notificaciones': (context) => const PantallaNotificaciones(),
};
