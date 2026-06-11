import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Pestaña Inventario — mockup con grid de stock.
class UtileroKioscoStockTab extends StatelessWidget {
  const UtileroKioscoStockTab({super.key, required this.usuarioId});

  final String usuarioId;

  void _agregar(BuildContext context) {
    UtileroAgregarMaterialDialog.mostrar(context, usuarioId: usuarioId);
  }

  @override
  Widget build(BuildContext context) {
    return DtflyMockupDashboardLayout(
      saludo: 'Inventario',
      subtitulo: 'Stock disponible por material',
      stats: const [],
      compacto: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(20),
            elevation: 2,
            child: InkWell(
              onTap: () => _agregar(context),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Agregar material',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Escaleras u otros implementos nuevos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: DtflyTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          StreamBuilder(
            stream: InventarioService.streamMateriales(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFC62828)),
                  ),
                );
              }
              final mats = snap.data ?? [];
              final stock = UtileroInventarioKiosco.stockDesdeMateriales(mats);
              final total = UtileroInventarioKiosco.totalDesdeMateriales(mats);

              return LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final cols = constraints.maxWidth >= 420 ? 3 : 2;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (cols - 1)) / cols;
                  final itemHeight = itemWidth * 1.05;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final cat in UtileroMaterialCat.todas)
                        SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: _StockCardCompacta(
                            cat: cat,
                            disponible: stock[cat.id] ?? 0,
                            total: total[cat.id] ?? 0,
                            stockBajo:
                                (stock[cat.id] ?? 0) <= UtileroMaterialCat.umbralStockBajo,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StockCardCompacta extends StatelessWidget {
  const _StockCardCompacta({
    required this.cat,
    required this.disponible,
    required this.total,
    required this.stockBajo,
  });

  final UtileroMaterialCat cat;
  final int disponible;
  final int total;
  final bool stockBajo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stockBajo ? const Color(0xFFC62828) : DtflyTheme.borderSubtle,
          width: stockBajo ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UtileroMaterialIcon(categoria: cat, size: 22),
          const SizedBox(height: 4),
          Text(
            cat.nombre.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cat.color,
            ),
          ),
          const Spacer(),
          Text(
            '$disponible',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: stockBajo ? const Color(0xFFC62828) : DtflyTheme.textPrimary,
              height: 1,
            ),
          ),
          const Text(
            'Disp.',
            style: TextStyle(fontSize: 10, color: DtflyTheme.textSecondary),
          ),
          if (stockBajo)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '🔴 BAJO',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UtileroKioscoStockScreen extends StatelessWidget {
  const UtileroKioscoStockScreen({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC62828),
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: UtileroKioscoStockTab(usuarioId: usuarioId),
    );
  }
}
