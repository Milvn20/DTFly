import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';

class UtileroPerfil {
  const UtileroPerfil({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.fotoPerfil,
    required this.cargo,
    required this.fechaIngreso,
    required this.estado,
    required this.notifEmail,
    required this.notifSistema,
    this.deporteId,
    this.deporteNombre,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String? fotoPerfil;
  final String cargo;
  final DateTime? fechaIngreso;
  final String estado;
  final bool notifEmail;
  final bool notifSistema;
  final String? deporteId;
  final String? deporteNombre;

  String get nombreCompleto {
    final parts = [nombre, apellido].where((e) => e.trim().isNotEmpty);
    return parts.join(' ').trim();
  }

  bool get activo => estado.toLowerCase() == 'activo';

  UtileroPerfil copyWith({
    String? deporteId,
    String? deporteNombre,
  }) {
    return UtileroPerfil(
      id: id,
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      fotoPerfil: fotoPerfil,
      cargo: cargo,
      fechaIngreso: fechaIngreso,
      estado: estado,
      notifEmail: notifEmail,
      notifSistema: notifSistema,
      deporteId: deporteId ?? this.deporteId,
      deporteNombre: deporteNombre ?? this.deporteNombre,
    );
  }

  static UtileroPerfil fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    Map<String, dynamic>? datosUsuario,
  }) {
    final d = doc.data() ?? {};
    final ts = d['fecha_ingreso'] as Timestamp?;
    var deporteId = DeporteUsuario.idDesde(d);
    if (deporteId == null && datosUsuario != null) {
      deporteId = DeporteUsuario.idDesde(datosUsuario);
    }
    var deporteNombre = DeporteUsuario.nombreDesde(d);
    if ((deporteNombre == 'Sin categoría' || deporteNombre.isEmpty) &&
        datosUsuario != null) {
      deporteNombre = DeporteUsuario.nombreDesde(datosUsuario);
    }
    return UtileroPerfil(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      apellido: d['apellido'] as String? ?? '',
      correo: d['correo'] as String? ?? '',
      telefono: d['telefono'] as String? ?? '',
      fotoPerfil: d['foto_perfil'] as String?,
      cargo: d['cargo'] as String? ?? 'Utilero',
      fechaIngreso: ts?.toDate(),
      estado: d['estado'] as String? ?? 'Activo',
      notifEmail: d['notif_email'] as bool? ?? true,
      notifSistema: d['notif_sistema'] as bool? ?? true,
      deporteId: deporteId,
      deporteNombre: deporteNombre,
    );
  }
}
