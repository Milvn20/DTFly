import 'package:cloud_firestore/cloud_firestore.dart';

class Entrenamiento {
  const Entrenamiento({
    required this.id,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    required this.titulo,
    required this.cancha,
    required this.inicioProgramado,
    required this.finProgramado,
    required this.estado,
    required this.codigoUnion,
    required this.codigoValidezSegundos,
    this.codigoActualizadoEn,
    this.sesionIniciadaEn,
    this.finalizadoEn,
    this.creadoEn,
  });

  final String id;
  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String titulo;
  final String cancha;
  final DateTime inicioProgramado;
  final DateTime finProgramado;
  final String estado;
  final String codigoUnion;
  final int codigoValidezSegundos;
  final DateTime? codigoActualizadoEn;
  final DateTime? sesionIniciadaEn;
  final DateTime? finalizadoEn;
  final DateTime? creadoEn;

  bool get esActivo => estado == 'activo';
  bool get esProgramado => estado == 'programado';
  bool get esFinalizado => estado == 'finalizado';

  static Entrenamiento fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime ts(Timestamp? t) =>
        t?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Entrenamiento(
      id: doc.id,
      entrenadorEmail: d['entrenadorEmail'] as String? ?? '',
      entrenadorUsuarioId: d['entrenadorUsuarioId'] as String? ?? '',
      titulo: d['titulo'] as String? ?? 'Entrenamiento',
      cancha: d['cancha'] as String? ?? '',
      inicioProgramado: ts(d['inicioProgramado'] as Timestamp?),
      finProgramado: ts(d['finProgramado'] as Timestamp?),
      estado: d['estado'] as String? ?? 'programado',
      codigoUnion: d['codigoUnion'] as String? ?? '',
      codigoValidezSegundos: (d['codigoValidezSegundos'] as num?)?.toInt() ?? 60,
      codigoActualizadoEn: (d['codigoActualizadoEn'] as Timestamp?)?.toDate(),
      sesionIniciadaEn: (d['sesionIniciadaEn'] as Timestamp?)?.toDate(),
      finalizadoEn: (d['finalizadoEn'] as Timestamp?)?.toDate(),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
