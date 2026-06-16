import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioContrasenaAlumno {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Genera un salt aleatorio de 16 bytes en formato hexadecimal
  String _generarSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Calcula el hash SHA-256 de (salt + contrasena)
  String _calcularHash(String salt, String contrasena) {
    final bytes = utf8.encode(salt + contrasena);
    return sha256.convert(bytes).toString();
  }

  // Busca un alumno por email. Devuelve {id, data} o null.
  Future<Map<String, dynamic>?> _buscarAlumnoPorEmail(String email) async {
    final query = await _firestore
        .collection('usuarios')
        .where('email', isEqualTo: email)
        .where('rol', isEqualTo: 'alumno')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return {
      'id': query.docs.first.id,
      'data': query.docs.first.data(),
    };
  }

  // Establece (o cambia) la contrasena de un alumno por su ID.
  // Se usa al crear el alumno y cuando el alumno elige una nueva.
  Future<void> establecerContrasena(
    String alumnoId,
    String nuevaContrasena,
  ) async {
    final salt = _generarSalt();
    final hash = _calcularHash(salt, nuevaContrasena);

    await _firestore.collection('usuarios').doc(alumnoId).update({
      'hashContrasena': hash,
      'saltContrasena': salt,
      'necesitaCambiarContrasena': false,
    });
  }

  // Valida el login de un alumno. Devuelve {id, data} si es correcto, o null.
  Future<Map<String, dynamic>?> validarLogin(
    String email,
    String contrasena,
  ) async {
    final alumno = await _buscarAlumnoPorEmail(email);
    if (alumno == null) return null;

    final data = alumno['data'] as Map<String, dynamic>;
    final salt = data['saltContrasena'];
    final hashGuardado = data['hashContrasena'];

    if (salt == null || hashGuardado == null) return null;

    final hashCalculado = _calcularHash(salt, contrasena);
    if (hashCalculado != hashGuardado) return null;

    return alumno;
  }

  // Comprueba si un email corresponde a un alumno (para el login hibrido).
  Future<bool> esAlumno(String email) async {
    final alumno = await _buscarAlumnoPorEmail(email);
    return alumno != null;
  }

  // El padre/tutor marca al alumno para que cambie su contrasena.
  Future<void> marcarParaRestablecer(String alumnoId) async {
    await _firestore.collection('usuarios').doc(alumnoId).update({
      'necesitaCambiarContrasena': true,
    });
  }

  // Comprueba si el alumno esta marcado para cambiar contrasena.
  Future<bool> necesitaCambiar(String email) async {
    final alumno = await _buscarAlumnoPorEmail(email);
    if (alumno == null) return false;
    final data = alumno['data'] as Map<String, dynamic>;
    return data['necesitaCambiarContrasena'] ?? false;
  }

  // El alumno cambia su contrasena tras haber sido marcado por el supervisor.
  Future<void> cambiarContrasenaOlvidada(
    String email,
    String nuevaContrasena,
  ) async {
    final alumno = await _buscarAlumnoPorEmail(email);
    if (alumno == null) {
      throw Exception('No existe ningun alumno con ese correo');
    }

    final data = alumno['data'] as Map<String, dynamic>;
    final necesita = data['necesitaCambiarContrasena'] ?? false;

    if (necesita != true) {
      throw Exception(
        'Tu tutor o tu padre/madre todavia no ha activado el cambio de contrasena. Pideselo.',
      );
    }

    await establecerContrasena(alumno['id'], nuevaContrasena);
  }
}