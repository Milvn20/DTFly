import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';

class NotaDt {
  const NotaDt({
    required this.id,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    required this.texto,
    required this.semanaInicio,
    this.creadoEn,
    this.deporteId,
  });

  final String id;
  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String texto;
  final DateTime semanaInicio;
  final DateTime? creadoEn;
  final String? deporteId;

  static NotaDt fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final semana = d['semanaInicio'] as Timestamp?;
    return NotaDt(
      id: doc.id,
      entrenadorEmail: d['entrenadorEmail'] as String? ?? '',
      entrenadorUsuarioId: d['entrenadorUsuarioId'] as String? ?? '',
      texto: d['texto'] as String? ?? '',
      semanaInicio: semana?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
      deporteId: DeporteUsuario.idDesde(d),
    );
  }
}
