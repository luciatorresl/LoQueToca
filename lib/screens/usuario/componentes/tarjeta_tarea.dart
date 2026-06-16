import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/servicio_tareas.dart';
import '../servicios/servicio_puntos.dart';
import '../dialogos/dialogo_recompensa.dart';
import '../dialogos/dialogo_planta_crece.dart';
import '../../auth/sesion_alumno.dart';
import '../servicios/servicio_seguimiento.dart';

class TarjetaTarea extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final Future<String?> Function(bool?) onMarcarCompletada;
  final VoidCallback onEditar;

  const TarjetaTarea({
    required this.id,
    required this.data,
    required this.onMarcarCompletada,
    required this.onEditar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final esCreadadoPorAlumno = data['creadaPor'] == 'alumno';
    final colorTexto = esCreadadoPorAlumno ? Colors.black : Colors.blue;
    final esNueva = data['vistaPorAlumno'] == false;

    return ListTile(
      leading: Checkbox(
        value: data['completada'] ?? false,
        onChanged: (bool? nuevoValor) async {
          if (nuevoValor == true) {
            final confirmar = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('¿Has completado la tarea?'),
                content: Text('TAREA: ${data['titulo']}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('NO'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('SÍ'),
                  ),
                ],
              ),
            );

            if (confirmar == true) {
              final yaPuntuada = data['puntuada'] == true;           
              final idReal = await onMarcarCompletada(true);

              if (!yaPuntuada && idReal != null && context.mounted) {
                final alumnoId = SesionAlumno.alumnoId!;
                final resultado =
                    await ServicioPuntos().sumarPorTareaCompletada(alumnoId);
                await ServicioTareas.marcarComoPuntuada(idReal);
                await ServicioSeguimiento().registrarTareaCompletada(alumnoId);

                if (context.mounted) {
                  await mostrarDialogoRecompensa(context, resultado);
                }
                // Si sube de etapa, mostrar segundo dialogo
                if (resultado.subioEtapa &&
                    resultado.imagenEtapaNueva != null &&
                    context.mounted) {
                  await mostrarDialogoPlantaCrece(context, resultado.imagenEtapaNueva!,
                  );
                }
              }
            }
          } else {
            await onMarcarCompletada(false);
          }
        },
      ),
      title: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              data['hora'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (esNueva)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '¡NUEVA!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    data['titulo'],
                    style: TextStyle(
                      color: colorTexto,
                      fontWeight: esNueva ? FontWeight.bold : FontWeight.normal,
                      decoration: (data['completada'] ?? false)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: esCreadadoPorAlumno
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEditar,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Eliminar tarea'),
                        content: const Text(
                            '¿Estás seguro de que quieres eliminar esta tarea?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await ServicioTareas.eliminarTarea(id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
    );
  }
}