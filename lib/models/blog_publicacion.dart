import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/muro_tipo.dart';

/// Publicación del Muro Deportivo (colección `blog_publicaciones`).
class BlogPublicacion {
  const BlogPublicacion({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.imagenUrl,
    required this.esAvisoImportante,
    required this.tipo,
    required this.autorEmail,
    required this.autorNombre,
    required this.creadoEn,
    this.actualizadoEn,
    this.deporteId,
    this.deporteNombre,
    this.compartidoTodasSelecciones = false,
    this.fijado = false,
    this.partidoId,
    this.generadoAutomaticamente = false,
  });

  final String id;
  final String titulo;
  final String contenido;
  final String imagenUrl;
  final bool esAvisoImportante;
  final MuroTipo tipo;
  final String autorEmail;
  final String autorNombre;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  final String? deporteId;
  final String? deporteNombre;
  final bool compartidoTodasSelecciones;
  final bool fijado;
  final String? partidoId;
  final bool generadoAutomaticamente;

  /// Primeras líneas para la tarjeta del feed.
  String get extracto {
    final t = contenido.trim();
    if (t.length <= 140) return t;
    return '${t.substring(0, 137)}…';
  }

  String get seleccionVisible {
    if (compartidoTodasSelecciones) {
      return 'Todas las selecciones';
    }
    if (deporteNombre != null && deporteNombre!.isNotEmpty) return deporteNombre!;
    return DeportesCategoria.nombreVisible(deporteId);
  }

  static BlogPublicacion fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final deporte = DeporteUsuario.idDesde(d);
    return BlogPublicacion(
      id: doc.id,
      titulo: d['titulo'] as String? ?? '',
      contenido: d['contenido'] as String? ?? '',
      imagenUrl: d['imagenUrl'] as String? ?? '',
      esAvisoImportante: d['esAvisoImportante'] as bool? ?? false,
      tipo: MuroTipo.fromId(d['tipo'] as String?),
      autorEmail: d['autorEmail'] as String? ?? '',
      autorNombre: d['autorNombre'] as String? ?? '',
      creadoEn: _ts(d['creadoEn']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      actualizadoEn: _ts(d['actualizadoEn']),
      deporteId: deporte,
      deporteNombre: DeporteUsuario.nombreDesde(d),
      compartidoTodasSelecciones:
          d['compartido_todas_selecciones'] as bool? ?? false,
      fijado: d['fijado'] as bool? ?? false,
      partidoId: d['partidoId'] as String?,
      generadoAutomaticamente:
          d['generadoAutomaticamente'] as bool? ?? false,
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
