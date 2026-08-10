import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_perfil_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_dashboard_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_navigation.dart';
import 'package:flutter_application_1/screens/admin/admin_tab_shell.dart';
import 'package:flutter_application_1/screens/muro/muro_deportivo_screen.dart';

/// Pestaña Inicio del administrador (dashboard).
class AdminInicioTab extends StatelessWidget {
  const AdminInicioTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
    required this.adminNombre,
    required this.onIrTab,
  });

  final String adminId;
  final String adminEmail;
  final String adminNombre;
  final void Function(int tabIndex) onIrTab;

  @override
  Widget build(BuildContext context) {
    return AdminTabShell(
      nombre: adminNombre,
      subtitulo: 'Panel de administración DTFly',
      child: AdminDashboardTab(
        adminId: adminId,
        adminEmail: adminEmail,
        adminNombre: adminNombre,
        onIrTab: onIrTab,
        onIrSeccion: (s) => AdminNavigation.abrir(
          context,
          seccion: s,
          adminId: adminId,
          adminEmail: adminEmail,
        ),
        onAbrirPerfil: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminPerfilScreen(
              adminId: adminId,
              adminEmail: adminEmail,
              adminNombre: adminNombre,
            ),
          ),
        ),
        onAbrirMuro: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => MuroDeportivoScreen(
              soloLectura: false,
              autorEmail: adminEmail,
              autorNombre: adminNombre,
              permitirCambiarSeleccion: true,
            ),
          ),
        ),
      ),
    );
  }
}
