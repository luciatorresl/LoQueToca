class Conversores {
  static int convertirHoraAMinutos(String? hora) {
    if (hora == null || hora.isEmpty) return 9999;
    final partes = hora.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  static String convertirTimeOfDayAString(int hora, int minuto) {
    return '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
  }
}