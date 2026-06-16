import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class ServicioSupervisor {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser!.uid;

  //////// ALUMNOS /////////
  Stream<List<Map<String, dynamic>>> obtenerAlumnos() {
    return _firestore
        .collection('usuarios')
        .doc(_uid)
        .snapshots()
        .switchMap((doc) {
          final data = doc.data() ?? {};
          final alumnosDirectos = List<String>.from(data['alumnosIds'] ?? []);
          
          return _firestore
              .collection('codigos')
              .snapshots()
              .switchMap((codigosSnapshot) {

                //OBTENER ALUMNOS DE GRUPOS DONDE SOY TUTOR
                final alumnosDeGrupos = <String>{};
                
                for (final codigoDoc in codigosSnapshot.docs) {
                  final tutoresIds = List<String>.from(codigoDoc.data()['tutoresIds'] ?? []);

                  // SOLO SI ESTOY EN tutoresIds (tutor actual, no supervisor original)
                  if (tutoresIds.contains(_uid)) {
                    final alumnosIds = List<String>.from(codigoDoc.data()['alumnosIds'] ?? []);
                    alumnosDeGrupos.addAll(alumnosIds);
                  }
                }

                // COMBINAR ALUMNOS DIRECTOS + ALUMNOS DE GRUPOS
                final todosIds = <String>{...alumnosDirectos, ...alumnosDeGrupos}.toList();

                if (todosIds.isEmpty) {
                  return Stream.value([]);
                }

                // Obtener datos de todos los alumnos
                return _firestore
                    .collection('usuarios')
                    .where(FieldPath.documentId, whereIn: todosIds)
                    .snapshots()
                    .map((snapshot) => snapshot.docs
                        .map((doc) => {
                          'id': doc.id,
                          'nombre': doc['nombre'] ?? 'Sin nombre',
                          'codigoId': doc['codigoId'],
                        })
                        .toList());
              });
        });
  }

  Future<void> vincularAlumno(String alumnoId) async {
    // VERIFICAR QUE EL ALUMNO EXISTE
    final alumnoDoc = await _firestore.collection('usuarios').doc(alumnoId).get();
    
    if (!alumnoDoc.exists) {
      throw 'El alumno no existe';
    }

    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('usuarios').doc(alumnoId),
      {'codigoId': null},
    );

    batch.update(
      _firestore.collection('usuarios').doc(_uid),
      {'alumnosIds': FieldValue.arrayUnion([alumnoId])},
    );

    await batch.commit();
  }

  Future<void> desvincularAlumno(String alumnoId) async {
    final alumno = await _firestore.collection('usuarios').doc(alumnoId).get();
    final codigoId = alumno['codigoId'];

    if (codigoId != null) {
      await _firestore.collection('codigos').doc(codigoId).update({
        'alumnosIds': FieldValue.arrayRemove([alumnoId])
      });
      await _firestore.collection('usuarios').doc(alumnoId).update({
        'codigoId': null
      });
    }

    await _firestore.collection('usuarios').doc(_uid).update({
      'alumnosIds': FieldValue.arrayRemove([alumnoId])
    });
  }

  // ////// CÓDIGOS ////////
  Stream<List<Map<String, dynamic>>> obtenerCodigos() {
    return _firestore
        .collection('codigos')
        .snapshots()
        .map((snapshot) {
          final todosLos = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          // FILTRAR: solo mostrar grupos donde soy tutor o supervisor
          final misCodigos = todosLos.where((codigo) {
            final tutoresIds = List<String>.from(codigo['tutoresIds'] ?? []);
            
            return tutoresIds.contains(_uid);
          }).toList();

          return misCodigos;
        });
  }

  Future<void> crearCodigo(String nombre) async {
    // VERIFICAR QUE NO EXISTA UN GRUPO CON ESE NOMBRE
    final existente = await _firestore
        .collection('codigos')
        .where('nombre', isEqualTo: nombre)
        .limit(1)
        .get();

    if (existente.docs.isNotEmpty) {
      throw 'Ya existe un grupo con ese nombre';
    }

    await _firestore.collection('codigos').add({
      'nombre': nombre,
      'supervisorId': _uid,
      'tutoresIds': [_uid],
      'alumnosIds': [],
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> eliminarCodigo(String codigoId, {required bool desvincular}) async {
    final firestore = _firestore;

    // Obtener el código CON sus alumnos
    final codigoDoc = await firestore.collection('codigos').doc(codigoId).get();
    if (!codigoDoc.exists) return;

    final alumnosIds = List<String>.from(codigoDoc['alumnosIds'] ?? []);

    // Procesar alumnos
    for (final alumnoId in alumnosIds) {
      // SIEMPRE desvinculación del grupo
      await firestore.collection('usuarios').doc(alumnoId).update({
        'codigoId': null
      });

      // SOLO SI desvincular == true, quitar del tutor
      if (desvincular) {
        await firestore.collection('usuarios').doc(_uid).update({
          'alumnosIds': FieldValue.arrayRemove([alumnoId])
        });
      }
    }

    // Borrar tareas grupales SIMPLES + copias
    final tareasGrupales = await firestore
        .collection('tareas_grupales')
        .where('codigoId', isEqualTo: codigoId)
        .get();

    for (final doc in tareasGrupales.docs) {
      final tareaId = doc.id;

      final tareas = await firestore
          .collection('tareas')
          .where('tareaGrupalId', isEqualTo: tareaId)
          .get();

      for (final t in tareas.docs) {
        await t.reference.delete();
      }

      await doc.reference.delete();
    }

    // Borrar reglas repetidas grupales + sus copias por alumno
    final reglasGrupales = await firestore
        .collection('tareas_grupales_repetidas')
        .where('codigoId', isEqualTo: codigoId)
        .get();

    for (final regla in reglasGrupales.docs) {
      final copias = await firestore
          .collection('tareas_repetidas')
          .where('tareaGrupalRepetidaId', isEqualTo: regla.id)
          .get();

      for (final copia in copias.docs) {
        await copia.reference.delete();
      }

      await regla.reference.delete();
    }

    // Eliminar código
    await firestore.collection('codigos').doc(codigoId).delete();
  }

  Future<void> quitarAlumnoDeGrupo(String alumnoId, String codigoId) async {
    final firestore = _firestore;

    // Buscar tareas grupales de este código
    final tareasGrupales = await firestore
        .collection('tareas_grupales')
        .where('codigoId', isEqualTo: codigoId)
        .get();

    // Buscar y borrar las copias del alumno (tareas SIMPLES)
    for (final tareaGrupal in tareasGrupales.docs) {
      final tareaGrupalId = tareaGrupal.id;

      final tareasAlumno = await firestore
          .collection('tareas')
          .where('alumnoId', isEqualTo: alumnoId)
          .where('tareaGrupalId', isEqualTo: tareaGrupalId)
          .get();

      for (final tarea in tareasAlumno.docs) {
        await tarea.reference.delete();
      }
    }

    // Borrar las copias repetidas del alumno vinculadas a este grupo
    final reglasGrupales = await firestore
        .collection('tareas_grupales_repetidas')
        .where('codigoId', isEqualTo: codigoId)
        .get();

    for (final regla in reglasGrupales.docs) {
      final copiasAlumno = await firestore
          .collection('tareas_repetidas')
          .where('alumnoId', isEqualTo: alumnoId)
          .where('tareaGrupalRepetidaId', isEqualTo: regla.id)
          .get();

      for (final copia in copiasAlumno.docs) {
        await copia.reference.delete();
      }
    }

    // Desvinculación del grupo
    await firestore.collection('codigos').doc(codigoId).update({
      'alumnosIds': FieldValue.arrayRemove([alumnoId])
    });
    
    await firestore.collection('usuarios').doc(alumnoId).update({
      'codigoId': null
    });
  }

  Future<void> anadirAlumnoAGrupo(String alumnoId, String codigoId) async {
    // VERIFICAR QUE EL ALUMNO EXISTE
    final alumnoDoc = await _firestore.collection('usuarios').doc(alumnoId).get();
    
    if (!alumnoDoc.exists) {
      throw 'El alumno no existe';
    }

    // comprobar que no pertenezca ya a otro grupo
    final grupoActualId = alumnoDoc.data()?['codigoId'];
    
    if (grupoActualId != null && grupoActualId != codigoId) {
      final grupoActualDoc = await _firestore.collection('codigos').doc(grupoActualId).get();
      final nombreGrupoActual = grupoActualDoc.data()?['nombre'] ?? 'otro grupo';
      
      throw 'Este alumno ya pertenece al grupo "$nombreGrupoActual". '
            'Hay que sacarlo de ese grupo antes de añadirlo a uno nuevo.';
    }

    final firestore = _firestore;
    final ahora = Timestamp.now();

    final batch = firestore.batch();

    // Actualizar el código
    batch.update(
      firestore.collection('codigos').doc(codigoId),
      {'alumnosIds': FieldValue.arrayUnion([alumnoId])},
    );

    // Actualizar el alumno
    batch.update(
      firestore.collection('usuarios').doc(alumnoId),
      {'codigoId': codigoId},
    );

    // Actualizar el tutor
    batch.update(
      firestore.collection('usuarios').doc(_uid),
      {'alumnosIds': FieldValue.arrayUnion([alumnoId])},
    );

    await batch.commit();

    // DESPUÉS del batch, obtener tareas grupales FUTURAS
    final tareasGrupales = await firestore
        .collection('tareas_grupales')
        .where('codigoId', isEqualTo: codigoId)
        .get();

    final fechaHoy = DateTime.now();
    final fechaHoyStr = '${fechaHoy.year}-${fechaHoy.month.toString().padLeft(2, '0')}-${fechaHoy.day.toString().padLeft(2, '0')}';

    // Crear copias SOLO de las futuras (tareas grupales SIMPLES)
    for (final tareaGrupal in tareasGrupales.docs) {
      final data = tareaGrupal.data();
      final fechaTarea = data['fecha'] ?? '';

      // Solo si la tarea es hoy o futura
      if (fechaTarea.compareTo(fechaHoyStr) >= 0) {
        await firestore.collection('tareas').add({
          'titulo': data['titulo'] ?? '',
          'fecha': data['fecha'],
          'hora': data['hora'],
          'alumnoId': alumnoId,
          'completada': false,
          'esGrupal': true,
          'tareaGrupalId': tareaGrupal.id,
          'creadaPor': 'tutor',
        });
      }
    }

    // Replicar las reglas repetidas grupales del grupo
    final reglasGrupales = await firestore
        .collection('tareas_grupales_repetidas')
        .where('codigoId', isEqualTo: codigoId)
        .get();

    final inicioDeHoy = DateTime(fechaHoy.year, fechaHoy.month, fechaHoy.day);   

    for (final regla in reglasGrupales.docs) {
      final data = regla.data();

      // Si la regla empezaba antes de hoy, el alumno nuevo solo la ve a partir de hoy
      final fechaInicioOriginal = (data['fechaInicio'] as Timestamp).toDate();
      final fechaInicioCopia = fechaInicioOriginal.isBefore(inicioDeHoy)
          ? inicioDeHoy
          : fechaInicioOriginal;

      await firestore.collection('tareas_repetidas').add({
        'titulo': data['titulo'] ?? '',
        'hora': data['hora'],
        'alumnoId': alumnoId,
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
  }

  Stream<Map<String, dynamic>> obtenerCodigo(String codigoId) {
    return _firestore.collection('codigos').doc(codigoId).snapshots().map((doc) => doc.data() ?? {});
  }

  // PERFIL SUPERVISOR
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

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  //ALUMNO INDIVIDUAL
  Stream<Map<String, dynamic>> obtenerAlumno(String alumnoId) {
    return _firestore.collection('usuarios').doc(alumnoId).snapshots().map((doc) => doc.data() ?? {});
  }

  Future<void> actualizarAlumno(String alumnoId, {String? nombre, String? email}) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (email != null) updates['email'] = email;
    if (updates.isEmpty) return;

    await _firestore.collection('usuarios').doc(alumnoId).update(updates);
  }

  Future<void> vincularTutorAGrupo(String nombreGrupo) async {
    final codigoQuery = await _firestore
        .collection('codigos')
        .where('nombre', isEqualTo: nombreGrupo)
        .limit(1)
        .get();

    if (codigoQuery.docs.isEmpty) {
      throw 'Grupo no encontrado';
    }

    final codigoId = codigoQuery.docs.first.id;
    final codigoData = codigoQuery.docs.first.data();
    
    final tutoresIds = List<String>.from(codigoData['tutoresIds'] ?? []);

    if (tutoresIds.contains(_uid)) {
      throw 'Ya eres tutor de este grupo';
    }

    tutoresIds.add(_uid);

    await _firestore.collection('codigos').doc(codigoId).update({
      'tutoresIds': tutoresIds,
    });
  }

  // ABANDONAR GRUPO
  Future<void> abandonarGrupo(String codigoId) async {
    final codigoDoc = await _firestore.collection('codigos').doc(codigoId).get();

    if (!codigoDoc.exists) {
      throw 'El grupo no existe';
    }

    final tutoresIds = List<String>.from(codigoDoc.data()?['tutoresIds'] ?? []);
    final supervisorId = codigoDoc.data()?['supervisorId'] ?? '';

    //SI ERES EL CREADOR Y ÚNICO TUTOR, NO PUEDES ABANDONAR
    if (supervisorId == _uid && tutoresIds.length <= 1) {
      throw 'No puedes abandonar si eres el único tutor';
    }

    // SI ERES EL CREADOR PERO HAY OTROS TUTORES, EL PRIMERO DE LA LISTA SE CONVIERTE EN NUEVO SUPERVISOR
    if (supervisorId == _uid && tutoresIds.length > 1) {
      tutoresIds.remove(_uid);
      
      await _firestore.collection('codigos').doc(codigoId).update({
        'tutoresIds': tutoresIds,
        'supervisorId': tutoresIds.first,
      });
    } else {
      //SI NO ERES EL CREADOR, SOLO ABANDONA
      tutoresIds.remove(_uid);
      
      await _firestore.collection('codigos').doc(codigoId).update({
        'tutoresIds': tutoresIds,
      });
    }
  }

  // OBTENER DATOS DE USUARIO (para tutores)
  Stream<Map<String, dynamic>> obtenerUsuario(String usuarioId) {
    return _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

}





