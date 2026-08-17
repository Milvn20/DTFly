import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/muro_tipo.dart';
import 'package:flutter_application_1/models/blog_publicacion.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Layout estilo mockup «Sport Campus» para el Muro Deportivo.
class MuroDeportivoLayout extends StatelessWidget {
  const MuroDeportivoLayout({
    super.key,
    required this.posts,
    required this.soloLectura,
    required this.deporteId,
    required this.filtroTipo,
    required this.onCambiarFiltro,
    required this.onVerDetalle,
    required this.onPublicar,
    required this.onEditar,
    required this.onEliminar,
    this.permitirCambiarSeleccion = false,
    this.seleccionVista,
    this.onCambiarSeleccion,
    this.nombreUsuario,
    this.mostrarEncabezado = true,
  });

  final List<BlogPublicacion> posts;
  final bool soloLectura;
  final String? deporteId;
  final MuroTipo? filtroTipo;
  final ValueChanged<MuroTipo?> onCambiarFiltro;
  final void Function(BlogPublicacion) onVerDetalle;
  final VoidCallback onPublicar;
  final void Function(BlogPublicacion) onEditar;
  final void Function(BlogPublicacion) onEliminar;
  final bool permitirCambiarSeleccion;
  final String? seleccionVista;
  final ValueChanged<String?>? onCambiarSeleccion;
  final String? nombreUsuario;
  final bool mostrarEncabezado;

  String get _seleccionLabel {
    final id = permitirCambiarSeleccion ? seleccionVista : deporteId;
    if (id == null || id.isEmpty) return 'Todas las selecciones';
    return DeportesCategoria.nombreVisible(id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final anchoSidebar = c.maxWidth >= 980;
        final feed = _ColumnaFeed(
          posts: posts,
          soloLectura: soloLectura,
          filtroTipo: filtroTipo,
          onCambiarFiltro: onCambiarFiltro,
          onVerDetalle: onVerDetalle,
          onPublicar: onPublicar,
          onEditar: onEditar,
          onEliminar: onEliminar,
          seleccionLabel: _seleccionLabel,
          permitirCambiarSeleccion: permitirCambiarSeleccion,
          seleccionVista: seleccionVista,
          onCambiarSeleccion: onCambiarSeleccion,
          nombreUsuario: nombreUsuario,
          mostrarEncabezado: mostrarEncabezado,
        );

        final contenido = anchoSidebar
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: feed),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _PanelLateral(
                        deporteId:
                            permitirCambiarSeleccion ? seleccionVista : deporteId,
                        posts: posts,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    feed,
                    const SizedBox(height: 20),
                    _PanelLateral(
                      deporteId:
                          permitirCambiarSeleccion ? seleccionVista : deporteId,
                      posts: posts,
                    ),
                  ],
                ),
              );

        return SingleChildScrollView(child: contenido);
      },
    );
  }
}

class _ColumnaFeed extends StatelessWidget {
  const _ColumnaFeed({
    required this.posts,
    required this.soloLectura,
    required this.filtroTipo,
    required this.onCambiarFiltro,
    required this.onVerDetalle,
    required this.onPublicar,
    required this.onEditar,
    required this.onEliminar,
    required this.seleccionLabel,
    required this.permitirCambiarSeleccion,
    this.seleccionVista,
    this.onCambiarSeleccion,
    this.nombreUsuario,
    this.mostrarEncabezado = true,
  });

  final List<BlogPublicacion> posts;
  final bool soloLectura;
  final MuroTipo? filtroTipo;
  final ValueChanged<MuroTipo?> onCambiarFiltro;
  final void Function(BlogPublicacion) onVerDetalle;
  final VoidCallback onPublicar;
  final void Function(BlogPublicacion) onEditar;
  final void Function(BlogPublicacion) onEliminar;
  final String seleccionLabel;
  final bool permitirCambiarSeleccion;
  final String? seleccionVista;
  final ValueChanged<String?>? onCambiarSeleccion;
  final String? nombreUsuario;
  final bool mostrarEncabezado;

