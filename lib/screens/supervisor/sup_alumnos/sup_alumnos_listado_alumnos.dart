import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../servicios/servicios_supervisor.dart';
import '../widgets/widgets_tarjeta_alumno.dart';
import 'sup_alumnos_dialogo_vincular.dart';
import 'sup_alumnos_vista_alumno.dart';

class ListadoAlumnos extends StatefulWidget {
  const ListadoAlumnos({super.key});

  @override
  State<ListadoAlumnos> createState() => _ListadoAlumnosState();
}

class _ListadoAlumnosState extends State<ListadoAlumnos> {
  final _servicio = ServicioSupervisor();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumnos'),
        actions: [
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) =>
                  DialogoVincularAlumno(servicio: _servicio),
            ),
            icon: const Icon(Icons.link, color: Colors.blue),
            label: const Text(
              'Vincular',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _servicio.obtenerAlumnos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alumnos = snapshot.data!;
          if (alumnos.isEmpty) {
            return const Center(child: Text('No hay alumnos'));
          }

          // AGRUPAR ALUMNOS POR CODIGO
          final grupos = <String, List<Map<String, dynamic>>>{};
          final sinGrupo = <Map<String, dynamic>>[];

          for (var a in alumnos) {
            final codigoId = a['codigoId'];

            if (codigoId == null) {
              sinGrupo.add(a);
            } else {
              grupos.putIfAbsent(
                codigoId as String,
                () => [],
              ).add(a);
            }
          }

          return ListView(
            children: [
              // GRUPOS
              ...grupos.entries.map((e) {
                final alumnosGrupo = e.value;

                return StreamBuilder<Map<String, dynamic>>(
                  stream: _servicio.obtenerCodigo(e.key),
                  builder: (context, snapshotCodigo) {
                     // NO MOSTRAR SI EL GRUPO NO EXISTE O YA NO ERES TUTOR
                    if (!snapshotCodigo.hasData || snapshotCodigo.data!.isEmpty) {
                      return const SizedBox();
                    }

                    final tutoresIds = List<String>.from(snapshotCodigo.data!['tutoresIds'] ?? []);
                    
                    // SI NO ERES TUTOR DEL GRUPO, NO LO MUESTRA
                    if (!tutoresIds.contains(uid)) {
                      return const SizedBox();
                    }

                    final nombreGrupo = snapshotCodigo.data!['nombre'] ?? 'Sin nombre';

                    return Column(
                      children: [
                        // ENCABEZADO DEL GRUPO
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.blue.shade900,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            nombreGrupo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // ALUMNOS DEL GRUPO
                        ...alumnosGrupo.map((a) {
                          return StreamBuilder<Map<String, dynamic>>(
                            stream: _servicio.obtenerAlumno(a['id']),
                            builder: (context, snapshotAlumno) {
                              if (!snapshotAlumno.hasData) return const SizedBox();

                              final alumnoActual = snapshotAlumno.data!;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: TarjetaAlumno(
                                  nombre: alumnoActual['nombre'] ?? 'Sin nombre',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VistaAlumno(
                                        alumnoId: a['id'],
                                        nombre: alumnoActual['nombre'] ?? 'Sin nombre',
                                      ),
                                    ),
                                  ),
                                  onQuitar: () async {
                                    await _servicio.quitarAlumnoDeGrupo(a['id'], e.key);
                                  },
                                  onDesvincular: () async {
                                    await _servicio.desvincularAlumno(a['id']);
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                        // SEPARADOR ENTRE GRUPOS
                        Divider(
                          height: 20,
                          thickness: 2,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    );
                  },
                );
              }).toList(),

              // SIN GRUPO
              if (sinGrupo.isNotEmpty) ...[
                // ENCABEZADO SIN GRUPO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.blue.shade900,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Sin grupo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // ALUMNOS SIN GRUPO
                ...sinGrupo.map((a) {
                  return StreamBuilder<Map<String, dynamic>>(
                    stream: _servicio.obtenerAlumno(a['id']),
                    builder: (context, snapshotAlumno) {
                      if (!snapshotAlumno.hasData) return const SizedBox();

                      final alumnoActual = snapshotAlumno.data!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: TarjetaAlumno(
                          nombre: alumnoActual['nombre'] ?? 'Sin nombre',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VistaAlumno(
                                alumnoId: a['id'],
                                nombre: alumnoActual['nombre'] ?? 'Sin nombre',
                              ),
                            ),
                          ),
                          onDesvincular: () async {
                            await _servicio.desvincularAlumno(a['id']);
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            ],
          );
        },
      ),
    );
  }
}