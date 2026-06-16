import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../componentes/selector_dias.dart';
import '../componentes/lista_tareas.dart';
import '../utilidades/formatos_fecha.dart';

class PantallaInicio extends StatefulWidget {
  final DateTime? fechaInicial;

  const PantallaInicio({
    this.fechaInicial,
    super.key,
  });

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  late DateTime diaActual;

  @override
  void initState() {
    super.initState();
    diaActual = widget.fechaInicial ?? DateTime.now();
  }

  @override
  void didUpdateWidget(PantallaInicio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fechaInicial != null && widget.fechaInicial != oldWidget.fechaInicial) {
      diaActual = widget.fechaInicial!;
    }
  }

  List<DateTime> get siguientes7Dias =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  String get fechaClave =>
      DateFormat('yyyy-MM-dd').format(diaActual);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SelectorDias(
          dias: siguientes7Dias,
          diaSeleccionado: diaActual,
          onDiaSeleccionado: (dia) {
            setState(() => diaActual = dia);
          },
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            FormatosFecha.fechaLarga(diaActual),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListaTareas(
            fechaClave: fechaClave,
          ),
        ),
      ],
    );
  }
}