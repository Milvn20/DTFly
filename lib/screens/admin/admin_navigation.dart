import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_auditoria_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_busqueda_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_config_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_entrenadores_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_jugadores_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_reportes_tab.dart';
import 'package:flutter_application_1/screens/admin/admin_seccion_screen.dart';

/// Secciones del admin accesibles desde «Más» o accesos rápidos.
enum AdminSeccion {
  reportes,
  entrenadores,
  jugadores,
  busqueda,
  configuracion,
  auditoria,
}

/// Navegación a pantallas secundarias del administrador.
class AdminNavigation {
  AdminNavigation._();

  static void abrir(
    BuildContext context, {
    required AdminSeccion seccion,
    required String adminId,
    required String adminEmail,
  }) {
    final (:titulo, :body) = _contenido(
      seccion: seccion,
      adminId: adminId,
      adminEmail: adminEmail,
    );
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSeccionScreen(
          titulo: titulo,
          child: body,
        ),
      ),
    );
  }

  static ({String titulo, Widget body}) _contenido({
    required AdminSeccion seccion,
    required String adminId,
    required String adminEmail,
  }) {
    return switch (seccion) {
      AdminSeccion.reportes => (
          titulo: 'Reportes',
          body: AdminReportesTab(adminId: adminId, adminEmail: adminEmail),
        ),
      AdminSeccion.entrenadores => (
          titulo: 'Entrenadores',
          body: AdminEntrenadoresTab(adminId: adminId, adminEmail: adminEmail),
        ),
      AdminSeccion.jugadores => (
          titulo: 'Jugadores',
          body: AdminJugadoresTab(adminId: adminId, adminEmail: adminEmail),
        ),
      AdminSeccion.busqueda => (
          titulo: 'Búsqueda global',
          body: AdminBusquedaTab(adminId: adminId, adminEmail: adminEmail),
        ),
      AdminSeccion.configuracion => (
          titulo: 'Configuración',
          body: AdminConfigTab(adminId: adminId, adminEmail: adminEmail),
        ),
      AdminSeccion.auditoria => (
          titulo: 'Auditoría',
          body: AdminAuditoriaTab(),
        ),
    };
  }
}
