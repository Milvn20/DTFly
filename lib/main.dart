import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/entrenador/entrenador_seleccion_categoria_screen.dart';
import 'screens/role_main_shell.dart';
import 'theme/dtfly_theme.dart';

/// Vista previa del entrenador sin Firebase:
/// `flutter run --dart-define=DTFLY_COACH_PREVIEW=true`
const bool kCoachPreview = bool.fromEnvironment(
  'DTFLY_COACH_PREVIEW',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kCoachPreview) {
    runApp(const MyApp(coachPreview: true));
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  runApp(const MyApp(coachPreview: false));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.coachPreview});

  final bool coachPreview;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DTFly',
      theme: DtflyTheme.materialTheme(),
      home: coachPreview
          ? const EntrenadorSeleccionCategoriaScreen(
              nombre: 'DT',
              usuarioEmail: 'preview@dtfly.local',
              usuarioId: 'preview-local',
            )
          : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
