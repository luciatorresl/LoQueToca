import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../auth/sesion_alumno.dart';
import '../componentes/seccion_perfil_usuario.dart';
import '../componentes/foto_perfil_circular.dart';
import '../servicios/servicio_foto_perfil.dart';

class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  
  @override
  Widget build(BuildContext context) {
    final uid = SesionAlumno.alumnoId!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FOTO DE PERFIL
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final foto = data?['fotoPerfil'] as String?;

              return Column(
                children: [
                  FotoPerfilCircular(fotoBase64: foto, tamano: 140),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _elegirOrigenFoto(context, uid),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      foto == null ? 'Añadir foto' : 'Cambiar foto',
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Perfil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const SeccionPerfilUsuario(),
          const SizedBox(height: 20),
          _grupoActual(),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaCodigos()),
              );
            },
            child: const Text('Códigos'),
          ),
        ],
      ),
    );
  }

  // Pregunta al alumno si quiere camara o galeria y guarda la foto
  void _elegirOrigenFoto(BuildContext context, String alumnoId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿De dónde sacas la foto?'),
        content: const Text('Elige una opción'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
            onPressed: () {
              Navigator.pop(dialogContext);
              _guardarFoto(context, alumnoId, 'galeria');
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
            onPressed: () {
              Navigator.pop(dialogContext);
              _guardarFoto(context, alumnoId, 'camara');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _guardarFoto(
    BuildContext context,
    String alumnoId,
    String fuente,
  ) async {
    try {
      final ok = await ServicioFotoPerfil()
          .seleccionarYGuardar(alumnoId, fuente);

      if (!context.mounted) return;

      if (ok) {
        _mostrarMensaje(
          context,
          icono: Icons.check_circle,
          colorIcono: Colors.green,
          titulo: '¡Foto guardada!',
          mensaje: 'Tu foto se ha guardado bien.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      _mostrarMensaje(
        context,
        icono: Icons.error,
        colorIcono: Colors.red,
        titulo: 'No se ha podido guardar tu foto',
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _mostrarMensaje(
    BuildContext context, {
    required IconData icono,
    required Color colorIcono,
    required String titulo,
    required String mensaje,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: colorIcono, size: 80),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 140,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grupoActual() {
    final uid = SesionAlumno.alumnoId!;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final codigoId = userData?['codigoId'];

        // Si no tiene grupo, no mostrar nada
        if (codigoId == null) {
          return const SizedBox();
        }

        // Obtener datos del grupo
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('codigos')
              .doc(codigoId)
              .snapshots(),
          builder: (context, snapshotGrupo) {
            if (!snapshotGrupo.hasData) {
              return const SizedBox();
            }

            final grupoData = snapshotGrupo.data?.data() as Map<String, dynamic>?;
            final nombreGrupo = grupoData?['nombre'] ?? 'Sin nombre';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MI GRUPO:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombreGrupo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PantallaCodigos extends StatefulWidget {
  const PantallaCodigos({super.key});

  @override
  State<PantallaCodigos> createState() => _PantallaCodigosState();
}

class _PantallaCodigosState extends State<PantallaCodigos> {
  String get uid => SesionAlumno.alumnoId!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Códigos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gestionar mis códigos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoIntroducirCodigo(),
              icon: const Icon(Icons.input),
              label: const Text('Introducir nombre de grupo'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _mostrarCodigoIndividual(),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Mi código individual'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoIntroducirCodigo() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Introducir nombre de grupo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Nombre del grupo',
            labelStyle: TextStyle(fontSize: 16),
            hintText: 'Ej: INGLES-1B',
            hintStyle: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombreGrupo = controller.text.trim();
              if (nombreGrupo.isEmpty) {
                Navigator.pop(context);
                _mostrarMensajeGrande(
                  context,
                  'Por favor, introduce un nombre de grupo',
                  Colors.orange,
                );
                return;
              }

              try {
                final query = await FirebaseFirestore.instance
                    .collection('codigos')
                    .where('nombre', isEqualTo: nombreGrupo)
                    .limit(1)
                    .get();

                if (query.docs.isEmpty) {
                  Navigator.pop(context);
                  _mostrarMensajeGrande(
                    context,
                    'Grupo no encontrado 😟',
                    Colors.red,
                  );
                  return;
                }

                final doc = query.docs.first;
                final codigoId = doc.id;
                final supervisorId = doc['supervisorId'];

                // comprobar si el alumno ya pertenece a otro grupo
                final userDoc = await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .get();
                final grupoActualId = userDoc.data()?['codigoId'];

                if (grupoActualId != null && grupoActualId != codigoId) {
                  // Obtener el nombre del grupo actual para el mensaje
                  final grupoActualDoc = await FirebaseFirestore.instance
                      .collection('codigos')
                      .doc(grupoActualId)
                      .get();
                  final nombreGrupoActual =
                      grupoActualDoc.data()?['nombre'] ?? 'otro grupo';

                  Navigator.pop(context);
                  _mostrarMensajeGrande(
                    context,
                    'Ya perteneces al grupo "$nombreGrupoActual" ✅',
                    Colors.orange,
                  );
                  return;
                }

                final alumnosIds = List<String>.from(doc['alumnosIds'] ?? []);
                if (alumnosIds.contains(uid)) {
                  Navigator.pop(context);
                  _mostrarMensajeGrande(
                    context,
                    'Ya estás en este grupo ✅',
                    Colors.blue,
                  );
                  return;
                }

                final batch = FirebaseFirestore.instance.batch();

                batch.update(
                  doc.reference,
                  {'alumnosIds': FieldValue.arrayUnion([uid])},
                );

                batch.update(
                  FirebaseFirestore.instance.collection('usuarios').doc(uid),
                  {'codigoId': codigoId},
                );

                batch.update(
                  FirebaseFirestore.instance.collection('usuarios').doc(uid),
                  {'tutoresIds': FieldValue.arrayUnion([supervisorId])},
                );

                batch.update(
                  FirebaseFirestore.instance.collection('usuarios').doc(supervisorId),
                  {'alumnosIds': FieldValue.arrayUnion([uid])},
                );

                await batch.commit();

                final tareasGrupales = await FirebaseFirestore.instance
                    .collection('tareas_grupales')
                    .where('codigoId', isEqualTo: codigoId)
                    .get();

                for (final tareaGrupal in tareasGrupales.docs) {
                  final data = tareaGrupal.data();

                  await FirebaseFirestore.instance.collection('tareas').add({
                    'titulo': data['titulo'] ?? '',
                    'fecha': data['fecha'],
                    'hora': data['hora'],
                    'alumnoId': uid,
                    'completada': false,
                    'esGrupal': true,
                    'tareaGrupalId': tareaGrupal.id,
                    'creadaPor': 'tutor',
                  });
                }

                // Replicar reglas repetidas grupales
                final reglasGrupales = await FirebaseFirestore.instance
                    .collection('tareas_grupales_repetidas')
                    .where('codigoId', isEqualTo: codigoId)
                    .get();

                final ahora = DateTime.now();
                final inicioDeHoy = DateTime(ahora.year, ahora.month, ahora.day);

                for (final regla in reglasGrupales.docs) {
                  final data = regla.data();

                  final fechaInicioOriginal =
                      (data['fechaInicio'] as Timestamp).toDate();
                  final fechaInicioCopia =
                      fechaInicioOriginal.isBefore(inicioDeHoy)
                          ? inicioDeHoy
                          : fechaInicioOriginal;

                  await FirebaseFirestore.instance
                      .collection('tareas_repetidas')
                      .add({
                    'titulo': data['titulo'] ?? '',
                    'hora': data['hora'],
                    'alumnoId': uid,
                    'creadaPor': data['creadaPor'] ?? 'tutor',
                    'patron': data['patron'],
                    'diasSemana': data['diasSemana'] ?? [],
                    'diaMes': data['diaMes'],
                    'fechaInicio': Timestamp.fromDate(fechaInicioCopia),
                    'fechaFin': data['fechaFin'],
                    'esGrupal': true,
                    'tareaGrupalRepetidaId': regla.id,
                    'createdAt': Timestamp.now(),
                  });
                }

                Navigator.pop(context);

                _mostrarMensajeGrande(
                  context,
                  '¡Te has unido al grupo!\n$nombreGrupo ✅',
                  Colors.green,
                );
              } catch (e) {
                Navigator.pop(context);
                _mostrarMensajeGrande(
                  context,
                  'Error: $e',
                  Colors.red,
                );
              }
            },
            child: const Text('Unirse', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajeGrande(BuildContext context, String mensaje, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarCodigoIndividual() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>;
      String codigoIndividual = userData['codigoIndividual'] ?? '';

      if (codigoIndividual.isEmpty) {
        const uuid = Uuid();
        codigoIndividual = uuid.v4().substring(0, 8).toUpperCase();

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .update({
          'codigoIndividual': codigoIndividual,
        });

        await FirebaseFirestore.instance
            .collection('codigos_invitacion')
            .doc(codigoIndividual)
            .set({
          'usuarioId': uid,
          'fechaCreacion': Timestamp.now(),
          'activo': true,
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Tu código individual es:'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                GestureDetector(
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código copiado al portapapeles'),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      codigoIndividual,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}