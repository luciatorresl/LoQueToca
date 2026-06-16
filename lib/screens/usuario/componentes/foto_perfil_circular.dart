import 'dart:convert';
import 'package:flutter/material.dart';

class FotoPerfilCircular extends StatelessWidget {
  final String? fotoBase64;
  final double tamano;

  const FotoPerfilCircular({
    super.key,
    required this.fotoBase64,
    this.tamano = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoBase64 == null || fotoBase64!.isEmpty) {
      return CircleAvatar(
        radius: tamano / 2,
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          Icons.person,
          size: tamano * 0.6,
          color: Colors.grey.shade600,
        ),
      );
    }

    try {
      final bytes = base64Decode(fotoBase64!);
      return CircleAvatar(
        radius: tamano / 2,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (_) {
      return CircleAvatar(
        radius: tamano / 2,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, size: tamano * 0.6),
      );
    }
  }
}