import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';

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
    this.imagenBase64,
    this.esPersonalizado = false,
    this.deporteId,
    this.deporteNombre,
    this.compartidoGeneral = false,
    this.ubicacion,
    this.pasillo,
    this.estante,
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
  final String? imagenBase64;
  final bool esPersonalizado;
  final String? deporteId;
  final String? deporteNombre;
  /// Visible en todas las selecciones (vallas, escaleras, material «General», etc.).
  final bool compartidoGeneral;
  final String? ubicacion;
  final String? pasillo;
  final String? estante;

  String get ubicacionTexto {
    final parts = <String>[];
    if (ubicacion != null && ubicacion!.trim().isNotEmpty) {
      parts.add(ubicacion!.trim());
    }
    if (pasillo != null && pasillo!.trim().isNotEmpty) {
      parts.add('Pasillo ${pasillo!.trim()}');
    }
    if (estante != null && estante!.trim().isNotEmpty) {
      parts.add('Estante ${estante!.trim()}');
    }
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  bool get tieneFotoPersonalizada {
    final b64 = imagenBase64?.trim();
    if (b64 != null && b64.isNotEmpty) return true;
    final url = imagenUrl?.trim();
    return url != null && url.isNotEmpty;
  }

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
      imagenUrl: (d['imagenUrl'] ?? d['fotoUrl'] ?? d['imagen']) as String?,
      imagenBase64: d['imagenBase64'] as String?,
      esPersonalizado: d['esPersonalizado'] as bool? ?? false,
      deporteId: DeporteUsuario.idDesde(d),
      deporteNombre: DeporteUsuario.nombreDesde(d),
      compartidoGeneral: d['compartido_todas_selecciones'] as bool? ??
          d['deporte'] == DeportesCategoria.idGeneral,
      ubicacion: d['ubicacion'] as String?,
      pasillo: d['pasillo'] as String?,
      estante: d['estante'] as String?,
    );
  }
}
