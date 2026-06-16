import 'package:flutter/material.dart';
import '../../../screens/auth/login_screen.dart';
import '../servicios/servicios_padre.dart';
import 'hijo_activo.dart';
import 'pantalla_seleccion_hijo.dart';
import 'padre_tareas.dart';
import 'padre_perfil.dart';
import 'padre_seguimiento.dart';

class HomePadre extends StatefulWidget {
  const HomePadre({super.key});

  @override
  State<HomePadre> createState() => _HomePadreState();
}

class _HomePadreState extends State<HomePadre> {
  int _indice = 0;
  final _servicio = ServicioPadre();

  void _cambiarHijo() {
    HijoActivo.limpiar();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PantallaSeleccionHijo()),
    );
  }

  Future<void> _cerrarSesion() async {
    HijoActivo.limpiar();
    await _servicio.cerrarSesion();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreHijo = HijoActivo.nombre ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Seguimiento de $nombreHijo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar de hijo',
            onPressed: _cambiarHijo,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(
        index: _indice,
        children: const [
          PadreTareas(),
          PadreSeguimiento(),
          PadrePerfil(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tareas'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Seguimiento'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}