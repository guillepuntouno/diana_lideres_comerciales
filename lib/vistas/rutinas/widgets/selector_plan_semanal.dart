import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../modelos/hive/plan_trabajo_unificado_hive.dart';

/// Widget para seleccionar el plan semanal
class SelectorPlanSemanal extends StatelessWidget {
  final List<PlanTrabajoUnificadoHive> planesDisponibles;
  final PlanTrabajoUnificadoHive? planSeleccionado;
  final ValueChanged<PlanTrabajoUnificadoHive> onPlanChanged;

  const SelectorPlanSemanal({
    Key? key,
    required this.planesDisponibles,
    required this.planSeleccionado,
    required this.onPlanChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (planesDisponibles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: const Color(0xFFDE1327),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Plan Semanal',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PlanTrabajoUnificadoHive>(
                isExpanded: true,
                value: planSeleccionado,
                hint: Text(
                  'Selecciona un plan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                items: planesDisponibles.map((plan) {
                  final esPlanActual = plan == planSeleccionado;
                  final tieneActividades = plan.dias.values
                      .any((dia) => dia.configurado && dia.clientes.isNotEmpty);
                  
                  return DropdownMenuItem(
                    value: plan,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                plan.semana,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: esPlanActual ? FontWeight.w600 : FontWeight.normal,
                                  color: const Color(0xFF1C2120),
                                ),
                              ),
                              Text(
                                '${plan.fechaInicio} - ${plan.fechaFin}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF8F8E8E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Indicadores de estado
                        Row(
                          children: [
                            if (plan.estatus == 'enviado')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38A169).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Enviado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF38A169),
                                  ),
                                ),
                              ),
                            if (!plan.sincronizado) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.cloud_off,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                            ],
                            if (!tieneActividades) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: const Color(0xFFF6C343),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (plan) {
                  if (plan != null) {
                    onPlanChanged(plan);
                  }
                },
              ),
            ),
          ),
          // Mostrar información adicional del plan seleccionado
          if (planSeleccionado != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPlanInfo(
                    'Días configurados',
                    '${planSeleccionado!.dias.values.where((d) => d.configurado).length}',
                    Icons.calendar_today,
                  ),
                  _buildPlanInfo(
                    'Total clientes',
                    '${_contarTotalClientes(planSeleccionado!)}',
                    Icons.people,
                  ),
                  _buildPlanInfo(
                    'Actividades',
                    '${_contarTotalActividades(planSeleccionado!)}',
                    Icons.assignment,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8F8E8E)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2120),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF8F8E8E),
          ),
        ),
      ],
    );
  }

  int _contarTotalClientes(PlanTrabajoUnificadoHive plan) {
    final clientesUnicos = <String>{};
    for (var dia in plan.dias.values) {
      for (var cliente in dia.clientes) {
        clientesUnicos.add(cliente.clienteId);
      }
    }
    return clientesUnicos.length;
  }

  int _contarTotalActividades(PlanTrabajoUnificadoHive plan) {
    int total = 0;
    for (var dia in plan.dias.values) {
      total += dia.clientes.length;
      if (dia.tipo == 'administrativo' && dia.configurado) {
        total++; // Contar la actividad administrativa
      }
    }
    return total;
  }
}