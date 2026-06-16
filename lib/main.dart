import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/sesion_alumno.dart';
import 'screens/usuario/servicios/servicio_seguimiento.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('es', null);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _seguimiento = ServicioSeguimiento();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final alumnoId = SesionAlumno.alumnoId;
    if (alumnoId == null) return; // Solo para alumnos

    if (state == AppLifecycleState.resumed) {
      // Vuelve a primer plano: nueva sesion
      SesionAlumno.inicioSesionActual = DateTime.now();
      _seguimiento.registrarEntrada(alumnoId);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      // Pasa a segundo plano: cerrar sesion y sumar tiempo
      final inicio = SesionAlumno.inicioSesionActual;
      if (inicio != null) {
        final segundos = DateTime.now().difference(inicio).inSeconds;
        _seguimiento.registrarSalida(alumnoId, segundos);
        SesionAlumno.inicioSesionActual = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoQueToca',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
      ],
      locale: const Locale('es'),
      home: const LoginScreen(),
    );
  }
}