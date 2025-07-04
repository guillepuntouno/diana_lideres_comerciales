import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pantalla_rutinas_resultados.dart';

/// Widget para las tabs de rutinas
class TabRutinas extends StatelessWidget {
  final TipoRutina rutinaSeleccionada;
  final ValueChanged<TipoRutina> onRutinaChanged;

  const TabRutinas({
    Key? key,
    required this.rutinaSeleccionada,
    required this.onRutinaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TipoRutina.values.map((rutina) {
            final isSelected = rutina == rutinaSeleccionada;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onRutinaChanged(rutina),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDE1327) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFDE1327) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForRutina(rutina),
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF8F8E8E),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rutina.titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.white : const Color(0xFF1C2120),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getIconForRutina(TipoRutina rutina) {
    switch (rutina) {
      case TipoRutina.todas:
        return Icons.dashboard;
      case TipoRutina.visitasClientes:
        return Icons.people;
      case TipoRutina.administrativas:
        return Icons.business_center;
      case TipoRutina.formularios:
        return Icons.assignment_turned_in;
    }
  }
}