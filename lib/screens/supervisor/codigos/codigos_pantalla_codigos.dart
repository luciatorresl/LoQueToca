import 'package:flutter/material.dart';
import '../servicios/servicios_supervisor.dart';
import 'codigos_vista_codigo.dart';

class PantallaCodigos extends StatefulWidget {
  const PantallaCodigos({super.key});

  @override
  State<PantallaCodigos> createState() => _PantallaCodigosState();
}

class _PantallaCodigosState extends State<PantallaCodigos> {
  final _servicio = ServicioSupervisor();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BOTÓN CREAR + UNIRSE
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _crearCodigoDialog,
                icon: const Icon(Icons.add),
                label: const Text('Crear grupo'),
              ),
              ElevatedButton.icon(
                onPressed: _unirseAGrupoDialog,
                icon: const Icon(Icons.login),
                label: const Text('Unirse a grupo'),
              ),
            ],
          ),
        ),

        // LISTA
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _servicio.obtenerCodigos(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final codigos = snapshot.data!;
              if (codigos.isEmpty) {
                return const Center(child: Text('No hay grupos'));
              }

              return ListView.builder(
                itemCount: codigos.length,
                itemBuilder: (context, i) {
                  final c = codigos[i];

                  return ListTile(
                    title: Text(
                      c['nombre']?.toString() ?? 'Sin nombre',
                    ),
                    subtitle: Text('${c['alumnosIds'].length} alumnos'),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VistaCodigo(
                            codigoId: c['id'],
                            nombre: c['nombre'],
                          ),
                        ),
                      );
                    },

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ABANDONAR GRUPO
                        IconButton(
                          icon: const Icon(Icons.exit_to_app),
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Abandonar grupo'),
                                content: const Text(
                                  '¿Seguro que quieres abandonar este grupo?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Abandonar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              try {
                                await _servicio.abandonarGrupo(c['id']);
                              } catch (e) {
                                if (mounted) {
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
                          },
                        ),
                        // ELIMINAR GRUPO
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final resultado = await showDialog<String>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Eliminar grupo'),
                                content: const Text(
                                  '¿Qué quieres hacer con los alumnos del grupo?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'cancelar'),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'mantener'),
                                    child: const Text('Mantener alumnos vinculados'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'desvincular'),
                                    child: const Text(
                                      'Desvincular alumnos',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (resultado == 'mantener') {
                              await _servicio.eliminarCodigo(c['id'], desvincular: false);
                            } else if (resultado == 'desvincular') {
                              await _servicio.eliminarCodigo(c['id'], desvincular: true);
                            }
                          }
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _crearCodigoDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del grupo',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nombre = controller.text.trim();

              if (nombre.isEmpty) {
                if (mounted) Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Campo vacío'),
                    content: const Text('Introduce un nombre para el grupo'),
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

              try {
                await _servicio.crearCodigo(nombre);
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Éxito'),
                      content: const Text('Grupo creado correctamente'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                if (mounted) {
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
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _unirseAGrupoDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unirse a un grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del grupo',
            hintText: 'Ej: Grupo A',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = controller.text.trim();

              if (nombre.isEmpty) {
                if (mounted) Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Campo vacío'),
                    content: const Text('Introduce el nombre del grupo'),
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

              try {
                await _servicio.vincularTutorAGrupo(nombre);
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Éxito'),
                      content: const Text('Unido al grupo correctamente'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                if (mounted) {
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
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }
}