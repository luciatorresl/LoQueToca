import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/login_screen.dart';
import 'hijo_activo.dart';
import 'padre_home.dart';

class PantallaSeleccionHijo extends StatefulWidget {
  const PantallaSeleccionHijo({super.key});

  @override
  State<PantallaSeleccionHijo> createState() => _PantallaSeleccionHijoState();
}

class _PantallaSeleccionHijoState extends State<PantallaSeleccionHijo> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> _cargarHijos() async {
    final uid = _auth.currentUser!.uid;
    final padreDoc = await _firestore.collection('usuarios').doc(uid).get();
    final hijosIds = List<String>.from(padreDoc.data()?['hijosIds'] ?? []);

    final hijos = <Map<String, dynamic>>[];
    for (final hijoId in hijosIds) {
      final hijoDoc =
          await _firestore.collection('usuarios').doc(hijoId).get();
      if (hijoDoc.exists) {
        hijos.add({'id': hijoId, ...?hijoDoc.data()});
      }
    }
    return hijos;
  }

  void _entrar(Map<String, dynamic> hijo) {
    HijoActivo.seleccionar(hijo['id'], hijo['nombre'] ?? 'Sin nombre');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePadre()),
    );
  }

  Future<void> _cerrarSesion() async {
    HijoActivo.limpiar();
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige un usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cargarHijos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final hijos = snapshot.data!;

          if (hijos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes ningún usuario vinculado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Si solo hay un hijo, entrar directo sin mostrar la pantalla
          if (hijos.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _entrar(hijos.first);
            });
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: hijos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final hijo = hijos[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: const Icon(Icons.person, size: 36),
                  title: Text(
                    hijo['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _entrar(hijo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}