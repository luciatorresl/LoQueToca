import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioSeguimiento {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Formato fecha YYYY-MM-DD sin libreria externa.
  String _claveFecha(DateTime fecha) {
    final f = DateTime(fecha.year, fecha.month, fecha.day);
    final mm = f.month.toString().padLeft(2, '0');
    final dd = f.day.toString().padLeft(2, '0');
    return '${f.year}-$mm-$dd';
  }

  String _docDiarioId(String alumnoId, DateTime fecha) =>
      '${alumnoId}_${_claveFecha(fecha)}';

  ////////////////////////////////////////////////////////////////////////////////

  /// cuando el alumno entra, devuelve los dias que llevaba sin entrar ANTES de esta entrada (0 si ha entrado hoy)
  Future<int> registrarEntrada(String alumnoId) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // Leer ultima entrada ANTES de actualizar
    final userRef = _firestore.collection('usuarios').doc(alumnoId);
    final snapPrev = await userRef.get();
    final ultimaEntradaPrev = (snapPrev.data()?['ultimaEntrada'] as Timestamp?)?.toDate();

    int diasSinEntrar = 0;
    if (ultimaEntradaPrev != null) {
      final ultimoDia = DateTime(
        ultimaEntradaPrev.year,
        ultimaEntradaPrev.month,
        ultimaEntradaPrev.day,
      );
      diasSinEntrar = hoy.difference(ultimoDia).inDays;
    }

    // Marcar entrada del dia
    await _firestore
        .collection('actividad_diaria')
        .doc(_docDiarioId(alumnoId, hoy))
        .set({
      'alumnoId': alumnoId,
      'fecha': Timestamp.fromDate(hoy),
      'entro': true,
    }, SetOptions(merge: true));

    // Actualizar ultima entrada + racha
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      final ultimoDiaTs = data['rachaUltimoDia'] as Timestamp?;
      final rachaActual = (data['rachaActual'] ?? 0) as int;

      int nuevaRacha;
      if (ultimoDiaTs == null) {
        nuevaRacha = 1;
      } else {
        final ultimoDia = DateTime(
          ultimoDiaTs.toDate().year,
          ultimoDiaTs.toDate().month,
          ultimoDiaTs.toDate().day,
        );
        final diffDias = hoy.difference(ultimoDia).inDays;
        if (diffDias == 0) {
          nuevaRacha = rachaActual;
        } else if (diffDias == 1) {
          nuevaRacha = rachaActual + 1;
        } else {
          nuevaRacha = 1;
        }
      }

      tx.update(userRef, {
        'ultimaEntrada': Timestamp.fromDate(ahora),
        'rachaActual': nuevaRacha,
        'rachaUltimoDia': Timestamp.fromDate(hoy),
      });
    });

    return diasSinEntrar;
  }

  /// cuando el alumno sale Suma los segundos que ha estado a hoy y al total
  Future<void> registrarSalida(
    String alumnoId,
    int segundosSesion,
  ) async {
    if (segundosSesion <= 0) return;

    final hoy = DateTime.now();

    // Suma al doc del dia
    await _firestore
        .collection('actividad_diaria')
        .doc(_docDiarioId(alumnoId, hoy))
        .set({
      'alumnoId': alumnoId,
      'fecha': Timestamp.fromDate(DateTime(hoy.year, hoy.month, hoy.day)),
      'segundosEnApp': FieldValue.increment(segundosSesion),
    }, SetOptions(merge: true));

    // Suma a los totales del alumno (para calcular media de sesion)
    await _firestore.collection('usuarios').doc(alumnoId).update({
      'totalSegundosApp': FieldValue.increment(segundosSesion),
      'totalSesiones': FieldValue.increment(1),
    });
  }

  Future<void> _sumarContadorDia(String alumnoId, String campo) async {
    final hoy = DateTime.now();
    await _firestore
        .collection('actividad_diaria')
        .doc(_docDiarioId(alumnoId, hoy))
        .set({
      'alumnoId': alumnoId,
      'fecha': Timestamp.fromDate(DateTime(hoy.year, hoy.month, hoy.day)),
      campo: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> registrarTareaCompletada(String alumnoId) =>
      _sumarContadorDia(alumnoId, 'tareasCompletadas');

  Future<void> registrarTareaEditada(String alumnoId) =>
      _sumarContadorDia(alumnoId, 'tareasEditadas');

  Future<void> registrarTareaAnadida(String alumnoId) =>
      _sumarContadorDia(alumnoId, 'tareasAnadidas');



  ////////////////////////////////////////////////////////////////////////////////

  Future<ResumenSeguimiento> obtenerResumen(String alumnoId) async {
    final userDoc =
        await _firestore.collection('usuarios').doc(alumnoId).get();
    final userData = userDoc.data() ?? {};

    final ultimaEntradaTs = userData['ultimaEntrada'] as Timestamp?;
    final puntos = (userData['puntos'] ?? 0) as int;
    final rachaActual = (userData['rachaActual'] ?? 0) as int;
    final totalSeg = (userData['totalSegundosApp'] ?? 0) as int;
    final totalSes = (userData['totalSesiones'] ?? 0) as int;

    // Si la racha es de hace mas de 1 dia -> la mostramos como 0
    final rachaUltimoDiaTs = userData['rachaUltimoDia'] as Timestamp?;
    int rachaMostrar = rachaActual;
    if (rachaUltimoDiaTs != null) {
      final hoy = DateTime.now();
      final ultimo = rachaUltimoDiaTs.toDate();
      final diff = DateTime(hoy.year, hoy.month, hoy.day)
          .difference(DateTime(ultimo.year, ultimo.month, ultimo.day))
          .inDays;
      if (diff > 1) rachaMostrar = 0;
    }

    final diasSinEntrar = ultimaEntradaTs == null
        ? null
        : DateTime.now()
            .difference(DateTime(
              ultimaEntradaTs.toDate().year,
              ultimaEntradaTs.toDate().month,
              ultimaEntradaTs.toDate().day,
            ))
            .inDays;

    final mediaSegSesion = totalSes > 0 ? (totalSeg / totalSes).round() : 0;

    // Sumar metricas de la ultima semana (hoy y 6 dias atras)
    final ahora = DateTime.now();
    final hace7Dias = DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(const Duration(days: 6));

    final semanaQuery = await _firestore
        .collection('actividad_diaria')
        .where('alumnoId', isEqualTo: alumnoId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(hace7Dias))
        .get();

    int completadasSemana = 0;
    int editadasSemana = 0;
    int anadidasSemana = 0;
    for (final doc in semanaQuery.docs) {
      final d = doc.data();
      completadasSemana += (d['tareasCompletadas'] ?? 0) as int;
      editadasSemana += (d['tareasEditadas'] ?? 0) as int;
      anadidasSemana += (d['tareasAnadidas'] ?? 0) as int;
    }

    return ResumenSeguimiento(
      ultimaEntrada: ultimaEntradaTs?.toDate(),
      diasSinEntrar: diasSinEntrar,
      rachaActual: rachaMostrar,
      tareasCompletadasSemana: completadasSemana,
      tareasAnadidasSemana: anadidasSemana,
      tareasEditadasSemana: editadasSemana,
      mediaSegundosSesion: mediaSegSesion,
      puntos: puntos,
    );
  }
}

class ResumenSeguimiento {
  final DateTime? ultimaEntrada;
  final int? diasSinEntrar;
  final int rachaActual;
  final int tareasCompletadasSemana;
  final int tareasAnadidasSemana;
  final int tareasEditadasSemana;
  final int mediaSegundosSesion;
  final int puntos;

  ResumenSeguimiento({
    required this.ultimaEntrada,
    required this.diasSinEntrar,
    required this.rachaActual,
    required this.tareasCompletadasSemana,
    required this.tareasAnadidasSemana,
    required this.tareasEditadasSemana,
    required this.mediaSegundosSesion,
    required this.puntos,
  });
}