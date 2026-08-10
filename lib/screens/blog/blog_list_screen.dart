import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/muro/muro_deportivo_screen.dart';

/// Compatibilidad: redirige al Muro Deportivo.
class BlogListScreen extends StatelessWidget {
  const BlogListScreen({
    super.key,
    required this.soloLectura,
    required this.autorEmail,
    required this.autorNombre,
    this.deporteId,
    this.permitirCambiarSeleccion = false,
  });

  final bool soloLectura;
  final String autorEmail;
  final String autorNombre;
  final String? deporteId;
  final bool permitirCambiarSeleccion;

  @override
  Widget build(BuildContext context) {
    return MuroDeportivoScreen(
      soloLectura: soloLectura,
      autorEmail: autorEmail,
      autorNombre: autorNombre,
      deporteId: deporteId,
      permitirCambiarSeleccion: permitirCambiarSeleccion,
    );
  }
}
