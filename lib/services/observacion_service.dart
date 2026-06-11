import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/observacion_jugador.dart';

/// Observaciones y evaluaciones (colección `observaciones`).
class ObservacionService {
  ObservacionService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'observaciones';

  static const rendimientos = [
    'excelente',
    'bueno',
    'regular',
    'mejorar',
  ];

  static Future<void> crear({
    required String jugadorId,
    required String jugadorNombre,
    required String entrenadorEmail,
    required String entrenadorUsuarioId,
    required String tipo,
    required String texto,
    required String rendimiento,
    String? entrenamientoId,
    String? partidoId,
    String? referenciaTitulo,
  }) async {
    await _db.collection(_col).add({
      'jugadorId': jugadorId,
      'jugadorNombre': jugadorNombre,
      'entrenadorEmail': entrenadorEmail,
      'entrenadorUsuarioId': entrenadorUsuarioId,
      'tipo': tipo,
      'texto': texto,
      'rendimiento': rendimiento,
      if (entrenamientoId != null) 'entrenamientoId': entrenamientoId,
      if (partidoId != null) 'partidoId': partidoId,
      if (referenciaTitulo != null) 'referenciaTitulo': referenciaTitulo,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<ObservacionJugador>> streamPorJugador(String jugadorId) {
    return _db
        .collection(_col)
        .where('jugadorId', isEqualTo: jugadorId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ObservacionJugador.fromDoc).toList();
      list.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return list;
    });
  }

  static Stream<List<ObservacionJugador>> streamPorEntrenador(
    String entrenadorEmail,
  ) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ObservacionJugador.fromDoc).toList();
      list.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return list;
    });
  }

  static Future<void> eliminar(String id) async {
    await _db.collection(_col).doc(id).delete();
  }
}
