import 'package:flutter/material.dart';



import 'package:flutter_application_1/screens/utilero/utilero_modulos_screens.dart';

import 'package:flutter_application_1/screens/utilero/utilero_seccion_screen.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';

import 'package:flutter_application_1/widgets/dtfly_pill_menu_button.dart';

import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';

import 'package:flutter_application_1/widgets/utilero_material_acciones_sheet.dart';



/// Pestaña «Más» — menú completo del utilero universitario.

class UtileroMasTab extends StatelessWidget {

  const UtileroMasTab({

    super.key,

    required this.usuarioId,

    required this.usuarioEmail,

    required this.nombre,

    required this.onCerrarSesion,

    this.deporteId,

    this.onCambiarSeleccion,

  });



  final String usuarioId;

  final String usuarioEmail;

  final String nombre;

  final VoidCallback onCerrarSesion;

  final String? deporteId;

  final VoidCallback? onCambiarSeleccion;



  static const _filas = <({String etiqueta, IconData icono})>[

    (etiqueta: 'Herramientas utilero', icono: Icons.dashboard_customize_outlined),

    (etiqueta: 'Cambiar selección', icono: Icons.swap_horiz),

    (etiqueta: 'Calendario', icono: Icons.calendar_month_outlined),

    (etiqueta: 'Checklist pre-entreno', icono: Icons.checklist_rtl),

    (etiqueta: 'Contacto DT', icono: Icons.contact_phone_outlined),

    (etiqueta: 'Solicitudes de compra', icono: Icons.shopping_cart_outlined),

    (etiqueta: 'Material dañado', icono: Icons.build_circle_outlined),

    (etiqueta: 'Inventario físico', icono: Icons.fact_check_outlined),

    (etiqueta: 'Reportes', icono: Icons.summarize_outlined),

    (etiqueta: 'Agregar material', icono: Icons.add_circle_outline),

    (etiqueta: 'Eliminar material', icono: Icons.delete_outline),

    (etiqueta: 'Historial y exportar', icono: Icons.history),

    (etiqueta: 'Estadísticas', icono: Icons.bar_chart),

    (etiqueta: 'Mi perfil', icono: Icons.person_outline),

    (etiqueta: 'Notificaciones', icono: Icons.notifications_outlined),

    (etiqueta: 'Configuración', icono: Icons.settings_outlined),

    (etiqueta: 'Cerrar Sesión', icono: Icons.door_front_door_outlined),

  ];



  String get _primerNombre {

    final p = nombre.trim().split(RegExp(r'\s+')).firstWhere(

          (e) => e.isNotEmpty,

          orElse: () => 'Utilero',

        );

    return p;

  }



  void _push(BuildContext context, Widget screen) {

    Navigator.push<void>(

      context,

      MaterialPageRoute(builder: (_) => screen),

    );

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

      case 'Herramientas utilero':

        _push(

          context,

          UtileroHerramientasScreen(

            usuarioId: usuarioId,

            usuarioEmail: usuarioEmail,

            nombre: nombre,

            deporteId: deporteId,

          ),

        );

      case 'Cambiar selección':

        onCambiarSeleccion?.call();

      case 'Calendario':

        _push(

          context,

          UtileroCalendarioScreen(

            usuarioId: usuarioId,

            deporteId: deporteId,

          ),

        );

      case 'Checklist pre-entreno':

        _push(context, UtileroChecklistScreen(usuarioId: usuarioId));

      case 'Contacto DT':

        _push(context, UtileroContactoDtScreen(deporteId: deporteId));

      case 'Solicitudes de compra':

        _push(

          context,

          UtileroSolicitudesScreen(

            usuarioId: usuarioId,

            deporteId: deporteId,

          ),

        );

      case 'Material dañado':

        _push(

          context,

          UtileroMaterialDanadoScreen(

            usuarioId: usuarioId,

            deporteId: deporteId,

          ),

        );

      case 'Inventario físico':

        _push(

          context,

          UtileroInventarioFisicoScreen(

            usuarioId: usuarioId,

            deporteId: deporteId,

          ),

        );

      case 'Reportes':

        _push(

          context,

          UtileroReportesScreen(

            usuarioId: usuarioId,

            usuarioEmail: usuarioEmail,

            deporteId: deporteId,

          ),

        );

      case 'Agregar material':

        UtileroAgregarMaterialDialog.mostrar(

          context,

          usuarioId: usuarioId,

          deporteId: deporteId,

        );

      case 'Eliminar material':

        Navigator.push<void>(

          context,

          MaterialPageRoute(

            builder: (_) => UtileroEliminarMaterialListaScreen(

              usuarioId: usuarioId,

              deporteId: deporteId,

            ),

          ),

        );

      case 'Historial y exportar':

        UtileroSeccionScreen.abrir(

          context,

          titulo: 'Historial',

          usuarioId: usuarioId,

          usuarioEmail: usuarioEmail,

          nombreInicial: nombre,

          seccion: UtileroSeccion.historial,

        );

      case 'Estadísticas':

        UtileroSeccionScreen.abrir(

          context,

          titulo: 'Estadísticas',

          usuarioId: usuarioId,

          usuarioEmail: usuarioEmail,

          nombreInicial: nombre,

          seccion: UtileroSeccion.estadisticas,

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

                deporteId: deporteId,

                onCambiarSeleccion: onCambiarSeleccion,

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

      case 'Configuración':

        UtileroSeccionScreen.abrir(

          context,

          titulo: 'Configuración',

          usuarioId: usuarioId,

          usuarioEmail: usuarioEmail,

          nombreInicial: nombre,

          seccion: UtileroSeccion.configuracion,

        );

      case 'Cerrar Sesión':

        onCerrarSesion();

    }

  }

}


