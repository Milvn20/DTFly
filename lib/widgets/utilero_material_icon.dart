import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';

/// Icono o foto de un material del kiosco utilero.
class UtileroMaterialIcon extends StatelessWidget {
  const UtileroMaterialIcon({
    super.key,
    required this.categoria,
    this.size = 32,
    this.imagenUrl,
    this.imagenBase64,
  });

  final UtileroMaterialCat categoria;
  final double size;
  final String? imagenUrl;
  final String? imagenBase64;

  @override
  Widget build(BuildContext context) {
    return UtileroMaterialThumbnail(
      categoria: categoria,
      imagenUrl: imagenUrl,
      imagenBase64: imagenBase64,
      size: size,
    );
  }
}

/// Muestra foto personalizada (base64 o URL); si no, el PNG de la categoría.
class UtileroMaterialThumbnail extends StatelessWidget {
  const UtileroMaterialThumbnail({
    super.key,
    required this.categoria,
    this.imagenUrl,
    this.imagenBase64,
    this.size = 32,
  });

  final UtileroMaterialCat? categoria;
  final String? imagenUrl;
  final String? imagenBase64;
  final double size;

  static Uint8List? _decodificarBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return base64Decode(raw.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodificarBase64(imagenBase64);
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _iconoRed(url: imagenUrl),
        ),
      );
    }
    return _iconoRed(url: imagenUrl);
  }

  Widget _iconoRed({String? url}) {
    final link = url?.trim();
    if (link != null && link.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          link,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: size * 0.45,
                  height: size * 0.45,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: categoria?.color ?? const Color(0xFFC62828),
                  ),
                ),
              ),
            );
          },
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
