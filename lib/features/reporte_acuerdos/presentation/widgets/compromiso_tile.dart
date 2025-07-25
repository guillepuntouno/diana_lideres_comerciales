import 'package:flutter/material.dart';
import '../../domain/compromiso.dart';

class CompromisoTile extends StatelessWidget {
  final Compromiso compromiso;

  const CompromisoTile({
    super.key,
    required this.compromiso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetalleDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con ID y Estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ID: ${compromiso.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Tipo de compromiso
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2120).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1C2120).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    compromiso.tipo,
                    style: const TextStyle(
                      color: Color(0xFF1C2120),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Detalle
                Text(
                  compromiso.detalle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1C2120),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Información adicional
                _buildInfoRow(Icons.business, compromiso.clienteNombre),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.route, 'Ruta: ${compromiso.rutaId}'),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.calendar_today, 'Fecha: ${compromiso.fecha}'),
                
                if (compromiso.cantidad != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.shopping_cart, 'Cantidad: ${compromiso.cantidad}'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final color = _getStatusColor();
    final textColor = compromiso.isPending ? color : Colors.white;
    final bgColor = compromiso.isPending ? color.withOpacity(0.1) : color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        compromiso.status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (compromiso.isPending) return const Color(0xFFEAB308);
    if (compromiso.isCompleted) return const Color(0xFF0FA958);
    if (compromiso.isCancelled) return Colors.red;
    return Colors.grey;
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showDetalleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Detalle del Compromiso',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C2120),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('ID', compromiso.id),
              _buildDetailItem('Tipo', compromiso.tipo),
              _buildDetailItem('Detalle', compromiso.detalle),
              _buildDetailItem('Cliente', compromiso.clienteNombre),
              _buildDetailItem('ID Cliente', compromiso.clienteId),
              _buildDetailItem('Ruta', compromiso.rutaId),
              _buildDetailItem('Estado', compromiso.status),
              _buildDetailItem('Fecha', compromiso.fecha),
              if (compromiso.cantidad != null)
                _buildDetailItem('Cantidad', compromiso.cantidad.toString()),
              _buildDetailItem('Creado', compromiso.createdAt),
              if (compromiso.retroalimentacion != null && compromiso.retroalimentacion!.isNotEmpty)
                _buildDetailItem('Retroalimentación', compromiso.retroalimentacion!),
              if (compromiso.reconocimiento != null && compromiso.reconocimiento!.isNotEmpty)
                _buildDetailItem('Reconocimiento', compromiso.reconocimiento!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFDE1327)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1C2120),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}