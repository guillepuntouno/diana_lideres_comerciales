import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:diana_lc_front/shared/servicios/sesion_servicio.dart';
import 'package:diana_lc_front/shared/servicios/asesores_service.dart';
import 'package:diana_lc_front/shared/modelos/lider_comercial_modelo.dart';
import 'package:diana_lc_front/shared/modelos/asesor_dto.dart';
import 'package:diana_lc_front/shared/modelos/hive/resultado_excelencia_hive.dart';
import 'package:diana_lc_front/shared/repositorios/programa_excelencia_local_repository.dart';

class EvaluacionDesempenioPrincipal extends StatefulWidget {
  const EvaluacionDesempenioPrincipal({Key? key}) : super(key: key);

  @override
  State<EvaluacionDesempenioPrincipal> createState() => _EvaluacionDesempenioPrincipalState();
}

class _EvaluacionDesempenioPrincipalState extends State<EvaluacionDesempenioPrincipal> {
  String? _selectedAdvisor;
  String? _selectedChannel;
  
  // Datos reales
  LiderComercial? _liderComercial;
  List<AsesorDTO> _advisors = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  final List<String> _channels = ['Detalle', 'Mayoreo'];
  
  // Repositorio para acceso a Hive
  final ProgramaExcelenciaLocalRepository _repository = ProgramaExcelenciaLocalRepository();
  
  // Lista de evaluaciones filtradas
  List<ResultadoExcelenciaHive> _evaluacionesFiltradas = [];
  
  @override
  void initState() {
    super.initState();
    _cargarDatosReales();
    _cargarEvaluaciones();
  }
  
  void _cargarEvaluaciones() {
    // Solo actualizar las evaluaciones sin setState ya que el ValueListenableBuilder
    // se encargará de la reconstrucción automática
    _evaluacionesFiltradas = _repository.obtenerEvaluacionesFiltradas(
      liderClave: _liderComercial?.clave,
      canal: _selectedChannel,
      asesorCodigo: _selectedAdvisor,
    );
  }
  
  Future<void> _cargarDatosReales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener líder comercial de la sesión (Cognito)
      _liderComercial = await SesionServicio.obtenerLiderComercial();
      
      if (_liderComercial == null) {
        throw Exception('No se pudo obtener la información del líder de la sesión');
      }
      
      print('👤 Líder obtenido de Cognito: ${_liderComercial!.nombre} - ${_liderComercial!.clave}');
      
      // Cargar asesores del líder
      _advisors = await AsesoresService.obtenerAsesoresPorLider(
        codigoLider: _liderComercial!.clave,
        pais: _liderComercial!.pais,
      );
      
      print('👥 Asesores cargados: ${_advisors.length}');
      
