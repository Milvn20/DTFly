import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de auditoría del panel admin (`admin_auditoria`).
class AdminAuditoriaRegistro {
  const AdminAuditoriaRegistro({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.accion,
    required this.detalle,
    this.entidadTipo,
    this.entidadId,
    this.creadoEn,
  });

  final String id;
  final String adminId;
  final String adminEmail;
  final String accion;
  final String detalle;
  final String? entidadTipo;
  final String? entidadId;
  final DateTime? creadoEn;

  static AdminAuditoriaRegistro fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AdminAuditoriaRegistro(
      id: doc.id,
      adminId: d['admin_id'] as String? ?? '',
      adminEmail: d['admin_email'] as String? ?? '',
      accion: d['accion'] as String? ?? '',
      detalle: d['detalle'] as String? ?? '',
      entidadTipo: d['entidad_tipo'] as String?,
      entidadId: d['entidad_id'] as String?,
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
    );
  }
}
