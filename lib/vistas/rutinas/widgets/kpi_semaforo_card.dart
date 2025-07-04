import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget para mostrar un KPI con semáforo de colores
class KPISemaforoCard extends StatelessWidget {
  final String titulo;
  final int valor;
  final bool esPorcentaje;
  final String? sufijo;
  final Color color;
  final IconData icono;

  const KPISemaforoCard({
    Key? key,
    required this.titulo,
    required this.valor,
    this.esPorcentaje = false,
    this.sufijo,
    required this.color,
    required this.icono,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${valor}${esPorcentaje ? '%' : ''}${sufijo ?? ''}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}