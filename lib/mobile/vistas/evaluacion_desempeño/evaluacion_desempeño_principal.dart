import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EvaluacionDesempenioPrincipal extends StatefulWidget {
  const EvaluacionDesempenioPrincipal({Key? key}) : super(key: key);

  @override
  State<EvaluacionDesempenioPrincipal> createState() => _EvaluacionDesempenioPrincipalState();
}

class _EvaluacionDesempenioPrincipalState extends State<EvaluacionDesempenioPrincipal> {
  String? _selectedAdvisor;
  String? _selectedChannel;
  
  final List<Map<String, String>> _advisors = [
    {'id': '1', 'name': 'Juan Carlos Méndez'},
    {'id': '2', 'name': 'María López González'},
    {'id': '3', 'name': 'Pedro Rodríguez'},
    {'id': '4', 'name': 'Ana Martínez'},
    {'id': '5', 'name': 'Carlos Gutiérrez'},
  ];
  
  final List<String> _channels = ['Detalle', 'Mayoreo'];
  
  final List<Map<String, dynamic>> _evaluations = [
    {
      'date': DateTime(2025, 1, 10),
      'advisorName': 'Juan Carlos Méndez',
      'channel': 'Detalle',
    },
    {
      'date': DateTime(2025, 1, 8),
      'advisorName': 'María López González',
      'channel': 'Mayoreo',
    },
    {
      'date': DateTime(2025, 1, 5),
      'advisorName': 'Pedro Rodríguez',
      'channel': 'Detalle',
    },
  ];
  
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
      ),
      body: Column(
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
          _buildLockedField('Nombre del Líder', 'Hugo Sandoval'),
          const SizedBox(height: 12),
          _buildLockedField('País', 'El Salvador'),
          const SizedBox(height: 12),
          _buildAdvisorDropdown(),
          const SizedBox(height: 12),
          _buildChannelDropdown(),
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
              hintText: 'Seleccione un asesor',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFF8F8E8E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _advisors.map((advisor) {
              return DropdownMenuItem(
                value: advisor['id'],
                child: Text(
                  advisor['name']!,
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAdvisor = value;
              });
            },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Evaluaciones Realizadas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2120),
                ),
              ),
            ),
            const Divider(height: 1),
            _buildTableHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _evaluations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildTableRow(_evaluations[index]);
                },
              ),
            ),
          ],
        ),
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
        ],
      ),
    );
  }
  
  Widget _buildTableRow(Map<String, dynamic> evaluation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateFormat.format(evaluation['date']),
              style: GoogleFonts.poppins(color: const Color(0xFF1C2120)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              evaluation['advisorName'],
              style: GoogleFonts.poppins(color: const Color(0xFF1C2120)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: evaluation['channel'] == 'Detalle' 
                    ? const Color(0xFF38A169).withOpacity(0.1)
                    : const Color(0xFFF6C343).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                evaluation['channel'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: evaluation['channel'] == 'Detalle' 
                      ? const Color(0xFF38A169)
                      : const Color(0xFFBB8A00),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _startEvaluation() {
    if (_selectedAdvisor == null || _selectedChannel == null) return;
    
    final selectedAdvisorData = _advisors.firstWhere(
      (advisor) => advisor['id'] == _selectedAdvisor,
    );
    
    Navigator.pushNamed(
      context,
      '/evaluacion_desempenio_llenado',
      arguments: {
        'leaderName': 'Hugo Sandoval',
        'country': 'El Salvador',
        'advisorId': _selectedAdvisor,
        'advisorName': selectedAdvisorData['name'],
        'channel': _selectedChannel,
      },
    );
  }
}