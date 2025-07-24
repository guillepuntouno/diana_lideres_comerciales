import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget para filtros de Ruta y Cliente
class FiltrosRutina extends StatelessWidget {
  final String? rutaSeleccionada;
  final String? clienteSeleccionado;
  final List<String> rutasDisponibles;
  final List<String> clientesDisponibles;
  final ValueChanged<String?> onRutaChanged;
  final ValueChanged<String?> onClienteChanged;

  const FiltrosRutina({
    Key? key,
    this.rutaSeleccionada,
    this.clienteSeleccionado,
    required this.rutasDisponibles,
    required this.clientesDisponibles,
    required this.onRutaChanged,
    required this.onClienteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtro de Ruta
            _buildFilterChip(
              label: 'Ruta',
              value: rutaSeleccionada,
              items: rutasDisponibles,
              onChanged: onRutaChanged,
              icon: Icons.route,
            ),
            
            const SizedBox(width: 8),
            
            // Filtro de Cliente
            _buildFilterChip(
              label: 'Cliente',
              value: clienteSeleccionado,
              items: clientesDisponibles,
              onChanged: onClienteChanged,
              icon: Icons.person,
            ),
            
            // Botón para limpiar filtros
            if (rutaSeleccionada != null || clienteSeleccionado != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  onRutaChanged(null);
                  onClienteChanged(null);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Limpiar',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final isSelected = value != null;
    
    return PopupMenuButton<String?>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        if (isSelected)
          PopupMenuItem<String?>(
            value: null,
            child: Text(
              'Todos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const PopupMenuDivider(),
        ...items.map((item) => PopupMenuItem<String>(
          value: item,
          child: Row(
            children: [
              if (value == item)
                Icon(
                  Icons.check,
                  size: 16,
                  color: const Color(0xFFDE1327),
                ),
              SizedBox(width: value == item ? 8 : 24),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDE1327).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFDE1327).withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFFDE1327) : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              value ?? label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFFDE1327) : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isSelected ? const Color(0xFFDE1327) : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}