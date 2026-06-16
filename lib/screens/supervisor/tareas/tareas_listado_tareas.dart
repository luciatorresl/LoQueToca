import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_tareas.dart';
import '../servicios/servicio_tareas_repetidas.dart';
import 'tareas_dialogo_editar_tarea.dart';
import 'dialogo_editar_tarea_repetida.dart';

class ListadoTareas extends StatefulWidget {
  final String alumnoId;

  const ListadoTareas({super.key, required this.alumnoId});

  @override
  State<ListadoTareas> createState() => _ListadoTareasState();
}

class _ListadoTareasState extends State<ListadoTareas> {
  final _servicio = ServicioTareas();
  final _servicioRepetidas = ServicioTareasRepetidas();
  DateTime _diaSeleccionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final fechaSeleccionadaStr =
        DateFormat('yyyy-MM-dd').format(_diaSeleccionado);

    return Column(
      children: [
        // SELECTOR DE FECHA
        Padding(
          padding: const EdgeInsets.all(10),
          child: ElevatedButton(
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
            child: Text(DateFormat('dd/MM/yyyy').format(_diaSeleccionado)),
          ),
        ),

        // LISTA DE TAREAS DEL DÍA
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _servicio.obtener(widget.alumnoId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<TareaRepetida>>(
                stream: _servicioRepetidas.obtenerReglas(widget.alumnoId),
                builder: (context, snapReglas) {
                  if (!snapReglas.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tareas = snapshot.data!;
                  final reglas = snapReglas.data!;

                  // Tareas normales del dia
                  final List<Map<String, dynamic>> items = tareas
                      .where((t) => t['fecha'] == fechaSeleccionadaStr)
                      .map((t) => {...t, 'esVirtual': false})
                      .toList();

                  // Anadir repetidas que ocurran ese dia (no materializadas)
                  for (final regla in reglas) {
                    if (!regla.ocurreEn(_diaSeleccionado)) continue;

                    final yaMaterializada = tareas.any((t) =>
                        t['tareaRepetidaId'] == regla.id &&
                        t['fecha'] == fechaSeleccionadaStr);

                    if (yaMaterializada) continue;

                    items.add({
                      'id': 'virtual_${regla.id}_$fechaSeleccionadaStr',
                      'esVirtual': true,
                      'tareaRepetidaId': regla.id,
                      'titulo': regla.titulo,
                      'hora': regla.hora,
                      'fecha': fechaSeleccionadaStr,
                      'creadaPor': regla.creadaPor,
                      'esGrupal': regla.esGrupal,
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
                      final esDeEsteTutor = t['creadaPor'] == 'tutor';

                      return ListTile(
                        leading: Checkbox(
                          value: t['completada'] ?? false,
                          onChanged: (_) {
                            // El tutor no marca tareas como completadas
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
                                  color: t['esGrupal'] == true
                                      ? Colors.blue
                                      : (t['creadaPor'] == 'alumno' ||
                                              t['creadaPor'] == 'padre')
                                          ? Colors.red
                                          : Colors.black,
                                  fontWeight: t['esGrupal'] == true
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: t['esGrupal'] == true ? 18 : 16,
                                  decoration: t['completada'] == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(t['hora'] ?? ''),
                        trailing: Builder(
                          builder: (context) {
                            // Solo el tutor que creo la regla/tarea puede tocar
                            if (!esDeEsteTutor || t['esGrupal'] == true) {
                              return const SizedBox.shrink();
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editarTarea(t),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _borrarTarea(t),
                                ),
                              ],
                            );
                          },
                        ),
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
  }

  void _editarTarea(Map<String, dynamic> t) {
    final esRepetida =
        t['esVirtual'] == true || t['tareaRepetidaId'] != null;

    if (esRepetida) {
      // Editar la regla entera
      TareaRepetida? regla = t['_reglaObj'] as TareaRepetida?;

      // Si la tarea ya estaba materializada, el _reglaObj puede no estar
      // Hay que cargar la regla por id
      if (regla == null && t['tareaRepetidaId'] != null) {
        _editarReglaPorId(t['tareaRepetidaId']);
        return;
      }

      if (regla != null) {
        showDialog(
          context: context,
          builder: (_) => DialogoEditarTareaRepetida(regla: regla),
        );
      }
      return;
    }

    // Tarea normal
    showDialog(
      context: context,
      builder: (_) => DialogoEditarTarea(
        tareaId: t['id'],
        tarea: t,
      ),
    );
  }

  Future<void> _editarReglaPorId(String reglaId) async {
    final lista = await _servicioRepetidas.obtenerReglas(widget.alumnoId).first;
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

  Future<void> _borrarTarea(Map<String, dynamic> t) async {
    final esRepetida =
        t['esVirtual'] == true || t['tareaRepetidaId'] != null;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esRepetida ? 'Eliminar toda la serie' : 'Eliminar tarea'),
        content: Text(esRepetida
            ? 'Esta tarea se repite. Si la borras, desaparecerá de todos los '
                'días futuros. ¿Continuar?'
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
      // Borrar la regla. Las apariciones ya materializadas se quedan
      await _servicioRepetidas.borrar(t['tareaRepetidaId']);
    } else {
      await _servicio.eliminar(t['id']);
    }
  }
}