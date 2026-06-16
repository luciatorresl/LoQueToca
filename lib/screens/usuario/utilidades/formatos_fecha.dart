import 'package:intl/intl.dart';

class FormatosFecha {
  static String fechaLarga(DateTime fecha) {
    return DateFormat.yMMMMEEEEd('es').format(fecha);
  }

  static String fechaCorta(DateTime fecha) {
    return DateFormat('yyyy-MM-dd').format(fecha);
  }

  static String horaFormato(int hora, int minuto) {
    return '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
  }
}