import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/models/nota_dt.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/models/blog_publicacion.dart';
import 'package:flutter_application_1/screens/blog/blog_list_screen.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_estadisticas_screen.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_historial_screen.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_seleccion_categoria_screen.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_inicio_tab.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_planificacion_tab.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_plantel_tab.dart';
import 'package:flutter_application_1/screens/estadisticas/estadisticas_deportivas_screen.dart';
import 'package:flutter_application_1/screens/inventario/inventario_screen.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_home.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_prestamos_tab.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_stock_screen.dart';
import 'package:flutter_application_1/screens/utilero/utilero_modulos_screens.dart';
import 'package:flutter_application_1/screens/utilero/utilero_mas_tab.dart';
import 'package:flutter_application_1/screens/utilero/utilero_seleccion_deporte_screen.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/screens/jugador/jugador_ficha_screen.dart';
import 'package:flutter_application_1/screens/jugador/jugador_inicio_tab.dart';
import 'package:flutter_application_1/screens/jugadores_screen.dart';
import 'package:flutter_application_1/screens/observaciones/observaciones_entrenador_screen.dart';
import 'package:flutter_application_1/screens/observaciones/observaciones_jugador_screen.dart';
import 'package:flutter_application_1/screens/partidos/partido_detalle_screen.dart';
import 'package:flutter_application_1/screens/partidos/partidos_gestion_screen.dart';
import 'package:flutter_application_1/services/blog_service.dart';
import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/services/nota_dt_service.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/services/reportes_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_bottom_nav.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';
import 'package:flutter_application_1/widgets/dtfly_pill_menu_button.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';

/// Contenedor principal con pestañas inferiores según el rol (mockup DTFly).
class RoleMainShell extends StatefulWidget {
  const RoleMainShell({
    super.key,
    required this.nombre,
    required this.rol,
    required this.usuarioEmail,
    required this.usuarioId,
    this.categoriaDeportiva,
  });

  final String nombre;
  final String rol;
  final String usuarioEmail;
  final String usuarioId;
  /// Disciplina elegida en [EntrenadorSeleccionCategoriaScreen] (`futbol`, `tenis`, etc.).
  final String? categoriaDeportiva;

  @override
  State<RoleMainShell> createState() => _RoleMainShellState();
}

class _RoleMainShellState extends State<RoleMainShell> {
  int _index = 0;
  String? _deporteUtilero;
  Timer? _timerRotacionCodigo;
  StreamSubscription<Entrenamiento?>? _subSesionActiva;

  @override
  void initState() {
    super.initState();
    _deporteUtilero = widget.categoriaDeportiva;
    if (AppRoles.normalize(widget.rol) == AppRoles.entrenador) {
      _subSesionActiva =
          EntrenamientoService.streamActivo(widget.usuarioEmail).listen((activo) {
        _timerRotacionCodigo?.cancel();
        _timerRotacionCodigo = null;
        if (activo == null) return;
        final id = activo.id;
        _timerRotacionCodigo =
            Timer.periodic(const Duration(seconds: 60), (_) {
          EntrenamientoService.rotarCodigoUnion(id);
        });
      });
    }
  }

  @override
  void dispose() {
    _timerRotacionCodigo?.cancel();
    _subSesionActiva?.cancel();
    super.dispose();
  }

