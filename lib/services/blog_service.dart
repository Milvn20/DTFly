import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/muro_tipo.dart';
import 'package:flutter_application_1/models/blog_publicacion.dart';

/// Muro Deportivo (colección `blog_publicaciones`, Storage `blog/`).
class BlogService {
  BlogService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _col = 'blog_publicaciones';

  /// Visible en el muro de una selección (incluye avisos generales).
  static bool perteneceASeleccion(BlogPublicacion p, String? deporteId) {
    if (p.compartidoTodasSelecciones ||
        p.deporteId == DeportesCategoria.idGeneral) {
      return true;
    }
    if (deporteId == null || deporteId.isEmpty) return true;
    final d = p.deporteId;
    if (d == null || d.isEmpty) return true;
    return d == deporteId;
  }

  static List<BlogPublicacion> _ordenarFeed(List<BlogPublicacion> list) {
    final copia = [...list];
    copia.sort((a, b) {
      if (a.fijado != b.fijado) return a.fijado ? -1 : 1;
      if (a.esAvisoImportante != b.esAvisoImportante) {
        return a.esAvisoImportante ? -1 : 1;
      }
      return b.creadoEn.compareTo(a.creadoEn);
    });
    return copia;
  }

  static Stream<List<BlogPublicacion>> streamPublicaciones() {
    return _db
        .collection(_col)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(BlogPublicacion.fromDoc).toList());
  }

  static Stream<List<BlogPublicacion>> streamMuroSeleccion({
    String? deporteId,
    MuroTipo? tipo,
  }) {
    return streamPublicaciones().map((list) {
      var filtrada = list.where((p) => perteneceASeleccion(p, deporteId));
      if (tipo != null) {
        filtrada = filtrada.where((p) => p.tipo == tipo);
      }
      return _ordenarFeed(filtrada.toList());
    });
  }

  static Stream<List<BlogPublicacion>> streamPublicacionesFiltradas(
    MuroTipo? tipo, {
    String? deporteId,
  }) =>
      streamMuroSeleccion(deporteId: deporteId, tipo: tipo);

  static Stream<List<BlogPublicacion>> streamAvisosImportantes({
    String? deporteId,
  }) {
    return streamMuroSeleccion(deporteId: deporteId).map(
      (list) => list.where((p) => p.esAvisoImportante).toList(),
    );
  }

  static Map<String, dynamic> _camposDeporte({
    String? deporteId,
    bool compartidoTodasSelecciones = false,
  }) {
    if (compartidoTodasSelecciones) {
      return {
        ...DeporteUsuario.camposAlGuardar(DeportesCategoria.idGeneral),
        'compartido_todas_selecciones': true,
      };
    }
    if (deporteId == null || deporteId.isEmpty) {
      return {'compartido_todas_selecciones': false};
    }
    return {
      ...DeporteUsuario.camposAlGuardar(deporteId),
      'compartido_todas_selecciones': false,
    };
  }

  static Future<String> crear({
    required String titulo,
    required String contenido,
    required String autorEmail,
    required String autorNombre,
    MuroTipo tipo = MuroTipo.avisoComunicado,
    bool esAvisoImportante = false,
    bool fijado = false,
    bool compartidoTodasSelecciones = false,
    String? deporteId,
    String? partidoId,
    bool generadoAutomaticamente = false,
    Uint8List? imagenBytes,
    String? nombreImagen,
  }) async {
    String imagenUrl = '';
    if (imagenBytes != null && imagenBytes.isNotEmpty) {
      imagenUrl = await _subirImagen(imagenBytes, nombreImagen ?? 'foto.jpg');
    }
    final ref = await _db.collection(_col).add({
      'titulo': titulo,
      'contenido': contenido,
      'imagenUrl': imagenUrl,
      'tipo': tipo.id,
      'esAvisoImportante': esAvisoImportante,
      'fijado': fijado,
      'autorEmail': autorEmail,
      'autorNombre': autorNombre,
      'partidoId': partidoId,
      'generadoAutomaticamente': generadoAutomaticamente,
      'creadoEn': FieldValue.serverTimestamp(),
      ..._camposDeporte(
        deporteId: deporteId,
        compartidoTodasSelecciones: compartidoTodasSelecciones,
      ),
    });
    return ref.id;
  }

  static Future<void> actualizar({
    required String id,
    required String titulo,
    required String contenido,
    MuroTipo? tipo,
    bool? esAvisoImportante,
    bool? fijado,
    bool? compartidoTodasSelecciones,
    String? deporteId,
    Uint8List? imagenBytes,
    String? nombreImagen,
    bool quitarImagen = false,
  }) async {
    final data = <String, dynamic>{
      'titulo': titulo,
      'contenido': contenido,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    if (tipo != null) data['tipo'] = tipo.id;
    if (esAvisoImportante != null) {
      data['esAvisoImportante'] = esAvisoImportante;
    }
    if (fijado != null) data['fijado'] = fijado;
    if (compartidoTodasSelecciones != null ||
        deporteId != null) {
      data.addAll(
        _camposDeporte(
          deporteId: deporteId,
          compartidoTodasSelecciones:
              compartidoTodasSelecciones ?? false,
        ),
      );
    }
    if (quitarImagen) {
      data['imagenUrl'] = '';
    } else if (imagenBytes != null && imagenBytes.isNotEmpty) {
      data['imagenUrl'] = await _subirImagen(
        imagenBytes,
        nombreImagen ?? 'foto.jpg',
      );
    }
    await _db.collection(_col).doc(id).update(data);
  }

  static Future<void> eliminar(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    final url = doc.data()?['imagenUrl'] as String? ?? '';
    await _db.collection(_col).doc(id).delete();
    if (url.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (_) {}
    }
  }

  static Future<void> eliminarPorPartido(String partidoId) async {
    final snap = await _db
        .collection(_col)
        .where('partidoId', isEqualTo: partidoId)
        .get();
    for (final doc in snap.docs) {
      await eliminar(doc.id);
    }
  }

  static Future<void> _upsertPartido({
    required String partidoId,
    required MuroTipo tipo,
    required String titulo,
    required String contenido,
    required String autorEmail,
    required String autorNombre,
    String? deporteId,
    List<String> imagenUrls = const [],
  }) async {
    final snap = await _db
        .collection(_col)
        .where('partidoId', isEqualTo: partidoId)
        .get();
    final existente = snap.docs.where((d) {
      return d.data()['tipo'] == tipo.id;
    }).firstOrNull;

    final imagenUrl = imagenUrls.isNotEmpty ? imagenUrls.first : '';

    if (existente != null) {
      await existente.reference.update({
        'titulo': titulo,
        'contenido': contenido,
        'imagenUrl': imagenUrl,
        'actualizadoEn': FieldValue.serverTimestamp(),
        ..._camposDeporte(deporteId: deporteId),
      });
      return;
    }

    await crear(
      titulo: titulo,
      contenido: contenido,
      autorEmail: autorEmail,
      autorNombre: autorNombre,
      tipo: tipo,
      deporteId: deporteId,
      partidoId: partidoId,
      generadoAutomaticamente: true,
    );
  }

  static String _fmtFechaPartido(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> sincronizarPartidoProgramado({
    required String partidoId,
    required String entrenadorEmail,
    required String entrenadorNombre,
    String? deporteId,
    required DateTime fechaHora,
    required String rival,
    required String lugar,
    String notas = '',
  }) async {
    final titulo = 'Próximo partido vs $rival';
    final buffer = StringBuffer(
      'Fecha: ${_fmtFechaPartido(fechaHora)}\n'
      'Lugar: ${lugar.isNotEmpty ? lugar : 'Por confirmar'}',
    );
    if (notas.trim().isNotEmpty) {
      buffer.write('\n\n$notas');
    }
    await _upsertPartido(
      partidoId: partidoId,
      tipo: MuroTipo.proximoPartido,
      titulo: titulo,
      contenido: buffer.toString(),
      autorEmail: entrenadorEmail,
      autorNombre: entrenadorNombre,
      deporteId: deporteId,
    );
  }

  static Future<void> sincronizarResultadoPartido({
    required String partidoId,
    required String entrenadorEmail,
    required String entrenadorNombre,
    String? deporteId,
    required String rival,
    required int golesLocal,
    required int golesRival,
    String observacionFinal = '',
    List<String> fotosUrls = const [],
  }) async {
    final titulo = 'Resultado vs $rival';
    final buffer = StringBuffer(
      'Marcador: $golesLocal - $golesRival\n'
      'Fecha del partido registrada en calendario.',
    );
    if (observacionFinal.trim().isNotEmpty) {
      buffer.write('\n\n$observacionFinal');
    }
    await _upsertPartido(
      partidoId: partidoId,
      tipo: MuroTipo.resultado,
      titulo: titulo,
      contenido: buffer.toString(),
      autorEmail: entrenadorEmail,
      autorNombre: entrenadorNombre,
      deporteId: deporteId,
      imagenUrls: fotosUrls,
    );
  }

  static Future<void> publicarActividadSemana({
    required String entrenadorEmail,
    required String entrenadorNombre,
    String? deporteId,
    required String texto,
  }) async {
    await crear(
      titulo: 'Actividades de la semana',
      contenido: texto.trim(),
      autorEmail: entrenadorEmail,
      autorNombre: entrenadorNombre,
      tipo: MuroTipo.actividadSemana,
      deporteId: deporteId,
      generadoAutomaticamente: true,
    );
  }

  static Future<String> _subirImagen(Uint8List bytes, String nombre) async {
    final path = 'blog/${DateTime.now().millisecondsSinceEpoch}_$nombre';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
