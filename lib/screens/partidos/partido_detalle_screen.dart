import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Vista de solo lectura del cierre de un partido (alumnos y plantel).
class PartidoDetalleScreen extends StatelessWidget {
  const PartidoDetalleScreen({super.key, required this.partido});

  final Partido partido;

  @override
  Widget build(BuildContext context) {
    return DtflyDarkScaffold(
      title: 'Detalle del partido',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'vs ${partido.rival}',
            style: const TextStyle(
              color: DtflyTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          Text(
            '${_fmt(partido.fechaHora)} · ${partido.lugar}',
            style: const TextStyle(color: DtflyTheme.textSecondary),
          ),
          if (partido.resultadoTexto != null) ...[
            const SizedBox(height: 16),
            Text(
              'Resultado: ${partido.resultadoTexto}',
              style: const TextStyle(
                color: DtflyTheme.accentOrange,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ],
          if (partido.observacionFinal.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Observación del DT', style: DtflyTheme.panelTitle),
            const SizedBox(height: 8),
            Text(
              partido.observacionFinal,
              style: DtflyTheme.panelBody,
            ),
          ],
          if (partido.fotosUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Fotos', style: DtflyTheme.panelTitle),
            const SizedBox(height: 10),
            for (final url in partido.fotosUrls)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 120,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
          ],
          if (partido.notas.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Notas previas', style: DtflyTheme.panelTitle),
            const SizedBox(height: 6),
            Text(partido.notas, style: DtflyTheme.panelBody),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
