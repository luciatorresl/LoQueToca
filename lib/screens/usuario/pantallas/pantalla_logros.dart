import 'package:flutter/material.dart';
import '../../auth/sesion_alumno.dart';
import '../servicios/servicio_puntos.dart';

class _EtapaPlanta {
  final int puntosMinimos;
  final String imagen;
  const _EtapaPlanta(this.puntosMinimos, this.imagen);
}

const List<_EtapaPlanta> _etapas = [
  _EtapaPlanta(0,    'assets/planta/planta_1.png'),
  _EtapaPlanta(50,   'assets/planta/planta_2.png'),
  _EtapaPlanta(150,  'assets/planta/planta_3.png'),
  _EtapaPlanta(300,  'assets/planta/planta_4.png'),
  _EtapaPlanta(600,  'assets/planta/planta_5.png'),
];

// Puntos para llegar al maximo crecimiento (igual al ultimo umbral).
const int _puntosMaximaEtapa = 600;

class PantallaLogros extends StatelessWidget {
  const PantallaLogros({super.key});

  /// Devuelve la etapa actual segun los puntos.
  _EtapaPlanta _etapaActual(int puntos) {
    _EtapaPlanta actual = _etapas.first;
    for (final etapa in _etapas) {
      if (puntos >= etapa.puntosMinimos) {
        actual = etapa;
      }
    }
    return actual;
  }

  /// Devuelve los puntos del siguiente nivel, o null si ya esta en el maximo.
  int? _puntosSiguienteEtapa(int puntos) {
    for (final etapa in _etapas) {
      if (puntos < etapa.puntosMinimos) {
        return etapa.puntosMinimos;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioPuntos();
    final alumnoId = SesionAlumno.alumnoId!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<int>(
        stream: servicio.escucharPuntos(alumnoId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final puntos = snapshot.data!;
          final etapaActual = _etapaActual(puntos);
          final siguiente = _puntosSiguienteEtapa(puntos);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // PANEL DE PUNTOS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Mis puntos',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$puntos',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Image.asset(
                          etapaActual.imagen,
                          key: ValueKey(etapaActual.imagen),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (siguiente != null)
                    Column(
                      children: [
                        const Text(
                          'Mi planta está creciendo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BarraProgreso(
                          puntosActuales: puntos,
                          puntosSiguiente: siguiente,
                          puntosEtapaActual: etapaActual.puntosMinimos,
                        ),
                      ],
                    )
                  else
                    const Text(
                      '¡Tu planta ha florecido!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  final int puntosActuales;
  final int puntosSiguiente;
  final int puntosEtapaActual;

  const _BarraProgreso({
    required this.puntosActuales,
    required this.puntosSiguiente,
    required this.puntosEtapaActual,
  });

  @override
  Widget build(BuildContext context) {
    final rango = puntosSiguiente - puntosEtapaActual;
    final avance = puntosActuales - puntosEtapaActual;
    final progreso = rango > 0 ? (avance / rango).clamp(0.0, 1.0) : 1.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 16,
            backgroundColor: Colors.grey.shade300,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.lightGreen),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$puntosActuales / $puntosSiguiente puntos',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}