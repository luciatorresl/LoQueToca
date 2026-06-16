import 'package:flutter/material.dart';
import '../servicios/servicios_padre.dart';
import '../sup_alumnos/sup_alumnos_seguimiento.dart';

class PadreSeguimiento extends StatelessWidget {
  const PadreSeguimiento({super.key});

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioPadre();

    return StreamBuilder<Map<String, dynamic>>(
      stream: servicio.obtenerAlumnoVinculado(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final alumnoId = snapshot.data!['id'];

        // Reutilizamos la pantalla del tutor pasandole el alumno del padre
        return PantallaSeguimiento(alumnoId: alumnoId);
      },
    );
  }
}