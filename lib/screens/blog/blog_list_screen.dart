import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/blog_publicacion.dart';
import 'package:flutter_application_1/screens/blog/blog_editor_screen.dart';
import 'package:flutter_application_1/services/blog_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Listado de blog: lectura para alumnos, gestión para entrenador.
class BlogListScreen extends StatelessWidget {
  const BlogListScreen({
    super.key,
    required this.soloLectura,
    required this.autorEmail,
    required this.autorNombre,
  });

  final bool soloLectura;
  final String autorEmail;
  final String autorNombre;

  @override
  Widget build(BuildContext context) {
    return DtflyDarkScaffold(
      title: soloLectura ? 'Noticias y avisos' : 'Blog y noticias',
      floatingActionButton: soloLectura
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirEditor(context, null),
              backgroundColor: DtflyTheme.primary,
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
            ),
      body: StreamBuilder<List<BlogPublicacion>>(
        stream: BlogService.streamPublicaciones(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error al cargar: ${snap.error}',
                style: const TextStyle(color: DtflyTheme.textSecondary),
              ),
            );
          }
          final posts = snap.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay publicaciones.',
                style: TextStyle(color: DtflyTheme.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, i) => _PostCard(
              post: posts[i],
              soloLectura: soloLectura,
              onEditar: () => _abrirEditor(context, posts[i]),
              onEliminar: () => _confirmarEliminar(context, posts[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirEditor(
    BuildContext context,
    BlogPublicacion? post,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlogEditorScreen(
          publicacion: post,
          autorEmail: autorEmail,
          autorNombre: autorNombre,
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    BlogPublicacion post,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Eliminar «${post.titulo}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await BlogService.eliminar(post.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada.')),
      );
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.soloLectura,
    required this.onEditar,
    required this.onEliminar,
  });

  final BlogPublicacion post;
  final bool soloLectura;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return DtflyDarkCard(
      destacado: post.esAvisoImportante,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.esAvisoImportante)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DtflyTheme.accentOrange.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AVISO IMPORTANTE',
                style: TextStyle(
                  color: DtflyTheme.accentOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          if (post.imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imagenUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (post.imagenUrl.isNotEmpty) const SizedBox(height: 10),
          Text(
            post.titulo,
            style: const TextStyle(
              color: DtflyTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.contenido,
            style: const TextStyle(color: DtflyTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${post.autorNombre} · ${_fmt(post.creadoEn)}',
            style: const TextStyle(color: DtflyTheme.textMuted, fontSize: 12),
          ),
          if (!soloLectura) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
