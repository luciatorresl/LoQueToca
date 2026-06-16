import 'package:flutter/material.dart';

class TarjetaAlumno extends StatelessWidget {
  final String nombre;
  final VoidCallback onTap;
  final VoidCallback? onQuitar;
  final VoidCallback? onDesvincular;

  const TarjetaAlumno({
    super.key,
    required this.nombre,
    required this.onTap,
    this.onQuitar,
    this.onDesvincular,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(nombre),
      onTap: onTap,
      trailing: onQuitar != null || onDesvincular != null
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'quitar') onQuitar?.call();
                if (value == 'desvincular') onDesvincular?.call();
              },
              itemBuilder: (_) => [
                if (onQuitar != null) const PopupMenuItem(value: 'quitar', child: Text('Quitar del grupo')),
                if (onDesvincular != null) const PopupMenuItem(value: 'desvincular', child: Text('Desvincular')),
              ],
            )
          : null,
    );
  }
}
