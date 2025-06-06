// lib/vistas/rutinas/pantalla_rutina_diaria.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../modelos/activity_model.dart'; // Importar el modelo compartido

// -----------------------------------------------------------------------------
// COLORES CORPORATIVOS DIANA
// -----------------------------------------------------------------------------
class AppColors {
  static const Color dianaRed = Color(0xFFDE1327);
  static const Color dianaGreen = Color(0xFF38A169);
  static const Color dianaYellow = Color(0xFFF6C343);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF1C2120);
  static const Color mediumGray = Color(0xFF8F8E8E);
}

// Remover las definiciones duplicadas de enum y ActivityModel ya que están en el archivo compartido

// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL
// -----------------------------------------------------------------------------
class PantallaRutinaDiaria extends StatefulWidget {
  const PantallaRutinaDiaria({super.key});

  @override
  State<PantallaRutinaDiaria> createState() => _PantallaRutinaDiariaState();
}

class _PantallaRutinaDiariaState extends State<PantallaRutinaDiaria> {
  List<ActivityModel> _actividades = [];
  bool _isLoading = true;
  bool _offline = false;
  String _diaActual = '';
  String _semanaActual = '';
  String _fechaFormateada = '';

  @override
  void initState() {
    super.initState();
    _inicializarRutina();
  }

  Future<void> _inicializarRutina() async {
    try {
      print('🔄 Iniciando rutina...');
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 500)); // UX loading

      DateTime ahora = DateTime.now();
      print('📅 Configurando fecha actual: $ahora');
      _configurarFechaActual(ahora);

