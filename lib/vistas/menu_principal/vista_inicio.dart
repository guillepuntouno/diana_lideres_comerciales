import 'package:flutter/material.dart';
import '../../widgets/encabezado_inicio.dart';
import '../../widgets/connection_status_widget.dart';
import '../../servicios/sesion_servicio.dart';
import '../../modelos/lider_comercial_modelo.dart';

class VistaInicio extends StatefulWidget {
  const VistaInicio({super.key});

  @override
  State<VistaInicio> createState() => _VistaInicioState();
}

class _VistaInicioState extends State<VistaInicio> {
  LiderComercial? _liderComercial;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final lider = await SesionServicio.obtenerLiderComercial();
      if (mounted) {
        setState(() {
          _liderComercial = lider;
        });
      }
    } catch (e) {
      print('Error cargando datos del usuario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoInicio(
            nombreUsuario: _liderComercial?.nombre ?? 'Usuario',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const ConnectionStatusWidget(),
                  Expanded(
                    child: _liderComercial != null
                        ? _buildDashboard()
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final totalRutas = _liderComercial!.rutas.length;
    final totalNegocios = _liderComercial!.rutas
        .fold<int>(0, (sum, ruta) => sum + ruta.negocios.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido, ${_liderComercial!.nombre}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información General',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Centro de Distribución', _liderComercial!.centroDistribucion),
                _buildInfoRow('País', _liderComercial!.pais),
                _buildInfoRow('Clave', _liderComercial!.clave),
                _buildInfoRow('Total de Rutas', '$totalRutas'),
                _buildInfoRow('Total de Negocios', '$totalNegocios'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (totalRutas > 0) ...[
          const Text(
            'Resumen de Rutas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _liderComercial!.rutas.length,
              itemBuilder: (context, index) {
                final ruta = _liderComercial!.rutas[index];
                return Card(
                  child: ListTile(
                    title: Text(ruta.nombre),
                    subtitle: Text('Asesor: ${ruta.asesor} • ${ruta.negocios.length} negocios'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Aquí se podría navegar a los detalles de la ruta
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
