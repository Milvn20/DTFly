import 'package:cloud_firestore/cloud_firestore.dart';

/// Documento en `entrenamientos/{id}/asistencias/{jugadorId}`.
class AsistenciaRegistro {
  const AsistenciaRegistro({
    required this.jugadorId,
    required this.nombre,
    required this.email,
    required this.estado,
    this.unidoEn,
    this.fechaEntrenamiento,
    this.entrenamientoTitulo,
  });

  final String jugadorId;
  final String nombre;
  final String email;
  final String estado;
  final DateTime? unidoEn;
  final DateTime? fechaEntrenamiento;
  final String? entrenamientoTitulo;

  static AsistenciaRegistro fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AsistenciaRegistro(
      jugadorId: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      estado: d['estado'] as String? ?? 'presente',
      unidoEn: (d['unidoEn'] as Timestamp?)?.toDate(),
      fechaEntrenamiento: (d['fechaEntrenamiento'] as Timestamp?)?.toDate(),
      entrenamientoTitulo: d['entrenamientoTitulo'] as String?,
    );
  }
}
