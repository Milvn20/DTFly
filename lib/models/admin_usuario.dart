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
    this.edad,
    this.posicionDeportiva,
    this.tipoBeca,
    this.institucion,
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
  final int? edad;
  final String? posicionDeportiva;
  final String? tipoBeca;
  final String? institucion;

  String get rolNormalizado => AppRoles.normalize(rol);

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  static AdminUsuario fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final activoRaw = d['activo'];
    final edadRaw = d['edad'];
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
      edad: edadRaw is int ? edadRaw : int.tryParse('$edadRaw'),
      posicionDeportiva: d['posicionDeportiva'] as String?,
      tipoBeca: d['tipoBeca'] as String?,
      institucion: d['institucion'] as String?,
    );
  }
}
