import 'package:hive_flutter/hive_flutter.dart';
import 'modelos/hive/plan_trabajo_unificado_hive.dart';
import 'dart:convert';

void debugPlanUnificado() async {
  // Abrir la caja de planes unificados
  final box = await Hive.openBox<PlanTrabajoUnificadoHive>('planes_trabajo_unificado');
  
  print('📦 Total de planes en la caja: ${box.length}');
  
  // Iterar sobre cada plan
  for (var i = 0; i < box.length; i++) {
    final plan = box.getAt(i);
    if (plan != null) {
      print('\n🗓️ Plan ${i + 1}:');
      print('  ID: ${plan.id}');
      print('  Semana: ${plan.semana}');
      print('  Días configurados: ${plan.dias.length}');
      
      // Revisar cada día
      plan.dias.forEach((dia, diaPlan) {
        print('\n  📅 $dia:');
        print('    Tipo: ${diaPlan.tipo}');
        print('    Clientes asignados: ${diaPlan.clienteIds.length}');
        print('    Visitas registradas: ${diaPlan.clientes.length}');
        
        // Revisar cada visita
        for (var j = 0; j < diaPlan.clientes.length; j++) {
          final visita = diaPlan.clientes[j];
          print('\n    👤 Cliente ${j + 1} (${visita.clienteId}):');
          print('      Hora inicio: ${visita.horaInicio ?? "NO DEFINIDA"}');
          print('      Hora fin: ${visita.horaFin ?? "NO DEFINIDA"}');
          print('      Estatus: ${visita.estatus}');
          print('      Comentario inicio: ${visita.comentarioInicio ?? "NO DEFINIDO"}');
          
          // Verificar cuestionario
          if (visita.cuestionario != null) {
            print('      ✅ Cuestionario: SÍ');
            
            if (visita.cuestionario!.tipoExhibidor != null) {
              final te = visita.cuestionario!.tipoExhibidor!;
              print('        Tipo exhibidor:');
              print('          - Posee adecuado: ${te.poseeAdecuado}');
              print('          - Tipo: ${te.tipo ?? "NO DEFINIDO"}');
              print('          - Modelo: ${te.modelo ?? "NO DEFINIDO"}');
              print('          - Cantidad: ${te.cantidad ?? "NO DEFINIDA"}');
            } else {
              print('        ❌ Tipo exhibidor: NO DEFINIDO');
            }
            
            if (visita.cuestionario!.estandaresEjecucion != null) {
              final ee = visita.cuestionario!.estandaresEjecucion!;
              print('        Estándares ejecución:');
              print('          - Primera posición: ${ee.primeraPosicion}');
              print('          - Planograma: ${ee.planograma}');
              print('          - Portafolio foco: ${ee.portafolioFoco}');
              print('          - Anclaje: ${ee.anclaje}');
            } else {
              print('        ❌ Estándares ejecución: NO DEFINIDO');
            }
            
            if (visita.cuestionario!.disponibilidad != null) {
              final d = visita.cuestionario!.disponibilidad!;
              print('        Disponibilidad:');
              print('          - Ristras: ${d.ristras}');
              print('          - Max: ${d.max}');
              print('          - Familiar: ${d.familiar}');
              print('          - Dulce: ${d.dulce}');
              print('          - Galleta: ${d.galleta}');
            } else {
              print('        ❌ Disponibilidad: NO DEFINIDA');
            }
          } else {
            print('      ❌ Cuestionario: NO');
          }
          
          print('      Compromisos: ${visita.compromisos.length}');
          for (var k = 0; k < visita.compromisos.length; k++) {
            final c = visita.compromisos[k];
            print('        Compromiso ${k + 1}:');
            print('          - Tipo: ${c.tipo}');
            print('          - Detalle: ${c.detalle}');
            print('          - Cantidad: ${c.cantidad}');
            print('          - Fecha plazo: ${c.fechaPlazo}');
          }
          
          print('      Retroalimentación: ${visita.retroalimentacion ?? "NO DEFINIDA"}');
          print('      Reconocimiento: ${visita.reconocimiento ?? "NO DEFINIDO"}');
        }
      });
      
      // Mostrar JSON completo
      print('\n📄 JSON Completo:');
      try {
        final json = plan.toJsonCompleto();
        print(const JsonEncoder.withIndent('  ').convert(json));
      } catch (e) {
        print('❌ Error al convertir a JSON: $e');
      }
    }
  }
  
  print('\n✅ Debug completado');
}

// Función main para ejecutar el debug
void main() async {
  await Hive.initFlutter();
  
  // Registrar adaptadores necesarios
  // Nota: Asegúrate de que los adaptadores estén registrados antes de ejecutar esto
  
  await debugPlanUnificado();
}