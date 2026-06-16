import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_padre.dart';
import '../servicios/servicio_tareas_repetidas.dart';
import '../tareas/tareas_dialogo_editar_tarea.dart';
import '../tareas/dialogo_crear_tarea_repetida.dart';
import '../tareas/dialogo_editar_tarea_repetida.dart';

class PadreTareas extends StatefulWidget {
  const PadreTareas({super.key});

  @override
  State<PadreTareas> createState() => _PadreTareasState();
}

class _PadreTareasState extends State<PadreTareas> {
  final _servicio = ServicioPadre();
  final _servicioRepetidas = ServicioTareasRepetidas();
  DateTime _diaSeleccionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicio.obtenerAlumnoVinculado(),
      builder: (context, snapshotAlumno) {
        if (!snapshotAlumno.hasData || snapshotAlumno.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final alumno = snapshotAlumno.data!;
        final alumnoId = alumno['id'];
        final nombreAlumno = alumno['nombre'] ?? 'Sin nombre';
        final fechaSeleccionadaStr =
            DateFormat('yyyy-MM-dd').format(_diaSeleccionado);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                'Tareas de $nombreAlumno',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: _diaSeleccionado,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) {
                        setState(() => _diaSeleccionado = fecha);
                      }
                    },
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_diaSeleccionado),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () => _elegirTipoDeTarea(alumnoId),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _servicio.obtenerTareasAlumno(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<List<TareaRepetida>>(
                    stream: _servicioRepetidas.obtenerReglas(alumnoId),
                    builder: (context, snapReglas) {
                      if (!snapReglas.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final tareas = snapshot.data!;
                      final reglas = snapReglas.data!;

                      // 1. Tareas normales del dia
                      final List<Map<String, dynamic>> items = tareas
                          .where((t) => t['fecha'] == fechaSeleccionadaStr)
                          .map((t) => {...t, 'esVirtual': false})
                          .toList();

                      // 2. Anadir repetidas que ocurran ese dia (no materializadas)
                      for (final regla in reglas) {
                        if (!regla.ocurreEn(_diaSeleccionado)) continue;

                        final yaMaterializada = tareas.any((t) =>
                            t['tareaRepetidaId'] == regla.id &&
                            t['fecha'] == fechaSeleccionadaStr);
                        if (yaMaterializada) continue;

                        items.add({
                          'id':
                              'virtual_${regla.id}_$fechaSeleccionadaStr',
                          'esVirtual': true,
                          'tareaRepetidaId': regla.id,
                          'titulo': regla.titulo,
                          'hora': regla.hora,
                          'fecha': fechaSeleccionadaStr,
                          'creadaPor': regla.creadaPor,
                          'completada': false,
                          '_reglaObj': regla,
                        });
                      }

                      // Ordenar por hora
                      items.sort((a, b) {
                        int conv(String? h) {
                          if (h == null || h.isEmpty) return 9999;
                          final p = h.split(':');
                          return int.parse(p[0]) * 60 + int.parse(p[1]);
                        }
                        return conv(a['hora']).compareTo(conv(b['hora']));
                      });

                      if (items.isEmpty) {
                        return const Center(
                            child: Text('No hay tareas para este día'));
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final t = items[i];
                          final esRepetida = t['esVirtual'] == true ||
                              t['tareaRepetidaId'] != null;
                          // El padre puede tocar todo menos lo del tutor
                          final puedoEditar = t['creadaPor'] != 'tutor';

                          Color getColorTarea() {
                            if (t['creadaPor'] == 'tutor') return Colors.blue;
                            if (t['creadaPor'] == 'padre') return Colors.red;
                            return Colors.black;
                          }

                          return ListTile(
                            leading: Checkbox(
                              value: t['completada'] ?? false,
                              onChanged: (_) {
                                // El padre no marca como completadas
                              },
                            ),
                            title: Row(
                              children: [
                                if (esRepetida)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Text('🔁',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                Expanded(
                                  child: Text(
                                    t['titulo'] ?? 'Sin título',
                                    style: TextStyle(
                                      color: getColorTarea(),
                                      decoration: t['completada'] == true
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(t['hora'] ?? ''),
                            trailing: puedoEditar
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _editarTarea(t),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _borrarTarea(t),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // MENU para elegir tipo de tarea (simple o repetida)
  void _elegirTipoDeTarea(String alumnoId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.event_note, color: Colors.blue),
              title: const Text('Tarea simple'),
              subtitle: const Text('Una sola vez en una fecha concreta'),
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoCrearTarea(alumnoId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.green),
              title: const Text('Tarea repetida'),
              subtitle: const Text(
                  'Se repite todos los días, semanas o meses'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => DialogoCrearTareaRepetida(
                    alumnoId: alumnoId,
                    creadaPor: 'padre',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // EDITAR (distingue simple vs repetida)
  void _editarTarea(Map<String, dynamic> t) {
    final esRepetida =
        t['esVirtual'] == true || t['tareaRepetidaId'] != null;

    if (esRepetida) {
      final reglaInline = t['_reglaObj'] as TareaRepetida?;
      if (reglaInline != null) {
        showDialog(
          context: context,
          builder: (_) => DialogoEditarTareaRepetida(regla: reglaInline),
        );
      } else if (t['tareaRepetidaId'] != null) {
        _editarReglaPorId(t['tareaRepetidaId'], t['alumnoId']);
      }
      return;
    }

    _mostrarDialogoEditarTarea(t);
  }

  Future<void> _editarReglaPorId(String reglaId, String alumnoId) async {
    final lista = await _servicioRepetidas.obtenerReglas(alumnoId).first;
    final regla = lista.firstWhere(
      (r) => r.id == reglaId,
      orElse: () => throw Exception('Regla no encontrada'),
    );
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => DialogoEditarTareaRepetida(regla: regla),
      );
    }
  }

  // BORRAR (distingue simple vs repetida)
  Future<void> _borrarTarea(Map<String, dynamic> t) async {
    final esRepetida =
        t['esVirtual'] == true || t['tareaRepetidaId'] != null;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            esRepetida ? 'Eliminar toda la serie' : 'Eliminar tarea'),
        content: Text(esRepetida
            ? 'Esta tarea se repite. Si la borras, desaparecerá de todos '
                'los días futuros. ¿Continuar?'
            : '¿Seguro que quieres eliminar la tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (esRepetida) {
      await _servicioRepetidas.borrar(t['tareaRepetidaId']);
    } else {
      await _servicio.eliminarTarea(t['id']);
    }
  }

  // DIALOGOS de tarea simple 
  void _mostrarDialogoCrearTarea(String alumnoId) {
    final tituloController = TextEditingController();
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nueva tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                      labelText: 'Título de la tarea'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (fecha != null) {
                      setStateDialog(() => fechaSeleccionada = fecha);
                    }
                  },
                  child: Text(
                    fechaSeleccionada == null
                        ? 'Seleccionar fecha'
                        : DateFormat('dd/MM/yyyy').format(fechaSeleccionada!),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          alwaysUse24HourFormat: true,
                        ),
                        child: child!,
                      ),
                    );
                    if (hora != null) {
                      setStateDialog(() => horaSeleccionada = hora);
                    }
                  },
                  child: Text(
                    horaSeleccionada == null
                        ? 'Añadir hora (opcional)'
                        : '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tituloController.text.isEmpty ||
                      fechaSeleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Rellena título y fecha')),
                    );
                    return;
                  }

                  String? hora;
                  if (horaSeleccionada != null) {
                    hora =
                        '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}';
                  }

                  try {
                    await _servicio.crearTarea(
                      titulo: tituloController.text,
                      fecha: DateFormat('yyyy-MM-dd')
                          .format(fechaSeleccionada!),
                      hora: hora,
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogoEditarTarea(Map<String, dynamic> tarea) {
    final tituloController = TextEditingController(text: tarea['titulo']);
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;

    if (tarea['fecha'] != null) {
      fechaSeleccionada = DateFormat('yyyy-MM-dd').parse(tarea['fecha']);
    }

    if (tarea['hora'] != null && tarea['hora'].isNotEmpty) {
      final p = tarea['hora'].split(':');
      horaSeleccionada = TimeOfDay(
        hour: int.parse(p[0]),
        minute: int.parse(p[1]),
      );
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (fecha != null) {
                      setStateDialog(() => fechaSeleccionada = fecha);
                    }
                  },
                  child: Text(
                    fechaSeleccionada == null
                        ? 'Seleccionar fecha'
                        : DateFormat('dd/MM/yyyy').format(fechaSeleccionada!),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: horaSeleccionada ?? TimeOfDay.now(),
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          alwaysUse24HourFormat: true,
                        ),
                        child: child!,
                      ),
                    );
                    if (hora != null) {
                      setStateDialog(() => horaSeleccionada = hora);
                    }
                  },
                  child: Text(
                    horaSeleccionada == null
                        ? 'Hora'
                        : '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? hora;
                  if (horaSeleccionada != null) {
                    hora =
                        '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}';
                  }

                  try {
                    await _servicio.editarTarea(
                      tarea['id'],
                      titulo: tituloController.text,
                      fecha: DateFormat('yyyy-MM-dd')
                          .format(fechaSeleccionada!),
                      hora: hora,
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}