import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Categorías del Muro Deportivo / Tablón Informativo.
enum MuroTipo {
  avisoComunicado(
    'aviso_comunicado',
    'Aviso / Comunicado',
    Icons.campaign_outlined,
    DtflyTheme.primary,
  ),
  fechaImportante(
    'fecha_importante',
    'Fecha importante',
    Icons.event_outlined,
    Color(0xFF7C3AED),
  ),
  actividadSemana(
    'actividad_semana',
    'Actividad de la semana',
    Icons.fitness_center_outlined,
    Color(0xFF059669),
  ),
  proximoPartido(
    'proximo_partido',
    'Próximo partido',
    Icons.sports_soccer_outlined,
    Color(0xFF2563EB),
  ),
  resultado(
    'resultado',
    'Resultado deportivo',
    Icons.emoji_events_outlined,
    Color(0xFFD97706),
  ),
  tablaPosiciones(
    'tabla_posiciones',
    'Tabla de posiciones',
    Icons.leaderboard_outlined,
    Color(0xFF0891B2),
  ),
  logroDestacado(
    'logro_destacado',
    'Logro / Destacado',
    Icons.star_outline,
    Color(0xFFCA8A04),
  );

  const MuroTipo(this.id, this.etiqueta, this.icono, this.color);

  final String id;
  final String etiqueta;
  final IconData icono;
  final Color color;

  static MuroTipo fromId(String? raw) {
    if (raw == null || raw.isEmpty) return MuroTipo.avisoComunicado;
    for (final t in MuroTipo.values) {
      if (t.id == raw) return t;
    }
    return MuroTipo.avisoComunicado;
  }

  /// Etiqueta corta para chips del feed.
  String get etiquetaCorta {
    switch (this) {
      case MuroTipo.avisoComunicado:
        return 'Avisos';
      case MuroTipo.fechaImportante:
        return 'Fechas';
      case MuroTipo.actividadSemana:
        return 'Actividades';
      case MuroTipo.proximoPartido:
        return 'Partidos';
      case MuroTipo.resultado:
        return 'Resultados';
      case MuroTipo.tablaPosiciones:
        return 'Tabla';
      case MuroTipo.logroDestacado:
        return 'Logros';
    }
  }
}
