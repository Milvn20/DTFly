import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_ingresar_stock_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Pestaña Inventario — grid compacto de stock por categoría y materiales «Más».
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
            'Toca para sumar stock · «Agregar material» para uno nuevo con tu foto',
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
              final agregados =
                  UtileroInventarioKiosco.materialesAgregados(mats);

              return LayoutBuilder(
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
                          for (final cat in UtileroMaterialCat.todas
                              .where((c) => c.id != 'mas'))
                        Builder(builder: (context) {
                          final img = UtileroInventarioKiosco
                              .imagenDeCategoria(mats, cat);
                          return SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: _InventarioMiniCard(
                            titulo: cat.nombre,
                            tituloColor: cat.color,
                            disponible: stock[cat.id] ?? 0,
                            stockBajo: (stock[cat.id] ?? 0) <=
                                UtileroMaterialCat.umbralStockBajo,
                            categoria: cat,
                            imagenUrl: img.url,
                            imagenBase64: img.base64,
                            onTap: () {
                              UtileroIngresarStockDialog.mostrarPorCategoria(
                                context,
                                categoria: cat,
                                usuarioId: usuarioId,
                                disponible: stock[cat.id] ?? 0,
                                total: total[cat.id] ?? 0,
                                imagenUrl: img.url,
                                imagenBase64: img.base64,
                              );
                            },
                          ),
                        );
                        }),
                      for (final m in agregados)
                        SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: _InventarioMiniCard(
                            titulo: m.nombre,
                            tituloColor: const Color(0xFF6C757D),
                            disponible: m.cantidadDisponible,
                            stockBajo: m.cantidadDisponible <=
                                UtileroMaterialCat.umbralStockBajo,
                            categoria: UtileroMaterialCat.todas
                                .firstWhere((c) => c.id == 'mas'),
                            imagenUrl: m.imagenUrl,
                            imagenBase64: m.imagenBase64,
                            onTap: () =>
                                UtileroIngresarStockDialog.mostrarPorMaterial(
                              context,
                              material: m,
                              usuarioId: usuarioId,
                            ),
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

/// Tarjeta compacta unificada (categorías estándar y materiales «Más»).
class _InventarioMiniCard extends StatelessWidget {
  const _InventarioMiniCard({
    required this.titulo,
    required this.tituloColor,
    required this.disponible,
    required this.stockBajo,
    required this.categoria,
    required this.onTap,
    this.imagenUrl,
    this.imagenBase64,
  });

  final String titulo;
  final Color tituloColor;
  final int disponible;
  final bool stockBajo;
  final UtileroMaterialCat categoria;
  final String? imagenUrl;
  final String? imagenBase64;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  stockBajo ? const Color(0xFFC62828) : DtflyTheme.borderSubtle,
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
                categoria: categoria,
                size: 22,
                imagenUrl: imagenUrl,
                imagenBase64: imagenBase64,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: tituloColor,
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
              const Icon(
                Icons.add_circle_outline,
                size: 14,
                color: DtflyTheme.textSecondary,
              ),
            ],
          ),
        ),
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
