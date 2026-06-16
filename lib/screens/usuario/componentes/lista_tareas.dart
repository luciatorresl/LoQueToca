import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarjeta_tarea.dart';
import '../../auth/sesion_alumno.dart';
import '../dialogos/dialogo_editar_tarea.dart';
import '../servicios/servicio_tareas.dart';
import '../../supervisor/servicios/servicio_tareas_repetidas.dart';

class ListaTareas extends StatefulWidget {
  final String fechaClave;

  const ListaTareas({
    required this.fechaClave,
    super.key,
  });

  @override
  State<ListaTareas> createState() => _ListaTareasState();
}

class _ListaTareasState extends State<ListaTareas> {
  String get uid => SesionAlumno.alumnoId!;
  final _servicioRepetidas = ServicioTareasRepetidas();

  void _marcarTareasComoVistas(List<QueryDocumentSnapshot> docs) {
    Future.delayed(const Duration(seconds: 2), () async {
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['vistaPorAlumno'] == false) {
          await FirebaseFirestore.instance
              .collection('tareas')
              .doc(doc.id)
              .update({'vistaPorAlumno': true});
        }
      }
    });
  }

  /// Convierte la fechaClave "yyyy-MM-dd" en DateTime
  DateTime _parseFecha(String f) {
    final p = f.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  @override
  Widget build(BuildContext context) {
    final fechaDelDia = _parseFecha(widget.fechaClave);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tareas')
          .where('alumnoId', isEqualTo: uid)
          .where('fecha', isEqualTo: widget.fechaClave)
          .snapshots(),
      builder: (context, snapTareas) {
        if (!snapTareas.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<TareaRepetida>>(
          stream: _servicioRepetidas.obtenerReglas(uid),
          builder: (context, snapReglas) {
            if (!snapReglas.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tareasNormalesDocs = snapTareas.data!.docs;
            final reglas = snapReglas.data!;

            // Tareas normales del dia
            final List<Map<String, dynamic>> items = tareasNormalesDocs
                .map((d) => {
                      'id': d.id,
                      'esVirtual': false,
                      ...d.data() as Map<String, dynamic>,
                    })
                .toList();

            // Reglas que ocurren ese dia y aun NO estan completadas/registradas
            // Una repeticion ya esta "materializada" si existe una tarea normal
            // con tareaRepetidaId == regla.id y fecha == fechaClave.
            for (final regla in reglas) {
              if (!regla.ocurreEn(fechaDelDia)) continue;

              final yaMaterializada = tareasNormalesDocs.any((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['tareaRepetidaId'] == regla.id &&
                    data['fecha'] == widget.fechaClave;
              });

              if (yaMaterializada) continue;

              // Item virtual (no esta en Firestore todavia)
              items.add({
                'id': 'virtual_${regla.id}_${widget.fechaClave}',
                'esVirtual': true,
                'tareaRepetidaId': regla.id,
                'titulo': regla.titulo,
                'hora': regla.hora,
                'fecha': widget.fechaClave,
                'alumnoId': regla.alumnoId,
                'creadaPor': regla.creadaPor,
                'completada': false,
                'puntuada': false,
              });
            }

            // Ordenar por hora
            items.sort((a, b) {
              int convertir(String? h) {
                if (h == null || h.isEmpty) return 9999;
                final p = h.split(':');
                return int.parse(p[0]) * 60 + int.parse(p[1]);
              }
              return convertir(a['hora']).compareTo(convertir(b['hora']));
            });

            if (items.isEmpty) {
              return const Center(child: Text("No hay tareas"));
            }

            // Marcar como vistas las normales (no las virtuales)
            _marcarTareasComoVistas(tareasNormalesDocs);

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final t = items[i];
                final esVirtual = t['esVirtual'] == true;

                return TarjetaTarea(
                  id: t['id'],
                  data: t,
                  onMarcarCompletada: (completada) async {
                    if (esVirtual) {
                      // Materializar la repeticion: crear documento real
                      final ref = await FirebaseFirestore.instance
                          .collection('tareas')
                          .add({
                        'titulo': t['titulo'],
                        'hora': t['hora'],
                        'fecha': t['fecha'],
                        'alumnoId': t['alumnoId'],
                        'creadaPor': t['creadaPor'],
                        'tareaRepetidaId': t['tareaRepetidaId'],
                        'completada': completada ?? false,
                        'puntuada': false,
                        'vistaPorAlumno': true,
                        'createdAt': Timestamp.now(),
                      });
                      return ref.id;
                    } else {
                      await ServicioTareas.marcarCompletada(
                        t['id'],
                        completada ?? false,
                      );
                      return t['id'] as String;
                    }
                  },
                  onEditar: () {
                    if (esVirtual) {
                      // No se pueden editar repeticiones virtuales individualmente
                      return;
                    }
                    mostrarDialogoEditarTarea(context, t['id'], t);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}