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
  '/': (BuildContext context) => const PantallaLogin(),
  '/login': (BuildContext context) => const PantallaLogin(),
  '/home': (context) => const PantallaMenuPrincipal(),
  '/plan_configuracion': (context) => const VistaProgramacionSemana(),
  '/programar_dia': (context) => const VistaProgramarDia(),
  '/asignacion_clientes': (context) => const VistaAsignacionClientes(),
  '/planes_trabajo': (context) => const VistaPlanesTrabajo(),
  '/rutina_diaria': (context) => const PantallaRutinaDiaria(),
  '/visita_cliente': (context) => const PantallaVisitaCliente(),
  '/formulario_dinamico': (context) => const PantallaFormularioDinamico(),
  '/resumen_visita': (context) => const PantallaResumenVisita(),
  '/notificaciones': (context) => const PantallaNotificaciones(),
  '*': (BuildContext context) => const PantallaLogin(),
};