      print('📋 Cargando actividades del día: $_diaActual');
      // Añadir timeout de 10 segundos
      await _cargarActividadesDelDia().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Timeout al cargar actividades');
          throw Exception('Timeout al cargar actividades');
        },
      );

      print('✅ Rutina inicializada correctamente');
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ Error en _inicializarRutina: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar rutina: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _configurarFechaActual(DateTime fecha) {
    // Configurar día actual
    List<String> diasSemana = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    _diaActual = diasSemana[fecha.weekday - 1];

    // Calcular número de semana
    int numeroSemana =
        ((fecha.difference(DateTime(fecha.year, 1, 1)).inDays +
                    DateTime(fecha.year, 1, 1).weekday -
                    1) /
                7)
            .ceil();
    _semanaActual = 'SEMANA $numeroSemana - ${fecha.year}';

    // Formatear fecha legible SIN localización española
    List<String> meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    String dia = fecha.day.toString();
    String mes = meses[fecha.month - 1];
    String anio = fecha.year.toString();

    _fechaFormateada = '$_diaActual, $dia de $mes de $anio';
  }

  Future<void> _cargarActividadesDelDia() async {
    try {
      print('🔍 Iniciando carga de actividades...');
      print('🎯 Día actual: $_diaActual');
      print('📅 Semana actual: $_semanaActual');

      List<ActivityModel> actividadesDelDia = [];

      final prefs = await SharedPreferences.getInstance();
      print('📱 SharedPreferences obtenido');

      // DEPURACIÓN: Mostrar TODAS las claves guardadas en SharedPreferences
      Set<String> keys = prefs.getKeys();
      print('🔑 TODAS las claves en SharedPreferences: $keys');

      // Buscar claves que puedan contener planes
      for (String key in keys) {
        print('📋 Clave: $key');
        if (key.contains('plan') || key.contains('seman')) {
          String? value = prefs.getString(key);
          print(
            '   └── Valor: ${value?.substring(0, value.length > 200 ? 200 : value.length)}...',
          );
        }
      }

      final String? jsonString = prefs.getString('plan_semanal');
      print(
        '📄 JSON plan_semanal obtenido: ${jsonString != null ? 'SÍ' : 'NO'}',
      );

      if (jsonString != null) {
        print('📄 CONTENIDO COMPLETO DEL JSON:');
        print(jsonString);
        print('📄 FIN DEL JSON');

        try {
          print('🔄 Decodificando JSON...');
          Map<String, dynamic> planesData = jsonDecode(jsonString);
          print('📊 Planes encontrados: ${planesData.keys.toList()}');

          // Mostrar TODOS los planes y sus estatus (SIN filtrar por fecha)
          planesData.forEach((semana, plan) {
            print('📋 Semana: $semana');
            print('   └── Estatus: ${plan['estatus']}');
            print(
              '   └── Días configurados: ${(plan['dias'] as Map?)?.keys.toList() ?? 'Sin días'}',
            );
          });

          // BUSCAR cualquier plan con estatus "enviado" (no importa la fecha)
          Map<String, dynamic>? planActivo;
          String? semanaActiva;

          for (String semana in planesData.keys) {
            final plan = planesData[semana];
            print('🔍 Revisando semana: $semana, estatus: ${plan['estatus']}');

            // BUSCAR ESTATUS "enviado"
            if (plan['estatus'] == 'enviado') {
              planActivo = plan;
              semanaActiva = semana;
              print('✅ Plan ENVIADO encontrado para semana: $semana');
              print(
                '   🔄 USANDO ESTE PLAN (IGNORANDO SI ES LA SEMANA ACTUAL)',
              );
              break;
            }
          }

          if (planActivo != null && semanaActiva != null) {
            print(
              '🗓️ Buscando actividades para el día: $_diaActual en plan de semana: $semanaActiva',
            );

            final diasData = planActivo['dias'] as Map<String, dynamic>?;
            print('📅 Datos de días disponibles: ${diasData?.keys.toList()}');

            if (diasData != null) {
              // Mostrar contenido completo de TODOS los días
              diasData.forEach((dia, diaInfo) {
                print('📋 Día $dia:');
                print('   └── Contenido completo: $diaInfo');
              });

              // REGLA 1: Buscar el día actual
              if (diasData.containsKey(_diaActual)) {
                final diaData = diasData[_diaActual] as Map<String, dynamic>;
                print('📋 ✅ ENCONTRADO - Datos del día $_diaActual:');
                print('   └── Objetivo: ${diaData['objetivo']}');
                print('   └── Tipo: ${diaData['tipo']}');
                print('   └── Comentario: ${diaData['comentario']}');
                print('   └── TipoActividad: ${diaData['tipoActividad']}');
                print(
                  '   └── Clientes: ${(diaData['clientesAsignados'] as List?)?.length ?? 0}',
                );

                // REGLA 2: Comprobar el tipo de actividad
                String tipoActividad = diaData['tipo'] ?? '';
                print('🎯 Tipo de actividad detectado: $tipoActividad');

                if (tipoActividad == 'administrativo') {
                  print('📝 PROCESANDO ACTIVIDAD ADMINISTRATIVA');

                  // REGLA 3: Para actividad administrativa
                  String titulo =
                      diaData['objetivo'] ?? 'Actividad administrativa';
                  String descripcion =
                      diaData['comentario'] ?? 'Sin comentarios';

                  actividadesDelDia.add(
                    ActivityModel(
                      id: '${_diaActual}_admin',
                      type: ActivityType.admin,
                      title: titulo,
                      direccion:
                          descripcion, // Usar direccion para guardar la descripción
                    ),
                  );

                  print('➕ ✅ ACTIVIDAD ADMINISTRATIVA CREADA:');
                  print('   └── Título: $titulo');
                  print('   └── Descripción: $descripcion');
                } else if (tipoActividad == 'gestion_cliente') {
                  print('🏪 PROCESANDO ACTIVIDAD DE GESTIÓN DE CLIENTES');

                  // REGLA 4: Para actividad de gestión de clientes
                  final clientesAsignados =
                      diaData['clientesAsignados'] as List<dynamic>?;
                  print(
                    '👥 Clientes asignados encontrados: ${clientesAsignados?.length ?? 0}',
                  );

                  if (clientesAsignados != null &&
                      clientesAsignados.isNotEmpty) {
                    // REGLA 5: Iterar en cada cliente
                    for (int i = 0; i < clientesAsignados.length; i++) {
                      final cliente =
                          clientesAsignados[i] as Map<String, dynamic>;

                      String clienteNombre =
                          cliente['clienteNombre'] ?? 'Cliente sin nombre';
                      String clienteDireccion =
                          cliente['clienteDireccion'] ??
                          'Dirección no disponible';
                      String clienteId = cliente['clienteId'] ?? 'ID_$i';

                      // REGLA 6: Crear ActivityModel por cada cliente
                      String tituloVisita = 'Visita a cliente: $clienteNombre';

                      actividadesDelDia.add(
                        ActivityModel(
                          id: '${_diaActual}_cliente_$clienteId',
                          type: ActivityType.visita,
                          title: tituloVisita,
                          direccion:
                              clienteDireccion, // Descripción en dirección
                          cliente: clienteId,
                          asesor: diaData['rutaNombre'], // Info adicional
                          status:
                              cliente['visitado'] == true
                                  ? ActivityStatus.completada
                                  : ActivityStatus.pendiente,
                        ),
                      );

                      print('➕ ✅ VISITA A CLIENTE CREADA #${i + 1}:');
                      print('   └── Título: $tituloVisita');
                      print('   └── Dirección: $clienteDireccion');
                      print('   └── ID Cliente: $clienteId');
                      print('   └── Tipo Cliente: ${cliente['clienteTipo']}');
                      print('   └── Visitado: ${cliente['visitado']}');
                    }
                  } else {
                    print(
                      '⚠️ No hay clientes asignados para gestión de clientes',
                    );
                    // Crear actividad genérica si no hay clientes
                    actividadesDelDia.add(
                      ActivityModel(
                        id: '${_diaActual}_gestion_sin_clientes',
                        type: ActivityType.admin,
                        title: diaData['objetivo'] ?? 'Gestión de clientes',
                        direccion: 'No hay clientes asignados',
                      ),
                    );
                  }
                } else {
                  print('❓ TIPO DE ACTIVIDAD DESCONOCIDO: $tipoActividad');
                  // Crear actividad genérica para tipos desconocidos
                  actividadesDelDia.add(
                    ActivityModel(
                      id: '${_diaActual}_$tipoActividad',
                      type: ActivityType.admin,
                      title: diaData['objetivo'] ?? 'Actividad sin definir',
                      direccion:
                          diaData['comentario'] ?? 'Tipo: $tipoActividad',
                    ),
                  );
                }
              } else {
                print('❌ Día $_diaActual NO encontrado en el plan');
                print('   └── Días disponibles: ${diasData.keys.toList()}');
                print(
                  '   └── ¿Coincide exactamente? ${diasData.keys.contains(_diaActual)}',
                );

                // FALLBACK: Intentar con otros días para debugging
                if (diasData.isNotEmpty) {
                  String primerDia = diasData.keys.first;
                  print('🔄 PROBANDO con el primer día disponible: $primerDia');
                  final diaData = diasData[primerDia] as Map<String, dynamic>;

                  if (diaData['tipo'] == 'gestion_cliente') {
                    final clientesAsignados =
                        diaData['clientesAsignados'] as List<dynamic>?;
                    if (clientesAsignados != null &&
                        clientesAsignados.isNotEmpty) {
                      for (var cliente in clientesAsignados) {
                        final clienteData = cliente as Map<String, dynamic>;
                        actividadesDelDia.add(
                          ActivityModel(
                            id: '${primerDia}_${clienteData['clienteId']}',
                            type: ActivityType.visita,
                            title:
                                'Visita a cliente: ${clienteData['clienteNombre']} ($primerDia)',
                            direccion: clienteData['clienteDireccion'],
                            cliente: clienteData['clienteId'],
                          ),
                        );
                      }
                      print(
                        '➕ Cargadas ${clientesAsignados.length} visitas del día $primerDia como ejemplo',
                      );
                    }
                  }
                }
              }
            } else {
              print('❌ No hay datos de días en el plan');
            }
          } else {
            print('❌ No hay ningún plan con estatus "enviado"');
          }
        } catch (e) {
          print('❌ Error procesando JSON: $e');
        }
      } else {
        print('❌ NO HAY JSON GUARDADO EN "plan_semanal"');
        print('🔍 Buscando en otras claves posibles...');

        // Buscar en otras claves que puedan tener planes
        for (String key in keys) {
          if (key.toLowerCase().contains('plan') ||
              key.toLowerCase().contains('seman')) {
            String? value = prefs.getString(key);
            if (value != null) {
              print('🎯 Encontrado contenido en clave "$key":');
              print(value);
            }
          }
        }
      }

      // Si no hay actividades reales, cargar datos de prueba
      if (actividadesDelDia.isEmpty) {
        print('⚠️ No hay actividades reales, cargando datos de prueba...');
        actividadesDelDia = [
          ActivityModel(
            id: 'prueba_1',
            type: ActivityType.admin,
            title: 'Enviar reporte de ventas',
          ),
          ActivityModel(
            id: 'prueba_2',
            type: ActivityType.visita,
            title: 'Supermercado Central',
            asesor: 'Juan Pérez',
            cliente: '001',
            direccion: 'Av. Principal 123',
          ),
          ActivityModel(
            id: 'prueba_3',
            type: ActivityType.visita,
            title: 'Bodega Santa Ana',
            asesor: 'María González',
            cliente: '002',
            direccion: 'Calle Comercio 456',
          ),
        ];
        print('✅ Datos de prueba cargados: ${actividadesDelDia.length}');
      } else {
        print(
          '🎉 🎉 🎉 ACTIVIDADES REALES CARGADAS: ${actividadesDelDia.length} 🎉 🎉 🎉',
        );
        actividadesDelDia.forEach((actividad) {
          print('   ✅ ${actividad.title} (${actividad.type.name})');
        });
      }

      print('🔄 Cargando estado de actividades...');
      // Cargar estado guardado de actividades
      await _cargarEstadoActividades(actividadesDelDia);

      print('✅ Actividades finales: ${actividadesDelDia.length}');
      setState(() {
        _actividades = actividadesDelDia;
      });
    } catch (e, stackTrace) {
      print('❌ Error al cargar actividades: $e');
      print('Stack trace: $stackTrace');

      // Cargar datos de emergencia
      setState(() {
        _actividades = [
          ActivityModel(
            id: 'emergencia_1',
            type: ActivityType.admin,
            title: 'Actividad de emergencia',
          ),
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar actividades, mostrando datos de prueba',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _cargarEstadoActividades(List<ActivityModel> actividades) async {
    try {
      print('🔄 Cargando estado de ${actividades.length} actividades...');
      final prefs = await SharedPreferences.getInstance();
      final String? estadosJson = prefs.getString(
        'estados_actividades_${_diaActual}',
      );

      if (estadosJson != null) {
        print('📄 Estados encontrados para $_diaActual');
        Map<String, dynamic> estados = jsonDecode(estadosJson);

        for (var actividad in actividades) {
          if (estados.containsKey(actividad.id)) {
            final estadoData = estados[actividad.id];
            actividad.status = ActivityStatus.values.firstWhere(
              (e) => e.name == estadoData['status'],
            );
            if (estadoData['horaInicio'] != null) {
              actividad.horaInicio = DateTime.fromMillisecondsSinceEpoch(
                estadoData['horaInicio'],
              );
            }
            if (estadoData['horaFin'] != null) {
              actividad.horaFin = DateTime.fromMillisecondsSinceEpoch(
                estadoData['horaFin'],
              );
            }
            print(
              '✅ Estado cargado para: ${actividad.title} - ${actividad.status}',
            );
          }
        }
      } else {
        print('⚠️ No hay estados guardados para $_diaActual');
      }
    } catch (e, stackTrace) {
      print('❌ Error al cargar estados: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _guardarEstadoActividades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> estados = {};

      for (var actividad in _actividades) {
        estados[actividad.id] = actividad.toJson();
      }

      await prefs.setString(
        'estados_actividades_${_diaActual}',
        jsonEncode(estados),
      );
    } catch (e) {
      print('Error al guardar estados: $e');
    }
  }

  Future<void> _cambiarEstadoActividad(ActivityModel actividad) async {
    setState(() {
      switch (actividad.status) {
        case ActivityStatus.pendiente:
          actividad.status = ActivityStatus.enCurso;
          actividad.horaInicio = DateTime.now();
          break;
        case ActivityStatus.enCurso:
          actividad.status = ActivityStatus.completada;
          actividad.horaFin = DateTime.now();
          break;
        case ActivityStatus.completada:
          actividad.status = ActivityStatus.pendiente;
          actividad.horaInicio = null;
          actividad.horaFin = null;
          break;
        case ActivityStatus.postergada:
          actividad.status = ActivityStatus.pendiente;
          break;
      }
    });

    await _guardarEstadoActividades();
  }

  Future<void> _postergarActividad(ActivityModel actividad) async {
    setState(() {
      actividad.status = ActivityStatus.postergada;
      actividad.horaInicio = null;
      actividad.horaFin = null;
    });

    await _guardarEstadoActividades();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actividad "${actividad.title}" postergada'),
        backgroundColor: AppColors.dianaYellow,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int get _actividadesCompletadas =>
      _actividades.where((a) => a.status == ActivityStatus.completada).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.dianaRed),
        ),
      );
    }

    final int total = _actividades.length;
    final double progreso = total == 0 ? 0.0 : _actividadesCompletadas / total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Agenda de Hoy',
          style: GoogleFonts.poppins(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _offline ? Icons.cloud_off : Icons.cloud_done,
              color: _offline ? Colors.orange : AppColors.dianaGreen,
            ),
            onPressed: () {
              // TODO: Implementar lógica de sincronización
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_offline) const _OfflineBanner(),
          _HeaderHoy(
            diaActual: _diaActual,
            fechaFormateada: _fechaFormateada,
            completadas: _actividadesCompletadas,
            total: total,
            progreso: progreso,
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                total == 0
                    ? _EstadoVacio()
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final actividad = _actividades[index];
                        return _ActivityTile(
                          actividad: actividad,
                          onToggle: () => _cambiarEstadoActividad(actividad),
                          onPostpone: () => _postergarActividad(actividad),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: total,
                    ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.dianaRed,
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
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS DE SOPORTE
// -----------------------------------------------------------------------------

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.all(8),
      child: Text(
        'Trabajando sin conexión – los cambios se enviarán al recuperar señal',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HeaderHoy extends StatelessWidget {
  final String diaActual;
  final String fechaFormateada;
  final int completadas;
  final int total;
  final double progreso;

  const _HeaderHoy({
    required this.diaActual,
    required this.fechaFormateada,
    required this.completadas,
    required this.total,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoy · $diaActual',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fechaFormateada,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: Colors.grey.shade300,
            color: AppColors.dianaRed,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$completadas de $total actividades completadas',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityModel actividad;
  final VoidCallback onToggle;
  final VoidCallback onPostpone;

  const _ActivityTile({
    required this.actividad,
    required this.onToggle,
    required this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    IconData leadingIcon;
    Color leadingColor;

    switch (actividad.type) {
      case ActivityType.admin:
        leadingIcon = Icons.description_outlined;
        leadingColor = AppColors.dianaRed;
        break;
      case ActivityType.visita:
        leadingIcon = Icons.storefront_outlined;
        leadingColor = AppColors.dianaRed;
        break;
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (actividad.status) {
      case ActivityStatus.completada:
        statusColor = AppColors.dianaGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Completada';
        break;
      case ActivityStatus.enCurso:
        statusColor = AppColors.dianaYellow;
        statusIcon = Icons.timelapse;
        statusText = 'En curso';
        break;
      case ActivityStatus.postergada:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        statusText = 'Postergada';
        break;
      default:
        statusColor = Colors.grey.shade400;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Pendiente';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: actividad.type == ActivityType.admin ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(leadingIcon, color: leadingColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actividad.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      if (actividad.asesor != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ruta: ${actividad.asesor}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                      if (actividad.direccion != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          actividad.direccion!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Botón de visita SOLO para actividades de tipo visita
                if (actividad.type == ActivityType.visita) ...[
                  IconButton(
                    onPressed: () async {
                      print(
                        '🏪 Navegando a visita cliente: ${actividad.title}',
                      );
                      final resultado = await Navigator.pushNamed(
                        context,
                        '/visita_cliente',
                        arguments: actividad,
                      );

                      // Si regresa con resultado positivo, marcar como completada
                      if (resultado == true) {
                        print('✅ Visita completada, actualizando estado');
                        onToggle(); // Esto cambiará el estado de la actividad
                      }
                    },
                    icon: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.dianaRed,
                    ),
                    tooltip: 'Iniciar Visita',
                  ),
                  const SizedBox(width: 8),
                ],

                // Botón postergar solo para actividades en curso o pendientes
                if (actividad.status == ActivityStatus.enCurso ||
                    actividad.status == ActivityStatus.pendiente)
                  IconButton(
                    onPressed: onPostpone,
                    icon: const Icon(
                      Icons.schedule,
                      color: AppColors.mediumGray,
                    ),
                    tooltip: 'Postergar',
                  ),

                const SizedBox(width: 8),

                // Icono de estado (solo clickeable para actividades admin)
                if (actividad.type == ActivityType.admin)
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  )
                else
                  Icon(statusIcon, color: statusColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay actividades programadas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para el día de hoy',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/plan_configuracion');
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              'Crear Plan de Trabajo',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dianaRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
