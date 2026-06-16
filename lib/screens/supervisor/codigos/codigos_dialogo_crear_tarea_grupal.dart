import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_tareas.dart';

class DialogoCrearTareaGrupal extends StatefulWidget {
  final String codigoId;

  const DialogoCrearTareaGrupal({super.key, required this.codigoId});

  @override
  State<DialogoCrearTareaGrupal> createState() => _DialogoCrearTareaGrupalState();
}

class _DialogoCrearTareaGrupalState extends State<DialogoCrearTareaGrupal> {
  final _titulo = TextEditingController();
  DateTime? _fecha;
  TimeOfDay? _hora;
  bool _cargando = false;
  final _servicio = ServicioTareas();

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear tarea grupal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final f = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (f != null) setState(() => _fecha = f);
            },
            child: Text(_fecha == null ? 'Seleccionar fecha' : DateFormat('dd/MM/yyyy').format(_fecha!)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
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
                  ? 'Hora (opcional)'
                  : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _cargando ? null : _crear, child: const Text('Crear')),
      ],
    );
  }

  Future<void> _crear() async {
    if (_titulo.text.isEmpty || _fecha == null) return;

    setState(() => _cargando = true);

    try {
      String? hora;

      if (_hora != null) {
        hora =
            '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';
      }

      await _servicio.crearGrupal(
        titulo: _titulo.text,
        fecha: DateFormat('yyyy-MM-dd').format(_fecha!),
        hora: hora,
        codigoId: widget.codigoId,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}
