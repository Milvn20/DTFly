import 'package:cloud_firestore/cloud_firestore.dart';

class ActividadUtilero {
  const ActividadUtilero({
    required this.id,
    required this.utileroId,
    required this.accion,
    required this.descripcion,
    required this.material,
    required this.cantidad,
    required this.estado,
    required this.fecha,
  });

  final String id;
  final String utileroId;
  final String accion;
  final String descripcion;
  final String material;
  final int cantidad;
  final String estado;
  final DateTime fecha;

  static ActividadUtilero fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['fecha'] as Timestamp?;
    return ActividadUtilero(
      id: doc.id,
      utileroId: d['utilero_id'] as String? ?? '',
      accion: d['accion'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      material: d['material'] as String? ?? '—',
      cantidad: (d['cantidad'] as num?)?.toInt() ?? 0,
      estado: d['estado'] as String? ?? 'Completado',
      fecha: ts?.toDate() ?? DateTime.now(),
    );
  }
}
