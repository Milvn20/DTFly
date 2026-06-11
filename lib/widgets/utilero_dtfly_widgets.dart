import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Cuadro de estadística estilo Inicio DT (grid 2×2).
class DtflyStatCard extends StatelessWidget {
  const DtflyStatCard({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.colorIcono,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color? colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DtflyTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: colorIcono ?? DtflyTheme.primary, size: 28),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: DtflyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              color: DtflyTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón rojo píldora (como «+ Crear entrenamiento»).
class DtflyRedPillButton extends StatelessWidget {
  const DtflyRedPillButton({
    super.key,
    required this.texto,
    required this.onTap,
    this.icono = Icons.add,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? onTap;
  final IconData icono;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.coachRed,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: cargando ? null : onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (cargando)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(icono, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de material/inventario estilo lista Plantel.
class DtflyMaterialRow extends StatelessWidget {
  const DtflyMaterialRow({
    super.key,
    required this.categoria,
    required this.titulo,
    required this.subtitulo,
    required this.trailing,
    this.onTap,
    this.destacado = false,
  });

  final UtileroMaterialCat categoria;
  final String titulo;
  final String subtitulo;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.surfaceCard,
      borderRadius: DtflyTheme.borderRadius,
      elevation: 0,
      child: InkWell(
        borderRadius: DtflyTheme.borderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: DtflyTheme.borderRadius,
            border: Border.all(
              color: destacado ? DtflyTheme.warning : DtflyTheme.borderSubtle,
              width: destacado ? 1.5 : 1,
            ),
            boxShadow: DtflyTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DtflyTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: UtileroMaterialIcon(categoria: categoria, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: DtflyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DtflyTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: DtflyTheme.textMuted, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de acción principal (estilo «Entrenamiento de hoy»).
class DtflyActionCard extends StatelessWidget {
  const DtflyActionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.emoji,
    required this.botonTexto,
    required this.onBoton,
    this.badge,
  });

  final String titulo;
  final String subtitulo;
  final String emoji;
  final String botonTexto;
  final VoidCallback onBoton;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DtflyTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DtflyTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: DtflyTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: DtflyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
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
          const SizedBox(height: 16),
          DtflyRedPillButton(
            texto: botonTexto,
            icono: Icons.inventory_2_outlined,
            onTap: onBoton,
          ),
        ],
      ),
    );
  }
}

/// Título de sección (como «Próximos programados»).
class DtflySectionTitle extends StatelessWidget {
  const DtflySectionTitle(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
  }
}
