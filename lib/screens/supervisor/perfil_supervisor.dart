import 'package:flutter/material.dart';
import 'servicios/servicios_supervisor.dart';

class PerfilSupervisor extends StatefulWidget {
  const PerfilSupervisor({super.key});

  @override
  State<PerfilSupervisor> createState() => _PerfilSupervisorState();
}

class _PerfilSupervisorState extends State<PerfilSupervisor> {
  final _servicio = ServicioSupervisor();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicio.obtenerPerfil(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final nombre = TextEditingController(text: data['nombre'] ?? '');
        final email = TextEditingController(text: data['email'] ?? '');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DATOS PERSONALES
              const Text(
                'Datos personales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await _servicio.actualizarPerfil(
                    nombre: nombre.text,
                    email: email.text,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guardado')),
                    );
                  }
                },
                child: const Text('Guardar cambios'),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}