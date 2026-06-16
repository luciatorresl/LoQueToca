import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilidades/formatos_fecha.dart';
import '../../auth/sesion_alumno.dart';
import '../servicios/servicio_seguimiento.dart';

Future<void> mostrarDialogoCrearTarea(
  BuildContext context, {
  required Function(DateTime) onTareaCreada,
}) async {
  final titulo = TextEditingController();
  DateTime? fecha;
  TimeOfDay? hora;

  final String uid = SesionAlumno.alumnoId!;

  List<DateTime> siguientes7Dias =
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Nueva tarea"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titulo,
                decoration: const InputDecoration(labelText: "Título *"),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialEntryMode: TimePickerEntryMode.input,
                    initialTime: TimeOfDay.now(),
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
                      ? "Hora (opcional)"
                      : hora!.format(context),
                ),
              ),
            ],
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
                  h =
                      '${hora!.hour.toString().padLeft(2, '0')}:${hora!.minute.toString().padLeft(2, '0')}';
                }

                await FirebaseFirestore.instance
                    .collection('tareas')
                    .add({
                  'titulo': titulo.text,
                  'fecha': DateFormat('yyyy-MM-dd').format(fecha!),
                  'hora': h,
                  'alumnoId': uid,
                  'completada': false,
                  'creadaPor': 'alumno',
                });

                await ServicioSeguimiento().registrarTareaAnadida(uid);

                // Llamar la callback para cambiar la fecha en PantallaInicio
                onTareaCreada(fecha!);

                Navigator.pop(context);
              },
              child: const Text("Crear"),
            ),
          ],
        );
      },
    ),
  );
}