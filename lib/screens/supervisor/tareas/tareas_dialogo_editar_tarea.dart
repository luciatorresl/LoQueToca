import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_tareas.dart';

class DialogoEditarTarea extends StatefulWidget {
  final String tareaId;
  final Map<String, dynamic> tarea;

  const DialogoEditarTarea({
    super.key,
    required this.tareaId,
    required this.tarea,
  });

  @override
  State<DialogoEditarTarea> createState() => _DialogoEditarTareaState();
}

class _DialogoEditarTareaState extends State<DialogoEditarTarea> {
  late TextEditingController _titulo;
  late DateTime _fecha;
  TimeOfDay? _hora;
  bool _cargando = false;
  final _servicio = ServicioTareas();

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.tarea['titulo']);
    _fecha = DateTime.parse(widget.tarea['fecha']);

    if (widget.tarea['hora'] != null && widget.tarea['hora'].toString().isNotEmpty) {
      final p = widget.tarea['hora'].split(':');
      _hora = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final f = await showDatePicker(
                context: context,
                initialDate: _fecha,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (f != null) setState(() => _fecha = f);
            },
            child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final t = await showTimePicker(
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
              if (t != null) setState(() => _hora = t);
            },
            child: Text(
              _hora == null
                  ? 'Hora'
                  : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _cargando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _cargando = true);
    try {
      String? hora;
      if (_hora != null) {
        hora = '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';
      }
      await _servicio.editar(
        widget.tareaId,
        titulo: _titulo.text,
        fecha: DateFormat('yyyy-MM-dd').format(_fecha),
        hora: hora,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}
