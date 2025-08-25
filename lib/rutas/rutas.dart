// lib/rutas/rutas.dart

import 'package:flutter/material.dart';
import 'package:diana_lc_front/vistas/login/pantalla_login.dart';
import 'package:diana_lc_front/vistas/menu_principal/pantalla_menu_principal.dart';
import 'package:diana_lc_front/vistas/menu_principal/vista_programar_dia.dart';
import 'package:diana_lc_front/vistas/menu_principal/vista_asignacion_clientes.dart';
import 'package:diana_lc_front/vistas/menu_principal/vista_configuracion_plan.dart';
import 'package:diana_lc_front/vistas/menu_principal/vista_indicadores_gestion.dart';
import 'package:diana_lc_front/vistas/planes_trabajo/vista_planes_trabajo.dart';
import 'package:diana_lc_front/vistas/planes_trabajo/rutina_diaria.dart';
import 'package:diana_lc_front/mobile/vistas/visita_cliente/pantalla_visita_cliente.dart';
import 'package:diana_lc_front/mobile/vistas/formulario_dinamico/pantalla_formulario_dinamico.dart';
import 'package:diana_lc_front/mobile/vistas/resumen/pantalla_resumen_visita.dart';
import 'package:diana_lc_front/vistas/notificaciones/pantalla_notificaciones.dart';
import 'package:diana_lc_front/vistas/debug/pantalla_debug_hive.dart';
import 'package:diana_lc_front/vistas/resultados/pantalla_resultados_dia.dart';
import 'package:diana_lc_front/mobile/vistas/rutinas/pantalla_rutinas_resultados.dart';
import 'package:diana_lc_front/web/vistas/administracion/pantalla_administracion.dart';
import 'package:diana_lc_front/vistas/programa_excelencia/pantalla_evaluaciones_lider_v2.dart';
import 'package:diana_lc_front/features/reporte_acuerdos/presentation/reporte_acuerdos_screen.dart';
import 'package:diana_lc_front/web/vistas/evaluacion_desempeno/pantalla_evaluacion_desempeno.dart';
import 'package:diana_lc_front/mobile/vistas/evaluacion_desempeño/evaluacion_desempeño_principal.dart';
import 'package:diana_lc_front/mobile/vistas/evaluacion_desempeño/evaluacion_desempeño_llenado.dart';
import 'package:diana_lc_front/mobile/vistas/evaluacion_desempeño/evaluacion_capturas_screen.dart';
import 'package:diana_lc_front/vistas/platform_selection/pantalla_seleccion_plataforma.dart';

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
  '/programa_excelencia': (context) => const PantallaEvaluacionesLiderV2(),
  '/reporte_acuerdos': (context) => const ReporteAcuerdosScreen(),
  '/evaluacion_desempeno': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    return PantallaEvaluacionDesempeno(
      liderData: args?['liderData'] ?? {},
      rutaData: args?['rutaData'] ?? {},
      pais: args?['pais'] ?? '',
      centroDistribucion: args?['centroDistribucion'] ?? '',
    );
  },
  '/evaluacion_desempenio_principal': (context) => const EvaluacionDesempenioPrincipal(),
  '/evaluacion_desempenio_llenado': (context) => const EvaluacionDesempenioLlenado(),
  '/evaluacion_capturas': (context) => const EvaluacionCapturasScreen(),
  
  // Rutas administrativas web
  '/administracion': (context) => const PantallaAdministracion(),

  // Ruta de debug
  '/debug_hive': (context) => const PantallaDebugHive(),
  
  // Ruta de selección de plataforma
  '/platform_selection': (context) => const PantallaSeleccionPlataforma(),
  
  // Ruta catch-all para AuthGuard
  '*': (BuildContext context) => const PantallaLogin(),
};