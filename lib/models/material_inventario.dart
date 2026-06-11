import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de stock según módulo de inventario DTFly.
abstract class EstadoStockMaterial {
  static const String disponible = 'disponible';
  static const String prestado = 'prestado';
  static const String danado = 'danado';
}

/// Material deportivo (colección `inventario`).
class MaterialInventario {
  const MaterialInventario({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidadTotal,
    required this.cantidadDisponible,
    required this.cantidadDanada,
    required this.unidad,
    required this.actualizadoEn,
    this.imagenUrl,
  });

  final String id;
  final String nombre;
  final String categoria;
  final int cantidadTotal;
  final int cantidadDisponible;
  final int cantidadDanada;
  final String unidad;
  final DateTime? actualizadoEn;
  final String? imagenUrl;

  /// Unidades actualmente en préstamo/entrega.
  int get prestados {
    final p = cantidadTotal - cantidadDisponible - cantidadDanada;
    return p < 0 ? 0 : p;
  }

  bool get tieneDanados => cantidadDanada > 0;

  static MaterialInventario fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final ts = d['actualizadoEn'] as Timestamp?;
    final total = (d['cantidadTotal'] as num?)?.toInt() ?? 0;
    final disp = (d['cantidadDisponible'] as num?)?.toInt() ?? 0;
    var danada = (d['cantidadDanada'] as num?)?.toInt() ?? 0;
    if (danada + disp > total) {
      danada = (total - disp).clamp(0, total);
    }
    return MaterialInventario(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      categoria: d['categoria'] as String? ?? 'General',
      cantidadTotal: total,
      cantidadDisponible: disp,
      cantidadDanada: danada,
      unidad: d['unidad'] as String? ?? 'unidad',
      actualizadoEn: ts?.toDate(),
      imagenUrl: d['imagenUrl'] as String?,
    );
  }
}
