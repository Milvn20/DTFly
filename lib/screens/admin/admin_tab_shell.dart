import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';

/// Contenedor de pestaña admin con cabecera DTFly (como entrenador/jugador).
class AdminTabShell extends StatelessWidget {
  const AdminTabShell({
    super.key,
    required this.nombre,
    required this.subtitulo,
    required this.child,
    this.cargando = false,
  });

  final String nombre;
  final String subtitulo;
  final Widget child;
  final bool cargando;

  String get _primerNombre {
    final p = nombre.trim().split(RegExp(r'\s+')).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => 'Administrador',
        );
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: DtflyCoachHeader(
            saludo: '¡Hola, $_primerNombre!',
            subtitulo: subtitulo,
          ),
        ),
        Expanded(
          child: cargando
              ? const Center(
                  child: CircularProgressIndicator(color: DtflyTheme.coachRed),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: child,
                ),
        ),
      ],
    );
  }
}
