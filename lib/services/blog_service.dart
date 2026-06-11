import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_application_1/models/blog_publicacion.dart';

/// Blog y noticias (colección `blog_publicaciones`, Storage `blog/`).
class BlogService {
  BlogService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _col = 'blog_publicaciones';

  static Stream<List<BlogPublicacion>> streamPublicaciones() {
    return _db
        .collection(_col)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(BlogPublicacion.fromDoc).toList());
  }

  static Stream<List<BlogPublicacion>> streamAvisosImportantes() {
    return streamPublicaciones().map(
      (list) => list.where((p) => p.esAvisoImportante).toList(),
    );
  }

  static Future<String> crear({
    required String titulo,
    required String contenido,
    required String autorEmail,
    required String autorNombre,
    bool esAvisoImportante = false,
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
      'esAvisoImportante': esAvisoImportante,
      'autorEmail': autorEmail,
      'autorNombre': autorNombre,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> actualizar({
    required String id,
    required String titulo,
    required String contenido,
    bool? esAvisoImportante,
    Uint8List? imagenBytes,
    String? nombreImagen,
    bool quitarImagen = false,
  }) async {
    final data = <String, dynamic>{
      'titulo': titulo,
      'contenido': contenido,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    if (esAvisoImportante != null) {
      data['esAvisoImportante'] = esAvisoImportante;
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

  static Future<String> _subirImagen(Uint8List bytes, String nombre) async {
    final path =
        'blog/${DateTime.now().millisecondsSinceEpoch}_$nombre';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
