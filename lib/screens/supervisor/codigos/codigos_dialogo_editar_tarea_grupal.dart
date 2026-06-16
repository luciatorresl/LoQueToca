import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_tareas.dart';

class DialogoEditarTareaGrupal extends StatefulWidget {
  final Map<String, dynamic> tarea;

  const DialogoEditarTareaGrupal({
    super.key,
    required this.tarea,
  });

  @override
  State<DialogoEditarTareaGrupal> createState() =>
      _DialogoEditarTareaGrupalState();
}

class _DialogoEditarTareaGrupalState
    extends State<DialogoEditarTareaGrupal> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = ServicioTareas();

  late TextEditingController _tituloController;

  DateTime? _fecha;
  TimeOfDay? _hora;

  @override
  void initState() {
    super.initState();

    _tituloController =
        TextEditingController(text: widget.tarea['titulo']);

    // convertir fecha string → DateTime
    if (widget.tarea['fecha'] != null) {
      _fecha = DateTime.parse(widget.tarea['fecha']);
    }

    // convertir hora string → TimeOfDay
    if (widget.tarea['hora'] != null &&
        widget.tarea['hora'].toString().contains(':')) {
      final partes = widget.tarea['hora'].split(':');
      _hora = TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),

      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // TÍTULO
              TextFormField(
                controller: _tituloController,
                decoration:
                    const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Introduce un título'
                        : null,
              ),

              const SizedBox(height: 10),

              // FECHA
              ListTile(
                title: Text(
                  _fecha == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(_fecha!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final seleccion = await showDatePicker(
                    context: context,
                    initialDate: _fecha ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (seleccion != null) {
                    setState(() => _fecha = seleccion);
                  }
                },
              ),

              // HORA
              ListTile(
                title: Text(
                  _hora == null
                      ? 'Seleccionar hora'
                      : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final seleccion = await showTimePicker(
                    context: context,
                    initialTime: _hora ?? TimeOfDay.now(),
                    initialEntryMode: TimePickerEntryMode.input,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          alwaysUse24HourFormat: true,
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (seleccion != null) {
                    setState(() => _hora = seleccion);
                  }
                },
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),

        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final fechaStr = _fecha != null
                ? DateFormat('yyyy-MM-dd').format(_fecha!)
                : null;

            final horaStr = _hora != null
                ? '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}'
                : null;

            await _servicio.editarGrupal(
              widget.tarea['id'],
              titulo: _tituloController.text,
              fecha: fechaStr,
              hora: horaStr,
            );

            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}