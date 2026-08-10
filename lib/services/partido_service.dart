import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/models/observacion_jugador.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/services/blog_service.dart';
import 'package:flutter_application_1/services/observacion_service.dart';

/// Partidos / fixture (colección `partidos`, Storage `partidos/`).
class PartidoService {
  PartidoService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _col = 'partidos';

  static Future<String> crear({
    required String entrenadorEmail,
    required String entrenadorUsuarioId,
    required DateTime fechaHora,
    required String rival,
    required String lugar,
    String notas = '',
    String? categoriaDeportiva,
    String entrenadorNombre = 'DT',
  }) async {
    final ref = await _db.collection(_col).add({
      'entrenadorEmail': entrenadorEmail,
      'entrenadorUsuarioId': entrenadorUsuarioId,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'rival': rival,
      'lugar': lugar,
      'notas': notas,
      'estado': PartidoEstado.programado,
      'fotosUrls': <String>[],
      'observacionFinal': '',
      'creadoEn': FieldValue.serverTimestamp(),
      if (categoriaDeportiva != null && categoriaDeportiva.isNotEmpty)
        ...DeporteUsuario.camposAlGuardar(categoriaDeportiva),
    });

    await BlogService.sincronizarPartidoProgramado(
      partidoId: ref.id,
      entrenadorEmail: entrenadorEmail,
      entrenadorNombre: entrenadorNombre,
      deporteId: categoriaDeportiva,
      fechaHora: fechaHora,
      rival: rival,
      lugar: lugar,
      notas: notas,
    );

    return ref.id;
  }

  static Future<void> actualizar({
    required String id,
    DateTime? fechaHora,
    String? rival,
    String? lugar,
    String? notas,
    String? entrenadorEmail,
    String? entrenadorNombre,
    String? categoriaDeportiva,
  }) async {
    final data = <String, dynamic>{};
    if (fechaHora != null) {
      data['fechaHora'] = Timestamp.fromDate(fechaHora);
    }
    if (rival != null) data['rival'] = rival;
    if (lugar != null) data['lugar'] = lugar;
    if (notas != null) data['notas'] = notas;
    if (data.isEmpty) return;
    await _db.collection(_col).doc(id).update(data);

    final doc = await _db.collection(_col).doc(id).get();
    final d = doc.data();
    if (d == null) return;
    final p = Partido.fromDoc(doc);
    await BlogService.sincronizarPartidoProgramado(
      partidoId: id,
      entrenadorEmail: entrenadorEmail ?? p.entrenadorEmail,
      entrenadorNombre: entrenadorNombre ?? 'DT',
      deporteId: categoriaDeportiva ?? p.deporteId,
      fechaHora: p.fechaHora,
      rival: p.rival,
      lugar: p.lugar,
      notas: p.notas,
    );
  }

