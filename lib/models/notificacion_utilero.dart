import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacionUtilero {
  const NotificacionUtilero({
    required this.id,
    required this.utileroId,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.fecha,
    required this.tipo,
  });

  final String id;
  final String utileroId;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime fecha;
  final String tipo;

  static NotificacionUtilero fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final ts = d['fecha'] as Timestamp?;
    return NotificacionUtilero(
      id: doc.id,
      utileroId: d['utilero_id'] as String? ?? '',
      titulo: d['titulo'] as String? ?? '',
      mensaje: d['mensaje'] as String? ?? '',
      leida: d['leida'] as bool? ?? false,
      fecha: ts?.toDate() ?? DateTime.now(),
      tipo: d['tipo'] as String? ?? 'sistema',
    );
  }
}
