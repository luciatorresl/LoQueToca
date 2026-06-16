class SesionAlumno {
  static String? alumnoId;
  static DateTime? inicioSesionActual;

  static void iniciar(String id) {
    alumnoId = id;
    inicioSesionActual = DateTime.now();
  }

  static void cerrar() {
    alumnoId = null;
    inicioSesionActual = null;
  }
}