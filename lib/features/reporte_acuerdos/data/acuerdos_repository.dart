import 'package:hive/hive.dart';
import 'package:diana_lc_front/shared/servicios/hive_service.dart';
import 'package:diana_lc_front/shared/modelos/hive/plan_trabajo_unificado_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/cliente_hive.dart';
import 'package:diana_lc_front/shared/modelos/hive/visita_cliente_hive.dart';
import '../domain/compromiso.dart';

class AcuerdosRepository {
  Box<PlanTrabajoUnificadoHive>? _planBox;
  Box<ClienteHive>? _clienteBox;
  Box<VisitaClienteHive>? _visitasBox;

  AcuerdosRepository() {
    try {
      _planBox = Hive.box<PlanTrabajoUnificadoHive>(HiveService.planTrabajoUnificadoBox);
    } catch (e) {
      print('Error abriendo planBox: $e');
    }
    
    try {
      _clienteBox = Hive.box<ClienteHive>(HiveService.clienteBox);
    } catch (e) {
      print('Error abriendo clienteBox: $e');
    }
    
    try {
      _visitasBox = Hive.box<VisitaClienteHive>(HiveService.visitaClienteBox);
    } catch (e) {
      print('Error abriendo visitasBox: $e');
    }
  }

  List<Compromiso> obtenerTodosLosCompromisos() {
    final compromisos = <Compromiso>[];
    
    print('=== Buscando compromisos ===');
    print('PlanBox disponible: ${_planBox != null}');
    print('VisitasBox disponible: ${_visitasBox != null}');
    
    // Primero buscar en los planes de trabajo unificados
    if (_planBox != null) {
      print('Planes en planBox: ${_planBox!.length}');
      for (final plan in _planBox!.values) {
      // Iterar sobre todos los días del plan
      for (final dia in plan.dias.values) {
        // Verificar si el día tiene clientes/visitas
        if (dia.tipo != 'gestion_cliente' || dia.clientes.isEmpty) continue;
        
        // Iterar sobre todas las visitas del día
        for (final visita in dia.clientes) {
          if (visita.compromisos.isEmpty) continue;
          
          // Obtener información del cliente
          final cliente = _obtenerCliente(visita.clienteId);
          final clienteNombre = cliente?.nombre ?? 'Cliente ${visita.clienteId}';
          
          // Procesar cada compromiso de la visita
          for (final compromisoHive in visita.compromisos) {
            compromisos.add(
              Compromiso(
                id: '${plan.id}_${dia.dia}_${visita.clienteId}_${compromisoHive.fechaPlazo}_${compromisoHive.tipo}'.replaceAll(' ', '_'),
                tipo: compromisoHive.tipo,
                detalle: compromisoHive.detalle,
                cantidad: compromisoHive.cantidad,
                fecha: compromisoHive.fechaPlazo,
                clienteId: visita.clienteId,
                clienteNombre: clienteNombre,
                rutaId: dia.rutaId ?? '',
                status: visita.estatus == 'completada' ? 'CERRADO' : 'PENDIENTE',
                createdAt: visita.fechaModificacion?.toIso8601String() ?? DateTime.now().toIso8601String(),
                retroalimentacion: visita.retroalimentacion,
                reconocimiento: visita.reconocimiento,
                visitaId: '${plan.id}_${dia.dia}_${visita.clienteId}',
              ),
            );
          }
        }
      }
    }
    }
    
    // También buscar en las visitas guardadas en el modelo VisitaClienteHive
    if (_visitasBox != null) {
      print('Visitas en visitasBox: ${_visitasBox!.length}');
      for (final visita in _visitasBox!.values) {
      try {
        // Los compromisos pueden estar en el campo formularios
        final formularios = Map<String, dynamic>.from(visita.formularios);
        
        // Buscar compromisos en diferentes posibles ubicaciones dentro de formularios
        List<dynamic> todosCompromisos = [];
        
        // Opción 1: directamente en formularios['compromisos']
        if (formularios['compromisos'] is List) {
          todosCompromisos.addAll(formularios['compromisos'] as List);
          print('Encontrados ${(formularios['compromisos'] as List).length} compromisos en formularios["compromisos"]');
        }
        
        // Opción 2: en formularioDinamico
        final formularioDinamicoData = formularios['formularioDinamico'];
        final formularioDinamico = formularioDinamicoData != null 
            ? Map<String, dynamic>.from(formularioDinamicoData) 
            : null;
      if (formularioDinamico != null) {
        final compromisosData = formularioDinamico['compromisos'] as Map<String, dynamic>?;
        if (compromisosData != null && compromisosData['compromisos'] is List) {
          todosCompromisos.addAll(compromisosData['compromisos'] as List);
        }
      }
      
      // Obtener información del cliente
      final clienteNombre = visita.clienteNombre;
      
      // Obtener retroalimentación y reconocimiento
      String? retroalimentacion;
      String? reconocimiento;
      
      if (formularios['retroalimentacion'] != null) {
        retroalimentacion = formularios['retroalimentacion'].toString();
      }
      if (formularios['reconocimiento'] != null) {
        reconocimiento = formularios['reconocimiento'].toString();
      }
      
      // También buscar en comentarios del formulario dinámico
      if (formularioDinamico != null) {
        final comentariosData = formularioDinamico['comentarios'];
        final comentarios = comentariosData != null 
            ? Map<String, dynamic>.from(comentariosData)
            : null;
        if (comentarios != null) {
          retroalimentacion ??= comentarios['retroalimentacion']?.toString();
          reconocimiento ??= comentarios['reconocimiento']?.toString();
        }
      }
      
      // Procesar cada compromiso encontrado
      for (final compromisoData in todosCompromisos) {
        if (compromisoData is Map<String, dynamic>) {
          compromisos.add(
            Compromiso(
              id: compromisoData['id']?.toString() ?? 
                  '${visita.visitaId}_${compromisoData['tipo']}_${compromisoData['fecha']}'.replaceAll(' ', '_'),
              tipo: compromisoData['tipo']?.toString() ?? '',
              detalle: compromisoData['detalle']?.toString() ?? '',
              cantidad: int.tryParse(compromisoData['cantidad']?.toString() ?? ''),
              fecha: compromisoData['fechaFormateada']?.toString() ?? 
                     compromisoData['fecha']?.toString() ?? '',
              clienteId: visita.clienteId,
              clienteNombre: clienteNombre,
              rutaId: compromisoData['rutaId']?.toString() ?? '',
              status: compromisoData['status']?.toString() ?? 'PENDIENTE',
              createdAt: compromisoData['createdAt']?.toString() ?? 
                        visita.fechaModificacion?.toIso8601String() ?? 
                        visita.fechaCreacion.toIso8601String(),
              retroalimentacion: retroalimentacion,
              reconocimiento: reconocimiento,
              visitaId: visita.visitaId,
            ),
          );
        }
      }
      } catch (e) {
        print('Error procesando visita ${visita.visitaId}: $e');
        continue;
      }
    }
    }
    
    // Ordenar por fecha más reciente primero
    compromisos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('Total de compromisos encontrados: ${compromisos.length}');
    print('========================');
    
    return compromisos;
  }

