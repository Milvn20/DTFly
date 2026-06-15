import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_inventario_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_tab_shell.dart';

/// Pestaña Inventario global del administrador.
class AdminInventarioShellTab extends StatelessWidget {
  const AdminInventarioShellTab({
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
      subtitulo: 'Inventario global',
      child: AdminInventarioTab(
        adminId: adminId,
        adminEmail: adminEmail,
      ),
    );
  }
}
