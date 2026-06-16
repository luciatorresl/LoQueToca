import 'package:flutter/material.dart';
import '../servicios/servicios_supervisor.dart';

class DialogoVincularAlumno extends StatefulWidget {
  final ServicioSupervisor servicio;

  const DialogoVincularAlumno({super.key, required this.servicio});

  @override
  State<DialogoVincularAlumno> createState() => _DialogoVincularAlumnoState();
}

class _DialogoVincularAlumnoState extends State<DialogoVincularAlumno> {
  final _controller = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular alumno'),
      content: TextField(
        controller: _controller,
        enabled: !_cargando,
        decoration: const InputDecoration(labelText: 'UID del alumno'),
      ),
      actions: [
        TextButton(onPressed: _cargando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _cargando ? null : _vincular,
          child: _cargando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Vincular'),
        ),
      ],
    );
  }

  Future<void> _vincular() async {
    final id = _controller.text.trim();

    if (id.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Campo vacío'),
          content: const Text('Introduce el UID del alumno'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Guardamos el context del PADRE antes de cerrar el diálogo
    final navigator = Navigator.of(context);
    final padreContext = context;

    setState(() => _cargando = true);

    try {
      await widget.servicio.vincularAlumno(id);

      // 1. Cerrar el diálogo de vincular
      if (mounted) navigator.pop();

      // 2. Mostrar SnackBar usando el navigator (no el context muerto)
      ScaffoldMessenger.of(padreContext).showSnackBar(
        const SnackBar(
          content: Text('Alumno vinculado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Mostrar error sin cerrar el diálogo (el usuario puede corregir)
      setState(() => _cargando = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('$e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