  static const _accesos = [
    (tipo: MuroTipo.fechaImportante, titulo: 'Fechas\nimportantes', color: Color(0xFF2563EB)),
    (tipo: MuroTipo.actividadSemana, titulo: 'Actividades\nde la semana', color: Color(0xFF059669)),
    (tipo: MuroTipo.proximoPartido, titulo: 'Próximos\npartidos', color: Color(0xFFEA580C)),
    (tipo: MuroTipo.tablaPosiciones, titulo: 'Tabla de\nposiciones', color: Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarEncabezado) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Muro Deportivo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entérate de todo lo que pasa en $seleccionLabel',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (nombreUsuario != null && nombreUsuario!.isNotEmpty)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: DtflyTheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        nombreUsuario!.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: DtflyTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreUsuario!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Estudiante',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (permitirCambiarSeleccion && onCambiarSeleccion != null) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ChipSeleccion(
                  label: 'Todas',
                  activo: seleccionVista == null,
                  onTap: () => onCambiarSeleccion!(null),
                ),
                for (final d in DeportesCategoria.todas) ...[
                  const SizedBox(width: 8),
                  _ChipSeleccion(
                    label: d.nombre,
                    activo: seleccionVista == d.id,
                    onTap: () => onCambiarSeleccion!(d.id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: cols == 4 ? 1.55 : 1.35,
              children: [
                for (final a in _accesos)
                  _AccesoRapidoCard(
                    titulo: a.titulo,
                    icono: a.tipo.icono,
                    color: a.color,
                    activo: filtroTipo == a.tipo,
                    onTap: () => onCambiarFiltro(
                      filtroTipo == a.tipo ? null : a.tipo,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text(
              'Últimas publicaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (filtroTipo != null)
              TextButton(
                onPressed: () => onCambiarFiltro(null),
                child: Text('Ver todas · ${filtroTipo!.etiquetaCorta}'),
              )
            else
              const Text(
                'Más recientes',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          _EmptyMuro(soloLectura: soloLectura, onPublicar: onPublicar)
        else
          ...posts.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TarjetaPublicacionMockup(
                post: p,
                onTap: () => onVerDetalle(p),
                onEditar: soloLectura ? null : () => onEditar(p),
                onEliminar: soloLectura ? null : () => onEliminar(p),
              ),
            ),
          ),
        if (!soloLectura) ...[
          const SizedBox(height: 8),
          _BarraPublicar(onPublicar: onPublicar, autorNombre: nombreUsuario),
        ],
      ],
    );
  }
}

class _AccesoRapidoCard extends StatelessWidget {
  const _AccesoRapidoCard({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.activo,
    required this.onTap,
  });

  final String titulo;
  final IconData icono;
  final Color color;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: activo ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activo ? color : const Color(0xFFE2E8F0),
              width: activo ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.25,
                  color: activo ? color : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaPublicacionMockup extends StatelessWidget {
  const _TarjetaPublicacionMockup({
    required this.post,
    required this.onTap,
    this.onEditar,
    this.onEliminar,
  });

  final BlogPublicacion post;
  final VoidCallback onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final tipo = post.tipo;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho >= 560;

    Widget imagen = post.imagenUrl.isNotEmpty
        ? Image.network(
            post.imagenUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _PlaceholderImagen(tipo: tipo),
          )
        : _PlaceholderImagen(tipo: tipo);

    final contenido = Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _EtiquetaTipo(tipo: tipo, destacado: post.esAvisoImportante),
                const Spacer(),
                if (onEditar != null || onEliminar != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      if (v == 'editar') onEditar?.call();
                      if (v == 'eliminar') onEliminar?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF1E293B),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.extracto,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                height: 1.45,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: tipo.color.withValues(alpha: 0.15),
                  child: Icon(tipo.icono, size: 14, color: tipo.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.autorNombre.isNotEmpty
                        ? post.autorNombre
                        : 'Equipo DTFly',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  _tiempoRelativo(post.creadoEn),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  child: const Text('Ver más'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: post.esAvisoImportante || post.fijado
                  ? DtflyTheme.accentOrange.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
              width: post.esAvisoImportante || post.fijado ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: horizontal
              ? SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 200, child: imagen),
                      contenido,
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 160, child: imagen),
                    SizedBox(height: 180, child: contenido),
                  ],
                ),
        ),
      ),
    );
  }

  static String _tiempoRelativo(DateTime d) {
    if (d.millisecondsSinceEpoch == 0) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}

