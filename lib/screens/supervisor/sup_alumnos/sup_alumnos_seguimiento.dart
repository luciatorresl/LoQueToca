import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../usuario/servicios/servicio_seguimiento.dart';

class PantallaSeguimiento extends StatefulWidget {
  final String alumnoId;
  const PantallaSeguimiento({super.key, required this.alumnoId});

  @override
  State<PantallaSeguimiento> createState() => _PantallaSeguimientoState();
}

class _PantallaSeguimientoState extends State<PantallaSeguimiento> {
  final _servicio = ServicioSeguimiento();
  late Future<ResumenSeguimiento> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerResumen(widget.alumnoId);
  }

  Future<void> _recargar() async {
    setState(() {
      _futuro = _servicio.obtenerResumen(widget.alumnoId);
    });
  }

  String _formatoMinutos(int segundos) {
    if (segundos < 60) return '$segundos s';
    final min = (segundos / 60).round();
    return '$min min';
  }

  String _formatoUltimaEntrada(DateTime? fecha) {
    if (fecha == null) return 'Nunca';
    return DateFormat("d 'de' MMMM 'a las' HH:mm", 'es').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _recargar,
      child: FutureBuilder<ResumenSeguimiento>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                'Error al cargar seguimiento:\n\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final r = snapshot.data!;
          final diasSinEntrar = r.diasSinEntrar;
          final mostrarAviso = diasSinEntrar != null && diasSinEntrar >= 3;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // BOTÓN DE REFRESCAR
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refrescar',
                  onPressed: _recargar,
                ),
              ),
              
              // AVISO si lleva varios dias sin entrar
              if (mostrarAviso)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.deepOrange, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lleva $diasSinEntrar días sin entrar en la app',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // TABLA
              _Fila(
                icono: Icons.login,
                titulo: 'Última entrada',
                valor: _formatoUltimaEntrada(r.ultimaEntrada),
              ),
              _Fila(
                icono: Icons.event_busy,
                titulo: 'Días sin entrar',
                valor: diasSinEntrar == null ? '—' : '$diasSinEntrar',
              ),
              _Fila(
                icono: Icons.local_fire_department,
                titulo: 'Racha actual',
                valor: '${r.rachaActual} '
                    '${r.rachaActual == 1 ? "día" : "días"}',
                color: r.rachaActual > 0 ? Colors.deepOrange : null,
              ),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Últimos 7 días',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              _Fila(
                icono: Icons.check_circle,
                titulo: 'Tareas completadas',
                valor: '${r.tareasCompletadasSemana}',
              ),
              _Fila(
                icono: Icons.add_task,
                titulo: 'Tareas añadidas',
                valor: '${r.tareasAnadidasSemana}',
              ),
              _Fila(
                icono: Icons.edit,
                titulo: 'Tareas editadas',
                valor: '${r.tareasEditadasSemana}',
              ),
              const Divider(height: 32),
              _Fila(
                icono: Icons.timer,
                titulo: 'Tiempo medio por sesión',
                valor: _formatoMinutos(r.mediaSegundosSesion),
              ),
              _Fila(
                icono: Icons.star,
                titulo: 'Puntos totales',
                valor: '${r.puntos}',
                color: Colors.amber.shade700,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color? color;

  const _Fila({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, color: color ?? Colors.blueGrey, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}