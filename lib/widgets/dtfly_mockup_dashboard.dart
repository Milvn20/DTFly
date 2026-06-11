import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';

/// Color rojo sólido del mockup DTFly (#C62828).
const Color dtflyMockupRed = Color(0xFFC62828);

/// App bar del mockup: menú (izq.) | logo DTFly (der.).
class DtflyMockupAppBar extends StatelessWidget {
  const DtflyMockupAppBar({
    super.key,
    this.onMenu,
    this.onNotificaciones,
  });

  final VoidCallback? onMenu;
  final VoidCallback? onNotificaciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
            onPressed: onMenu ?? () {},
          ),
          const Spacer(),
          if (onNotificaciones != null)
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
              onPressed: onNotificaciones,
            ),
          const DtflyCoachLogo(size: 52),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Tarjeta estadística horizontal del mockup (icono | número + etiqueta).
class DtflyMockupStatTile extends StatelessWidget {
  const DtflyMockupStatTile({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icono, color: dtflyMockupRed, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DtflyTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DtflyTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera roja completa del mockup: app bar + saludo + avatar + stats 2×2.
class DtflyMockupDashboardHeader extends StatelessWidget {
  const DtflyMockupDashboardHeader({
    super.key,
    required this.saludo,
    required this.subtitulo,
    required this.stats,
    this.fotoUrl,
    this.onMenu,
    this.onNotificaciones,
    this.compacto = false,
  });

  final String saludo;
  final String subtitulo;
  final List<({IconData icono, String valor, String etiqueta})> stats;
  final String? fotoUrl;
  final VoidCallback? onMenu;
  final VoidCallback? onNotificaciones;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9B1C1C), dtflyMockupRed],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DtflyMockupAppBar(
                onMenu: onMenu,
                onNotificaciones: onNotificaciones,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saludo,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: compacto ? 20 : 24,
                            ),
                          ),
                          SizedBox(height: compacto ? 2 : 4),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: compacto ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fotoUrl != null && fotoUrl!.isNotEmpty)
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        backgroundImage: NetworkImage(fotoUrl!),
                      ),
                  ],
                ),
              ),
              if (stats.length >= 4) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DtflyMockupStatTile(
                              icono: stats[0].icono,
                              valor: stats[0].valor,
                              etiqueta: stats[0].etiqueta,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DtflyMockupStatTile(
                              icono: stats[1].icono,
                              valor: stats[1].valor,
                              etiqueta: stats[1].etiqueta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DtflyMockupStatTile(
                              icono: stats[2].icono,
                              valor: stats[2].valor,
                              etiqueta: stats[2].etiqueta,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DtflyMockupStatTile(
                              icono: stats[3].icono,
                              valor: stats[3].valor,
                              etiqueta: stats[3].etiqueta,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else
                SizedBox(height: compacto ? 20 : 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja blanca con esquinas superiores redondeadas (contenido principal mockup).
class DtflyMockupContentSheet extends StatelessWidget {
  const DtflyMockupContentSheet({
    super.key,
    required this.child,
    this.overlap = 20,
  });

  final Widget child;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -overlap),
      child: Container(
        decoration: const BoxDecoration(
          color: DtflyTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: child,
      ),
    );
  }
}

/// Badge «En curso» del mockup.
class DtflyMockupBadge extends StatelessWidget {
  const DtflyMockupBadge(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: dtflyMockupRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: dtflyMockupRed,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Tarjeta blanca interior (ubicación / detalle).
class DtflyMockupInnerCard extends StatelessWidget {
  const DtflyMockupInnerCard({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
  });

  final String emoji;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DtflyTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DtflyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: DtflyTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón rojo ancho del mockup.
class DtflyMockupPrimaryButton extends StatelessWidget {
  const DtflyMockupPrimaryButton({
    super.key,
    required this.texto,
    required this.onTap,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? onTap;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dtflyMockupRed,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: cargando ? null : onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: cargando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Layout completo mockup: header rojo + hoja blanca desplazable.
class DtflyMockupDashboardLayout extends StatelessWidget {
  const DtflyMockupDashboardLayout({
    super.key,
    required this.saludo,
    required this.subtitulo,
    required this.stats,
    required this.child,
    this.fotoUrl,
    this.onRefresh,
    this.onMenu,
    this.onNotificaciones,
    this.compacto = false,
  });

  final String saludo;
  final String subtitulo;
  final List<({IconData icono, String valor, String etiqueta})> stats;
  final Widget child;
  final String? fotoUrl;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onMenu;
  final VoidCallback? onNotificaciones;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final overlap = stats.length >= 4 ? 20.0 : 12.0;

    return ColoredBox(
      color: dtflyMockupRed,
      child: Column(
        children: [
          DtflyMockupDashboardHeader(
            saludo: saludo,
            subtitulo: subtitulo,
            stats: stats,
            fotoUrl: fotoUrl,
            onMenu: onMenu,
            onNotificaciones: onNotificaciones,
            compacto: compacto,
          ),
          Expanded(
            child: DtflyMockupContentSheet(
              overlap: overlap,
              child: onRefresh != null
                  ? RefreshIndicator(
                      onRefresh: onRefresh!,
                      color: dtflyMockupRed,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: compacto
                            ? const EdgeInsets.fromLTRB(14, 16, 14, 88)
                            : const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        children: [child],
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: compacto
                          ? const EdgeInsets.fromLTRB(14, 16, 14, 88)
                          : const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      children: [child],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