  ClienteHive? _obtenerCliente(String clienteId) {
    if (_clienteBox == null) return null;
    
    try {
      return _clienteBox!.values.firstWhere(
        (cliente) => cliente.id == clienteId,
      );
    } catch (e) {
      return null;
    }
  }

  List<String> obtenerTiposCompromiso() {
    final tipos = <String>{};
    
    if (_planBox != null) {
      for (final plan in _planBox!.values) {
        for (final dia in plan.dias.values) {
          if (dia.tipo != 'gestion_cliente' || dia.clientes.isEmpty) continue;
          
          for (final visita in dia.clientes) {
            for (final compromiso in visita.compromisos) {
              tipos.add(compromiso.tipo);
            }
          }
        }
      }
    }
    
    return tipos.toList()..sort();
  }

  Map<String, int> obtenerEstadisticasCompromisos() {
    int pendientes = 0;
    int completados = 0;
    int total = 0;
    
    final compromisos = obtenerTodosLosCompromisos();
    
    for (final compromiso in compromisos) {
      total++;
      if (compromiso.isPending) {
        pendientes++;
      } else if (compromiso.isCompleted) {
        completados++;
      }
    }
    
    return {
      'total': total,
      'pendientes': pendientes,
      'completados': completados,
      'porcentaje_cumplimiento': total > 0 ? ((completados / total) * 100).round() : 0,
    };
  }
}