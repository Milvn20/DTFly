import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de estadística deportiva (colección `estadisticas_deportivas`).
class EstadisticaDeportiva {
  const EstadisticaDeportiva({
    required this.id,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.entrenadorEmail,
    required this.tipo,
    required this.valor,
    required this.unidad,
    required this.periodo,
    required this.fechaRegistro,
    this.notas,
  });

  final String id;
  final String jugadorId;
  final String jugadorNombre;
  final String entrenadorEmail;
  /// Ej: goles, asistencias, minutos, distancia_km, intensidad.
  final String tipo;
  final double valor;
  final String unidad;
  /// semanal | mensual | sesion
  final String periodo;
  final DateTime fechaRegistro;
  final String? notas;

  static EstadisticaDeportiva fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final ts = d['fechaRegistro'] as Timestamp?;
    return EstadisticaDeportiva(
      id: doc.id,
      jugadorId: d['jugadorId'] as String? ?? '',
      jugadorNombre: d['jugadorNombre'] as String? ?? '',
      entrenadorEmail: d['entrenadorEmail'] as String? ?? '',
      tipo: d['tipo'] as String? ?? 'general',
      valor: (d['valor'] as num?)?.toDouble() ?? 0,
      unidad: d['unidad'] as String? ?? '',
      periodo: d['periodo'] as String? ?? 'sesion',
      fechaRegistro: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      notas: d['notas'] as String?,
    );
  }
}

/// Resumen agregado para gráficos de progreso.
class ResumenEstadisticasJugador {
  const ResumenEstadisticasJugador({
    required this.porTipo,
    required this.registrosRecientes,
    required this.promedioSemanal,
    required this.promedioMensual,
  });

  final Map<String, double> porTipo;
  final List<EstadisticaDeportiva> registrosRecientes;
  final Map<String, double> promedioSemanal;
  final Map<String, double> promedioMensual;
}
