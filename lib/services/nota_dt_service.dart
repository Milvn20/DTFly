import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/models/nota_dt.dart';
import 'package:flutter_application_1/services/blog_service.dart';

class NotaDtService {
  NotaDtService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'notas_dt';

  static DateTime inicioSemana(DateTime fecha) {
    final base = DateTime(fecha.year, fecha.month, fecha.day);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  static Future<void> crearNotaSemanal({
    required String entrenadorEmail,
    required String entrenadorUsuarioId,
    required String texto,
    String entrenadorNombre = 'DT',
    String? categoriaDeportiva,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) {
      throw StateError('Escribe una nota para el plantel.');
    }

    await _db.collection(_col).add({
      'entrenadorEmail': entrenadorEmail,
      'entrenadorUsuarioId': entrenadorUsuarioId,
      'texto': limpio,
      'semanaInicio': Timestamp.fromDate(inicioSemana(DateTime.now())),
      'creadoEn': FieldValue.serverTimestamp(),
      if (categoriaDeportiva != null && categoriaDeportiva.isNotEmpty)
        ...DeporteUsuario.camposAlGuardar(categoriaDeportiva),
    });

    await BlogService.publicarActividadSemana(
      entrenadorEmail: entrenadorEmail,
      entrenadorNombre: entrenadorNombre,
      deporteId: categoriaDeportiva,
      texto: limpio,
    );
  }

  static Stream<List<NotaDt>> streamSemanaEntrenador(String entrenadorEmail) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .snapshots()
        .map(_filtrarSemanaActual);
  }

  static Stream<List<NotaDt>> streamSemanaActualGlobal() {
    return _db.collection(_col).snapshots().map(_filtrarSemanaActual);
  }

  static Stream<List<NotaDt>> streamSemanaSeleccion(String? deporteId) {
    return streamSemanaActualGlobal().map((notas) {
      if (deporteId == null || deporteId.isEmpty) return notas;
      return notas
          .where((n) =>
              n.deporteId == null ||
              n.deporteId!.isEmpty ||
              n.deporteId == deporteId)
          .toList();
    });
  }

  static List<NotaDt> _filtrarSemanaActual(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final semana = inicioSemana(DateTime.now());
    final list = snap.docs.map(NotaDt.fromDoc).where((nota) {
      final n = DateTime(
        nota.semanaInicio.year,
        nota.semanaInicio.month,
        nota.semanaInicio.day,
      );
      return n == semana;
    }).toList();
    list.sort((a, b) {
      final ca = a.creadoEn ?? a.semanaInicio;
      final cb = b.creadoEn ?? b.semanaInicio;
      return cb.compareTo(ca);
    });
    return list;
  }

  static Future<void> eliminar(String id) async {
    await _db.collection(_col).doc(id).delete();
  }
}
