import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServicioTareas {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> crear({
    required String titulo,
    required String fecha,
    String? hora,
    required String alumnoId,
  }) async {
    await _firestore.collection('tareas').add({
      'titulo': titulo.trim(),
      'fecha': fecha,
      'hora': hora,
      'alumnoId': alumnoId,
      'creadaPor': 'tutor',
      'completada': false,
      'vistaPorAlumno': false,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> obtener(String alumnoId) {
    return _firestore
        .collection('tareas')
        .where('alumnoId', isEqualTo: alumnoId)
        .snapshots()
        .map((snapshot) {
          final tareas =
              snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

          // ORDENAMOS EN APP (NO EN FIRESTORE)
          tareas.sort((a, b) {
            final fechaA = a['fecha'] ?? '';
            final fechaB = b['fecha'] ?? '';

            final horaA = a['hora'] ?? '';
            final horaB = b['hora'] ?? '';

            return (fechaA + horaA).compareTo(fechaB + horaB);
          });

          return tareas;
        });
  }

  Future<void> editar(
    String tareaId, {
    String? titulo,
    String? fecha,
    String? hora,
  }) async {
    final updates = <String, dynamic>{};
    if (titulo != null) updates['titulo'] = titulo.trim();
    if (fecha != null) updates['fecha'] = fecha;
    if (hora != null) updates['hora'] = hora;
    if (updates.isEmpty) return;

    await _firestore.collection('tareas').doc(tareaId).update(updates);
  }

  Future<void> marcarCompletada(String tareaId, bool completada) async {
    await _firestore.collection('tareas').doc(tareaId).update({
      'completada': completada,
      'completadaEn': completada ? Timestamp.now() : null,
    });
  }

  Future<void> eliminar(String tareaId) async {
    await _firestore.collection('tareas').doc(tareaId).delete();
  }

  // Tareas grupales (por código)
    Future<void> crearGrupal({
    required String titulo,
    required String fecha,
    String? hora,
    required String codigoId,
  }) async {
    final codigoDoc = await _firestore.collection('codigos').doc(codigoId).get();

    if (!codigoDoc.exists) {
      throw Exception('El grupo no existe');
    }

    final alumnosIds = List<String>.from(codigoDoc.data()?['alumnosIds'] ?? []);

    final ref = await _firestore.collection('tareas_grupales').add({
      'titulo': titulo.trim(),
      'fecha': fecha,
      'hora': hora,
      'codigoId': codigoId,
      'createdAt': Timestamp.now(),
    });

    for (final alumnoId in alumnosIds) {
      await _firestore.collection('tareas').add({
        'titulo': titulo.trim(),
        'fecha': fecha,
        'hora': hora,
        'alumnoId': alumnoId,
        'completada': false,
        'esGrupal': true,
        'tareaGrupalId': ref.id,
        'creadaPor': 'tutor',
        'vistaPorAlumno': false,
      });
    }
  }

  Stream<List<Map<String, dynamic>>> obtenerGrupales(String codigoId) {
    return _firestore
        .collection('tareas_grupales')
        .where('codigoId', isEqualTo: codigoId)
        .snapshots()
        .map((snapshot) {
          final tareas = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          tareas.sort((a, b) {
            final fA = a['fecha'] ?? '';
            final fB = b['fecha'] ?? '';
            final hA = a['hora'] ?? '';
            final hB = b['hora'] ?? '';

            return (fA + hA).compareTo(fB + hB);
          });

          return tareas;
        });
  }

  Future<void> eliminarGrupal(String tareaGrupalId) async {
    final firestore = _firestore;

    await firestore
        .collection('tareas_grupales')
        .doc(tareaGrupalId)
        .delete();

    final tareas = await firestore
        .collection('tareas')
        .where('tareaGrupalId', isEqualTo: tareaGrupalId)
        .get();

    for (final doc in tareas.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> editarGrupal(
    String tareaGrupalId, {
    String? titulo,
    String? fecha,
    String? hora,
  }) async {
    final updates = <String, dynamic>{};
    if (titulo != null) updates['titulo'] = titulo.trim();
    if (fecha != null) updates['fecha'] = fecha;
    if (hora != null) updates['hora'] = hora;
    if (updates.isEmpty) return;

    await _firestore
        .collection('tareas_grupales')
        .doc(tareaGrupalId)
        .update(updates);

    final tareas = await _firestore
        .collection('tareas')
        .where('tareaGrupalId', isEqualTo: tareaGrupalId)
        .get();

    for (final doc in tareas.docs) {
      await doc.reference.update(updates);
    }
  }

  String obtenerUID() => _auth.currentUser!.uid;
}

