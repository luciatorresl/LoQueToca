import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

const List<int> _umbralesEtapa = [50, 150, 300, 600];
const List<String> _imagenesEtapa = [
  'assets/planta/planta_2.png',
  'assets/planta/planta_3.png',
  'assets/planta/planta_4.png',
  'assets/planta/planta_5.png',
];

class ResultadoPuntos {
  final int puntosGanados;
  final bool hayBonus;
  final int puntosBonus;
  final int puntosTotales;
  final bool subioEtapa;          // si la tarea ha hecho cruzar un umbral
  final String? imagenEtapaNueva; // imagen de la nueva etapa, si sube

  ResultadoPuntos({
    required this.puntosGanados,
    required this.hayBonus,
    required this.puntosBonus,
    required this.puntosTotales,
    required this.subioEtapa,
    required this.imagenEtapaNueva,
  });

  int get totalGanadoAhora => puntosGanados + puntosBonus;
}

class ServicioPuntos {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  Future<ResultadoPuntos> sumarPorTareaCompletada(String alumnoId) async {
    final docRef = _firestore.collection('usuarios').doc(alumnoId);

    return _firestore.runTransaction<ResultadoPuntos>((tx) async {
      final snapshot = await tx.get(docRef);
      final data = snapshot.data() ?? {};

      final int puntosAntes = (data['puntos'] ?? 0) as int;
      final int completadasActuales =
          (data['tareasCompletadasTotales'] ?? 0) as int;

      final int puntosGanados = 2 + _random.nextInt(4);
      final int nuevasCompletadas = completadasActuales + 1;
      final bool hayBonus = nuevasCompletadas % 3 == 0;
      final int puntosBonus = hayBonus ? 20 : 0;

      final int nuevosPuntos = puntosAntes + puntosGanados + puntosBonus;

      // Comprobar si ha cruzado un umbral
      bool subioEtapa = false;
      String? imagenEtapaNueva;
      for (int i = 0; i < _umbralesEtapa.length; i++) {
        final umbral = _umbralesEtapa[i];
        if (puntosAntes < umbral && nuevosPuntos >= umbral) {
          subioEtapa = true;
          imagenEtapaNueva = _imagenesEtapa[i];
        }
      }

      tx.update(docRef, {
        'puntos': nuevosPuntos,
        'tareasCompletadasTotales': nuevasCompletadas,
      });

      return ResultadoPuntos(
        puntosGanados: puntosGanados,
        hayBonus: hayBonus,
        puntosBonus: puntosBonus,
        puntosTotales: nuevosPuntos,
        subioEtapa: subioEtapa,
        imagenEtapaNueva: imagenEtapaNueva,
      );
    });
  }

  Stream<int> escucharPuntos(String alumnoId) {
    return _firestore.collection('usuarios').doc(alumnoId).snapshots().map(
      (doc) {
        final data = doc.data() ?? {};
        return (data['puntos'] ?? 0) as int;
      },
    );
  }
}