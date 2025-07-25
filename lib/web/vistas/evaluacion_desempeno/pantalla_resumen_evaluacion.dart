// lib/web/vistas/evaluacion_desempeno/pantalla_resumen_evaluacion.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';

class PantallaResumenEvaluacion extends StatelessWidget {
  final ResultadoExcelenciaHive evaluacion;

  const PantallaResumenEvaluacion({
    Key? key,
    required this.evaluacion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formulario = evaluacion.formularioMaestro;
    final tieneKPI = formulario.containsKey('resultadoKPI');
    final puntuacionMaxima = tieneKPI 
        ? (formulario['resultadoKPI']['puntuacionMaxima'] ?? 10).toDouble()
        : 10.0;
    final porcentaje = puntuacionMaxima > 0 
        ? (evaluacion.ponderacionFinal / puntuacionMaxima) * 100 
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Resumen de Evaluación',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C2120),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Color(0xFF1C2120)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de impresión en desarrollo')),
              );
            },
            tooltip: 'Imprimir',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF1C2120)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de compartir en desarrollo')),
              );
            },
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del líder y evaluación
              _buildInfoHeader(),
              
              const SizedBox(height: 24),
              
              // Resultado KPI si aplica
              if (tieneKPI) ...[
                _buildResultadoKPI(puntuacionMaxima, porcentaje),
                const SizedBox(height: 32),
              ],
              
              // Detalle de respuestas
              _buildDetalleRespuestas(),
              
              const SizedBox(height: 24),
              
              // Metadatos
              _buildMetadatos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de la Evaluación',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Líder:', evaluacion.liderNombre),
          const SizedBox(height: 8),
          _buildInfoRow('Correo:', evaluacion.liderCorreo),
          const SizedBox(height: 8),
          _buildInfoRow('País:', evaluacion.pais),
          const SizedBox(height: 8),
          _buildInfoRow('Centro:', evaluacion.centroDistribucion),
          const SizedBox(height: 8),
          _buildInfoRow('Ruta:', evaluacion.ruta),
          const SizedBox(height: 8),
          _buildInfoRow('Formulario:', evaluacion.tipoFormulario),
          const SizedBox(height: 8),
          _buildInfoRow('Fecha:', _formatearFecha(evaluacion.fechaCaptura)),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Duración:', 
            _calcularDuracion(evaluacion.fechaHoraInicio, evaluacion.fechaHoraFin),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: evaluacion.estatus == 'completada' 
                      ? const Color(0xFF38A169).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      evaluacion.estatus == 'completada' 
                          ? Icons.check_circle 
                          : Icons.pending,
                      size: 16,
                      color: evaluacion.estatus == 'completada' 
                          ? const Color(0xFF38A169)
                          : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      evaluacion.estatus == 'completada' ? 'Completada' : 'Pendiente',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: evaluacion.estatus == 'completada' 
                            ? const Color(0xFF38A169)
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: evaluacion.syncStatus == 'synced' 
                      ? const Color(0xFF38A169).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      evaluacion.syncStatus == 'synced' 
                          ? Icons.cloud_done 
                          : Icons.cloud_upload,
                      size: 16,
                      color: evaluacion.syncStatus == 'synced' 
                          ? const Color(0xFF38A169)
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      evaluacion.syncStatus == 'synced' ? 'Sincronizada' : 'Local',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: evaluacion.syncStatus == 'synced' 
                            ? const Color(0xFF38A169)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoKPI(double puntuacionMaxima, double porcentaje) {
    final color = _obtenerColorResultado(evaluacion.ponderacionFinal);
    final textoResultado = _obtenerTextoResultado(evaluacion.ponderacionFinal);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assessment,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            'Resultado de la Evaluación',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 24),
          // Círculo de progreso
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: porcentaje / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    evaluacion.ponderacionFinal.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'de ${puntuacionMaxima.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              textoResultado,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${porcentaje.toStringAsFixed(1)}% de efectividad',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRespuestas() {
    // Agrupar respuestas por categoría
    final Map<String, List<RespuestaEvaluacionHive>> respuestasPorCategoria = {};
    
    for (var respuesta in evaluacion.respuestas) {
      final categoria = respuesta.categoria ?? 'General';
      if (!respuestasPorCategoria.containsKey(categoria)) {
        respuestasPorCategoria[categoria] = [];
      }
      respuestasPorCategoria[categoria]!.add(respuesta);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle de Respuestas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2120),
          ),
        ),
        const SizedBox(height: 16),
        ...respuestasPorCategoria.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE1327).withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 20,
                        color: const Color(0xFFDE1327),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDE1327),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: entry.value.map((respuesta) {
                      return _buildRespuestaItem(respuesta);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRespuestaItem(RespuestaEvaluacionHive respuesta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            respuesta.preguntaTitulo,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Respuesta: ${respuesta.respuestaComoTexto}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (respuesta.ponderacion != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE1327).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${respuesta.ponderacion!.toStringAsFixed(1)} pts',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDE1327),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadatos() {
    final metadatos = evaluacion.metadatos ?? {};
    
    if (metadatos.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Información Adicional',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...metadatos.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildInfoRow(
                '${_formatearNombreCampo(entry.key)}:',
                entry.value.toString(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Color _obtenerColorResultado(double puntuacion) {
    final formulario = evaluacion.formularioMaestro;
    if (!formulario.containsKey('resultadoKPI')) return Colors.grey;
    
    final colorimetria = formulario['resultadoKPI']['colorimetria'] ?? {};
    
    for (var entry in colorimetria.entries) {
      final rango = entry.value.toString();
      final partes = rango.split('-');
      if (partes.length == 2) {
        final min = double.tryParse(partes[0]) ?? 0;
        final max = double.tryParse(partes[1]) ?? 0;
        
        if (puntuacion >= min && puntuacion <= max) {
          switch (entry.key) {
            case 'verde':
              return const Color(0xFF38A169);
            case 'amarillo':
              return const Color(0xFFF6C343);
            case 'rojo':
              return const Color(0xFFE53E3E);
            default:
              return Colors.grey;
          }
        }
      }
    }
    
    return Colors.grey;
  }

  String _obtenerTextoResultado(double puntuacion) {
    final formulario = evaluacion.formularioMaestro;
    if (!formulario.containsKey('resultadoKPI')) return '';
    
    final colorimetria = formulario['resultadoKPI']['colorimetria'] ?? {};
    
    for (var entry in colorimetria.entries) {
      final rango = entry.value.toString();
      final partes = rango.split('-');
      if (partes.length == 2) {
        final min = double.tryParse(partes[0]) ?? 0;
        final max = double.tryParse(partes[1]) ?? 0;
        
        if (puntuacion >= min && puntuacion <= max) {
          switch (entry.key) {
            case 'verde':
              return 'Excelente';
            case 'amarillo':
              return 'Bueno';
            case 'rojo':
              return 'Necesita mejorar';
            default:
              return '';
          }
        }
      }
    }
    
    return '';
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year} a las ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _calcularDuracion(DateTime inicio, DateTime? fin) {
    if (fin == null) return 'No finalizada';
    
    final duracion = fin.difference(inicio);
    if (duracion.inMinutes < 60) {
      return '${duracion.inMinutes} minutos';
    } else {
      final horas = duracion.inHours;
      final minutos = duracion.inMinutes % 60;
      return '$horas hora${horas != 1 ? 's' : ''} $minutos minutos';
    }
  }

  String _formatearNombreCampo(String campo) {
    // Convertir camelCase a texto legible
    return campo
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ')
        .trim();
  }
}