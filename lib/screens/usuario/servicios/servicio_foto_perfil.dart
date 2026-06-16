import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ServicioFotoPerfil {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<bool> seleccionarYGuardar(String alumnoId, String fuente) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: fuente == 'camara' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );

      if (foto == null) return false; // el usuario canceló

      final Uint8List bytes = await foto.readAsBytes();

      if (bytes.length > 900 * 1024) {
        throw Exception('La foto es muy grande. Prueba con otra foto.');
      }

      final String base64Foto = base64Encode(bytes);

      await _firestore.collection('usuarios').doc(alumnoId).update({
        'fotoPerfil': base64Foto,
      });

      return true;
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('No se ha podido guardar la foto. Inténtalo otra vez.');
    }
  }

  Future<void> borrar(String alumnoId) async {
    await _firestore.collection('usuarios').doc(alumnoId).update({
      'fotoPerfil': FieldValue.delete(),
    });
  }
}