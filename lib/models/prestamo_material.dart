import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de préstamo o entrega (colección `prestamos_inventario`).
class PrestamoMaterial {
  const PrestamoMaterial({
    required this.id,
    required this.materialId,
    required this.materialNombre,
    required this.cantidad,
    required this.prestadoA,
    required this.entrenadorEmail,
    required this.prestadoEn,
    required this.devuelto,
    this.devueltoEn,
    this.notas,
  });

  final String id;
  final String materialId;
  final String materialNombre;
  final int cantidad;
  final String prestadoA;
  final String entrenadorEmail;
  final DateTime prestadoEn;
  final bool devuelto;
  final DateTime? devueltoEn;
  final String? notas;

  static PrestamoMaterial fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final prestado = d['prestadoEn'] as Timestamp?;
    final devueltoTs = d['devueltoEn'] as Timestamp?;
    return PrestamoMaterial(
      id: doc.id,
      materialId: d['materialId'] as String? ?? '',
      materialNombre: d['materialNombre'] as String? ?? '',
      cantidad: (d['cantidad'] as num?)?.toInt() ?? 1,
      prestadoA: d['prestadoA'] as String? ?? '',
      entrenadorEmail: d['entrenadorEmail'] as String? ?? '',
      prestadoEn: prestado?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      devuelto: d['devuelto'] as bool? ?? false,
      devueltoEn: devueltoTs?.toDate(),
      notas: d['notas'] as String?,
    );
  }
}
