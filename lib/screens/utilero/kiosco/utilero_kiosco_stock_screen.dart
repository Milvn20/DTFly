import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Pestaña Inventario — grid compacto de stock por categoría.
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
            borderRadius: BorderRadius.circular(14),
            elevation: 1,
            child: InkWell(
              onTap: () => _agregar(context),
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Agregar material',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Puedes agregar foto al crear un material nuevo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: DtflyTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: InventarioService.streamMateriales(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Color(0xFFC62828),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                );
              }
              final mats = snap.data ?? [];
              final stock = UtileroInventarioKiosco.stockDesdeMateriales(mats);
              final total = UtileroInventarioKiosco.totalDesdeMateriales(mats);
              final conFoto =
                  UtileroInventarioKiosco.materialesConImagen(mats);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 6.0;
                      final cols = constraints.maxWidth >= 500 ? 4 : 3;
                      final itemWidth =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;
                      const itemHeight = 72.0;

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
                                stockBajo: (stock[cat.id] ?? 0) <=
                                    UtileroMaterialCat.umbralStockBajo,
                                imagenUrl: UtileroInventarioKiosco
                                    .imagenDeCategoria(mats, cat),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (conFoto.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Materiales con foto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DtflyTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...conFoto.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _MaterialConFotoFila(material: m),
                      ),
                    ),
                  ],
                ],
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
    this.imagenUrl,
  });

  final UtileroMaterialCat cat;
  final int disponible;
  final int total;
  final bool stockBajo;
  final String? imagenUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: stockBajo ? const Color(0xFFC62828) : DtflyTheme.borderSubtle,
          width: stockBajo ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          UtileroMaterialIcon(
            categoria: cat,
            size: 18,
            imagenUrl: imagenUrl,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cat.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cat.color,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: stockBajo
                            ? const Color(0xFFC62828)
                            : DtflyTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'disp.',
                      style: TextStyle(
                        fontSize: 8,
                        color: DtflyTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (stockBajo)
                  const Text(
                    'BAJO',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.bold,
                      fontSize: 7,
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

class _MaterialConFotoFila extends StatelessWidget {
  const _MaterialConFotoFila({required this.material});

  final MaterialInventario material;

  @override
  Widget build(BuildContext context) {
    final cat = UtileroMaterialCat.resolver(
      '${material.categoria} ${material.nombre}',
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DtflyTheme.borderSubtle, width: 0.8),
      ),
      child: Row(
        children: [
          UtileroMaterialThumbnail(
            categoria: cat,
            imagenUrl: material.imagenUrl,
            size: 36,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  material.categoria,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DtflyTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${material.cantidadDisponible}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'disp.',
                style: TextStyle(fontSize: 9, color: DtflyTheme.textSecondary),
              ),
            ],
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
