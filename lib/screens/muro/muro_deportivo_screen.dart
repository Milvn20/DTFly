import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/muro_tipo.dart';
import 'package:flutter_application_1/models/blog_publicacion.dart';
import 'package:flutter_application_1/screens/blog/blog_editor_screen.dart';
import 'package:flutter_application_1/screens/muro/muro_detalle_screen.dart';
import 'package:flutter_application_1/screens/muro/widgets/muro_deportivo_layout.dart';
import 'package:flutter_application_1/services/blog_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Feed reutilizable del Muro Deportivo (incrustable en tabs o pantalla completa).
class MuroDeportivoFeed extends StatefulWidget {
  const MuroDeportivoFeed({
    super.key,
    required this.soloLectura,
    required this.autorEmail,
    required this.autorNombre,
    this.deporteId,
    this.permitirCambiarSeleccion = false,
    this.mostrarFiltros = true,
    this.mostrarEncabezado = true,
    this.nombreUsuario,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  final bool soloLectura;
  final String autorEmail;
  final String autorNombre;
  final String? deporteId;
  final bool permitirCambiarSeleccion;
  final bool mostrarFiltros;
  final bool mostrarEncabezado;
  final String? nombreUsuario;
  final EdgeInsetsGeometry padding;

  @override
  State<MuroDeportivoFeed> createState() => _MuroDeportivoFeedState();
}

class _MuroDeportivoFeedState extends State<MuroDeportivoFeed> {
  MuroTipo? _filtro;
  String? _seleccionVista;

  @override
  void initState() {
    super.initState();
    _seleccionVista = widget.deporteId;
  }

  @override
  void didUpdateWidget(covariant MuroDeportivoFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deporteId != oldWidget.deporteId) {
      _seleccionVista = widget.deporteId;
    }
  }

  String? get _deporteEfectivo =>
      widget.permitirCambiarSeleccion ? _seleccionVista : widget.deporteId;

  Future<void> _abrirDetalle(BlogPublicacion post) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MuroDetalleScreen(
          publicacion: post,
          soloLectura: widget.soloLectura,
          autorEmail: widget.autorEmail,
          autorNombre: widget.autorNombre,
          deporteId: _deporteEfectivo,
          permitirElegirSeleccion: widget.permitirCambiarSeleccion,
        ),
      ),
    );
  }

  Future<void> _abrirEditor(BlogPublicacion? post) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlogEditorScreen(
          publicacion: post,
          autorEmail: widget.autorEmail,
          autorNombre: widget.autorNombre,
          deporteId: post?.deporteId ?? _deporteEfectivo,
          permitirElegirSeleccion: widget.permitirCambiarSeleccion,
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BlogPublicacion post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Eliminar «${post.titulo}» del muro?'),
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
    if (ok != true || !mounted) return;
    await BlogService.eliminar(post.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BlogPublicacion>>(
      stream: BlogService.streamPublicacionesFiltradas(
        _filtro,
        deporteId: _deporteEfectivo,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Color(0xFFF1F5F9),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: Center(
              child: Padding(
                padding: widget.padding,
                child: Text(
                  'Error al cargar el muro: ${snap.error}',
                  style: const TextStyle(color: DtflyTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final posts = snap.data ?? [];

        return ColoredBox(
          color: const Color(0xFFF1F5F9),
          child: MuroDeportivoLayout(
            posts: posts,
            soloLectura: widget.soloLectura,
            deporteId: widget.deporteId,
            filtroTipo: _filtro,
            onCambiarFiltro: (t) => setState(() => _filtro = t),
            onVerDetalle: _abrirDetalle,
            onPublicar: () => _abrirEditor(null),
            onEditar: (p) => _abrirEditor(p),
            onEliminar: _confirmarEliminar,
            permitirCambiarSeleccion: widget.permitirCambiarSeleccion,
            seleccionVista: _seleccionVista,
            onCambiarSeleccion: widget.permitirCambiarSeleccion
                ? (id) => setState(() => _seleccionVista = id)
                : null,
            nombreUsuario: widget.nombreUsuario ?? widget.autorNombre,
            mostrarEncabezado: widget.mostrarEncabezado,
          ),
        );
      },
    );
  }
}

/// Pantalla completa del Muro Deportivo.
class MuroDeportivoScreen extends StatelessWidget {
  const MuroDeportivoScreen({
    super.key,
    required this.soloLectura,
    required this.autorEmail,
    required this.autorNombre,
    this.deporteId,
    this.permitirCambiarSeleccion = false,
  });

  final bool soloLectura;
  final String autorEmail;
  final String autorNombre;
  final String? deporteId;
  final bool permitirCambiarSeleccion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Muro Deportivo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: MuroDeportivoFeed(
        soloLectura: soloLectura,
        autorEmail: autorEmail,
        autorNombre: autorNombre,
        deporteId: deporteId,
        permitirCambiarSeleccion: permitirCambiarSeleccion,
        nombreUsuario: autorNombre,
        mostrarEncabezado: false,
      ),
    );
  }
}
