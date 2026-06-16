import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../servicios/servicios_tareas.dart';
import '../tareas/dialogo_crear_tarea_repetida.dart';

class CrearTareaScreen extends StatefulWidget {
  final String tutorId;
  final String alumnoId;

  const CrearTareaScreen({
    super.key,
    required this.tutorId,
    required this.alumnoId,
  });

  @override
  State<CrearTareaScreen> createState() => _CrearTareaScreenState();
}

class _CrearTareaScreenState extends State<CrearTareaScreen> {
  final _tituloController = TextEditingController();
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _cargando = false;
  final _servicio = ServicioTareas();

  Future<void> _guardarTarea() async {
    if (_tituloController.text.isEmpty || _fechaSeleccionada == null) return;

    setState(() => _cargando = true);

    final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);

    String? hora;
    if (_horaSeleccionada != null) {
      hora =
          '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}';
    }

    try {
      await _servicio.crear(
        titulo: _tituloController.text,
        fecha: fecha,
        hora: hora,
        alumnoId: widget.alumnoId,
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration:
                  const InputDecoration(labelText: 'Título de la tarea'),
            ),

            const SizedBox(height: 16),

            // FECHA
            ElevatedButton(
              onPressed: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (fecha != null) {
                  setState(() {
                    _fechaSeleccionada = fecha;
                  });
                }
              },
              child: Text(
                _fechaSeleccionada == null
                    ? 'Seleccionar fecha'
                    : DateFormat.yMd('es')
                        .format(_fechaSeleccionada!),
              ),
            ),

            const SizedBox(height: 10),

            // HORA (OPCIONAL)
            ElevatedButton(
              onPressed: () async {
                final hora = await showTimePicker(
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

                if (hora != null) {
                  setState(() {
                    _horaSeleccionada = hora;
                  });
                }
              },
              child: Text(
                _horaSeleccionada == null
                    ? 'Añadir hora (opcional)'
                    : '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}',
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _cargando ? null : _guardarTarea,
              child: const Text('Guardar tarea'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }
}