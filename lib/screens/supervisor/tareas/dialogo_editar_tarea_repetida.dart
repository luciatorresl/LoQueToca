import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/servicio_tareas_repetidas.dart';

class DialogoEditarTareaRepetida extends StatefulWidget {
  final TareaRepetida regla;

  const DialogoEditarTareaRepetida({super.key, required this.regla});

  @override
  State<DialogoEditarTareaRepetida> createState() =>
      _DialogoEditarTareaRepetidaState();
}

class _DialogoEditarTareaRepetidaState
    extends State<DialogoEditarTareaRepetida> {
  late TextEditingController _titulo;
  TimeOfDay? _hora;
  late PatronRepeticion _patron;
  late Set<int> _diasSemanaSel;
  late int _diaMes;
  late DateTime _fechaInicio;
  DateTime? _fechaFin;
  late bool _conFechaFin;
  bool _cargando = false;

  static const _nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    final r = widget.regla;
    _titulo = TextEditingController(text: r.titulo);

    if (r.hora != null && r.hora!.isNotEmpty) {
      final p = r.hora!.split(':');
      _hora = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    _patron = r.patron;
    _diasSemanaSel = r.diasSemana.toSet();
    _diaMes = r.diaMes ?? 1;
    _fechaInicio = r.fechaInicio;
    _fechaFin = r.fechaFin;
    _conFechaFin = r.fechaFin != null;
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea repetida'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _hora ?? TimeOfDay.now(),
                  initialEntryMode: TimePickerEntryMode.input,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: true,
                    ),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => _hora = t);
              },
              child: Text(
                _hora == null
                    ? 'Hora (opcional)'
                    : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('¿Cada cuánto se repite?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PatronRepeticion>(
              segments: const [
                ButtonSegment(value: PatronRepeticion.diario, label: Text('Diario')),
                ButtonSegment(value: PatronRepeticion.semanal, label: Text('Semanal')),
                ButtonSegment(value: PatronRepeticion.mensual, label: Text('Mensual')),
              ],
              selected: {_patron},
              onSelectionChanged: (s) => setState(() => _patron = s.first),
            ),
            const SizedBox(height: 16),
            if (_patron == PatronRepeticion.semanal) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('¿Qué días de la semana?'),
              ),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final dia = i + 1;
                  final sel = _diasSemanaSel.contains(dia);
                  return FilterChip(
                    label: Text(_nombresDias[i]),
                    selected: sel,
                    onSelected: (s) => setState(() {
                      if (s) {
                        _diasSemanaSel.add(dia);
                      } else {
                        _diasSemanaSel.remove(dia);
                      }
                    }),
                  );
                }),
              ),
            ],
            if (_patron == PatronRepeticion.mensual) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('¿Qué día del mes?'),
              ),
              DropdownButton<int>(
                value: _diaMes,
                items: List.generate(31, (i) {
                  final d = i + 1;
                  return DropdownMenuItem(value: d, child: Text('Día $d'));
                }),
                onChanged: (v) => setState(() => _diaMes = v ?? 1),
              ),
            ],
            const Divider(height: 24),
            ListTile(
              dense: true,
              title: const Text('Empieza el'),
              trailing: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
              onTap: () async {
                final f = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (f != null) setState(() => _fechaInicio = f);
              },
            ),
            SwitchListTile(
              dense: true,
              title: const Text('¿Termina en algún momento?'),
              value: _conFechaFin,
              onChanged: (v) => setState(() {
                _conFechaFin = v;
                if (!v) _fechaFin = null;
              }),
            ),
            if (_conFechaFin)
              ListTile(
                dense: true,
                title: const Text('Termina el'),
                trailing: Text(_fechaFin == null
                    ? 'Elegir'
                    : DateFormat('dd/MM/yyyy').format(_fechaFin!)),
                onTap: () async {
                  final f = await showDatePicker(
                    context: context,
                    initialDate: _fechaFin ?? _fechaInicio,
                    firstDate: _fechaInicio,
                    lastDate: DateTime(2100),
                  );
                  if (f != null) setState(() => _fechaFin = f);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (_titulo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pon un título')),
      );
      return;
    }
    if (_patron == PatronRepeticion.semanal && _diasSemanaSel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un día de la semana')),
      );
      return;
    }

    setState(() => _cargando = true);

    final horaStr = _hora == null
        ? null
        : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';

    try {
      await FirebaseFirestore.instance
          .collection('tareas_repetidas')
          .doc(widget.regla.id)
          .update({
        'titulo': _titulo.text.trim(),
        'hora': horaStr,
        'patron': _patron.name,
        'diasSemana': _diasSemanaSel.toList()..sort(),
        'diaMes': _patron == PatronRepeticion.mensual ? _diaMes : null,
        'fechaInicio': Timestamp.fromDate(_fechaInicio),
        'fechaFin': _fechaFin != null ? Timestamp.fromDate(_fechaFin!) : null,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}