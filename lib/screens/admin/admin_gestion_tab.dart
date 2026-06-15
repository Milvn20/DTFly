import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_tab_shell.dart';
import 'package:flutter_application_1/screens/admin/admin_usuarios_tab.dart';

/// Pestaña Gestión — usuarios de todos los roles.
class AdminGestionTab extends StatelessWidget {
  const AdminGestionTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
    required this.adminNombre,
  });

  final String adminId;
  final String adminEmail;
  final String adminNombre;

  @override
  Widget build(BuildContext context) {
    return AdminTabShell(
      nombre: adminNombre,
      subtitulo: 'Gestión de usuarios',
      child: AdminUsuariosTab(
        adminId: adminId,
        adminEmail: adminEmail,
      ),
    );
  }
}
