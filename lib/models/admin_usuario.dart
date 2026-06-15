import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deporte_usuario.dart';

/// Usuario visto desde el panel de administración.
class AdminUsuario {
  const AdminUsuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.deporteId,
    this.deporteNombre,
    this.activo = true,
    this.fechaCreacion,
    this.telefono,
    this.carrera,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? deporteId;
  final String? deporteNombre;
  final bool activo;
  final DateTime? fechaCreacion;
  final String? telefono;
  final String? carrera;

  String get rolNormalizado => AppRoles.normalize(rol);

  static AdminUsuario fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final activoRaw = d['activo'];
    return AdminUsuario(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      rol: d['rol'] as String? ?? AppRoles.jugador,
      deporteId: DeporteUsuario.idDesde(d),
      deporteNombre: DeporteUsuario.nombreDesde(d),
      activo: activoRaw is bool ? activoRaw : true,
      fechaCreacion: (d['fecha_creacion'] as Timestamp?)?.toDate(),
      telefono: d['telefono'] as String?,
      carrera: d['carrera'] as String?,
    );
  }
}
