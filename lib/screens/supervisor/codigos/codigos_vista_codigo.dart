import 'package:flutter/material.dart';
import '../servicios/servicios_supervisor.dart';
import '../widgets/widgets_tarjeta_alumno.dart';
import 'codigos_dialogo_crear_tarea_grupal.dart';
import 'codigos_listado_tareas_grupales.dart';

class VistaCodigo extends StatefulWidget {
  final String codigoId;
  final String nombre;

  const VistaCodigo({
    super.key,
    required this.codigoId,
    required this.nombre,
  });

  @override
  State<VistaCodigo> createState() => _VistaCodigoState();
}

class _VistaCodigoState extends State<VistaCodigo>
    with TickerProviderStateMixin {
  late TabController _tabs;
  final _servicioSupervisor = ServicioSupervisor();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),

        // BOTÓN AÑADIR ALUMNO
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _anadirAlumnoDialog,
          ),
        ],

        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Alumnos'),
            Tab(text: 'Tareas grupales'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabs,
        children: [
          _tabAlumnos(),
          ListadoTareasGrupales(codigoId: widget.codigoId),
        ],
      ),

      // BOTÓN CREAR TAREA (solo en pestaña tareas)
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => DialogoCrearTareaGrupal(
                    codigoId: widget.codigoId,
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // TAB ALUMNOS
  Widget _tabAlumnos() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicioSupervisor.obtenerCodigo(widget.codigoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final alumnosIds = List<String>.from(snapshot.data!['alumnosIds'] ?? []);
        final tutoresIds = List<String>.from(snapshot.data!['tutoresIds'] ?? []);
        final supervisorId = snapshot.data!['supervisorId'] ?? '';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECCIÓN TUTORES
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tutores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (tutoresIds.isEmpty)
                      const Text('Sin tutores')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CREADOR DEL GRUPO
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StreamBuilder<Map<String, dynamic>>(
                              stream: _servicioSupervisor.obtenerUsuario(supervisorId),
                              builder: (context, snapshotCreador) {
                                if (!snapshotCreador.hasData) {
                                  return const SizedBox();
                                }

                                final creador = snapshotCreador.data!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Responsable:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.orange.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.orange.shade50,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.orange),
                                          const SizedBox(width: 12),
                                          Text(
                                            creador['nombre'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          
                          // OTROS TUTORES
                          const SizedBox(height: 12),
                          const Text(
                              'Tutores:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                          ),
                          ...tutoresIds.where((id) => id != supervisorId).map((tutorId) {
                            return StreamBuilder<Map<String, dynamic>>(
                              stream: _servicioSupervisor.obtenerUsuario(tutorId),
                              builder: (context, snapshotTutor) {
                                // IGNORAR SI NO EXISTE EL USUARIO
                                if (!snapshotTutor.hasData || snapshotTutor.data!.isEmpty) {
                                  return const SizedBox();
                                }

                                final tutor = snapshotTutor.data!;
                                final nombre = tutor['nombre'];

                                // IGNORAR SI NO TIENE NOMBRE (usuario vacío/eliminado)
                                if (nombre == null || nombre.toString().isEmpty) {
                                  return const SizedBox();
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blue.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.blue.shade50,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.school, color: Colors.blue),
                                        const SizedBox(width: 12),
                                        Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
                  ],
                ),
              ),

              const Divider(height: 30, thickness: 2),

              // SECCIÓN ALUMNOS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alumnos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (alumnosIds.isEmpty)
                      const Text('Sin alumnos')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: alumnosIds.length,
                        itemBuilder: (context, i) {
                          final alumnoId = alumnosIds[i];

                          return StreamBuilder<Map<String, dynamic>>(
                            stream: _servicioSupervisor.obtenerAlumno(alumnoId),
                            builder: (context, snapshotAlumno) {
                              if (!snapshotAlumno.hasData) {
                                return const SizedBox();
                              }

                              final alumno = snapshotAlumno.data!;

                              return TarjetaAlumno(
                                nombre: alumno['nombre'] ?? 'Sin nombre',
                                onTap: () {},
                                onQuitar: () async {
                                  final confirmar = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Quitar alumno'),
                                      content: const Text(
                                          '¿Seguro que quieres quitarlo del grupo?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Quitar'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmar == true) {
                                    await _servicioSupervisor.quitarAlumnoDeGrupo(
                                      alumnoId,
                                      widget.codigoId,
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // AÑADIR ALUMNO MANUALMENTE
  void _anadirAlumnoDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir alumno'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ID del alumno',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = controller.text.trim();

              if (id.isEmpty) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Campo vacío'),
                    content: const Text('Introduce el ID del alumno'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              try {
                await _servicioSupervisor.anadirAlumnoAGrupo(id, widget.codigoId);
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Éxito'),
                      content: const Text('Alumno añadido al grupo'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Error'),
                      content: Text('$e'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}