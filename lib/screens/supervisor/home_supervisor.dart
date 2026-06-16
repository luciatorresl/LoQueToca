
import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import 'servicios/servicios_supervisor.dart';
import 'sup_alumnos/sup_alumnos_listado_alumnos.dart';
import 'codigos/codigos_pantalla_codigos.dart';
import 'perfil_supervisor.dart';

class HomeSupervisor extends StatefulWidget {
  const HomeSupervisor({super.key});

  @override
  State<HomeSupervisor> createState() => _HomeSupervisorState();
}

class _HomeSupervisorState extends State<HomeSupervisor> {
  int _indice = 0;
  final _servicio = ServicioSupervisor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // LOGOUT ARRIBA A LA DERECHA
      appBar: AppBar(
        title: const Text('Supervisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _servicio.cerrarSesion();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),

      body: IndexedStack(
        index: _indice,
        children: [
          const ListadoAlumnos(),
          const PantallaCodigos(),
          const PerfilSupervisor(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        onTap: (i) {
          setState(() => _indice = i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Alumnos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}