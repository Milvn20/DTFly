import 'package:cloud_firestore/cloud_firestore.dart';

/// Solicitud de compra de material (colección `solicitudes_compra_utilero`).
class SolicitudCompraUtilero {
  const SolicitudCompraUtilero({
    required this.id,
    required this.utileroId,
    required this.materialNombre,
    required this.cantidad,
    required this.motivo,
    required this.estado,
    required this.creadoEn,
    this.deporteId,
    this.deporteNombre,
    this.respuesta,
  });

  final String id;
  final String utileroId;
  final String materialNombre;
  final int cantidad;
  final String motivo;
  /// pendiente | aprobada | rechazada
  final String estado;
  final DateTime? creadoEn;
  final String? deporteId;
  final String? deporteNombre;
  final String? respuesta;

  bool get pendiente => estado == 'pendiente';

  static SolicitudCompraUtilero fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return SolicitudCompraUtilero(
      id: doc.id,
      utileroId: d['utilero_id'] as String? ?? '',
      materialNombre: d['material_nombre'] as String? ?? '',
      cantidad: (d['cantidad'] as num?)?.toInt() ?? 1,
      motivo: d['motivo'] as String? ?? '',
      estado: d['estado'] as String? ?? 'pendiente',
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
      deporteId: d['deporte'] as String?,
      deporteNombre: d['deporteNombre'] as String?,
      respuesta: d['respuesta'] as String?,
    );
  }
}

/// Entrenador / DT visible para el utilero.
class UtileroContactoDt {
  const UtileroContactoDt({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.fotoUrl,
    this.deporteNombre,
  });

  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? fotoUrl;
  final String? deporteNombre;
}

/// Sesión de checklist pre-entrenamiento.
class ChecklistUtileroSesion {
  const ChecklistUtileroSesion({
    required this.id,
    required this.utileroId,
    required this.titulo,
    required this.items,
    required this.completado,
    required this.creadoEn,
    this.entrenamientoId,
  });

  final String id;
  final String utileroId;
  final String titulo;
  final Map<String, bool> items;
  final bool completado;
  final DateTime? creadoEn;
  final String? entrenamientoId;

  int get totalItems => items.length;
  int get marcados => items.values.where((v) => v).length;

  static ChecklistUtileroSesion fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final raw = d['items'] as Map<String, dynamic>? ?? {};
    return ChecklistUtileroSesion(
      id: doc.id,
      utileroId: d['utilero_id'] as String? ?? '',
      titulo: d['titulo'] as String? ?? 'Checklist',
      items: raw.map((k, v) => MapEntry(k, v == true)),
      completado: d['completado'] as bool? ?? false,
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
      entrenamientoId: d['entrenamiento_id'] as String?,
    );
  }
}
