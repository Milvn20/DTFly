import 'package:cloud_firestore/cloud_firestore.dart';

/// Publicación del blog / noticias (colección `blog_publicaciones`).
class BlogPublicacion {
  const BlogPublicacion({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.imagenUrl,
    required this.esAvisoImportante,
    required this.autorEmail,
    required this.autorNombre,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final String id;
  final String titulo;
  final String contenido;
  final String imagenUrl;
  final bool esAvisoImportante;
  final String autorEmail;
  final String autorNombre;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  static BlogPublicacion fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BlogPublicacion(
      id: doc.id,
      titulo: d['titulo'] as String? ?? '',
      contenido: d['contenido'] as String? ?? '',
      imagenUrl: d['imagenUrl'] as String? ?? '',
      esAvisoImportante: d['esAvisoImportante'] as bool? ?? false,
      autorEmail: d['autorEmail'] as String? ?? '',
      autorNombre: d['autorNombre'] as String? ?? '',
      creadoEn: _ts(d['creadoEn']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      actualizadoEn: _ts(d['actualizadoEn']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