  String get _primerNombre {
    final p = widget.nombre.trim().split(RegExp(r'\s+')).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => '',
        );
    return p.isEmpty ? 'Usuario' : p;
  }

  Future<void> _cambiarSeleccionUtilero() async {
    final elegido = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroSeleccionDeporteScreen(
          nombre: widget.nombre,
          usuarioEmail: widget.usuarioEmail,
          usuarioId: widget.usuarioId,
          modoCambio: true,
          deporteActual: _deporteUtilero,
        ),
      ),
    );
    if (elegido == null || !mounted) return;
    setState(() => _deporteUtilero = elegido);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Viendo inventario de ${DeportesCategoria.nombreVisible(elegido)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rol = AppRoles.normalize(widget.rol);
    final bodies = _bodiesFor(rol, context);
    final idx = _index.clamp(0, bodies.length - 1);

    if (rol == AppRoles.entrenador) {
      return Scaffold(
        backgroundColor: DtflyTheme.background,
        body: bodies[idx],
        bottomNavigationBar: DtflyBottomNav(
          currentIndex: idx,
          onTap: (i) => setState(() => _index = i),
          items: const [
            DtflyNavItem(icon: Icons.home_outlined, label: 'Inicio'),
            DtflyNavItem(icon: Icons.calendar_month_outlined, label: 'Planificación'),
            DtflyNavItem(icon: Icons.groups_outlined, label: 'Plantel'),
            DtflyNavItem(icon: Icons.menu, label: 'Más'),
          ],
        ),
      );
    }

    if (rol == AppRoles.utilero) {
      final mostrarFabAgregar = idx <= 2;
      return Scaffold(
        backgroundColor: const Color(0xFFC62828),
        body: bodies[idx],
        floatingActionButton: mostrarFabAgregar
            ? FloatingActionButton.extended(
                onPressed: () => UtileroAgregarMaterialDialog.mostrar(
                  context,
                  usuarioId: widget.usuarioId,
                  deporteId: _deporteUtilero,
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFC62828),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Agregar material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: DtflyBottomNav(
          currentIndex: idx,
          onTap: (i) => setState(() => _index = i),
          light: true,
          items: const [
            DtflyNavItem(icon: Icons.home_outlined, label: 'Inicio'),
            DtflyNavItem(icon: Icons.inventory_2_outlined, label: 'Inventario'),
            DtflyNavItem(icon: Icons.handshake_outlined, label: 'Préstamos'),
            DtflyNavItem(icon: Icons.menu, label: 'Más'),
          ],
        ),
      );
    }

    final items = _navItemsFor(rol);
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      body: bodies[idx],
      bottomNavigationBar: DtflyBottomNav(
        currentIndex: idx,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final it in items)
            DtflyNavItem(icon: it.icon, label: it.label),
        ],
      ),
    );
  }

  List<_NavItem> _navItemsFor(String rol) {
    switch (rol) {
      case AppRoles.entrenador:
        return const [
          _NavItem(Icons.home_outlined, 'Inicio'),
          _NavItem(Icons.calendar_month_outlined, 'Planificación'),
          _NavItem(Icons.groups_outlined, 'Plantel'),
          _NavItem(Icons.menu, 'Más'),
        ];
      case AppRoles.jugador:
        return const [
          _NavItem(Icons.home_outlined, 'Inicio'),
          _NavItem(Icons.trending_up_outlined, 'Mi Progreso'),
          _NavItem(Icons.campaign_outlined, 'Novedades'),
          _NavItem(Icons.menu, 'Más'),
        ];
      case AppRoles.utilero:
        return const [
          _NavItem(Icons.home_outlined, 'Inicio'),
          _NavItem(Icons.inventory_2_outlined, 'Inventario'),
          _NavItem(Icons.handshake_outlined, 'Préstamos'),
          _NavItem(Icons.menu, 'Más'),
        ];
      case AppRoles.administrador:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Inicio'),
          _NavItem(Icons.admin_panel_settings_outlined, 'Gestión'),
          _NavItem(Icons.assessment_outlined, 'Reportes'),
          _NavItem(Icons.menu, 'Más'),
        ];
      default:
        return const [
          _NavItem(Icons.home_outlined, 'Inicio'),
          _NavItem(Icons.help_outline, 'Ayuda'),
        ];
    }
  }

  List<Widget> _bodiesFor(String rol, BuildContext context) {
    switch (rol) {
      case AppRoles.entrenador:
        return [
          EntrenadorInicioTab(
            entrenadorEmail: widget.usuarioEmail,
            categoriaDeportiva: widget.categoriaDeportiva,
          ),
          EntrenadorPlanificacionTab(
            entrenadorEmail: widget.usuarioEmail,
            entrenadorUsuarioId: widget.usuarioId,
            categoriaDeportiva: widget.categoriaDeportiva,
          ),
          EntrenadorPlantelTab(
            entrenadorEmail: widget.usuarioEmail,
            entrenadorUsuarioId: widget.usuarioId,
            categoriaDeportiva: widget.categoriaDeportiva,
          ),
          _EntrenadorMasMenuTab(
            entrenadorEmail: widget.usuarioEmail,
            entrenadorUsuarioId: widget.usuarioId,
            entrenadorNombre: widget.nombre,
            categoriaDeportiva: widget.categoriaDeportiva,
            onCerrarSesion: _irALogin,
          ),
        ];
      case AppRoles.jugador:
        return [
          JugadorInicioTab(
            usuarioId: widget.usuarioId,
            usuarioEmail: widget.usuarioEmail,
            saludo: '¡Hola, $_primerNombre!',
            nombreParaAsistencia: widget.nombre,
          ),
          _JugadorProgresoTab(
            saludo: '¡Hola, $_primerNombre!',
            usuarioId: widget.usuarioId,
          ),
          _JugadorNovedadesTab(
            saludo: '¡Hola, $_primerNombre!',
            onVerBlog: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const BlogListScreen(
                    soloLectura: true,
                    autorEmail: '',
                    autorNombre: '',
                  ),
                ),
              );
            },
          ),
          _MasListaTab(
            titulo: 'Más',
            saludo: '¡Hola, $_primerNombre!',
            opciones: const [
              'Mi información',
              'Historial',
              'Estadísticas',
              'Comunicaciones',
              'Notificaciones',
              'Perfil',
              'Configuración',
              'Objetivos',
              'Soporte',
              'Cerrar Sesión',
            ],
            onCerrarSesion: _irALogin,
            onOpcion: (op) {
              if (op == 'Mi información' || op == 'Perfil') {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JugadorFichaScreen(
                      usuarioId: widget.usuarioId,
                      email: widget.usuarioEmail,
                      nombreInicial: widget.nombre,
                    ),
                  ),
                );
              } else if (op == 'Comunicaciones') {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BlogListScreen(
                      soloLectura: true,
                      autorEmail: '',
                      autorNombre: '',
                    ),
                  ),
                );
              } else if (op == 'Historial') {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ObservacionesJugadorScreen(
                      jugadorId: widget.usuarioId,
                    ),
                  ),
                );
              } else if (op == 'Estadísticas') {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EstadisticasDeportivasScreen(
                      entrenadorEmail: widget.usuarioEmail,
                      jugadorId: widget.usuarioId,
                      soloLectura: true,
                    ),
                  ),
                );
              } else if (op == 'Cerrar Sesión') {
                _irALogin();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$op: próximamente')),
                );
              }
            },
          ),
        ];
      case AppRoles.utilero:
        return [
          UtileroKioscoHome(
            usuarioId: widget.usuarioId,
            usuarioEmail: widget.usuarioEmail,
            nombre: widget.nombre,
            deporteId: _deporteUtilero,
            onIrInventario: () => setState(() => _index = 1),
            onIrPrestamos: () => setState(() => _index = 2),
            onCambiarSeleccion: _cambiarSeleccionUtilero,
            onIrMas: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => UtileroHerramientasScreen(
                    usuarioId: widget.usuarioId,
                    usuarioEmail: widget.usuarioEmail,
                    nombre: widget.nombre,
                    deporteId: _deporteUtilero,
                  ),
                ),
              );
            },
            onAgregarMaterial: () => UtileroAgregarMaterialDialog.mostrar(
              context,
              usuarioId: widget.usuarioId,
              deporteId: _deporteUtilero,
            ),
            onCerrarSesion: () async {
              await UtileroService.registrarAuditoriaSesion(
                utileroId: widget.usuarioId,
                esInicio: false,
              );
              _irALogin();
            },
          ),
          UtileroKioscoStockTab(
            usuarioId: widget.usuarioId,
            deporteId: _deporteUtilero,
            onCambiarSeleccion: _cambiarSeleccionUtilero,
          ),
          UtileroKioscoPrestamosTab(
            usuarioId: widget.usuarioId,
            usuarioEmail: widget.usuarioEmail,
            deporteId: _deporteUtilero,
            onCambiarSeleccion: _cambiarSeleccionUtilero,
          ),
          UtileroMasTab(
            usuarioId: widget.usuarioId,
            usuarioEmail: widget.usuarioEmail,
            nombre: widget.nombre,
            deporteId: _deporteUtilero,
            onCambiarSeleccion: _cambiarSeleccionUtilero,
            onCerrarSesion: () async {
              await UtileroService.registrarAuditoriaSesion(
                utileroId: widget.usuarioId,
                esInicio: false,
              );
              _irALogin();
            },
          ),
        ];
      case AppRoles.administrador:
        return [
          _AdminInicioTab(saludo: '¡Hola, Administrador!'),
          _PlaceholderTab(
            titulo: 'Gestión',
            subtitulo: 'Usuarios, equipos, permisos y configuración institucional.',
          ),
          _PlaceholderTab(
            titulo: 'Reportes',
            subtitulo: 'Reportes globales y exportación.',
          ),
          _MasListaTab(
            titulo: 'Más',
            opciones: const [
              'Configuración del sistema',
              'Auditoría',
              'Notificaciones',
              'Perfil',
              'Cerrar Sesión',
            ],
            onCerrarSesion: _irALogin,
          ),
        ];
      default:
        return [
          _PlaceholderTab(
            titulo: 'Inicio',
            subtitulo: 'Rol no reconocido. Contacta al administrador.',
          ),
          _PlaceholderTab(titulo: 'Ayuda', subtitulo: 'Revisa tu cuenta o el rol asignado en Firestore.'),
        ];
    }
  }

  void _irALogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }
}

