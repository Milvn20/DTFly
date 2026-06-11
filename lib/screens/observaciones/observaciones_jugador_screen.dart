import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/observacion_jugador.dart';
import 'package:flutter_application_1/services/observacion_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// El alumno solo ve sus propias observaciones y evaluaciones.
class ObservacionesJugadorScreen extends StatelessWidget {
  const ObservacionesJugadorScreen({super.key, required this.jugadorId});

  final String jugadorId;

  @override
  Widget build(BuildContext context) {
    return DtflyDarkScaffold(
      title: 'Mis observaciones',
      body: StreamBuilder<List<ObservacionJugador>>(
        stream: ObservacionService.streamPorJugador(jugadorId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Cuando tu entrenador registre observaciones o evaluaciones aparecerán aquí.',
                  style: TextStyle(color: DtflyTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final o = list[i];
              return DtflyDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          o.tipoEtiqueta,
                          style: const TextStyle(
                            color: DtflyTheme.accentOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          o.rendimiento.toUpperCase(),
                          style: TextStyle(
                            color: _colorRendimiento(o.rendimiento),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (o.referenciaTitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        o.referenciaTitulo!,
                        style: const TextStyle(color: DtflyTheme.textMuted, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      o.texto,
                      style: const TextStyle(color: DtflyTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(o.creadoEn),
                      style: const TextStyle(color: DtflyTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Color _colorRendimiento(String r) {
    switch (r) {
      case 'excelente':
        return Colors.greenAccent;
      case 'mejorar':
        return DtflyTheme.fieldRed;
      default:
        return DtflyTheme.accentOrange;
    }
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
