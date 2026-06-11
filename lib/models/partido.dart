import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado del partido en calendario.
abstract class PartidoEstado {
  static const programado = 'programado';
  static const jugado = 'jugado';
  static const cancelado = 'cancelado';
}

class Partido {
  const Partido({
    required this.id,
    required this.entrenadorEmail,
    required this.fechaHora,
    required this.rival,
    required this.lugar,
    required this.notas,
    this.estado = PartidoEstado.programado,
    this.golesLocal,
    this.golesRival,
    this.observacionFinal = '',
    this.fotosUrls = const [],
  });

  final String id;
  final String entrenadorEmail;
  final DateTime fechaHora;
  final String rival;
  final String lugar;
  final String notas;
  final String estado;
  final int? golesLocal;
  final int? golesRival;
  final String observacionFinal;
  final List<String> fotosUrls;

  bool get esJugado => estado == PartidoEstado.jugado;
  bool get esProximo => estado == PartidoEstado.programado;

  String? get resultadoTexto {
    if (!esJugado || golesLocal == null || golesRival == null) return null;
    return '$golesLocal - $golesRival';
  }

  static List<String> _leerFotos(Map<String, dynamic> d) {
    final raw = d['fotosUrls'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
    }
    return [];
  }

  static Partido fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['fechaHora'] as Timestamp?;
    return Partido(
      id: doc.id,
      entrenadorEmail: d['entrenadorEmail'] as String? ?? '',
      fechaHora: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      rival: d['rival'] as String? ?? '',
      lugar: d['lugar'] as String? ?? '',
      notas: d['notas'] as String? ?? '',
      estado: d['estado'] as String? ?? PartidoEstado.programado,
      golesLocal: (d['golesLocal'] as num?)?.toInt(),
      golesRival: (d['golesRival'] as num?)?.toInt(),
      observacionFinal: d['observacionFinal'] as String? ?? '',
      fotosUrls: _leerFotos(d),
    );
  }
}

/// Borrador de observación individual al cerrar un partido.
class ObservacionPartidoJugador {
  const ObservacionPartidoJugador({
    required this.jugadorId,
    required this.jugadorNombre,
    required this.texto,
    required this.rendimiento,
  });

  final String jugadorId;
  final String jugadorNombre;
  final String texto;
  final String rendimiento;
}