      // Cargar evaluaciones después de tener el líder
      _cargarEvaluaciones();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar datos reales: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
      
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar datos: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDE1327),
        title: Text(
          'Evaluación de Desempeño',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: _debugHiveData,
            tooltip: 'Debug Hive Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _buildFiltersSection(),
                const SizedBox(height: 16),
                _buildStartButton(),
                const SizedBox(height: 24),
                _buildTableSection(),
              ],
            ),
    );
  }
  
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            'Filtros de Evaluación',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2120),
            ),
          ),
          const SizedBox(height: 16),
          _buildLockedField('Nombre del Líder', _liderComercial?.nombre ?? 'Sin nombre'),
          const SizedBox(height: 12),
          _buildLockedField('País', _liderComercial?.pais ?? 'Sin país'),
          const SizedBox(height: 12),
          _buildChannelDropdown(),
          const SizedBox(height: 12),
          _buildAdvisorDropdown(),
        ],
      ),
    );
  }
  
  Widget _buildLockedField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8F8E8E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, size: 16, color: Color(0xFF8F8E8E)),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdvisorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asesor',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8F8E8E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedAdvisor,
            decoration: InputDecoration(
              hintText: _advisors.isEmpty ? 'No hay asesores disponibles' : 'Seleccione un asesor',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFF8F8E8E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _advisors.map((advisor) {
              return DropdownMenuItem(
                value: advisor.codigo,
                child: Text(
                  '${advisor.nombre} (${advisor.codigo})',
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: _advisors.isEmpty ? null : (value) {
              setState(() {
                _selectedAdvisor = value;
              });
            },
          ),
        ),
        if (_advisors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'No se encontraron asesores para este líder',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildChannelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Canal',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8F8E8E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedChannel,
            decoration: InputDecoration(
              hintText: 'Seleccione un canal',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFF8F8E8E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _channels.map((channel) {
              return DropdownMenuItem(
                value: channel,
                child: Text(
                  channel,
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedChannel = value;
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStartButton() {
    final isEnabled = _selectedAdvisor != null && _selectedChannel != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled ? _startEvaluation : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? const Color(0xFFDE1327) : Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Iniciar evaluación de desempeño',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTableSection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ValueListenableBuilder<Box<ResultadoExcelenciaHive>>(
          valueListenable: _repository.listenable,
          builder: (context, box, _) {
            // Obtener evaluaciones directamente sin setState
            // Si no hay filtros seleccionados, mostrar todas las evaluaciones del líder
            final evaluacionesFiltradas = _repository.obtenerEvaluacionesFiltradas(
              liderClave: _liderComercial?.clave,
              canal: _selectedChannel,
              asesorCodigo: _selectedAdvisor,
            );
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Evaluaciones Realizadas',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C2120),
                        ),
                      ),
                      if (evaluacionesFiltradas.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDE1327).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${evaluacionesFiltradas.length} registros',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFDE1327),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildTableHeader(),
                const Divider(height: 1),
                Expanded(
                  child: evaluacionesFiltradas.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: evaluacionesFiltradas.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _buildTableRow(evaluacionesFiltradas[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay evaluaciones registradas',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las evaluaciones realizadas aparecerán aquí',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Fecha',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Nombre del Asesor',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Canal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Estado',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Puntuación',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Acciones',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2120),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableRow(ResultadoExcelenciaHive evaluation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final metadatos = evaluation.metadatos ?? {};
    final asesorNombre = metadatos['asesorNombre'] ?? 'Sin asesor';
    final canal = metadatos['canal'] ?? 'Sin canal';
    
    // Determinar color del estado
    Color estadoColor;
    Color estadoBgColor;
    String estadoTexto;
    
    switch (evaluation.syncStatus) {
      case 'synced':
        estadoColor = const Color(0xFF38A169);
        estadoBgColor = const Color(0xFF38A169).withOpacity(0.1);
        estadoTexto = 'Sincronizado';
        break;
      case 'pending':
        estadoColor = const Color(0xFFF6C343);
        estadoBgColor = const Color(0xFFF6C343).withOpacity(0.1);
        estadoTexto = 'Pendiente';
        break;
      case 'failed':
        estadoColor = const Color(0xFFE53E3E);
        estadoBgColor = const Color(0xFFE53E3E).withOpacity(0.1);
        estadoTexto = 'Error';
        break;
      default:
        estadoColor = Colors.grey;
        estadoBgColor = Colors.grey.withOpacity(0.1);
        estadoTexto = 'Desconocido';
    }
    
    return InkWell(
      onTap: () => _mostrarDetalleEvaluacion(evaluation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(evaluation.fechaCaptura),
                style: GoogleFonts.poppins(color: const Color(0xFF1C2120)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                asesorNombre,
                style: GoogleFonts.poppins(color: const Color(0xFF1C2120)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: canal == 'Detalle' 
                      ? const Color(0xFF38A169).withOpacity(0.1)
                      : const Color(0xFFF6C343).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  canal,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: canal == 'Detalle' 
                        ? const Color(0xFF38A169)
                        : const Color(0xFFBB8A00),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  estadoTexto,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: estadoColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${evaluation.ponderacionFinal.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1C2120),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: const Color(0xFF1C2120),
                    tooltip: 'Ver detalles',
                    onPressed: () => _mostrarDetalleEvaluacion(evaluation),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    color: const Color(0xFF1C2120),
                    tooltip: 'Ver capturas',
                    onPressed: () => _verCapturas(evaluation),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _mostrarDetalleEvaluacion(ResultadoExcelenciaHive evaluacion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle de Evaluación',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('ID', evaluacion.id),
                      _buildDetailRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(evaluacion.fechaCaptura)),
                      _buildDetailRow('Líder', evaluacion.liderNombre),
                      _buildDetailRow('País', evaluacion.pais),
                      _buildDetailRow('Ruta', evaluacion.ruta),
                      _buildDetailRow('Centro de Distribución', evaluacion.centroDistribucion),
                      _buildDetailRow('Tipo de Formulario', evaluacion.tipoFormulario),
                      _buildDetailRow('Estatus', evaluacion.estatus),
                      _buildDetailRow('Ponderación Final', '${evaluacion.ponderacionFinal.toStringAsFixed(2)}%'),
                      if (evaluacion.observaciones != null)
                        _buildDetailRow('Observaciones', evaluacion.observaciones!),
                      const SizedBox(height: 16),
                      Text(
                        'Respuestas (${evaluacion.respuestas.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...evaluacion.respuestas.map((respuesta) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                respuesta.preguntaTitulo,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Respuesta: ${respuesta.respuestaComoTexto}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (respuesta.ponderacion != null)
                                Text(
                                  'Ponderación: ${respuesta.ponderacion!.toStringAsFixed(2)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF1C2120),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _verCapturas(ResultadoExcelenciaHive evaluacion) {
    Navigator.pushNamed(
      context,
      '/evaluacion_capturas',
      arguments: {
        'evaluacionId': evaluacion.id,
        'evaluacion': evaluacion,
      },
    );
  }
  
  void _debugHiveData() {
    print('🐛 === DEBUG HIVE DATA ===');
    print('📊 Líder actual: ${_liderComercial?.clave} - ${_liderComercial?.nombre}');
    print('🎯 Canal seleccionado: $_selectedChannel');
    print('👤 Asesor seleccionado: $_selectedAdvisor');
    
    // Obtener todas las evaluaciones
    final todasEvaluaciones = _repository.obtenerTodasEvaluaciones();
    print('📋 Total evaluaciones en DB: ${todasEvaluaciones.length}');
    
    // Mostrar un diálogo con la información
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Hive Data', style: GoogleFonts.poppins(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Líder: ${_liderComercial?.clave}', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Canal: $_selectedChannel', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Asesor: $_selectedAdvisor', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Total en DB: ${todasEvaluaciones.length}', style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 10),
            Text('Ver logs en consola para más detalles', style: GoogleFonts.poppins(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
  
  void _startEvaluation() {
    if (_selectedAdvisor == null || _selectedChannel == null) return;
    
    final selectedAdvisorData = _advisors.firstWhere(
      (advisor) => advisor.codigo == _selectedAdvisor,
    );
    
    Navigator.pushNamed(
      context,
      '/evaluacion_desempenio_llenado',
      arguments: {
        'leaderName': _liderComercial?.nombre ?? '',
        'country': _liderComercial?.pais ?? '',
        'advisorId': _selectedAdvisor,
        'advisorName': selectedAdvisorData.nombre,
        'channel': _selectedChannel,
      },
    );
  }
}