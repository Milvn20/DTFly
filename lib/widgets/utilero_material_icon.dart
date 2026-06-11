import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';

/// Icono o foto de un material del kiosco utilero.
class UtileroMaterialIcon extends StatelessWidget {
  const UtileroMaterialIcon({
    super.key,
    required this.categoria,
    this.size = 32,
    this.imagenUrl,
  });

  final UtileroMaterialCat categoria;
  final double size;
  final String? imagenUrl;

  @override
  Widget build(BuildContext context) {
    return UtileroMaterialThumbnail(
      categoria: categoria,
      imagenUrl: imagenUrl,
      size: size,
    );
  }
}

/// Muestra foto personalizada si existe; si no, el PNG de la categoría.
class UtileroMaterialThumbnail extends StatelessWidget {
  const UtileroMaterialThumbnail({
    super.key,
    required this.categoria,
    this.imagenUrl,
    this.size = 32,
  });

  final UtileroMaterialCat? categoria;
  final String? imagenUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imagenUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconoCategoria(),
        ),
      );
    }
    return _iconoCategoria();
  }

  Widget _iconoCategoria() {
    final cat = categoria;
    if (cat == null) {
      return Icon(Icons.inventory_2_outlined, size: size * 0.85);
    }
    return Image.asset(
      cat.imagenAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        cat.icono,
        size: size * 0.85,
        color: cat.color,
      ),
    );
  }
}
