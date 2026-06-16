import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicio_tareas_repetidas.dart';

class DialogoCrearTareaRepetidaGrupal extends StatefulWidget {
  final String codigoId;
  final String creadaPor;

  const DialogoCrearTareaRepetidaGrupal({
    super.key,
    required this.codigoId,
    this.creadaPor = 'tutor',
  });

  @override
  State<DialogoCrearTareaRepetidaGrupal> createState() =>
      _DialogoCrearTareaRepetidaGrupalState();
}

class _DialogoCrearTareaRepetidaGrupalState
    extends State<DialogoCrearTareaRepetidaGrupal> {
  final _titulo = TextEditingController();
  TimeOfDay? _hora;
  PatronRepeticion _patron = PatronRepeticion.diario;
  final Set<int> _diasSemanaSel = {}; // 1-7
  int _diaMes = 1; // 1-31
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin; // null = indefinido
  bool _conFechaFin = false;
  bool _cargando = false;

  static const _nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva tarea repetida grupal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),

            // HORA opcional
            ElevatedButton(
              onPressed: () async {
                final t = await showTimePicker(
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
                if (t != null) setState(() => _hora = t);
              },
              child: Text(
                _hora == null
                    ? 'Hora (opcional)'
                    : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const Divider(height: 24),

            // TIPO DE REPETICION
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

            // OPCION SEMANAL: elegir dias
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

            // OPCION MENSUAL: elegir dia del mes
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

            // FECHA DE INICIO
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

            // FECHA FIN opcional
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
          child: const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (_titulo.text.trim().isEmpty) {
      _mostrarError('Pon un título');
      return;
    }
    if (_patron == PatronRepeticion.semanal && _diasSemanaSel.isEmpty) {
      _mostrarError('Elige al menos un día de la semana');
      return;
    }
    if (_conFechaFin && _fechaFin == null) {
      _mostrarError('Elige una fecha de fin o desactiva la opción');
      return;
    }

    setState(() => _cargando = true);

    final horaStr = _hora == null
        ? null
        : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';

    try {
      await ServicioTareasRepetidas().crearGrupal(
        titulo: _titulo.text,
        hora: horaStr,
        codigoId: widget.codigoId,
        creadaPor: widget.creadaPor,
        patron: _patron,
        diasSemana: _diasSemanaSel.toList()..sort(),
        diaMes: _patron == PatronRepeticion.mensual ? _diaMes : null,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}