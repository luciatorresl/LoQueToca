import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'servicio_contrasena_alumno.dart';

class PantallaOlvidoContrasenaAlumno extends StatefulWidget {
  const PantallaOlvidoContrasenaAlumno({super.key});

  @override
  State<PantallaOlvidoContrasenaAlumno> createState() =>
      _PantallaOlvidoContrasenaAlumnoState();
}

class _PantallaOlvidoContrasenaAlumnoState
    extends State<PantallaOlvidoContrasenaAlumno> {
  final _emailController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  final _servicio = ServicioContrasenaAlumno();
  bool _cargando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cambiar mi contraseña'),
        backgroundColor: const Color(0xFF4A90D9),
      ),
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
              const SizedBox(height: 24),
              const Text(
                'Escribe tu correo y tu contraseña nueva',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                controller: _nuevaContrasenaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña nueva',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmarContrasenaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Repite la contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _cambiarContrasena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar contraseña',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),

              const Divider(height: 32),
              TextButton(
                onPressed: _recuperarContrasenaAdulto,
                child: const Text(
                  'Soy tutor o familiar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cambiarContrasena() async {
    if (_emailController.text.trim().isEmpty ||
        _nuevaContrasenaController.text.isEmpty ||
        _confirmarContrasenaController.text.isEmpty) {
      setState(() => _error = 'Por favor rellena todos los campos');
      return;
    }

    if (_nuevaContrasenaController.text !=
        _confirmarContrasenaController.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    if (_nuevaContrasenaController.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _servicio.cambiarContrasenaOlvidada(
        _emailController.text.trim(),
        _nuevaContrasenaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Contraseña cambiada! Ya puedes entrar.'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _recuperarContrasenaAdulto() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escribe tu correo y te enviaremos un enlace '
              'para crear una contraseña nueva.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Correo enviado'),
                      content: const Text(
                        'Si ese correo está registrado, te llegará un enlace '
                        'para cambiar la contraseña. Revisa tu bandeja de entrada '
                        '(y la carpeta de spam).',
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                String mensaje;
                if (e.code == 'invalid-email') {
                  mensaje = 'El correo no tiene un formato válido.';
                } else if (e.code == 'user-not-found') {
                  mensaje = 'No hay ninguna cuenta con ese correo.';
                } else {
                  mensaje = 'No se ha podido enviar el correo. Inténtalo otra vez.';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mensaje)),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }
}