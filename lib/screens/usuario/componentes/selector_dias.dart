import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectorDias extends StatelessWidget {
  final List<DateTime> dias;
  final DateTime diaSeleccionado;
  final Function(DateTime) onDiaSeleccionado;

  const SelectorDias({
    required this.dias,
    required this.diaSeleccionado,
    required this.onDiaSeleccionado,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        itemBuilder: (context, i) {
          final dia = dias[i];
          final seleccionado =
              DateFormat('yyyy-MM-dd').format(dia) ==
              DateFormat('yyyy-MM-dd').format(diaSeleccionado);

          return GestureDetector(
            onTap: () => onDiaSeleccionado(dia),
            child: Container(
              width: 75,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: seleccionado ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat.E('es').format(dia)),
                  Text(
                    DateFormat.d().format(dia),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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