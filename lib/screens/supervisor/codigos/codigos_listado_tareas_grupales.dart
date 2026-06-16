import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_tareas.dart';
import '../servicios/servicio_tareas_repetidas.dart';
import 'codigos_dialogo_crear_tarea_grupal.dart';
import 'codigos_dialogo_editar_tarea_grupal.dart';
import 'codigos_dialogo_crear_tarea_repetida_grupal.dart';
import 'codigos_dialogo_editar_tarea_repetida_grupal.dart';

class ListadoTareasGrupales extends StatefulWidget {
  final String codigoId;

  const ListadoTareasGrupales({super.key, required this.codigoId});

  @override
  State<ListadoTareasGrupales> createState() =>
      _ListadoTareasGrupalesState();
}

class _ListadoTareasGrupalesState
    extends State<ListadoTareasGrupales> {
  final _servicio = ServicioTareas();
  final _servicioRepetidas = ServicioTareasRepetidas();
  DateTime _diaSeleccionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FECHA + BOTÓN CREAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

              // CREAR TAREA (elige simple o repetida)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _elegirTipoDeTarea,
              ),
            ],
          ),
        ),

        // LISTADO
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _servicio.obtenerGrupales(widget.codigoId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<TareaRepetida>>(
                stream: _servicioRepetidas
                    .obtenerReglasGrupales(widget.codigoId),
                builder: (context, snapReglas) {
                  if (!snapReglas.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final fechaStr =
                      DateFormat('yyyy-MM-dd').format(_diaSeleccionado);

                  // 1. Tareas grupales simples del día
                  final List<Map<String, dynamic>> items = snapshot.data!
                      .where((t) => t['fecha'] == fechaStr)
                      .map((t) => {...t, 'esVirtual': false})
                      .toList();

                  // 2. Reglas repetidas grupales que ocurran ese día (virtuales)
                  for (final regla in snapReglas.data!) {
                    if (!regla.ocurreEn(_diaSeleccionado)) continue;

                    items.add({
                      'id': 'virtual_${regla.id}_$fechaStr',
                      'esVirtual': true,
                      'tareaGrupalRepetidaId': regla.id,
                      'titulo': regla.titulo,
                      'hora': regla.hora,
                      'fecha': fechaStr,
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
                    return const Center(child: Text('Sin tareas'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final t = items[i];
                      final esRepetida = t['esVirtual'] == true;

                      return ListTile(
                        title: Row(
                          children: [
                            if (esRepetida)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Text('🔁',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            Expanded(child: Text(t['titulo'] ?? '')),
                          ],
                        ),
                        subtitle: Text(t['hora'] ?? 'Sin hora'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // EDITAR
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                if (esRepetida) {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        DialogoEditarTareaRepetidaGrupal(
                                      regla: t['_reglaObj'] as TareaRepetida,
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        DialogoEditarTareaGrupal(tarea: t),
                                  );
                                }
                              },
                            ),

                            // ELIMINAR
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _eliminar(t, esRepetida),
                            ),
                          ],
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

  // elegir tarea simple o repetida
  void _elegirTipoDeTarea() {
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
                showDialog(
                  context: context,
                  builder: (_) => DialogoCrearTareaGrupal(
                    codigoId: widget.codigoId,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.green),
              title: const Text('Tarea repetida'),
              subtitle: const Text('Se repite todos los días, semanas o meses'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => DialogoCrearTareaRepetidaGrupal(
                    codigoId: widget.codigoId,
                    creadaPor: 'tutor',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(Map<String, dynamic> t, bool esRepetida) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esRepetida ? 'Eliminar toda la serie' : 'Eliminar tarea'),
        content: Text(esRepetida
            ? 'Esta tarea grupal se repite. Si la borras, desaparecerá de '
                'todos los días futuros y de todos los alumnos del grupo. '
                '¿Continuar?'
            : '¿Seguro que quieres eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (esRepetida) {
      await _servicioRepetidas.borrarGrupal(t['tareaGrupalRepetidaId']);
    } else {
      await _servicio.eliminarGrupal(t['id']);
    }
  }
}