class _PlaceholderImagen extends StatelessWidget {
  const _PlaceholderImagen({required this.tipo});

  final MuroTipo tipo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tipo.color.withValues(alpha: 0.85),
            tipo.color.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(tipo.icono, size: 56, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}

class _EtiquetaTipo extends StatelessWidget {
  const _EtiquetaTipo({required this.tipo, this.destacado = false});

  final MuroTipo tipo;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tipo.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        destacado ? '${tipo.etiqueta.toUpperCase()} · IMPORTANTE' : tipo.etiqueta.toUpperCase(),
        style: TextStyle(
          color: tipo.color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BarraPublicar extends StatelessWidget {
  const _BarraPublicar({required this.onPublicar, this.autorNombre});

  final VoidCallback onPublicar;
  final String? autorNombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: DtflyTheme.primary.withValues(alpha: 0.12),
            child: Text(
              (autorNombre ?? 'D').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: DtflyTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onPublicar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Escribe un anuncio para tu selección…',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onPublicar,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Publicar'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLateral extends StatelessWidget {
  const _PanelLateral({required this.deporteId, required this.posts});

  final String? deporteId;
  final List<BlogPublicacion> posts;

  @override
  Widget build(BuildContext context) {
    final tablas = posts.where((p) => p.tipo == MuroTipo.tablaPosiciones).take(1);
    final fechas = posts.where((p) => p.tipo == MuroTipo.fechaImportante).take(3);
    final galeria = posts.where((p) => p.imagenUrl.isNotEmpty).take(4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tablas.isNotEmpty)
          _WidgetPanel(
            titulo: 'Tabla de posiciones',
            child: Text(
              tablas.first.extracto,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        const SizedBox(height: 14),
        _WidgetPanel(
          titulo: 'Próximos partidos',
          child: StreamBuilder<List<Partido>>(
            stream: PartidoService.streamProximosSeleccion(deporteId),
            builder: (context, snap) {
              final partidos = snap.data ?? [];
              if (partidos.isEmpty) {
                return const Text(
                  'No hay partidos programados.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                );
              }
              return Column(
                children: [
                  for (final p in partidos.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${p.fechaHora.day}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                                Text(
                                  _mes(p.fechaHora.month),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'vs ${p.rival}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  p.lugar.isNotEmpty ? p.lugar : 'Lugar por confirmar',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (fechas.isNotEmpty)
          _WidgetPanel(
            titulo: 'Fechas importantes',
            child: Column(
              children: [
                for (final f in fechas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${f.creadoEn.day}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    title: Text(
                      f.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      f.extracto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        if (galeria.isNotEmpty) ...[
          const SizedBox(height: 14),
          _WidgetPanel(
            titulo: 'Galería reciente',
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final g in galeria)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      g.imagenUrl,
                      fit: BoxFit.cover,
                      height: 70,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _mes(int m) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return meses[m - 1];
  }
}

class _WidgetPanel extends StatelessWidget {
  const _WidgetPanel({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyMuro extends StatelessWidget {
  const _EmptyMuro({required this.soloLectura, required this.onPublicar});

  final bool soloLectura;
  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aún no hay publicaciones en este muro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          if (!soloLectura) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPublicar,
              icon: const Icon(Icons.add),
              label: const Text('Publicar primera noticia'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipSeleccion extends StatelessWidget {
  const _ChipSeleccion({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  final String label;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: activo,
      onSelected: (_) => onTap(),
      selectedColor: DtflyTheme.primary.withValues(alpha: 0.15),
      checkmarkColor: DtflyTheme.primary,
    );
  }
}
