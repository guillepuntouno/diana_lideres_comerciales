import 'package:flutter/material.dart';

class EstadisticasCard extends StatelessWidget {
  final Map<String, int> estadisticas;

  const EstadisticasCard({
    super.key,
    required this.estadisticas,
  });

  @override
  Widget build(BuildContext context) {
    final total = estadisticas['total'] ?? 0;
    final pendientes = estadisticas['pendientes'] ?? 0;
    final completados = estadisticas['completados'] ?? 0;
    final porcentaje = estadisticas['porcentaje_cumplimiento'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen de Compromisos',
                style: TextStyle(
                  color: Color(0xFF1C2120),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDE1327).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFFDE1327),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', total.toString(), Icons.assignment),
              _buildStatItem('Pendientes', pendientes.toString(), Icons.pending_actions),
              _buildStatItem('Completados', completados.toString(), Icons.check_circle),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cumplimiento',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$porcentaje%',
                    style: const TextStyle(
                      color: Color(0xFF1C2120),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth * (porcentaje / 100),
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0FA958),
                              const Color(0xFF0FA958).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final Color iconColor = label == 'Pendientes' 
        ? const Color(0xFFEAB308) 
        : label == 'Completados' 
            ? const Color(0xFF0FA958)
            : const Color(0xFFDE1327);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}