import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Cabecera «¡Hola, DT!» + logo (mockup DTFly).
class DtflyCoachHeader extends StatelessWidget {
  const DtflyCoachHeader({
    super.key,
    this.categoriaDeportiva,
    this.saludo,
    this.subtitulo,
  });

  final String? categoriaDeportiva;
  /// Si se omite, muestra «¡Hola, DT!».
  final String? saludo;
  /// Subtítulo bajo el saludo (p. ej. «Utilería»).
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final categoriaNombre =
        DeportesCategoria.nombreVisible(categoriaDeportiva);
    final textoSaludo = saludo ?? '¡Hola, DT!';
    final textoSub = subtitulo ??
        (categoriaDeportiva != null ? categoriaNombre : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 14, 20),
        decoration: BoxDecoration(
          gradient: DtflyTheme.headerGradient,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textoSaludo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  if (textoSub != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      textoSub,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const DtflyCoachLogo(),
          ],
        ),
      ),
    );
  }
}

class DtflyCoachLogo extends StatelessWidget {
  const DtflyCoachLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/dtfly_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          color: Colors.white24,
          alignment: Alignment.center,
          child: Icon(Icons.sports_soccer, color: Colors.white, size: size * 0.55),
        );
      },
    );
  }
}
