import 'package:flutter/material.dart';
import '../dialogos/dialogo_crear_tarea.dart';

class PantallaTareas extends StatelessWidget {
  final Function(DateTime)? onTareaCreada;

  const PantallaTareas({
    this.onTareaCreada,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'AÑADIR TAREA A MI AGENDA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: () async {
              await mostrarDialogoCrearTarea(
                context,
                onTareaCreada: (fecha) {
                  if (onTareaCreada != null) {
                    onTareaCreada!(fecha);
                  }
                },
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}