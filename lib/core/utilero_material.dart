import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/material_inventario.dart';

/// Categorías de material para el módulo kiosco del utilero.
class UtileroMaterialCat {
  const UtileroMaterialCat({
    required this.id,
    required this.nombre,
    required this.imagenAsset,
    required this.etiquetaFirestore,
    required this.icono,
    required this.color,
  });

  final String id;
  final String nombre;
  final String imagenAsset;
  final String etiquetaFirestore;
  final IconData icono;
  final Color color;

  static const int umbralStockBajo = 5;

  static const List<UtileroMaterialCat> todas = [
    UtileroMaterialCat(
      id: 'balones',
      nombre: 'Balones',
      imagenAsset: 'assets/images/materiales/balones.png',
      etiquetaFirestore: 'Balones',
      icono: Icons.sports_soccer,
      color: Color(0xFFC62828),
    ),
    UtileroMaterialCat(
      id: 'conos',
      nombre: 'Conos',
      imagenAsset: 'assets/images/materiales/conos.png',
      etiquetaFirestore: 'Conos',
      icono: Icons.change_history,
      color: Color(0xFFF4A261),
    ),
    UtileroMaterialCat(
      id: 'poleras',
      nombre: 'Poleras',
      imagenAsset: 'assets/images/materiales/poleras.png',
      etiquetaFirestore: 'Poleras',
      icono: Icons.checkroom,
      color: Color(0xFF2E9B6B),
    ),
    UtileroMaterialCat(
      id: 'lentejas',
      nombre: 'Lentejas',
      imagenAsset: 'assets/images/materiales/lentejas.png',
      etiquetaFirestore: 'Lentejas',
      icono: Icons.circle_outlined,
      color: Color(0xFFD4842C),
    ),
    UtileroMaterialCat(
      id: 'petos',
      nombre: 'Petos',
      imagenAsset: 'assets/images/materiales/petos.png',
      etiquetaFirestore: 'Petos',
      icono: Icons.sports_martial_arts,
      color: Color(0xFF2D9C5A),
    ),
    UtileroMaterialCat(
      id: 'vallas',
      nombre: 'Vallas',
      imagenAsset: 'assets/images/materiales/vallas.png',
      etiquetaFirestore: 'Vallas',
      icono: Icons.fence,
      color: Color(0xFF5C6B7A),
    ),
    UtileroMaterialCat(
      id: 'escaleras',
      nombre: 'Escaleras',
      imagenAsset: 'assets/images/materiales/escaleras.png',
      etiquetaFirestore: 'Escaleras',
      icono: Icons.stairs_outlined,
      color: Color(0xFF2B2D42),
    ),
    UtileroMaterialCat(
      id: 'mas',
      nombre: 'Más',
      imagenAsset: 'assets/images/materiales/otros.png',
      etiquetaFirestore: 'General',
      icono: Icons.add_photo_alternate_outlined,
      color: Color(0xFF6C757D),
    ),
  ];

  static UtileroMaterialCat? porId(String? id) {
    if (id == null) return null;
    for (final c in todas) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Vallas, escaleras, cuerdas, etc. — visibles en todas las selecciones.
  static const Set<String> idsCompartidosEntreDeportes = {
    'vallas',
    'escaleras',
  };

  static bool esCompartidoEntreDeportes(String? categoriaId) {
    if (categoriaId == null || categoriaId.isEmpty) return false;
    return idsCompartidosEntreDeportes.contains(categoriaId);
  }

  /// Por nombre cuando no encaja en una categoría fija (cuerda, soga, arcos…).
  static bool nombreEsCompartido(String nombre, {String? categoria}) {
    final t = '${categoria ?? ''} $nombre'.toLowerCase();
    return t.contains('valla') ||
        t.contains('escalera') ||
        t.contains('cuerda') ||
        t.contains('soga') ||
        t.contains('cinta') ||
        t.contains('arco mini') ||
        t.contains('arco de');
  }

  static bool materialEsCompartido(MaterialInventario material) {
    final cat = resolver('${material.categoria} ${material.nombre}');
    return esCompartidoEntreDeportes(cat.id) ||
        nombreEsCompartido(material.nombre, categoria: material.categoria);
  }

  static UtileroMaterialCat resolver(String texto) {
    final t = texto.toLowerCase();
    for (final c in todas) {
      if (t.contains(c.nombre.toLowerCase()) ||
          t.contains(c.etiquetaFirestore.toLowerCase())) {
        return c;
      }
    }
    if (t.contains('balon') || t.contains('pelota')) return todas[0];
    if (t.contains('cono')) return todas[1];
    if (t.contains('polera') || t.contains('camiseta')) return todas[2];
    if (t.contains('lenteja') || t.contains('aro')) return todas[3];
    if (t.contains('peto') || t.contains('chaleco')) return todas[4];
    if (t.contains('valla') || t.contains('arco')) return todas[5];
    if (t.contains('escalera') || t.contains('coordina')) {
      return todas.firstWhere((c) => c.id == 'escaleras');
    }
    return todas.firstWhere((c) => c.id == 'mas');
  }
}

enum UtileroFlujoKiosco { recibir, prestar, devolver, danado }

/// Persona que recibe material (entrenador / profesor).
class UtileroPersonaEntrega {
  const UtileroPersonaEntrega({
    required this.id,
    required this.nombre,
    required this.email,
    this.fotoUrl,
  });

  final String id;
  final String nombre;
  final String email;
  final String? fotoUrl;
}
