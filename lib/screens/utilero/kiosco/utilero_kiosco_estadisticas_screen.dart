import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Estadísticas simples — barras estilo DT.
class UtileroKioscoEstadisticasScreen extends StatelessWidget {
  const UtileroKioscoEstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(
        backgroundColor: DtflyTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Estadísticas'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: InventarioService.streamMateriales(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: DtflyTheme.primary));
          }
          final mats = snap.data ?? [];
          final total = UtileroInventarioKiosco.totalDesdeMateriales(mats);
          final disp = UtileroInventarioKiosco.stockDesdeMateriales(mats);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Stock inicial vs actual',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...UtileroMaterialCat.todas.map((cat) {
                final t = total[cat.id] ?? 0;
                final d = disp[cat.id] ?? 0;
                if (t == 0 && d == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BarraComparativa(categoria: cat, inicial: t, actual: d),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _BarraComparativa extends StatelessWidget {
  const _BarraComparativa({
    required this.categoria,
    required this.inicial,
    required this.actual,
  });

  final UtileroMaterialCat categoria;
  final int inicial;
  final int actual;

  @override
  Widget build(BuildContext context) {
    final maxVal = [inicial, actual, 1].reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DtflyTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UtileroMaterialIcon(categoria: categoria, size: 24),
              const SizedBox(width: 8),
              Text(
                categoria.nombre,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _barra('Inicial', inicial, maxVal, DtflyTheme.textMuted),
          const SizedBox(height: 8),
          _barra('Disponible', actual, maxVal, DtflyTheme.success),
        ],
      ),
    );
  }

  Widget _barra(String label, int valor, double maxVal, Color color) {
    final frac = valor / maxVal;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: DtflyTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: frac.clamp(0.08, 1.0),
                child: Container(
                  height: 32,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$valor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
