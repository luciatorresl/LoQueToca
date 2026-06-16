/// Guarda en memoria el hijo que el padre tiene seleccionado actualmente.
class HijoActivo {
  static String? id;
  static String? nombre;

  static void seleccionar(String hijoId, String nombreHijo) {
    id = hijoId;
    nombre = nombreHijo;
  }

  static void limpiar() {
    id = null;
    nombre = null;
  }
}