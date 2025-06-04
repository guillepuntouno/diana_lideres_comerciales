import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class VistaProgramacionSemana extends StatefulWidget {
  const VistaProgramacionSemana({super.key});

  @override
  State<VistaProgramacionSemana> createState() =>
      _VistaProgramacionSemanaState();
}

class _VistaProgramacionSemanaState extends State<VistaProgramacionSemana> {
  final List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sabado',
  ];

  Map<String, bool> diasConfigurados = {
    'Lunes': false,
    'Martes': false,
    'Miércoles': false,
    'Jueves': false,
    'Viernes': false,
    'Sabado': false,
  };

  int _currentIndex = 1;

  String semana = '';
  String fechaInicio = '';
  String fechaFin = '';
  String estatus = 'Borrador';

  @override
  void initState() {
    super.initState();
    _inicializarPlan();
  }

  Future<void> _inicializarPlan() async {
    DateTime ahora = DateTime.now();

    int numeroSemana =
        ((ahora.difference(DateTime(ahora.year, 1, 1)).inDays +
                    DateTime(ahora.year, 1, 1).weekday -
                    1) /
                7)
            .ceil();
    int anio = ahora.year;
    semana = 'SEMANA $numeroSemana - $anio';

    DateTime inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    DateTime finSemana = inicioSemana.add(const Duration(days: 5));

    fechaInicio = _formatoFecha(inicioSemana);
    fechaFin = _formatoFecha(finSemana);

    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('plan_semanal');

    Map<String, dynamic> data = {};

    if (jsonString != null) {
      data = jsonDecode(jsonString);

      if (data.containsKey(semana)) {
        estatus = data[semana]['estatus'];
        Map<String, dynamic> dias = data[semana]['dias'];

        diasConfigurados = {for (var dia in dias.keys) dia: dias[dia] != null};
      }
    }

    setState(() {});
  }

  String _formatoFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  Future<void> _enviarPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('plan_semanal');

    if (jsonString != null) {
      Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey(semana)) {
        data[semana]['estatus'] = 'Programado';
        await prefs.setString('plan_semanal', jsonEncode(data));

        if (context.mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('¡Éxito!'),
                  content: const Text('El plan ha sido enviado correctamente.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cierra diálogo
                        Navigator.of(context).pop(); // Regresa
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2120)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crear Plan de Trabajo',
          style: TextStyle(
            color: Color(0xFF1C2120),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos Generales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDato('Semana:', semana),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDato('Desde:', fechaInicio)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDato('Hasta:', fechaFin)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDato('Estatus:', estatus),
                const Divider(color: Colors.grey, thickness: 0.5, height: 32),
                const Text(
                  'Programación de la semana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2120),
                  ),
                ),
                const SizedBox(height: 16),
                ...diasSemana.map((dia) {
                  final configurado = diasConfigurados[dia] ?? false;
                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        dia,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1C2120),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        configurado
                            ? Icons.check_circle
                            : Icons.hourglass_bottom,
                        color: configurado ? Colors.green : Colors.grey,
                      ),
                      onTap: () async {
                        final resultado = await Navigator.pushNamed(
                          context,
                          '/programar_dia',
                          arguments: dia,
                        );

                        if (resultado == true) {
                          setState(() {
                            diasConfigurados[dia] = true;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviarPlan,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'ENVIAR PLAN',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE1327),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: Colors.black12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        selectedItemColor: const Color(0xFFDE1327),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Rutinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildDato(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1C2120),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1C2120)),
          ),
        ),
      ],
    );
  }
}
