import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'pantalla_olvido_contrasena_alumno.dart';
import 'servicio_contrasena_alumno.dart';
import 'sesion_alumno.dart';
import '../usuario/home_usuario.dart';
import '../supervisor/home_supervisor.dart';
import '../supervisor/padre/pantalla_seleccion_hijo.dart';
import '../usuario/servicios/servicio_seguimiento.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _servicioAlumno = ServicioContrasenaAlumno();
  bool _cargando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LoQueToca',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90D9),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu agenda del día',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 48),
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
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Entrar',
                          style:
                              TextStyle(fontSize: 20, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Botones de recuperación y registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PantallaOlvidoContrasenaAlumno(),
                    ),
                  );
                },
                child: const Text(
                  '¿Has olvidado tu contraseña?',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  '¿No tienes cuenta?',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Comprobar si el correo pertenece a un alumno
      final esAlumno = await _servicioAlumno.esAlumno(email);

      if (esAlumno) {
        // LOGIN DE ALUMNO (contra Firestore, sin Firebase Auth)
        final alumno = await _servicioAlumno.validarLogin(email, password);

        if (alumno == null) {
          setState(() {
            _error = 'Correo o contraseña incorrectos';
            _cargando = false;
          });
          return;
        }

        SesionAlumno.iniciar(alumno['id']);

        // Registrar entrada y guardar dias sin entrar para mostrar bienvenida
        final diasSinEntrar = await ServicioSeguimiento().registrarEntrada(alumno['id']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeUsuario(diasSinEntrar: diasSinEntrar),
          ),
        );
        return;


      }

      // LOGIN DE SUPERVISOR (Firebase Auth normal)
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Usuario no encontrado';
          _cargando = false;
        });
        return;
      }

      final datos = doc.data() as Map<String, dynamic>;
      final rol = datos['rol'];

      if (!mounted) return;

      if (rol == 'supervisor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeSupervisor()),
        );
      } else if (rol == 'padre') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaSeleccionHijo()),
        );
      } else {
        setState(() {
          _error = 'Correo o contraseña incorrectos';
          _cargando = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _error = 'Usuario no encontrado';
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _error = 'Correo o contraseña incorrectos';
        } else {
          _error = 'Error: ${e.message}';
        }
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error inesperado';
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}