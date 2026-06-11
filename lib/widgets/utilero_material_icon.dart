import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';

/// Icono PNG de una categoría de material del kiosco utilero.
class UtileroMaterialIcon extends StatelessWidget {
  const UtileroMaterialIcon({
    super.key,
    required this.categoria,
    this.size = 32,
  });

  final UtileroMaterialCat categoria;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      categoria.imagenAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        categoria.icono,
        size: size * 0.85,
        color: categoria.color,
      ),
    );
  }
}
