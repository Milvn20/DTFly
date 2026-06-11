import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de observación del entrenador.
abstract class ObservacionTipo {
  static const individual = 'individual';
  static const entrenamiento = 'entrenamiento';
  static const partido = 'partido';
}

/// Observación o evaluación por jugador (colección `observaciones`).
class ObservacionJugador {
  const ObservacionJugador({
    required this.id,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    required this.tipo,
    required this.texto,
    required this.rendimiento,
    required this.creadoEn,
    this.entrenamientoId,
    this.partidoId,
    this.referenciaTitulo,
  });

  final String id;
  final String jugadorId;
  final String jugadorNombre;
  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String tipo;
  final String texto;
  /// Escala 1–5 o etiqueta: excelente, bueno, regular, mejorar.
  final String rendimiento;
  final DateTime creadoEn;
  final String? entrenamientoId;
  final String? partidoId;
  final String? referenciaTitulo;

  static ObservacionJugador fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final ts = d['creadoEn'] as Timestamp?;
    return ObservacionJugador(
      id: doc.id,
      jugadorId: d['jugadorId'] as String? ?? '',
      jugadorNombre: d['jugadorNombre'] as String? ?? '',
      entrenadorEmail: d['entrenadorEmail'] as String? ?? '',
      entrenadorUsuarioId: d['entrenadorUsuarioId'] as String? ?? '',
      tipo: d['tipo'] as String? ?? ObservacionTipo.individual,
      texto: d['texto'] as String? ?? '',
      rendimiento: d['rendimiento'] as String? ?? 'bueno',
      creadoEn: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      entrenamientoId: d['entrenamientoId'] as String?,
      partidoId: d['partidoId'] as String?,
      referenciaTitulo: d['referenciaTitulo'] as String?,
    );
  }

  String get tipoEtiqueta {
    switch (tipo) {
      case ObservacionTipo.entrenamiento:
        return 'Entrenamiento';
      case ObservacionTipo.partido:
        return 'Partido';
      default:
        return 'Individual';
    }
  }
}
