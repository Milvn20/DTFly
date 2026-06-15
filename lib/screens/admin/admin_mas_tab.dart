import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_navigation.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';
import 'package:flutter_application_1/widgets/dtfly_pill_menu_button.dart';

/// Pestaña «Más» del administrador — accesos secundarios.
class AdminMasTab extends StatelessWidget {
  const AdminMasTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
    required this.adminNombre,
    required this.onCerrarSesion,
  });

  final String adminId;
  final String adminEmail;
  final String adminNombre;
  final VoidCallback onCerrarSesion;

  static const _filas = <({String etiqueta, IconData icono, AdminSeccion? seccion})>[
    (etiqueta: 'Reportes y exportación', icono: Icons.summarize_outlined, seccion: AdminSeccion.reportes),
    (etiqueta: 'Entrenadores (DT)', icono: Icons.sports_outlined, seccion: AdminSeccion.entrenadores),
    (etiqueta: 'Jugadores', icono: Icons.school_outlined, seccion: AdminSeccion.jugadores),
    (etiqueta: 'Búsqueda global', icono: Icons.search, seccion: AdminSeccion.busqueda),
    (etiqueta: 'Configuración del sistema', icono: Icons.settings_outlined, seccion: AdminSeccion.configuracion),
    (etiqueta: 'Auditoría', icono: Icons.history, seccion: AdminSeccion.auditoria),
    (etiqueta: 'Cerrar Sesión', icono: Icons.door_front_door_outlined, seccion: null),
  ];

  String get _primerNombre {
    final p = adminNombre.trim().split(RegExp(r'\s+')).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => 'Administrador',
        );
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: DtflyCoachHeader(
            saludo: '¡Hola, $_primerNombre!',
            subtitulo: 'Más opciones',
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            itemCount: _filas.length,
            itemBuilder: (context, i) {
              final row = _filas[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DtflyPillMenuButton(
                  icon: row.icono,
                  label: row.etiqueta,
                  onTap: () {
                    if (row.seccion == null) {
                      onCerrarSesion();
                      return;
                    }
                    AdminNavigation.abrir(
                      context,
                      seccion: row.seccion!,
                      adminId: adminId,
                      adminEmail: adminEmail,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
