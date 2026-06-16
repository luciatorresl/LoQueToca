import 'package:flutter/material.dart';
import '../servicios/servicio_puntos.dart';

Future<void> mostrarDialogoRecompensa(
  BuildContext context,
  ResultadoPuntos resultado,
) {
  return showDialog(
    context: context,
    barrierDismissible: false, // Que solo se cierre con el boton, no por tocar fuera
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resultado.hayBonus ? Icons.emoji_events : Icons.star,
              size: 100,
              color: resultado.hayBonus ? Colors.amber : Colors.orange,
            ),
            const SizedBox(height: 16),

            Text(
              '¡Has ganado ${resultado.puntosGanados} puntos!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (resultado.hayBonus) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '¡Y además bonus de ${resultado.puntosBonus} puntos!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '¡Genial!',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}