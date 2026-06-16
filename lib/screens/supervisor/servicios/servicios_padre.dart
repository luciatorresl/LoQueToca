import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../padre/hijo_activo.dart';

class ServicioPadre {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser!.uid;
  String? get _hijoActivoId => HijoActivo.id;

  // Datos del hijo actualmente seleccionado
  Stream<Map<String, dynamic>> obtenerAlumnoVinculado() {
    final hijoId = _hijoActivoId;
    if (hijoId == null) return Stream.value({});

    return _firestore
        .collection('usuarios')
        .doc(hijoId)
        .snapshots()
        .map((doc) => {'id': hijoId, ...?doc.data()});
  }

  // Lista de todos los hijos del padre
  Future<List<Map<String, dynamic>>> obtenerHijos() async {
    final padreDoc = await _firestore.collection('usuarios').doc(_uid).get();
    final hijosIds = List<String>.from(padreDoc.data()?['hijosIds'] ?? []);

    final hijos = <Map<String, dynamic>>[];
    for (final hijoId in hijosIds) {
      final hijoDoc =
          await _firestore.collection('usuarios').doc(hijoId).get();
      if (hijoDoc.exists) {
        hijos.add({'id': hijoId, ...?hijoDoc.data()});
      }
    }
    return hijos;
  }

  // Vincular un nuevo hijo con el codigo individual del alumno
  Future<String> vincularHijoPorCodigo(String codigo) async {
    final codigoDoc = await _firestore
        .collection('codigos_invitacion')
        .doc(codigo)
        .get();

    if (!codigoDoc.exists) {
      throw Exception('Código no válido');
    }

    final data = codigoDoc.data() ?? {};
    final alumnoId = data['usuarioId'];
    if (alumnoId == null) {
      throw Exception('Este código no corresponde a un alumno');
    }

    final alumnoDoc =
        await _firestore.collection('usuarios').doc(alumnoId).get();
    if (!alumnoDoc.exists || alumnoDoc.data()?['rol'] != 'alumno') {
      throw Exception('Este código no corresponde a un alumno');
    }

    final padreDoc = await _firestore.collection('usuarios').doc(_uid).get();
    final hijosIds = List<String>.from(padreDoc.data()?['hijosIds'] ?? []);
    if (hijosIds.contains(alumnoId)) {
      throw Exception('Este hijo ya está vinculado');
    }

    await _firestore.collection('usuarios').doc(_uid).update({
      'hijosIds': FieldValue.arrayUnion([alumnoId]),
    });
    await _firestore.collection('usuarios').doc(alumnoId).update({
      'padresIds': FieldValue.arrayUnion([_uid]),
    });

    return alumnoId;
  }

  // Tareas del hijo activo
  Stream<List<Map<String, dynamic>>> obtenerTareasAlumno() {
    final hijoId = _hijoActivoId;
    if (hijoId == null) return Stream.value([]);

    return _firestore
        .collection('tareas')
        .where('alumnoId', isEqualTo: hijoId)
        .snapshots()
        .map((snapshot) {
      final tareas = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      tareas.sort((a, b) {
        int min(String? h) {
          if (h == null || h.isEmpty) return 9999;
          final p = h.split(':');
          return int.parse(p[0]) * 60 + int.parse(p[1]);
        }
        return min(a['hora']).compareTo(min(b['hora']));
      });

      return tareas;
    });
  }

  Future<void> crearTarea({
    required String titulo,
    required String fecha,
    String? hora,
  }) async {
    final hijoId = _hijoActivoId;
    if (hijoId == null) throw Exception('No hay hijo seleccionado');

    await _firestore.collection('tareas').add({
      'titulo': titulo.trim(),
      'fecha': fecha,
      'hora': hora,
      'alumnoId': hijoId,
      'creadaPor': 'padre',
      'completada': false,
      'vistaPorAlumno': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> editarTarea(
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

  Future<void> eliminarTarea(String tareaId) async {
    await _firestore.collection('tareas').doc(tareaId).delete();
  }

  Stream<Map<String, dynamic>> obtenerPerfil() {
    return _firestore
        .collection('usuarios')
        .doc(_uid)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> actualizarPerfil({String? nombre, String? email}) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (email != null) updates['email'] = email;
    if (updates.isEmpty) return;
    await _firestore.collection('usuarios').doc(_uid).update(updates);
  }

  Future<void> actualizarAlumno(String alumnoId, {String? nombre, String? email}) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (email != null) updates['email'] = email;
    if (updates.isEmpty) return;
    await _firestore.collection('usuarios').doc(alumnoId).update(updates);
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}