import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de repeticion
enum PatronRepeticion { diario, semanal, mensual }

class TareaRepetida {
  final String id;
  final String titulo;
  final String? hora;
  final String? alumnoId;        // null en la regla maestra grupal
  final String creadaPor;       // 'tutor' o 'padre'
  final PatronRepeticion patron;
  final List<int> diasSemana;   // 1=lun, 7=dom (solo si patron=semanal)
  final int? diaMes;            // 1-31 (solo si patron=mensual)
  final DateTime fechaInicio;
  final DateTime? fechaFin;     // null = indefinido

  // Campos grupales
  final bool esGrupal;                 // true si la regla proviene de un grupo
  final String? codigoId;              // grupo (solo en la regla maestra grupal)
  final String? tareaGrupalRepetidaId;

  TareaRepetida({
    required this.id,
    required this.titulo,
    required this.hora,
    required this.alumnoId,
    required this.creadaPor,
    required this.patron,
    required this.diasSemana,
    required this.diaMes,
    required this.fechaInicio,
    required this.fechaFin,
    this.esGrupal = false,
    this.codigoId,
    this.tareaGrupalRepetidaId,
  });

  factory TareaRepetida.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TareaRepetida(
      id: doc.id,
      titulo: d['titulo'] ?? '',
      hora: d['hora'],
      alumnoId: d['alumnoId'],
      creadaPor: d['creadaPor'] ?? '',
      patron: PatronRepeticion.values
          .firstWhere((p) => p.name == (d['patron'] ?? 'diario')),
      diasSemana: List<int>.from(d['diasSemana'] ?? []),
      diaMes: d['diaMes'],
      fechaInicio: (d['fechaInicio'] as Timestamp).toDate(),
      fechaFin: d['fechaFin'] != null
          ? (d['fechaFin'] as Timestamp).toDate()
          : null,
      esGrupal: d['esGrupal'] ?? false,
      codigoId: d['codigoId'],
      tareaGrupalRepetidaId: d['tareaGrupalRepetidaId'],
    );
  }

  /// Comprueba si esta regla genera una aparicion en la fecha dada.
  bool ocurreEn(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);

    if (dia.isBefore(inicio)) return false;
    if (fechaFin != null) {
      final fin = DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day);
      if (dia.isAfter(fin)) return false;
    }

    switch (patron) {
      case PatronRepeticion.diario:
        return true;
      case PatronRepeticion.semanal:
        return diasSemana.contains(dia.weekday);
      case PatronRepeticion.mensual:
        return dia.day == diaMes;
    }
  }
}

class ServicioTareasRepetidas {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///////////////////////////////////////
  //  REPETIDAS INDIVIDUALES (por alumno)
  ///////////////////////////////////////
  // Crear una nueva regla
  Future<void> crear({
    required String titulo,
    required String? hora,
    required String alumnoId,
    required String creadaPor,
    required PatronRepeticion patron,
    required List<int> diasSemana,
    required int? diaMes,
    required DateTime fechaInicio,
    required DateTime? fechaFin,
  }) async {
    await _firestore.collection('tareas_repetidas').add({
      'titulo': titulo.trim(),
      'hora': hora,
      'alumnoId': alumnoId,
      'creadaPor': creadaPor,
      'patron': patron.name,
      'diasSemana': diasSemana,
      'diaMes': diaMes,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin) : null,
      'createdAt': Timestamp.now(),
    });
  }

  // Stream con todas las reglas activas del alumno
  Stream<List<TareaRepetida>> obtenerReglas(String alumnoId) {
    return _firestore
        .collection('tareas_repetidas')
        .where('alumnoId', isEqualTo: alumnoId)
        .snapshots()
        .map((snap) => snap.docs.map(TareaRepetida.fromDoc).toList());
  }

  // Borrar una regla (afecta a todas las apariciones futuras)
  Future<void> borrar(String reglaId) async {
    await _firestore.collection('tareas_repetidas').doc(reglaId).delete();
  }

  ///////////////////////////////////////
  //  REPETIDAS GRUPALES
  ///////////////////////////////////////
  // Crear una nueva regla repetida grupal
  Future<void> crearGrupal({
    required String titulo,
    required String? hora,
    required String codigoId,
    required String creadaPor,
    required PatronRepeticion patron,
    required List<int> diasSemana,
    required int? diaMes,
    required DateTime fechaInicio,
    required DateTime? fechaFin,
  }) async {
    final codigoDoc = await _firestore.collection('codigos').doc(codigoId).get();
 
    if (!codigoDoc.exists) {
      throw Exception('El grupo no existe');
    }
 
    final alumnosIds = List<String>.from(codigoDoc.data()?['alumnosIds'] ?? []);
 
    final datosComunes = <String, dynamic>{
      'titulo': titulo.trim(),
      'hora': hora,
      'creadaPor': creadaPor,
      'patron': patron.name,
      'diasSemana': diasSemana,
      'diaMes': diaMes,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin) : null,
      'createdAt': Timestamp.now(),
    };
 
    // Regla maestra grupal
    final ref = await _firestore.collection('tareas_grupales_repetidas').add({
      ...datosComunes,
      'codigoId': codigoId,
    });
 
    // Una copia por alumno
    for (final alumnoId in alumnosIds) {
      await _firestore.collection('tareas_repetidas').add({
        ...datosComunes,
        'alumnoId': alumnoId,
        'esGrupal': true,
        'tareaGrupalRepetidaId': ref.id,
      });
    }
  }
 
  // Stream con las reglas repetidas grupales de un grupo
  Stream<List<TareaRepetida>> obtenerReglasGrupales(String codigoId) {
    return _firestore
        .collection('tareas_grupales_repetidas')
        .where('codigoId', isEqualTo: codigoId)
        .snapshots()
        .map((snap) => snap.docs.map(TareaRepetida.fromDoc).toList());
  }
 
  // Editar una regla grupal y propagar a todas las copias por alumno
  Future<void> editarGrupal(
    String tareaGrupalRepetidaId, {
    required String titulo,
    required String? hora,
    required PatronRepeticion patron,
    required List<int> diasSemana,
    required int? diaMes,
    required DateTime fechaInicio,
    required DateTime? fechaFin,
  }) async {
    final updates = <String, dynamic>{
      'titulo': titulo.trim(),
      'hora': hora,
      'patron': patron.name,
      'diasSemana': diasSemana,
      'diaMes': diaMes,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin) : null,
    };
 
    // Actualizar la regla maestra
    await _firestore
        .collection('tareas_grupales_repetidas')
        .doc(tareaGrupalRepetidaId)
        .update(updates);
 
    // Propagar a las copias por alumno
    final copias = await _firestore
        .collection('tareas_repetidas')
        .where('tareaGrupalRepetidaId', isEqualTo: tareaGrupalRepetidaId)
        .get();
 
    for (final doc in copias.docs) {
      await doc.reference.update(updates);
    }
  }
 
  // Borrar una regla grupal y todas sus copias por alumno
  Future<void> borrarGrupal(String tareaGrupalRepetidaId) async {
    // Borrar la regla maestra
    await _firestore
        .collection('tareas_grupales_repetidas')
        .doc(tareaGrupalRepetidaId)
        .delete();
 
    // Borrar las copias por alumno
    final copias = await _firestore
        .collection('tareas_repetidas')
        .where('tareaGrupalRepetidaId', isEqualTo: tareaGrupalRepetidaId)
        .get();
 
    for (final doc in copias.docs) {
      await doc.reference.delete();
    }
  }
}