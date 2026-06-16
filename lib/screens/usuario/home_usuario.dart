import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_tareas.dart';
import 'pantallas/pantalla_logros.dart';
import 'pantallas/pantalla_perfil.dart';
import 'dialogos/dialogo_bienvenida.dart';
import 'dialogos/dialogo_tarea_nueva.dart';
import '../auth/sesion_alumno.dart';

class HomeUsuario extends StatefulWidget {
  final int diasSinEntrar;

  const HomeUsuario({
    super.key,
    this.diasSinEntrar = 0,
  });

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
  int _index = 0;
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarAvisosAlEntrar();
    });
  }

  Future<void> _mostrarAvisosAlEntrar() async {
    // Mostrar primero "Te echabamos de menos" si lleva dias sin entrar
    if (widget.diasSinEntrar >= 2 && mounted) {
      await mostrarDialogoBienvenidaSiToca(context, widget.diasSinEntrar);
    }

    if (!mounted) return;

    // Comprobar si hay tareas nuevas (no vistas y no completadas)
    final alumnoId = SesionAlumno.alumnoId!;
    final query = await FirebaseFirestore.instance
        .collection('tareas')
        .where('alumnoId', isEqualTo: alumnoId)
        .where('vistaPorAlumno', isEqualTo: false)
        .get();

    // Rango visible de hoy a hoy+6 (los 7 dias que muestra la agenda)
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final finVentana = hoy.add(const Duration(days: 6));

    String clave(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final hoyStr = clave(hoy);
    final finStr = clave(finVentana);

    // Contar solo las pendientes (no completadas) Y dentro del rango visible
    final nuevasPendientes = query.docs.where((d) {
      final data = d.data();
      if (data['completada'] == true) return false;

      final fecha = data['fecha'];
      if (fecha == null || fecha is! String) return false;

      // Comparacion de fechas en formato 'yyyy-MM-dd'
      return fecha.compareTo(hoyStr) >= 0 && fecha.compareTo(finStr) <= 0;
    }).length;

    if (nuevasPendientes > 0 && mounted) {
      await mostrarDialogoTareaNueva(context, nuevasPendientes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi agenda: LO QUE TOCA')),
      body: IndexedStack(
        index: _index,
        children: [
          PantallaInicio(fechaInicial: _fechaSeleccionada),
          PantallaTareas(
            onTareaCreada: (fecha) {
              setState(() {
                _fechaSeleccionada = fecha;
                _index = 0;
              });
            },
          ),
          const PantallaLogros(),
          const PantallaPerfil(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.add_task), label: 'Tareas'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Logros'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}