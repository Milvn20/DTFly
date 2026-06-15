import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Pantalla secundaria del admin (desde «Más» o accesos rápidos).
class AdminSeccionScreen extends StatelessWidget {
  const AdminSeccionScreen({
    super.key,
    required this.titulo,
    required this.child,
  });

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
        title: Text(titulo),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: child,
      ),
    );
  }
}
