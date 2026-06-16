import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../screens/auth/servicio_contrasena_alumno.dart';
import '../servicios/servicios_padre.dart';
import '../../usuario/componentes/foto_perfil_circular.dart';


class PadrePerfil extends StatefulWidget {
  const PadrePerfil({super.key});

  @override
  State<PadrePerfil> createState() => _PadrePerfilState();
}

class _PadrePerfilState extends State<PadrePerfil> {
  final _servicio = ServicioPadre();
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicio.obtenerAlumnoVinculado(),
      builder: (context, snapshotAlumno) {
        if (!snapshotAlumno.hasData || snapshotAlumno.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final nombreAlumno = snapshotAlumno.data!['nombre'] ?? 'Sin nombre';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _tabIndex = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _tabIndex == 0 ? Colors.blue : Colors.grey[300],
                    ),
                    child: Text(
                      'Mi Perfil',
                      style: TextStyle(
                        color: _tabIndex == 0 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _tabIndex = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _tabIndex == 1 ? Colors.blue : Colors.grey[300],
                    ),
                    child: Text(
                      'Perfil de $nombreAlumno',
                      style: TextStyle(
                        color: _tabIndex == 1 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tabIndex == 0 ? _miPerfil() : _perfilHijo(),
            ),
          ],
        );
      },
    );
  }

  Widget _miPerfil() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicio.obtenerPerfil(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final nombre = TextEditingController(text: data['nombre'] ?? '');
        final email = TextEditingController(text: data['email'] ?? '');

        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                      setState(() {});
                    }
                  },
                  child: const Text('Guardar'),
                ),

                // botón añadir hijo
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _anadirHijo,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    'Añadir otro hijo',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _perfilHijo() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicio.obtenerAlumnoVinculado(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final alumno = snapshot.data!;
        final nombre = TextEditingController(text: alumno['nombre'] ?? '');
        final email = TextEditingController(text: alumno['email'] ?? '');
        final alumnoId = alumno['id'];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // FOTO DEL HIJO
                Center(
                  child: FotoPerfilCircular(
                    fotoBase64: alumno['fotoPerfil'] as String?,
                    tamano: 120,
                  ),
                ),
                const SizedBox(height: 20),

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
                    await _servicio.actualizarAlumno(
                      alumnoId,
                      nombre: nombre.text,
                      email: email.text,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guardado')),
                      );
                      setState(() {});
                    }
                  },
                  child: const Text('Guardar'),
                ),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _mostrarDialogoRestablecer(alumnoId),
                  icon: const Icon(Icons.key),
                  label: const Text(
                    'Restablecer contraseña',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoRestablecer(String alumnoId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: const Text(
          '¿Quieres permitir que el alumno cambie su contraseña? ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, permitir'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final servicio = ServicioContrasenaAlumno();
        await servicio.marcarParaRestablecer(alumnoId);

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Cambio activado'),
              content: const Text(
                'Listo. Dile al alumno que en la pantalla de inicio pulse '
                '"¿Has olvidado tu contraseña?", escriba su correo y elija '
                'una contraseña nueva.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _anadirHijo() async {
    final controller = TextEditingController();

    final codigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir otro hijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pídele a tu hijo/a el código que aparece en su perfil '
              'y escríbelo aquí.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Código del hijo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (codigo == null || codigo.isEmpty) return;

    try {
      await _servicio.vincularHijoPorCodigo(codigo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Hijo añadido correctamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}