/// Pestaña «Más» del entrenador: cabecera + lista de botones como en el mockup DTFly.
class _EntrenadorMasMenuTab extends StatelessWidget {
  const _EntrenadorMasMenuTab({
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    required this.entrenadorNombre,
    this.categoriaDeportiva,
    required this.onCerrarSesion,
  });

  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String entrenadorNombre;
  final String? categoriaDeportiva;
  final VoidCallback onCerrarSesion;

  static const List<_CoachMenuRow> _rows = [
    _CoachMenuRow('Cambiar deporte', Icons.sports),
    _CoachMenuRow('Blog y noticias', Icons.article_outlined),
    _CoachMenuRow('Gestión de partidos', Icons.sports_soccer),
    _CoachMenuRow('Observaciones', Icons.rate_review_outlined),
    _CoachMenuRow('Inventario deportivo', Icons.inventory_2_outlined),
    _CoachMenuRow('Estadísticas deportivas', Icons.insights_outlined),
    _CoachMenuRow('Gestionar Plantel', Icons.groups),
    _CoachMenuRow('Historial', Icons.stacked_line_chart),
    _CoachMenuRow('Estadisticas entrenamientos', Icons.bar_chart),
    _CoachMenuRow('Exportar Reportes', Icons.outbox),
    _CoachMenuRow('Configuracion De Validación', Icons.location_on),
    _CoachMenuRow('Notificaciones', Icons.notifications_none),
    _CoachMenuRow('Perfil', Icons.person_outline),
    _CoachMenuRow('Cerrar Sesión', Icons.door_front_door_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: DtflyCoachHeader(categoriaDeportiva: categoriaDeportiva),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            itemCount: _rows.length,
            itemBuilder: (context, i) {
              final row = _rows[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DtflyPillMenuButton(
                  icon: row.icon,
                  label: row.label,
                  onTap: () => _onMenuTap(context, row.label),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onMenuTap(BuildContext context, String label) async {
    if (label == 'Cambiar deporte') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EntrenadorSeleccionCategoriaScreen(
            nombre: entrenadorNombre,
            usuarioEmail: entrenadorEmail,
            usuarioId: entrenadorUsuarioId,
          ),
        ),
      );
      return;
    }
    if (label == 'Cerrar Sesión') {
      onCerrarSesion();
      return;
    }
    if (label == 'Blog y noticias') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => BlogListScreen(
            soloLectura: false,
            autorEmail: entrenadorEmail,
            autorNombre: entrenadorNombre,
          ),
        ),
      );
      return;
    }
    if (label == 'Gestión de partidos') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PartidosGestionScreen(
            entrenadorEmail: entrenadorEmail,
            entrenadorUsuarioId: entrenadorUsuarioId,
            categoriaDeportiva: categoriaDeportiva,
          ),
        ),
      );
      return;
    }
    if (label == 'Observaciones') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ObservacionesEntrenadorScreen(
            entrenadorEmail: entrenadorEmail,
            entrenadorUsuarioId: entrenadorUsuarioId,
            categoriaDeportiva: categoriaDeportiva,
          ),
        ),
      );
      return;
    }
    if (label == 'Inventario deportivo') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => InventarioScreen(entrenadorEmail: entrenadorEmail),
        ),
      );
      return;
    }
    if (label == 'Estadísticas deportivas') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => EstadisticasDeportivasScreen(
            entrenadorEmail: entrenadorEmail,
            categoriaDeportiva: categoriaDeportiva,
          ),
        ),
      );
      return;
    }
    if (label == 'Gestionar Plantel') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => JugadoresScreen(
            soloJugadores: true,
            categoriaDeportiva: categoriaDeportiva,
          ),
        ),
      );
      return;
    }
    if (label == 'Historial') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EntrenadorHistorialScreen(entrenadorEmail: entrenadorEmail),
        ),
      );
      return;
    }
    if (label == 'Estadisticas entrenamientos') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EntrenadorEstadisticasScreen(entrenadorEmail: entrenadorEmail),
        ),
      );
      return;
    }
    if (label == 'Exportar Reportes') {
      await _exportarReporte(context);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label: próximamente')),
      );
    }
  }

  Future<void> _exportarReporte(BuildContext context) async {
    try {
      final reporte = await ReportesService.generarExcelAsistencia(
        entrenadorEmail: entrenadorEmail,
        entrenadorId: entrenadorUsuarioId,
        deporte: categoriaDeportiva,
      );
      if (context.mounted) {
        final ubicacion = reporte.rutaArchivo == null
            ? ''
            : '\nUbicación: ${reporte.rutaArchivo}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reporte descargado: ${reporte.nombreArchivo} '
              '(${reporte.presentes} presentes, ${reporte.atrasados} atrasados, ${reporte.ausentes} ausentes).'
              '$ubicacion',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el reporte: $e')),
        );
      }
    }
  }
}

