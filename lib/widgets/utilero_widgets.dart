import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/material_categoria_visual.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

class UtileroStatCard extends StatelessWidget {
  const UtileroStatCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.color,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color ?? DtflyTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DtflyTheme.textPrimary,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: DtflyTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UtileroBarChart extends StatelessWidget {
  const UtileroBarChart({
    super.key,
    required this.titulo,
    required this.datos,
  });

  final String titulo;
  final Map<String, int> datos;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$titulo: sin datos aún'),
        ),
      );
    }
    final max = datos.values.reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: DtflyTheme.panelTitle),
            const SizedBox(height: 12),
            ...datos.entries.map((e) {
              final frac = max == 0 ? 0.0 : e.value / max;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 14,
                          backgroundColor: DtflyTheme.surfaceMuted,
                          color: DtflyTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Fila compacta: imagen/icono del material + nombre + cantidad disponible.
class UtileroMaterialStockTile extends StatelessWidget {
  const UtileroMaterialStockTile({
    super.key,
    required this.categoria,
    required this.cantidad,
    this.unidad = 'u.',
  });

  final String categoria;
  final int cantidad;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final visual = MaterialCategoriaVisual.resolver(categoria);
    final cat = UtileroMaterialCat.resolver(categoria);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: visual.colorFondo,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: UtileroMaterialIcon(categoria: cat, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                categoria,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: DtflyTheme.textPrimary,
                ),
              ),
            ),
            Text(
              '$cantidad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: cantidad <= 2
                    ? DtflyTheme.fieldRed
                    : DtflyTheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unidad,
              style: const TextStyle(
                fontSize: 11,
                color: DtflyTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumen general en una sola tarjeta compacta (no grillas grandes).
class UtileroResumenCompacto extends StatelessWidget {
  const UtileroResumenCompacto({
    super.key,
    required this.materialesRegistrados,
    required this.materialesEntregados,
    required this.materialesDevueltos,
    required this.stockBajo,
    required this.materialesDanados,
    required this.entrenamientosSemana,
    required this.entregadosHoy,
  });

  final int materialesRegistrados;
  final int materialesEntregados;
  final int materialesDevueltos;
  final int stockBajo;
  final int materialesDanados;
  final int entrenamientosSemana;
  final int entregadosHoy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen general', style: DtflyTheme.panelTitle.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MiniStat(icon: Icons.category, label: 'Registrados', value: '$materialesRegistrados'),
                _MiniStat(icon: Icons.outbound, label: 'Entregados', value: '$materialesEntregados'),
                _MiniStat(icon: Icons.assignment_return, label: 'Devueltos', value: '$materialesDevueltos'),
                _MiniStat(
                  icon: Icons.warning_amber,
                  label: 'Stock bajo',
                  value: '$stockBajo',
                  highlight: stockBajo > 0,
                ),
                _MiniStat(
                  icon: Icons.broken_image_outlined,
                  label: 'Dañados',
                  value: '$materialesDanados',
                  highlight: materialesDanados > 0,
                ),
                _MiniStat(icon: Icons.sports, label: 'Entren. semana', value: '$entrenamientosSemana'),
                _MiniStat(icon: Icons.today, label: 'Hoy', value: '$entregadosHoy'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? DtflyTheme.fieldRed.withValues(alpha: 0.1)
        : DtflyTheme.surfaceMuted;
    final fg = highlight ? DtflyTheme.fieldRed : DtflyTheme.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: DtflyTheme.textSecondary)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}

class UtileroAlertChip extends StatelessWidget {
  const UtileroAlertChip({
    super.key,
    required this.texto,
    required this.icono,
    this.esCritico = false,
  });

  final String texto;
  final IconData icono;
  final bool esCritico;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icono,
        size: 18,
        color: esCritico ? DtflyTheme.fieldRed : DtflyTheme.accentOrange,
      ),
      label: Text(texto),
      backgroundColor: esCritico
          ? DtflyTheme.fieldRed.withValues(alpha: 0.12)
          : DtflyTheme.accentOrange.withValues(alpha: 0.12),
    );
  }
}
