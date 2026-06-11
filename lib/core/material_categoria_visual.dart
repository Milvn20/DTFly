import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';

/// Icono e identidad visual por tipo de material deportivo.
class MaterialCategoriaVisual {
  MaterialCategoriaVisual._();

  static const List<String> categoriasDashboard = [
    'Balones',
    'Conos',
    'Poleras',
    'Lentejas',
    'Petos',
    'Vallas',
  ];

  static CategoriaVisualData resolver(String nombreCategoria) {
    final cat = UtileroMaterialCat.resolver(nombreCategoria);
    return CategoriaVisualData(
      imagenAsset: cat.imagenAsset,
      icono: cat.icono,
      colorFondo: cat.color.withValues(alpha: 0.12),
      colorIcono: cat.color,
    );
  }

  static Map<String, int> stockConDefaults(Map<String, int> raw) {
    final out = <String, int>{};
    for (final c in categoriasDashboard) {
      out[c] = raw[c] ?? 0;
    }
    for (final e in raw.entries) {
      if (!out.containsKey(e.key)) out[e.key] = e.value;
    }
    return out;
  }
}

class CategoriaVisualData {
  const CategoriaVisualData({
    required this.imagenAsset,
    required this.icono,
    required this.colorFondo,
    required this.colorIcono,
  });

  final String imagenAsset;
  final IconData icono;
  final Color colorFondo;
  final Color colorIcono;
}