class _CoachMenuRow {
  const _CoachMenuRow(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.titulo, required this.subtitulo});

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(subtitulo, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _JugadorNovedadesTab extends StatelessWidget {
  const _JugadorNovedadesTab({
    required this.saludo,
    required this.onVerBlog,
  });

  final String saludo;
  final VoidCallback onVerBlog;

  static String _fmtPartido(Partido p) {
    return '${p.fechaHora.day.toString().padLeft(2, '0')}/'
        '${p.fechaHora.month.toString().padLeft(2, '0')} '
        '${p.fechaHora.hour.toString().padLeft(2, '0')}:'
        '${p.fechaHora.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        children: [
          _StudentHeader(titulo: saludo),
          const SizedBox(height: 12),
          StreamBuilder<List<BlogPublicacion>>(
            stream: BlogService.streamPublicaciones(),
            builder: (context, blogSnap) {
              final posts = blogSnap.data ?? [];
              final avisos = posts.where((p) => p.esAvisoImportante).take(2);
              final noticias = posts.where((p) => !p.esAvisoImportante).take(2);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (avisos.isNotEmpty)
                    _StudentPanel(
                      title: 'Avisos importantes',
                      child: Column(
                        children: [
                          for (final p in avisos)
                            _NovedadBlogCard(titulo: p.titulo, extracto: p.contenido),
                        ],
                      ),
                    ),
                  if (avisos.isNotEmpty) const SizedBox(height: 10),
                  _StudentPanel(
                    title: 'Noticias',
                    child: Column(
                      children: [
                        if (noticias.isEmpty && avisos.isEmpty)
                          const Text('Sin publicaciones del equipo.')
                        else
                          for (final p in noticias)
                            _NovedadBlogCard(titulo: p.titulo, extracto: p.contenido),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onVerBlog,
                          style: TextButton.styleFrom(
                            foregroundColor: DtflyTheme.primary,
                          ),
                          child: const Text('Ver todas las noticias'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
          StreamBuilder<List<Partido>>(
            stream: PartidoService.streamProximosGlobales(),
            builder: (context, snap) {
              final partidos = snap.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StudentPanel(
                    title: 'Próximos partidos',
                    child: Column(
                      children: [
                        if (snap.hasError)
                          Text('No se pudieron cargar partidos: ${snap.error}')
                        else if (partidos.isEmpty)
                          const Text('Aún no hay partidos asignados por el DT.')
                        else
                          for (final p in partidos.take(4))
                            _NovedadPartidoCard(
                              fecha: _fmtPartido(p),
                              rival: p.rival,
                              lugar: p.lugar,
                              notas: p.notas,
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StudentPanel(
                    title: 'Notas del DT',
                    child: StreamBuilder<List<NotaDt>>(
                      stream: NotaDtService.streamSemanaActualGlobal(),
                      builder: (context, notaSnap) {
                        if (notaSnap.hasError) {
                          return Text(
                            'No se pudieron cargar las notas: ${notaSnap.error}',
                          );
                        }
                        final notas = notaSnap.data ?? [];
                        if (notas.isEmpty) {
                          return const Text(
                            'Cuando el DT publique lo que espera esta semana aparecerá aquí.',
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final nota in notas.take(4))
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DtflyTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: DtflyTheme.borderSubtle),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.flag_circle,
                                      color: DtflyTheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(nota.texto)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StudentPanel(
                    title: 'Resultados recientes',
                    child: StreamBuilder<List<Partido>>(
                      stream: PartidoService.streamResultadosGlobales(),
                      builder: (context, resSnap) {
                        final res = resSnap.data ?? [];
                        if (res.isEmpty) {
                          return const Text('Aún no hay resultados publicados.');
                        }
                        return Column(
                          children: [
                            for (final p in res.take(4))
                              InkWell(
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PartidoDetalleScreen(partido: p),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'vs ${p.rival}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            p.resultadoTexto ?? '-',
                                            style: const TextStyle(
                                              color: DtflyTheme.accentOrange,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (p.fotosUrls.isNotEmpty)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 6),
                                              child: Icon(
                                                Icons.photo_library_outlined,
                                                size: 18,
                                                color: DtflyTheme.primary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (p.observacionFinal.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            p.observacionFinal,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: DtflyTheme.textMuted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartidosGestionScreen(
                            entrenadorEmail: '',
                            entrenadorUsuarioId: '',
                            soloLectura: true,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: DtflyTheme.primary,
                    ),
                    child: const Text('Ver calendario completo'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NovedadBlogCard extends StatelessWidget {
  const _NovedadBlogCard({required this.titulo, required this.extracto});

  final String titulo;
  final String extracto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DtflyTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DtflyTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: DtflyTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            extracto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DtflyTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NovedadPartidoCard extends StatelessWidget {
  const _NovedadPartidoCard({
    required this.fecha,
    required this.rival,
    required this.lugar,
    required this.notas,
  });

  final String fecha;
  final String rival;
  final String lugar;
  final String notas;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DtflyTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DtflyTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: DtflyTheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              fecha,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs $rival',
                  style: const TextStyle(
                    color: DtflyTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  lugar,
                  style: const TextStyle(
                    color: DtflyTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (notas.trim().isNotEmpty)
                  Text(
                    notas,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DtflyTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JugadorProgresoTab extends StatelessWidget {
  const _JugadorProgresoTab({
    required this.saludo,
    required this.usuarioId,
  });

  final String saludo;
  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        children: [
          _StudentHeader(titulo: saludo),
          const SizedBox(height: 12),
          StreamBuilder<JugadorProgreso>(
            stream: EntrenamientoService.streamProgresoJugador(usuarioId),
            builder: (context, snap) {
              if (snap.hasError) {
                return _StudentPanel(
                  title: 'Resumen',
                  child: Text('No se pudo cargar tu progreso: ${snap.error}'),
                );
              }
              final p = snap.data ??
                  const JugadorProgreso(
                    total: 0,
                    presentes: 0,
                    atrasados: 0,
                    ausentes: 0,
                    asistenciaPct: 0,
                    puntualidadPct: 0,
                    puntos: [],
                  );
              final rendimiento = (p.asistenciaPct / 10).clamp(0, 10).toDouble();
              final progreso = (p.asistenciaPct / 100).clamp(0, 1).toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StudentPanel(
                    title: 'Resumen',
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _ProgressMetricPill(
                                icon: Icons.check_circle_outline,
                                iconColor: Colors.greenAccent.shade700,
                                label: 'Asistencia',
                                value: '${p.asistenciaPct}%',
                              ),
                              _ProgressMetricPill(
                                icon: Icons.timer_outlined,
                                iconColor: Colors.amber,
                                label: 'Puntualidad',
                                value: '${p.puntualidadPct}%',
                              ),
                              _ProgressMetricPill(
                                icon: Icons.star,
                                iconColor: Colors.amber,
                                label: 'Rendimiento',
                                value: rendimiento.toStringAsFixed(1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ProgressRing(value: progreso, label: '${p.asistenciaPct}%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StudentPanel(
                    title: 'Evolución',
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _MiniCount(label: 'Presente', value: p.presentes),
                              _MiniCount(label: 'Atrasado', value: p.atrasados),
                              _MiniCount(label: 'Ausente', value: p.ausentes),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProgressChart(puntos: p.puntos),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StudentPanel(
                    title: 'Objetivos del DT',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entrenamientos registrados: ${p.total}'),
                        const Text('Meta asistencia sobre 90%'),
                        const Text('Meta puntualidad sobre 85%'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  minHeight: 18,
                                  value: progreso,
                                  backgroundColor: DtflyTheme.borderSubtle,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    DtflyTheme.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: DtflyTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '${p.asistenciaPct}%',
                                style: const TextStyle(
                                  color: DtflyTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (p.total == 0) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Cuando te registres en entrenamientos, estos datos se actualizarán solos.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: DtflyTheme.headerGradient,
        borderRadius: DtflyTheme.borderRadiusLg,
        boxShadow: DtflyTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const DtflyCoachLogo(size: 58),
        ],
      ),
    );
  }
}

class _StudentPanel extends StatelessWidget {
  const _StudentPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: DtflyTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DtflyTheme.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DtflyTheme.panelTitle),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: DtflyTheme.panelBody,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ProgressMetricPill extends StatelessWidget {
  const _ProgressMetricPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: DtflyTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DtflyTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: DtflyTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DtflyTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: DtflyTheme.textSecondary),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: DtflyTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 12,
              backgroundColor: const Color(0xFFC7F1DE),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF202436),
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const Text(
                'Asistencia',
                style: TextStyle(fontSize: 11, color: Color(0xFF5A6070)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.puntos});

  final List<JugadorProgresoPunto> puntos;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: puntos.length < 2
          ? const Center(
              child: Text(
                'Sin datos suficientes',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          : CustomPaint(
              painter: _ProgressChartPainter(puntos),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter(this.puntos);

  final List<JugadorProgresoPunto> puntos;

  @override
  void paint(Canvas canvas, Size size) {
    final asistenciaPaint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final puntualidadPaint = Paint()
      ..color = Colors.orange.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final axisPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    Path pathFor(int Function(JugadorProgresoPunto p) value) {
      final path = Path();
      for (var i = 0; i < puntos.length; i++) {
        final x = puntos.length == 1 ? 0.0 : size.width * i / (puntos.length - 1);
        final y = size.height - (size.height * value(puntos[i]) / 100);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    canvas.drawPath(pathFor((p) => p.asistencia), asistenciaPaint);
    canvas.drawPath(pathFor((p) => p.puntualidad), puntualidadPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return oldDelegate.puntos != puntos;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AdminInicioTab extends StatelessWidget {
  const _AdminInicioTab({required this.saludo});

  final String saludo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(saludo, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Panel administrativo: usuarios, validación y reportes globales. '
            '(No aparece detallado en el PDF; estructura alineada al resto de la app.)',
          ),
        ],
      ),
    );
  }
}

class _MasListaTab extends StatelessWidget {
  const _MasListaTab({
    required this.titulo,
    required this.opciones,
    required this.onCerrarSesion,
    this.saludo,
    this.onOpcion,
  });

  final String titulo;
  final List<String> opciones;
  final VoidCallback onCerrarSesion;
  final String? saludo;
  final void Function(String opcion)? onOpcion;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, saludo == null ? 0 : 8, 12, 18),
        children: [
          if (saludo != null) ...[
            _StudentHeader(titulo: saludo!),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
              saludo == null ? 20 : 8,
              saludo == null ? 20 : 4,
              20,
              8,
            ),
            child:
                Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
          ),
          for (final op in opciones)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(op),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (op == 'Cerrar Sesión') {
                    onCerrarSesion();
                  } else if (onOpcion != null) {
                    onOpcion!(op);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$op: próximamente')),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
