import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_estadisticas_screen.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_historial_tab.dart';
import 'package:flutter_application_1/screens/utilero/utilero_seccion_screen.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/dtfly_pill_menu_button.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';

/// Pestaña «Más» — mockup + botones píldora.
class UtileroMasTab extends StatelessWidget {
  const UtileroMasTab({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombre,
    required this.onCerrarSesion,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombre;
  final VoidCallback onCerrarSesion;

  static const _filas = <({String etiqueta, IconData icono})>[
    (etiqueta: 'Agregar material', icono: Icons.add_circle_outline),
    (etiqueta: 'Historial', icono: Icons.history),
    (etiqueta: 'Estadísticas', icono: Icons.bar_chart),
    (etiqueta: 'Mi perfil', icono: Icons.person_outline),
    (etiqueta: 'Notificaciones', icono: Icons.notifications_outlined),
    (etiqueta: 'Cerrar Sesión', icono: Icons.door_front_door_outlined),
  ];

  String get _primerNombre {
    final p = nombre.trim().split(RegExp(r'\s+')).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => 'Utilero',
        );
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return DtflyMockupDashboardLayout(
      saludo: '¡Hola, $_primerNombre!',
      subtitulo: 'Utilero · Más opciones',
      stats: const [],
      child: Column(
        children: [
          for (final fila in _filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DtflyPillMenuButton(
                icon: fila.icono,
                label: fila.etiqueta,
                onTap: () => _onOpcion(context, fila.etiqueta),
              ),
            ),
        ],
      ),
    );
  }

  void _onOpcion(BuildContext context, String etiqueta) {
    switch (etiqueta) {
      case 'Agregar material':
        UtileroAgregarMaterialDialog.mostrar(context, usuarioId: usuarioId);
      case 'Historial':
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: DtflyTheme.background,
              appBar: AppBar(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                title: const Text('Historial'),
              ),
              body: UtileroKioscoHistorialTab(
                usuarioId: usuarioId,
                mostrarCabecera: false,
              ),
            ),
          ),
        );
      case 'Estadísticas':
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => const UtileroKioscoEstadisticasScreen(),
          ),
        );
      case 'Mi perfil':
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: DtflyTheme.background,
              appBar: AppBar(
                title: const Text('Mi perfil'),
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              body: UtileroPerfilTabContent(
                usuarioId: usuarioId,
                usuarioEmail: usuarioEmail,
                nombreInicial: nombre,
              ),
            ),
          ),
        );
      case 'Notificaciones':
        UtileroSeccionScreen.abrir(
          context,
          titulo: 'Notificaciones',
          usuarioId: usuarioId,
          usuarioEmail: usuarioEmail,
          nombreInicial: nombre,
          seccion: UtileroSeccion.notificaciones,
        );
      case 'Cerrar Sesión':
        onCerrarSesion();
    }
  }
}
