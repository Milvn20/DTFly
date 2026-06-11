import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/estadistica_deportiva.dart';

/// Estadísticas deportivas (`estadisticas_deportivas`).
class EstadisticaDeportivaService {
  EstadisticaDeportivaService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'estadisticas_deportivas';

  static const tiposComunes = [
    'goles',
    'asistencias',
    'minutos',
    'distancia_km',
    'intensidad',
    'asistencia_pct',
  ];

  static const periodos = ['sesion', 'semanal', 'mensual'];

  static Future<void> registrar({
    required String jugadorId,
    required String jugadorNombre,
    required String entrenadorEmail,
    required String tipo,
    required double valor,
    required String unidad,
    required String periodo,
    String? deporte,
    String notas = '',
    DateTime? fechaRegistro,
  }) async {
    await _db.collection(_col).add({
      'jugadorId': jugadorId,
      'jugadorNombre': jugadorNombre,
      'entrenadorEmail': entrenadorEmail,
      if (deporte != null && deporte.isNotEmpty) 'deporte': deporte,
      'tipo': tipo,
      'valor': valor,
      'unidad': unidad,
      'periodo': periodo,
      'notas': notas,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro ?? DateTime.now()),
    });
  }

  static Stream<List<EstadisticaDeportiva>> streamPorJugador(
    String jugadorId,
  ) {
    return _db
        .collection(_col)
        .where('jugadorId', isEqualTo: jugadorId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(EstadisticaDeportiva.fromDoc).toList();
      list.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      return list;
    });
  }

  static Stream<ResumenEstadisticasJugador> streamResumenJugador(
    String jugadorId,
  ) {
    return streamPorJugador(jugadorId).map(_calcularResumen);
  }

  static Stream<List<EstadisticaDeportiva>> streamPorEntrenador(
    String entrenadorEmail,
  ) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .snapshots()
        .map((s) {
      final list = s.docs.map(EstadisticaDeportiva.fromDoc).toList();
      list.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      return list;
    });
  }

  static ResumenEstadisticasJugador _calcularResumen(
    List<EstadisticaDeportiva> list,
  ) {
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    final porTipo = <String, double>{};
    final semanal = <String, List<double>>{};
    final mensual = <String, List<double>>{};

    for (final e in list) {
      porTipo[e.tipo] = (porTipo[e.tipo] ?? 0) + e.valor;
      if (!e.fechaRegistro.isBefore(inicioSemana)) {
        semanal.putIfAbsent(e.tipo, () => []).add(e.valor);
      }
      if (!e.fechaRegistro.isBefore(inicioMes)) {
        mensual.putIfAbsent(e.tipo, () => []).add(e.valor);
      }
    }

    double promedio(List<double> vals) =>
        vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;

    return ResumenEstadisticasJugador(
      porTipo: porTipo,
      registrosRecientes: list.take(10).toList(),
      promedioSemanal: {
        for (final e in semanal.entries) e.key: promedio(e.value),
      },
      promedioMensual: {
        for (final e in mensual.entries) e.key: promedio(e.value),
      },
    );
  }

  static Future<void> eliminar(String id) async {
    await _db.collection(_col).doc(id).delete();
  }
}
