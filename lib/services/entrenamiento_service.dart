import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/services/plantel_service.dart';
import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';

/// Colección Firestore: `entrenamientos`.
/// Requiere índice compuesto: `entrenadorEmail` + `estado`.
class EntrenamientoService {
  EntrenamientoService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'entrenamientos';
  static const Duration toleranciaPuntualidad = Duration(minutes: 10);

  static String generarCodigoUnion() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(7, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static Future<String> crearProgramado({
    required String entrenadorEmail,
    required String entrenadorUsuarioId,
    required String cancha,
    required String titulo,
    required DateTime inicio,
    required DateTime fin,
    String? categoriaDeportiva,
  }) async {
    final deporte = categoriaDeportiva;
    final ref = await _db.collection(_col).add({
      'entrenadorEmail': entrenadorEmail,
      'entrenadorUsuarioId': entrenadorUsuarioId,
      'cancha': cancha,
      'titulo': titulo,
      'inicioProgramado': Timestamp.fromDate(inicio),
      'finProgramado': Timestamp.fromDate(fin),
      'estado': 'programado',
      'codigoUnion': '',
      'codigoValidezSegundos': 60,
      if (deporte != null && deporte.isNotEmpty) ...DeporteUsuario.camposAlGuardar(deporte),
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Pasa a `activo`, cierra otros activos del mismo entrenador y asigna código inicial.
  static Future<void> activar(String id) async {
    final ref = _db.collection(_col).doc(id);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Entrenamiento no encontrado');
    final email = snap.data()!['entrenadorEmail'] as String;

    final previos = await _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: email)
        .where('estado', isEqualTo: 'activo')
        .get();

    final batch = _db.batch();
    for (final d in previos.docs) {
      if (d.id == id) continue;
      batch.update(d.reference, {
        'estado': 'programado',
        'codigoUnion': '',
        'codigoActualizadoEn': FieldValue.delete(),
      });
    }
    batch.update(ref, {
      'estado': 'activo',
      'codigoUnion': generarCodigoUnion(),
      'codigoValidezSegundos': 60,
      'codigoActualizadoEn': FieldValue.serverTimestamp(),
      'sesionIniciadaEn': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await registrarAusentesFaltantes(id);
  }

  static Future<void> finalizar(String id) async {
    await registrarAusentesFaltantes(id);
    await _db.collection(_col).doc(id).update({
      'estado': 'finalizado',
      'finalizadoEn': FieldValue.serverTimestamp(),
      'codigoUnion': '',
      'codigoActualizadoEn': FieldValue.delete(),
    });
  }

  /// Asegura que cada jugador del plantel tenga registro como ausente.
  static Future<void> registrarAusentesFaltantes(String entrenamientoId) async {
    final entrenamientoDoc = await _db.collection(_col).doc(entrenamientoId).get();
    if (!entrenamientoDoc.exists) return;
    final entrenamientoData = entrenamientoDoc.data() ?? {};
    final fechaEntrenamiento =
        entrenamientoData['inicioProgramado'] as Timestamp?;
    final tituloEntrenamiento =
        entrenamientoData['titulo'] as String? ?? 'Entrenamiento';
    final entrenadorEmail =
        entrenamientoData['entrenadorEmail'] as String? ?? '';
    var deporte = DeporteUsuario.idDesde(entrenamientoData);

    if (deporte == null || deporte.isEmpty) {
      final entrenadorId =
          entrenamientoData['entrenadorUsuarioId'] as String?;
      if (entrenadorId != null && entrenadorId.isNotEmpty) {
        final coach = await _db.collection('usuarios').doc(entrenadorId).get();
        deporte = DeporteUsuario.idDesde(coach.data() ?? {});
      }
    }

    final jugadoresDocs = await PlantelService.obtenerJugadoresPorDeporte(deporte);
    if (jugadoresDocs.isEmpty) return;

    final asistenciasRef = _db
        .collection(_col)
        .doc(entrenamientoId)
        .collection('asistencias');
    final existentes = await asistenciasRef.get();
    final existentesIds = existentes.docs.map((d) => d.id).toSet();

    WriteBatch? batch;
    var operaciones = 0;

    Future<void> commitPendiente() async {
      if (batch == null || operaciones == 0) return;
      await batch!.commit();
      batch = null;
      operaciones = 0;
    }

    for (final jugador in jugadoresDocs) {
      if (existentesIds.contains(jugador.id)) continue;
      batch ??= _db.batch();
      final data = jugador.data();
      batch!.set(asistenciasRef.doc(jugador.id), {
        'jugadorId': jugador.id,
        'nombre': data['nombre'] as String? ?? 'Sin nombre',
        'email': data['email'] as String? ?? '',
        'estado': 'ausente',
        'unidoEn': null,
        'entrenamientoId': entrenamientoId,
        'entrenamientoTitulo': tituloEntrenamiento,
        'fechaEntrenamiento': fechaEntrenamiento,
        'entrenadorEmail': entrenadorEmail,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      batch!.set(_asistenciaJugadorRef(jugador.id, entrenamientoId), {
        'jugadorId': jugador.id,
        'nombre': data['nombre'] as String? ?? 'Sin nombre',
        'email': data['email'] as String? ?? '',
        'estado': 'ausente',
        'unidoEn': null,
        'entrenamientoId': entrenamientoId,
        'entrenamientoTitulo': tituloEntrenamiento,
        'fechaEntrenamiento': fechaEntrenamiento,
        'entrenadorEmail': entrenadorEmail,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      operaciones += 2;
      if (operaciones >= 400) {
        await commitPendiente();
      }
    }

    await commitPendiente();
  }

  static Future<void> eliminarProgramado(String id) async {
    final ref = _db.collection(_col).doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    if ((snap.data()!['estado'] as String?) == 'activo') {
      throw StateError('No se puede eliminar un entrenamiento en curso');
    }
    await ref.delete();
  }

  static Future<void> rotarCodigoUnion(String id) async {
    await _db.collection(_col).doc(id).update({
      'codigoUnion': generarCodigoUnion(),
      'codigoActualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Entrenamiento>> streamProgramados(String entrenadorEmail) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .where('estado', isEqualTo: 'programado')
        .snapshots()
        .map((s) {
      final list = s.docs.map(Entrenamiento.fromDoc).toList();
      list.sort((a, b) => a.inicioProgramado.compareTo(b.inicioProgramado));
      return list;
    });
  }

  static Stream<Entrenamiento?> streamActivo(String entrenadorEmail) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Entrenamiento.fromDoc(s.docs.first));
  }

  /// Asistencias del entrenamiento en tiempo real (subcolección `asistencias`).
  static Stream<List<AsistenciaRegistro>> streamAsistencias(String entrenamientoId) {
    return _db
        .collection(_col)
        .doc(entrenamientoId)
        .collection('asistencias')
        .snapshots()
        .map((s) {
      final list = s.docs.map(AsistenciaRegistro.fromDoc).toList();
      list.sort((a, b) {
        if (a.unidoEn == null && b.unidoEn == null) {
          return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        }
        if (a.unidoEn == null) return 1;
        if (b.unidoEn == null) return -1;
        return a.unidoEn!.compareTo(b.unidoEn!);
      });
      return list;
    });
  }

  /// El DT marca puntual / atrasado / ausente (opcional, además del auto-registro del alumno).
  static Future<void> actualizarEstadoAsistencia({
    required String entrenamientoId,
    required String jugadorId,
    required String estado,
  }) async {
    final entDoc = await _db.collection(_col).doc(entrenamientoId).get();
    final entData = entDoc.data() ?? {};
    final asistenciaDoc = await _db
        .collection(_col)
        .doc(entrenamientoId)
        .collection('asistencias')
        .doc(jugadorId)
        .get();
    final asistenciaData = asistenciaDoc.data() ?? {};
    final marcadoEn = FieldValue.serverTimestamp();
    final payload = {
      'jugadorId': jugadorId,
      'nombre': asistenciaData['nombre'] as String? ?? '',
      'email': asistenciaData['email'] as String? ?? '',
      'estado': estado,
      'entrenamientoId': entrenamientoId,
      'entrenamientoTitulo': entData['titulo'] as String? ?? 'Entrenamiento',
      'fechaEntrenamiento': entData['inicioProgramado'],
      'entrenadorEmail': entData['entrenadorEmail'] as String? ?? '',
      'marcadoPorDtEn': marcadoEn,
      'actualizadoEn': marcadoEn,
    };

    if (estado != 'ausente' && asistenciaData['unidoEn'] == null) {
      payload['unidoEn'] = marcadoEn;
    }

    final batch = _db.batch();
    batch.set(
      _db
          .collection(_col)
          .doc(entrenamientoId)
          .collection('asistencias')
          .doc(jugadorId),
      payload,
      SetOptions(merge: true),
    );
    batch.set(
      _asistenciaJugadorRef(jugadorId, entrenamientoId),
      payload,
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  static Stream<List<Entrenamiento>> streamHistorial(String entrenadorEmail) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .where('estado', isEqualTo: 'finalizado')
        .snapshots()
        .map((s) {
      final list = s.docs.map(Entrenamiento.fromDoc).toList();
      list.sort((a, b) {
        final fa = a.finalizadoEn ?? a.inicioProgramado;
        final fb = b.finalizadoEn ?? b.inicioProgramado;
        return fb.compareTo(fa);
      });
      return list;
    });
  }

  static Future<Entrenamiento?> obtenerEntrenamientoParaReporte(
    String entrenadorEmail,
  ) async {
    final activo = await _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();
    if (activo.docs.isNotEmpty) {
      return Entrenamiento.fromDoc(activo.docs.first);
    }

    final finalizados = await _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .where('estado', isEqualTo: 'finalizado')
        .get();
    if (finalizados.docs.isEmpty) return null;

    final list = finalizados.docs.map(Entrenamiento.fromDoc).toList();
    list.sort((a, b) {
      final fa = a.finalizadoEn ?? a.inicioProgramado;
      final fb = b.finalizadoEn ?? b.inicioProgramado;
      return fb.compareTo(fa);
    });
    return list.first;
  }

  static Future<List<Entrenamiento>> obtenerEntrenamientosParaReporte(
    String entrenadorEmail,
  ) async {
    final snap = await _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .get();
    final list = snap.docs
        .map(Entrenamiento.fromDoc)
        .where((e) => e.estado == 'activo' || e.estado == 'finalizado')
        .toList();
    list.sort((a, b) => a.inicioProgramado.compareTo(b.inicioProgramado));
    return list;
  }

  static Future<List<AsistenciaRegistro>> obtenerAsistencias(
    String entrenamientoId,
  ) async {
    final snap = await _db
        .collection(_col)
        .doc(entrenamientoId)
        .collection('asistencias')
        .get();
    final list = snap.docs.map(AsistenciaRegistro.fromDoc).toList();
    list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return list;
  }

  static Stream<JugadorProgreso> streamProgresoJugador(String jugadorId) {
    return _db
        .collection('usuarios')
        .doc(jugadorId)
        .collection('asistencias')
        .snapshots()
        .map((snap) {
      final registros = snap.docs.map(AsistenciaRegistro.fromDoc).toList();
      registros.sort((a, b) {
        final fa = a.fechaEntrenamiento ?? a.unidoEn;
        final fb = b.fechaEntrenamiento ?? b.unidoEn;
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });

      final total = registros.length;
      final presentes = registros
          .where((r) => r.estado == 'presente' || r.estado == 'puntual')
          .length;
      final atrasados = registros.where((r) => r.estado == 'atrasado').length;
      final ausentes = registros.where((r) => r.estado == 'ausente').length;
      final asistenciasValidas = presentes + atrasados;
      final asistenciaPct = total == 0 ? 0 : (asistenciasValidas / total * 100).round();
      final puntualidadPct =
          asistenciasValidas == 0 ? 0 : (presentes / asistenciasValidas * 100).round();

      final recientes = registros.take(5).toList().reversed.toList();
      final puntos = <JugadorProgresoPunto>[];
      for (var i = 0; i < recientes.length; i++) {
        final r = recientes[i];
        puntos.add(
          JugadorProgresoPunto(
            etiqueta: 'Ent ${i + 1}',
            asistencia: r.estado == 'ausente' ? 0 : 100,
            puntualidad: r.estado == 'presente' || r.estado == 'puntual'
                ? 100
                : r.estado == 'atrasado'
                    ? 55
                    : 0,
          ),
        );
      }

      return JugadorProgreso(
        total: total,
        presentes: presentes,
        atrasados: atrasados,
        ausentes: ausentes,
        asistenciaPct: asistenciaPct,
        puntualidadPct: puntualidadPct,
        puntos: puntos,
      );
    });
  }

  /// El jugador ingresa el código que muestra el profesor (sesión `activo`).
  /// Crea/actualiza `entrenamientos/{id}/asistencias/{jugadorId}`.
  static Future<String> unirseConCodigo({
    required String codigo,
    required String jugadorUsuarioId,
    required String nombreJugador,
    required String emailJugador,
  }) async {
    final c = codigo.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (c.length < 4) {
      throw StateError('Ingresa el código completo');
    }
    final q = await _db
        .collection(_col)
        .where('codigoUnion', isEqualTo: c)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();
    if (q.docs.isEmpty) {
      throw StateError(
        'Código incorrecto o no hay entrenamiento activo. Pide al profesor el código actual.',
      );
    }
    final entDoc = q.docs.first;
    final entRef = entDoc.reference;
    final data = entDoc.data();
    final deporteEntrenamiento = DeporteUsuario.idDesde(data);
    if (deporteEntrenamiento != null && deporteEntrenamiento.isNotEmpty) {
      final jugadorDoc =
          await _db.collection('usuarios').doc(jugadorUsuarioId).get();
      final deporteJugador =
          DeporteUsuario.idDesde(jugadorDoc.data() ?? {});
      if (deporteJugador == null || deporteJugador.isEmpty) {
        throw StateError(
          'Debes tener un deporte asignado en tu ficha antes de unirte.',
        );
      }
      if (deporteJugador != deporteEntrenamiento) {
        throw StateError(DeporteUsuario.mensajeEntrenamientoOtroDeporte);
      }
    }
    final inicioProgramado =
        (data['inicioProgramado'] as Timestamp?)?.toDate() ?? DateTime.now();
    final inicioTimestamp = data['inicioProgramado'] as Timestamp?;
    final tituloEntrenamiento = data['titulo'] as String? ?? 'Entrenamiento';
    final entrenadorEmail = data['entrenadorEmail'] as String? ?? '';
    final estadoCalculado =
        DateTime.now().isAfter(inicioProgramado.add(toleranciaPuntualidad))
            ? 'atrasado'
            : 'presente';
    final asistenciaRef = entRef.collection('asistencias').doc(jugadorUsuarioId);
    final asistenciaJugadorRef = _asistenciaJugadorRef(
      jugadorUsuarioId,
      entRef.id,
    );

    await _db.runTransaction((tx) async {
      final asistencia = await tx.get(asistenciaRef);
      final estadoActual = asistencia.data()?['estado'] as String?;
      final yaRegistrado = asistencia.exists &&
          estadoActual != null &&
          estadoActual != 'ausente';

      final base = {
        'jugadorId': jugadorUsuarioId,
        'nombre': nombreJugador,
        'email': emailJugador,
        'entrenamientoId': entRef.id,
        'entrenamientoTitulo': tituloEntrenamiento,
        'fechaEntrenamiento': inicioTimestamp,
        'entrenadorEmail': entrenadorEmail,
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

      if (yaRegistrado) {
        tx.set(asistenciaRef, base, SetOptions(merge: true));
        tx.set(asistenciaJugadorRef, base, SetOptions(merge: true));
        return;
      }

      final payload = {
        ...base,
        'estado': estadoCalculado,
        'unidoEn': FieldValue.serverTimestamp(),
        'registroOrigen': 'codigo',
      };
      tx.set(asistenciaRef, payload, SetOptions(merge: true));
      tx.set(asistenciaJugadorRef, payload, SetOptions(merge: true));
    });
    return entRef.id;
  }

  static DocumentReference<Map<String, dynamic>> _asistenciaJugadorRef(
    String jugadorId,
    String entrenamientoId,
  ) {
    return _db
        .collection('usuarios')
        .doc(jugadorId)
        .collection('asistencias')
        .doc(entrenamientoId);
  }

  static Future<EntrenamientoStats> estadisticas(String entrenadorEmail) async {
    final all = await _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .get();
    var programados = 0;
    var activos = 0;
    var finalizados = 0;
    for (final d in all.docs) {
      final e = d.data()['estado'] as String? ?? '';
      if (e == 'programado') programados++;
      if (e == 'activo') activos++;
      if (e == 'finalizado') finalizados++;
    }
    return EntrenamientoStats(
      total: all.docs.length,
      programados: programados,
      activos: activos,
      finalizados: finalizados,
    );
  }
}

class EntrenamientoStats {
  const EntrenamientoStats({
    required this.total,
    required this.programados,
    required this.activos,
    required this.finalizados,
  });

  final int total;
  final int programados;
  final int activos;
  final int finalizados;
}

class JugadorProgreso {
  const JugadorProgreso({
    required this.total,
    required this.presentes,
    required this.atrasados,
    required this.ausentes,
    required this.asistenciaPct,
    required this.puntualidadPct,
    required this.puntos,
  });

  final int total;
  final int presentes;
  final int atrasados;
  final int ausentes;
  final int asistenciaPct;
  final int puntualidadPct;
  final List<JugadorProgresoPunto> puntos;
}

class JugadorProgresoPunto {
  const JugadorProgresoPunto({
    required this.etiqueta,
    required this.asistencia,
    required this.puntualidad,
  });

  final String etiqueta;
  final int asistencia;
  final int puntualidad;
}
