import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/blog_publicacion.dart';
import 'package:flutter_application_1/screens/blog/blog_editor_screen.dart';
import 'package:flutter_application_1/services/blog_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Detalle de una publicación del Muro Deportivo.
class MuroDetalleScreen extends StatelessWidget {
  const MuroDetalleScreen({
    super.key,
    required this.publicacion,
    required this.soloLectura,
    required this.autorEmail,
    required this.autorNombre,
    this.deporteId,
    this.permitirElegirSeleccion = false,
  });

  final BlogPublicacion publicacion;
  final bool soloLectura;
  final String autorEmail;
  final String autorNombre;
  final String? deporteId;
  final bool permitirElegirSeleccion;

  Future<void> _editar(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlogEditorScreen(
          publicacion: publicacion,
          autorEmail: autorEmail,
          autorNombre: autorNombre,
          deporteId: deporteId ?? publicacion.deporteId,
          permitirElegirSeleccion: permitirElegirSeleccion,
        ),
      ),
    );
  }

  Future<void> _eliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Eliminar «${publicacion.titulo}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DtflyTheme.primary),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await BlogService.eliminar(publicacion.id);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = publicacion.tipo;
    final fecha = publicacion.creadoEn;

    return DtflyDarkScaffold(
      title: 'Publicación',
      actions: soloLectura
          ? null
          : [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => _editar(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed: () => _eliminar(context),
              ),
            ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (publicacion.imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                publicacion.imagenUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (publicacion.imagenUrl.isNotEmpty) const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                icono: tipo.icono,
                texto: tipo.etiqueta,
                color: tipo.color,
              ),
              _Badge(
                icono: Icons.sports,
                texto: publicacion.seleccionVisible,
                color: DtflyTheme.secondary,
              ),
              if (publicacion.fijado)
                const _Badge(
                  icono: Icons.push_pin,
                  texto: 'Fijado',
                  color: DtflyTheme.secondary,
                ),
              if (publicacion.esAvisoImportante)
                const _Badge(
                  icono: Icons.priority_high,
                  texto: 'Aviso importante',
                  color: DtflyTheme.accentOrange,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            publicacion.titulo,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: DtflyTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tipo.color.withValues(alpha: 0.15),
                child: Icon(tipo.icono, size: 18, color: tipo.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publicacion.autorNombre.isNotEmpty
                          ? publicacion.autorNombre
                          : 'Equipo DTFly',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: DtflyTheme.textPrimary,
                      ),
                    ),
                    if (fecha.millisecondsSinceEpoch > 0)
                      Text(
                        _fmtFecha(fecha),
                        style: const TextStyle(
                          color: DtflyTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DtflyTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DtflyTheme.borderSubtle),
            ),
            child: Text(
              publicacion.contenido,
              style: const TextStyle(
                color: DtflyTheme.textPrimary,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtFecha(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
