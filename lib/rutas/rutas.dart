// lib/rutas/rutas.dart

import 'package:flutter/material.dart';
import '../vistas/login/pantalla_login.dart';
import '../vistas/menu_principal/pantalla_menu_principal.dart';
import '../vistas/menu_principal/vista_programar_dia.dart';
import '../vistas/menu_principal/vista_asignacion_clientes.dart';
import '../vistas/menu_principal/vista_configuracion_plan.dart';
import '../vistas/menu_principal/vista_indicadores_gestion.dart';
import '../vistas/planes_trabajo/vista_planes_trabajo.dart';
import '../vistas/planes_trabajo/rutina_diaria.dart';
import '../vistas/visita_cliente/pantalla_visita_cliente.dart';
import '../vistas/formulario_dinamico/pantalla_formulario_dinamico.dart';
import '../vistas/resumen/pantalla_resumen_visita.dart';
import '../vistas/notificaciones/pantalla_notificaciones.dart';
import '../vistas/debug/pantalla_debug_hive.dart';
import '../vistas/resultados/pantalla_resultados_dia.dart';
import '../vistas/rutinas/pantalla_rutinas_resultados.dart';

final Map<String, WidgetBuilder> rutas = {
  '/': (BuildContext context) => const PantallaLogin(),
  '/login': (BuildContext context) => const PantallaLogin(),
  '/home': (context) => const PantallaMenuPrincipal(),
  '/plan_configuracion': (context) => const VistaProgramacionSemana(),
  '/programar_dia': (context) => const VistaProgramarDia(),
  '/asignacion_clientes': (context) => const VistaAsignacionClientes(),
  '/indicadores_gestion': (context) => const VistaIndicadoresGestion(),
  '/planes_trabajo': (context) => const VistaPlanesTrabajo(),
  '/rutina_diaria': (context) => const PantallaRutinaDiaria(),
  '/visita_cliente': (context) => const PantallaVisitaCliente(),
  '/formulario_dinamico': (context) => const PantallaFormularioDinamico(),
  '/resumen_visita': (context) => const PantallaResumenVisita(),
  '/notificaciones': (context) => const PantallaNotificaciones(),
  '/resultados_dia': (context) => const PantallaResultadosDia(),
  '/rutinas_resultados': (context) => const PantallaRutinasResultados(),

  // Ruta de debug
  '/debug_hive': (context) => const PantallaDebugHive(),
  
  // Ruta catch-all para AuthGuard
  '*': (BuildContext context) => const PantallaLogin(),
};