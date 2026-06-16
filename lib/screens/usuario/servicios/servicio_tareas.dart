import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioTareas {
  static Future<void> marcarCompletada(String id, bool completada) async {
    await FirebaseFirestore.instance
        .collection('tareas')
        .doc(id)
        .update({'completada': completada});
  }

  static Future<void> marcarComoPuntuada(String id) async {
    await FirebaseFirestore.instance
        .collection('tareas')
        .doc(id)
        .update({'puntuada': true});
  }

  static Future<void> editarTarea(
    String id,
    String nuevoTitulo,
    String nuevaFecha,
    String? nuevaHora,
  ) async {
    await FirebaseFirestore.instance
        .collection('tareas')
        .doc(id)
        .update({
      'titulo': nuevoTitulo,
      'fecha': nuevaFecha,
      'hora': nuevaHora,
    });
  }

  static Future<void> eliminarTarea(String id) async {
    await FirebaseFirestore.instance
        .collection('tareas')
        .doc(id)
        .delete();
  }
}