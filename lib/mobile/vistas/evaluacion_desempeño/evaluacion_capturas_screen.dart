import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/shared/repositorios/programa_excelencia_local_repository.dart';
import 'dart:io';

class EvaluacionCapturasScreen extends StatefulWidget {
  const EvaluacionCapturasScreen({Key? key}) : super(key: key);

  @override
  State<EvaluacionCapturasScreen> createState() => _EvaluacionCapturasScreenState();
}

class _EvaluacionCapturasScreenState extends State<EvaluacionCapturasScreen> {
  final ProgramaExcelenciaLocalRepository _repository = ProgramaExcelenciaLocalRepository();
  
  String? _evaluacionId;
  ResultadoExcelenciaHive? _evaluacion;
  List<Map<String, dynamic>> _mediaItems = [];
  bool _isLoading = true;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }
  
  void _loadData() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _evaluacionId = args['evaluacionId'];
        _evaluacion = args['evaluacion'];
        _isLoading = true;
      });
      
      if (_evaluacionId != null) {
        _loadMediaItems();
      }
    }
  }
  
  void _loadMediaItems() {
    try {
      final items = _repository.obtenerMedia(_evaluacionId!);
      setState(() {
        _mediaItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando media: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFDE1327),
        title: Text(
          'Capturas de Evaluación',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildEvaluationInfo(),
                Expanded(
                  child: _buildMediaGrid(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildEvaluationInfo() {
    if (_evaluacion == null) return const SizedBox.shrink();
    
    final metadatos = _evaluacion!.metadatos ?? {};
    final asesorNombre = metadatos['asesorNombre'] ?? 'Sin asesor';
    final canal = metadatos['canal'] ?? 'Sin canal';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
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
                Icons.info_outline,
                color: const Color(0xFFDE1327),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información de la Evaluación',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('ID:', _evaluacion!.id),
          _buildInfoRow('Asesor:', asesorNombre),
          _buildInfoRow('Canal:', canal),
          _buildInfoRow('Líder:', _evaluacion!.liderNombre),
          _buildInfoRow('Puntuación:', '${_evaluacion!.ponderacionFinal.toStringAsFixed(1)}%'),
          _buildInfoRow('Total de capturas:', '${_mediaItems.length}'),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaGrid() {
    if (_mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay capturas disponibles',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las capturas de esta evaluación aparecerán aquí',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        return _buildMediaCard(_mediaItems[index], index);
      },
    );
  }
  
  Widget _buildMediaCard(Map<String, dynamic> mediaItem, int index) {
    final String? path = mediaItem['path'];
    final String? type = mediaItem['type'] ?? 'image';
    final String? caption = mediaItem['caption'];
    final String? timestamp = mediaItem['timestamp'];
    
    return GestureDetector(
      onTap: () => _showMediaDetail(mediaItem, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildMediaPreview(path, type),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Captura ${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2120),
                    ),
                  ),
                  if (caption != null && caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMediaPreview(String? path, String? type) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
        ),
      );
    }
    
    if (type == 'video') {
      return Container(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Intentar cargar la imagen
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          );
        },
      );
    }
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Archivo no encontrado',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMediaDetail(Map<String, dynamic> mediaItem, int index) {
    final String? path = mediaItem['path'];
    final String? caption = mediaItem['caption'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Captura ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Image
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: _buildMediaPreview(path, mediaItem['type']),
                    ),
                  ),
                ),
              ),
              // Caption
              if (caption != null && caption.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descripción:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF1C2120),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Hace un momento';
      }
    } catch (e) {
      return timestamp;
    }
  }
}