import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'servicio_contrasena_alumno.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _codigoController = TextEditingController();

  bool _cargando = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final password2 = _password2Controller.text.trim();
    final codigo = _codigoController.text.trim();

    // Campos obligatorios
    if (nombre.isEmpty || email.isEmpty || password.isEmpty || password2.isEmpty) {
      setState(() {
        _error = 'Por favor rellena todos los campos obligatorios';
        _cargando = false;
      });
      return;
    }

    // Formato de email
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _error = 'El correo electrónico no tiene un formato válido';
        _cargando = false;
      });
      return;
    }

    // Contraseña mínimo 6 caracteres
    if (password.length < 6) {
      setState(() {
        _error = 'La contraseña debe tener al menos 6 caracteres';
        _cargando = false;
      });
      return;
    }

    // Las dos contraseñas deben coincidir
    if (password != password2) {
      setState(() {
        _error = 'Las contraseñas no coinciden';
        _cargando = false;
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email, password: password);

      final uid = cred.user!.uid;

      // SIN CÓDIGO → alumno independiente
      if (codigo.isEmpty) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set({
          'nombre': nombre,
          'email': email,
          'rol': 'alumno',
          'tutoresIds': [],
          'createdAt': Timestamp.now(),
        });
        // guardar la contraseña del alumno en Firestore (con hash)
        await ServicioContrasenaAlumno().establecerContrasena(uid, password);

      } else {
        // BUSCAR EN "codigos_invitacion" PRIMERO
        final codigoInvitacionDoc = await FirebaseFirestore.instance
            .collection('codigos_invitacion')
            .doc(codigo)
            .get();

        if (codigoInvitacionDoc.exists) {
          final data = codigoInvitacionDoc.data() ?? {};
          final usuarioIdAlumno = data['usuarioId'];

          // Si tiene usuarioId → es código de PADRE
          if (usuarioIdAlumno != null) {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .set({
              'nombre': nombre,
              'email': email,
              'rol': 'padre',
              'hijosIds': [usuarioIdAlumno],
              'createdAt': Timestamp.now(),
            });

            // Actualizar el alumno para que sepa que tiene un padre
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(usuarioIdAlumno)
                .update({
              'padresIds': FieldValue.arrayUnion([uid])
            });

            // Marcar código como usado
            await codigoInvitacionDoc.reference.update({
              'activo': false,
              'padreId': uid,
              'usadoEn': Timestamp.now(),
            });
          } else {
            // Sin usuarioId → es código de SUPERVISOR
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .set({
              'nombre': nombre,
              'email': email,
              'rol': 'supervisor',
              'alumnosIds': [],
              'createdAt': Timestamp.now(),
            });

            // Marcar código como usado
            await codigoInvitacionDoc.reference.update({
              'activo': false,
              'supervisorId': uid,
              'usadoEn': Timestamp.now(),
            });
          }
        } else {
          // BUSCAR EN "codigos" (alumno con grupo) — POR NOMBRE del grupo, no por ID del grupo
          final claseQuery = await FirebaseFirestore.instance
              .collection('codigos')
              .where('nombre', isEqualTo: codigo)
              .limit(1)
              .get();

          if (claseQuery.docs.isEmpty) {
            setState(() {
              _error = 'Código no válido';
              _cargando = false;
            });
            return;
          }

          final claseDoc = claseQuery.docs.first;
          final codigoId = claseDoc.id;          // ID real del grupo
          final data = claseDoc.data();
          final tutores = List<String>.from(data['tutoresIds']);

          // Crear alumno vinculado
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .set({
            'nombre': nombre,
            'email': email,
            'rol': 'alumno',
            'tutoresIds': tutores,
            'codigoId': codigoId,
            'createdAt': Timestamp.now(),
          });

          // guardar la contraseña del alumno en Firestore (con hash)
          await ServicioContrasenaAlumno().establecerContrasena(uid, password);

          // Añadir alumno al código
          await FirebaseFirestore.instance
              .collection('codigos')
              .doc(codigoId)
              .update({
            'alumnosIds': FieldValue.arrayUnion([uid])
          });

          // Añadir alumno a cada tutor
          for (final tutorId in tutores) {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(tutorId)
                .update({
              'alumnosIds': FieldValue.arrayUnion([uid])
            });
          }

          // Copiar las tareas grupales SIMPLES futuras del grupo
          final tareasGrupales = await FirebaseFirestore.instance
              .collection('tareas_grupales')
              .where('codigoId', isEqualTo: codigoId)
              .get();

          final ahora = DateTime.now();
          final fechaHoyStr =
              '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';

          for (final tareaGrupal in tareasGrupales.docs) {
            final dataTarea = tareaGrupal.data();
            final fechaTarea = dataTarea['fecha'] ?? '';

            if (fechaTarea.compareTo(fechaHoyStr) >= 0) {
              await FirebaseFirestore.instance.collection('tareas').add({
                'titulo': dataTarea['titulo'] ?? '',
                'fecha': dataTarea['fecha'],
                'hora': dataTarea['hora'],
                'alumnoId': uid,
                'completada': false,
                'esGrupal': true,
                'tareaGrupalId': tareaGrupal.id,
                'creadaPor': 'tutor',
                'vistaPorAlumno': false,
              });
            }
          }

          // Copiar las reglas repetidas grupales del grupo
          final reglasGrupales = await FirebaseFirestore.instance
              .collection('tareas_grupales_repetidas')
              .where('codigoId', isEqualTo: codigoId)
              .get();

          final inicioDeHoy = DateTime(ahora.year, ahora.month, ahora.day);

          for (final regla in reglasGrupales.docs) {
            final dataRegla = regla.data();

            final fechaInicioOriginal =
                (dataRegla['fechaInicio'] as Timestamp).toDate();
            final fechaInicioCopia = fechaInicioOriginal.isBefore(inicioDeHoy)
                ? inicioDeHoy
                : fechaInicioOriginal;

            await FirebaseFirestore.instance
                .collection('tareas_repetidas')
                .add({
              'titulo': dataRegla['titulo'] ?? '',
              'hora': dataRegla['hora'],
              'alumnoId': uid,
              'creadaPor': dataRegla['creadaPor'] ?? 'tutor',
              'patron': dataRegla['patron'],
              'diasSemana': dataRegla['diasSemana'] ?? [],
              'diaMes': dataRegla['diaMes'],
              'fechaInicio': Timestamp.fromDate(fechaInicioCopia),
              'fechaFin': dataRegla['fechaFin'],
              'esGrupal': true,
              'tareaGrupalRepetidaId': regla.id,
              'createdAt': Timestamp.now(),
            });
          }
        }
      }

      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _error = 'Este correo ya está registrado. Inicia sesión o usa otro correo.';
        } else if (e.code == 'weak-password') {
          _error = 'La contraseña debe tener al menos 6 caracteres';
        } else {
          _error = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => _error = 'Error inesperado');
    }

    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Registro',
            style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crea tu cuenta',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Introduce un código si te lo han proporcionado.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // nombre y apellidos
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre y Apellidos',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // correo
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

             // contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // repetir contraseña
            TextField(
              controller: _password2Controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Repetir contraseña',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // código
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código (opcional)',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _cargando ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrarse',
                        style: TextStyle(
                            fontSize: 20, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _codigoController.dispose();
    super.dispose();
  }
}