  static Future<String> subirFoto(
    Uint8List bytes,
    String partidoId,
    String nombreArchivo,
  ) async {
    final path =
        'partidos/$partidoId/${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  static Future<List<String>> subirFotos({
    required String partidoId,
    required List<Uint8List> fotos,
    required List<String> nombres,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < fotos.length; i++) {
      final nombre = i < nombres.length ? nombres[i] : 'foto_$i.jpg';
      urls.add(await subirFoto(fotos[i], partidoId, nombre));
    }
    return urls;
  }

  /// Registra resultado, observación del partido, fotos y observaciones por jugador.
  static Future<void> registrarCierrePartido({
    required String partidoId,
    required String entrenadorEmail,
    required String entrenadorUsuarioId,
    required String rival,
    required int golesLocal,
    required int golesRival,
    String observacionFinal = '',
    List<String> fotosUrlsExistentes = const [],
    List<Uint8List> fotosNuevas = const [],
    List<String> nombresFotosNuevas = const [],
    List<ObservacionPartidoJugador> observacionesJugadores = const [],
    String entrenadorNombre = 'DT',
    String? categoriaDeportiva,
  }) async {
    final nuevasUrls = fotosNuevas.isEmpty
        ? <String>[]
        : await subirFotos(
            partidoId: partidoId,
            fotos: fotosNuevas,
            nombres: nombresFotosNuevas,
          );

    final todasFotos = [...fotosUrlsExistentes, ...nuevasUrls];

    await _db.collection(_col).doc(partidoId).update({
      'estado': PartidoEstado.jugado,
      'golesLocal': golesLocal,
      'golesRival': golesRival,
      'observacionFinal': observacionFinal.trim(),
      'fotosUrls': todasFotos,
      'cerradoEn': FieldValue.serverTimestamp(),
    });

    final doc = await _db.collection(_col).doc(partidoId).get();
    final deporteId =
        categoriaDeportiva ?? Partido.fromDoc(doc).deporteId;

    await BlogService.sincronizarResultadoPartido(
      partidoId: partidoId,
      entrenadorEmail: entrenadorEmail,
      entrenadorNombre: entrenadorNombre,
      deporteId: deporteId,
      rival: rival,
      golesLocal: golesLocal,
      golesRival: golesRival,
      observacionFinal: observacionFinal,
      fotosUrls: todasFotos,
    );

    final refTitulo = 'Partido vs $rival';
    for (final obs in observacionesJugadores) {
      if (obs.texto.trim().isEmpty) continue;
      await ObservacionService.crear(
        jugadorId: obs.jugadorId,
        jugadorNombre: obs.jugadorNombre,
        entrenadorEmail: entrenadorEmail,
        entrenadorUsuarioId: entrenadorUsuarioId,
        tipo: ObservacionTipo.partido,
        texto: obs.texto.trim(),
        rendimiento: obs.rendimiento,
        partidoId: partidoId,
        referenciaTitulo: refTitulo,
      );
    }
  }

  static Future<void> registrarResultado({
    required String id,
    required int golesLocal,
    required int golesRival,
    String entrenadorEmail = '',
    String entrenadorNombre = 'DT',
    String? categoriaDeportiva,
  }) async {
    await _db.collection(_col).doc(id).update({
      'estado': PartidoEstado.jugado,
      'golesLocal': golesLocal,
      'golesRival': golesRival,
    });

    final doc = await _db.collection(_col).doc(id).get();
    final p = Partido.fromDoc(doc);
    await BlogService.sincronizarResultadoPartido(
      partidoId: id,
      entrenadorEmail: entrenadorEmail.isNotEmpty ? entrenadorEmail : p.entrenadorEmail,
      entrenadorNombre: entrenadorNombre,
      deporteId: categoriaDeportiva ?? p.deporteId,
      rival: p.rival,
      golesLocal: golesLocal,
      golesRival: golesRival,
    );
  }

  static Future<void> eliminar(String id) async {
    await BlogService.eliminarPorPartido(id);
    await _db.collection(_col).doc(id).delete();
  }

  static List<Partido> _ordenar(List<Partido> list) {
    list.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    return list;
  }

  static List<Partido> _proximosDe(List<Partido> todos) {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    return _ordenar(
      todos.where((p) {
        if (p.estado != PartidoEstado.programado) return false;
        final d = DateTime(
          p.fechaHora.year,
          p.fechaHora.month,
          p.fechaHora.day,
        );
        return !d.isBefore(inicioHoy);
      }).toList(),
    );
  }

  static List<Partido> _jugadosDe(List<Partido> todos) {
    final list = todos.where((p) => p.estado == PartidoEstado.jugado).toList();
    list.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return list;
  }

  static Stream<List<Partido>> _streamFiltrado(
    Stream<QuerySnapshot<Map<String, dynamic>>> base,
    List<Partido> Function(List<Partido>) filtro,
  ) {
    return base.map((s) => filtro(s.docs.map(Partido.fromDoc).toList()));
  }

  static Stream<List<Partido>> streamProximos(String entrenadorEmail) {
    return _streamFiltrado(
      _db
          .collection(_col)
          .where('entrenadorEmail', isEqualTo: entrenadorEmail)
          .snapshots(),
      _proximosDe,
    );
  }

  static Stream<List<Partido>> streamProximosGlobales() {
    return _streamFiltrado(_db.collection(_col).snapshots(), _proximosDe);
  }

  static Stream<List<Partido>> streamProximosSeleccion(String? deporteId) {
    return streamProximosGlobales().map(
      (list) => list
          .where((p) =>
              deporteId == null ||
              deporteId.isEmpty ||
              p.deporteId == null ||
              p.deporteId!.isEmpty ||
              p.deporteId == deporteId)
          .toList(),
    );
  }

  static Stream<List<Partido>> streamResultados(String entrenadorEmail) {
    return _streamFiltrado(
      _db
          .collection(_col)
          .where('entrenadorEmail', isEqualTo: entrenadorEmail)
          .snapshots(),
      _jugadosDe,
    );
  }

  static Stream<List<Partido>> streamResultadosGlobales() {
    return _streamFiltrado(_db.collection(_col).snapshots(), _jugadosDe);
  }

  static Stream<List<Partido>> streamTodosEntrenador(String entrenadorEmail) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .snapshots()
        .map((s) {
      final list = s.docs.map(Partido.fromDoc).toList();
      list.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      return list;
    });
  }
}
