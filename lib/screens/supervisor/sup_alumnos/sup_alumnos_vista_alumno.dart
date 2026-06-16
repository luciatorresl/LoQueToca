
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../screens/auth/servicio_contrasena_alumno.dart';
import '../servicios/servicios_supervisor.dart';
import '../tareas/tareas_crear_tarea.dart';
import '../tareas/tareas_listado_tareas.dart';
import '../tareas/dialogo_crear_tarea_repetida.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sup_alumnos_seguimiento.dart';
import '../../usuario/componentes/foto_perfil_circular.dart';


class VistaAlumno extends StatefulWidget {
  final String alumnoId;
  final String nombre;

  const VistaAlumno({
    super.key,
    required this.alumnoId,
    required this.nombre,
  });

  @override
  State<VistaAlumno> createState() => _VistaAlumnoState();
}

class _VistaAlumnoState extends State<VistaAlumno> with TickerProviderStateMixin {
  late TabController _tabs;
  final _servicio = ServicioSupervisor();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Tareas'),
            Tab(text: 'Seguimiento'),
            Tab(text: 'Perfil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ListadoTareas(alumnoId: widget.alumnoId),
          PantallaSeguimiento(alumnoId: widget.alumnoId),
          _tabPerfil(),
        ],
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton(
              onPressed: () => _elegirTipoDeTarea(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _tabPerfil() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _servicio.obtenerAlumno(widget.alumnoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final alumno = snapshot.data!;
        final nombre = alumno['nombre'] ?? 'Sin nombre';
        final email = alumno['email'] ?? 'Sin email';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // FOTO DE PERFIL
                Center(
                  child: FotoPerfilCircular(
                    fotoBase64: alumno['fotoPerfil'] as String?,
                    tamano: 120,
                  ),
                ),
                const SizedBox(height: 20),

                // NOMBRE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nombre:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // EMAIL
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // UUID
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ID del alumno:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.alumnoId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BOTÓN RESTABLECER CONTRASEÑA
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _mostrarDialogoRestablecer(widget.alumnoId),
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

  void _elegirTipoDeTarea() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.event_note, color: Colors.blue),
              title: const Text('Tarea simple'),
              subtitle: const Text('Una sola vez en una fecha concreta'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CrearTareaScreen(
                      tutorId: '',
                      alumnoId: widget.alumnoId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.green),
              title: const Text('Tarea repetida'),
              subtitle: const Text('Se repite todos los días, semanas o meses'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => DialogoCrearTareaRepetida(
                    alumnoId: widget.alumnoId,
                    creadaPor: 'tutor',
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
}