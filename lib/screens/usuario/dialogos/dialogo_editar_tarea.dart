import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicio_tareas.dart';
import '../utilidades/formatos_fecha.dart';
import '../servicios/servicio_seguimiento.dart';
import '../../auth/sesion_alumno.dart';

Future<void> mostrarDialogoEditarTarea(
  BuildContext context,
  String id,
  Map<String, dynamic> data,
) async {
  final titulo = TextEditingController(text: data['titulo']);

  DateTime? fecha;
  TimeOfDay? hora;

  // Parsear la fecha existente
  if (data['fecha'] != null) {
    fecha = DateFormat('yyyy-MM-dd').parse(data['fecha']);
  }

  // Parsear la hora existente
  if (data['hora'] != null && data['hora'].isNotEmpty) {
    final p = data['hora'].split(':');
    hora = TimeOfDay(
      hour: int.parse(p[0]),
      minute: int.parse(p[1]),
    );
  }

  List<DateTime> siguientes7Dias =
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Editar tarea"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Editar título
                TextField(
                  controller: titulo,
                  decoration: const InputDecoration(labelText: "Título"),
                ),
                const SizedBox(height: 15),

                // Editar fecha
                const Text(
                  "Fecha",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: siguientes7Dias.map((d) {
                    final sel = fecha != null &&
                        DateFormat('yyyy-MM-dd').format(fecha!) ==
                            DateFormat('yyyy-MM-dd').format(d);

                    return ChoiceChip(
                      label: Text(DateFormat.E('es').add_d().format(d)),
                      selected: sel,
                      onSelected: (_) {
                        setStateDialog(() => fecha = d);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),

                // Editar hora
                ElevatedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialEntryMode: TimePickerEntryMode.input,
                      initialTime: hora ?? TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            alwaysUse24HourFormat: true,
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (t != null) {
                      setStateDialog(() => hora = t);
                    }
                  },
                  child: Text(
                    hora == null
                        ? "Seleccionar hora (opcional)"
                        : "Hora: ${hora!.format(context)}",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titulo.text.isEmpty || fecha == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Título y fecha son obligatorios")),
                  );
                  return;
                }

                String? h;
                if (hora != null) {
                  h = '${hora!.hour.toString().padLeft(2, '0')}:${hora!.minute.toString().padLeft(2, '0')}';
                }

                await ServicioTareas.editarTarea(
                  id,
                  titulo.text,
                  DateFormat('yyyy-MM-dd').format(fecha!),
                  h,
                );

                await ServicioSeguimiento().registrarTareaEditada(SesionAlumno.alumnoId!);

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    ),
  );
}