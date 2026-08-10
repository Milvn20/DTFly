import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil extendido del administrador (`admin_perfiles/{id}`).
class AdminPerfil {
  const AdminPerfil({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    this.fotoPerfil,
    this.cargo = 'Administrador DTFly',
    this.institucion,
    this.notifEmail = true,
    this.notifSistema = true,
    this.fechaIngreso,
    this.ultimoAcceso,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String? fotoPerfil;
  final String cargo;
  final String? institucion;
  final bool notifEmail;
  final bool notifSistema;
  final DateTime? fechaIngreso;
  final DateTime? ultimoAcceso;

  String get nombreCompleto {
    final parts = [nombre, apellido].where((e) => e.trim().isNotEmpty);
    final joined = parts.join(' ').trim();
    return joined.isEmpty ? 'Administrador' : joined;
  }

  static AdminPerfil fromDocs({
    required String adminId,
    required Map<String, dynamic>? perfilData,
    required Map<String, dynamic>? usuarioData,
  }) {
    final p = perfilData ?? {};
    final u = usuarioData ?? {};
    final nombreUsuario = u['nombre'] as String? ?? '';
    final partes = nombreUsuario.trim().split(RegExp(r'\s+'));
    final nombreDefault = partes.isNotEmpty ? partes.first : '';
    final apellidoDefault =
        partes.length > 1 ? partes.sublist(1).join(' ') : '';

    return AdminPerfil(
      id: adminId,
      nombre: (p['nombre'] as String?)?.trim().isNotEmpty == true
          ? p['nombre'] as String
          : nombreDefault,
      apellido: (p['apellido'] as String?)?.trim().isNotEmpty == true
          ? p['apellido'] as String
          : apellidoDefault,
      correo: (p['correo'] as String?)?.trim().isNotEmpty == true
          ? p['correo'] as String
          : (u['email'] as String? ?? ''),
      telefono: (p['telefono'] as String?)?.trim().isNotEmpty == true
          ? p['telefono'] as String
          : (u['telefono'] as String? ?? ''),
      fotoPerfil: p['foto_perfil'] as String?,
      cargo: p['cargo'] as String? ?? 'Administrador DTFly',
      institucion: p['institucion'] as String?,
      notifEmail: p['notif_email'] as bool? ?? true,
      notifSistema: p['notif_sistema'] as bool? ?? true,
      fechaIngreso: (p['fecha_ingreso'] as Timestamp?)?.toDate() ??
          (u['fecha_creacion'] as Timestamp?)?.toDate(),
      ultimoAcceso: (p['ultimo_acceso'] as Timestamp?)?.toDate(),
    );
  }
}
