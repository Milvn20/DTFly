import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_devoluciones_pendientes_screen.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_flujo_screen.dart';
import 'package:flutter_application_1/screens/utilero/utilero_modulos_screens.dart';
import 'package:flutter_application_1/screens/utilero/utilero_seccion_screen.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_cambiar_seleccion_button.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';
import 'package:flutter_application_1/widgets/utilero_material_acciones_sheet.dart';
import 'package:flutter_application_1/widgets/utilero_menu_sheet.dart';

/// Inicio utilero — layout idéntico al mockup DT (header rojo + hoja blanca).
class UtileroKioscoHome extends StatefulWidget {
  const UtileroKioscoHome({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombre,
    this.onIrInventario,
    this.onIrPrestamos,
    this.deporteId,
    this.onCambiarSeleccion,
    this.onMenu,
    this.onIrMas,
    this.onCerrarSesion,
    this.onAgregarMaterial,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombre;
  final VoidCallback? onIrInventario;
  final VoidCallback? onIrPrestamos;
  final String? deporteId;
  final VoidCallback? onCambiarSeleccion;
  final VoidCallback? onMenu;
  final VoidCallback? onIrMas;
  final VoidCallback? onCerrarSesion;
  final VoidCallback? onAgregarMaterial;

  @override
  State<UtileroKioscoHome> createState() => _UtileroKioscoHomeState();
}

class _UtileroKioscoHomeState extends State<UtileroKioscoHome> {
  UtileroResumenDashboard? _resumen;
  String? _fotoUrl;
  String? _deporteNombre;
  int _notificacionesNoLeidas = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await UtileroService.asegurarPerfil(
      usuarioId: widget.usuarioId,
      nombre: widget.nombre,
      correo: widget.usuarioEmail,
    );
    await UtileroService.sincronizarAlertasInventario(
      widget.usuarioId,
      deporteId: widget.deporteId,
    );
    final perfil = await UtileroService.streamPerfil(widget.usuarioId).first;
    if (mounted) {
      setState(() {
        _fotoUrl = perfil.fotoPerfil;
        _deporteNombre = perfil.deporteNombre;
      });
    }
    await _recargar();
  }

  @override
  void didUpdateWidget(covariant UtileroKioscoHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deporteId != widget.deporteId) {
      _recargar();
    }
  }

  Future<void> _recargar() async {
    final r = await UtileroService.cargarResumen(
      widget.usuarioId,
      deporteId: widget.deporteId,
    );
    final noLeidas =
        await UtileroService.contarNotificacionesNoLeidas(widget.usuarioId);
    if (mounted) {
      setState(() {
        _resumen = r;
        _notificacionesNoLeidas = noLeidas;
      });
    }
  }

  void _abrirHerramientas() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroHerramientasScreen(
          usuarioId: widget.usuarioId,
          usuarioEmail: widget.usuarioEmail,
          nombre: widget.nombre,
          deporteId: widget.deporteId,
        ),
      ),
    );
  }

  void _abrirNotificaciones() {
    UtileroSeccionScreen.abrir(
      context,
      titulo: 'Notificaciones',
      usuarioId: widget.usuarioId,
      usuarioEmail: widget.usuarioEmail,
      nombreInicial: widget.nombre,
      seccion: UtileroSeccion.notificaciones,
    ).then((_) => _recargar());
  }

  String get _primerNombre {
    final p = widget.nombre.trim().split(RegExp(r'\s+')).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => 'Utilero',
        );
    return p;
  }

  void _abrirFlujo(UtileroFlujoKiosco flujo) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroKioscoFlujoScreen(
          flujo: flujo,
          usuarioId: widget.usuarioId,
          usuarioEmail: widget.usuarioEmail,
          deporteId: widget.deporteId,
        ),
      ),
    ).then((_) => _recargar());
  }

  List<({IconData icono, String valor, String etiqueta})> get _stats {
    final r = _resumen;
    if (r == null) {
      return [
        (icono: Icons.inventory_2_outlined, valor: '—', etiqueta: 'Materiales'),
        (icono: Icons.handshake_outlined, valor: '—', etiqueta: 'Prestados'),
        (icono: Icons.assignment_return_outlined, valor: '—', etiqueta: 'Devueltos'),
        (icono: Icons.check_box_outlined, valor: '—', etiqueta: 'Stock bajo'),
      ];
    }
    return [
      (icono: Icons.inventory_2_outlined, valor: '${r.materialesRegistrados}', etiqueta: 'Materiales'),
      (icono: Icons.handshake_outlined, valor: '${r.entregadosHoy}', etiqueta: 'Prestados hoy'),
      (icono: Icons.emoji_events_outlined, valor: '${r.devueltosHoy}', etiqueta: 'Devueltos hoy'),
      (
        icono: Icons.check_box_outlined,
        valor: '${r.stockBajo}',
        etiqueta: 'Stock bajo',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumen;

    return StreamBuilder(
      stream: InventarioService.streamMaterialesDeporte(widget.deporteId),
      builder: (context, snap) {
        final mats = snap.data ?? [];
        final stock = snap.hasData
            ? UtileroInventarioKiosco.stockDesdeMateriales(mats)
            : <String, int>{};
        final agregados = UtileroInventarioKiosco.materialesAgregados(mats);

        return DtflyMockupDashboardLayout(
          saludo: '¡Hola, $_primerNombre!',
          subtitulo: _deporteNombre != null && _deporteNombre!.isNotEmpty
              ? 'Utilero · $_deporteNombre'
              : widget.deporteId != null && widget.deporteId!.isNotEmpty
                  ? 'Utilero · ${DeportesCategoria.nombreVisible(widget.deporteId)}'
                  : 'Utilero · Gestión de inventario',
          stats: _stats,
          fotoUrl: _fotoUrl,
          onRefresh: _recargar,
          onMenu: widget.onMenu ??
              () => UtileroMenuSheet.mostrar(
                context,
                nombre: widget.nombre,
                deporteId: widget.deporteId,
                onIrInventario: widget.onIrInventario ?? () {},
                onIrPrestamos: widget.onIrPrestamos ?? () {},
                onIrMas: widget.onIrMas ?? _abrirHerramientas,
                onCambiarSeleccion: widget.onCambiarSeleccion ?? () {},
                onAgregarMaterial: widget.onAgregarMaterial ?? () {},
                onEliminarMaterial: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UtileroEliminarMaterialListaScreen(
                        usuarioId: widget.usuarioId,
                        deporteId: widget.deporteId,
                      ),
                    ),
                  );
                },
                onCerrarSesion: widget.onCerrarSesion ?? () {},
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onCambiarSeleccion != null) ...[
                UtileroCambiarSeleccionButton(
                  deporteId: widget.deporteId,
                  onTap: widget.onCambiarSeleccion!,
                  compacto: true,
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _abrirHerramientas,
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: const Text('Herramientas utilero'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AccesoRapidoUtilero(
                      icono: Icons.calendar_month_outlined,
                      etiqueta: 'Calendario',
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UtileroCalendarioScreen(
                              usuarioId: widget.usuarioId,
                              deporteId: widget.deporteId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AccesoRapidoUtilero(
                      icono: Icons.checklist_rtl,
                      etiqueta: 'Checklist',
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UtileroChecklistScreen(
                              usuarioId: widget.usuarioId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AccesoRapidoUtilero(
                      icono: Icons.notifications_outlined,
                      etiqueta: 'Alertas',
                      badge: _notificacionesNoLeidas > 0
                          ? '$_notificacionesNoLeidas'
                          : null,
                      onTap: _abrirNotificaciones,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Acción principal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  if (r != null && r.prestamosPendientes > 0)
                    DtflyMockupBadge('${r.prestamosPendientes} pendientes'),
                ],
              ),
              const SizedBox(height: 12),
              DtflyMockupInnerCard(
                emoji: '🤝',
                titulo: r != null && r.prestamosPendientes > 0
                    ? 'Devoluciones pendientes'
                    : 'Prestar material',
                subtitulo: r != null && r.prestamosPendientes > 0
                    ? '${r.prestamosPendientes} por devolver — toca para ver lista'
                    : 'Entregar implementos a un profesor',
                onTap: () {
                  if (r != null && r.prestamosPendientes > 0) {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UtileroDevolucionesPendientesScreen(
                          usuarioId: widget.usuarioId,
                          usuarioEmail: widget.usuarioEmail,
                          deporteId: widget.deporteId,
                        ),
                      ),
                    ).then((_) => _recargar());
                  } else {
                    _abrirFlujo(UtileroFlujoKiosco.prestar);
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Resumen rápido',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DtflyTheme.borderSubtle),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 8,
                  runSpacing: 12,
                  children: UtileroMaterialCat.todas.map((cat) {
                    final n = stock[cat.id] ?? 0;
                    return SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          UtileroMaterialIcon(categoria: cat, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '$n',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFFC62828),
                            ),
                          ),
                          Text(
                            cat.nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: DtflyTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca Inventario para ver todo el stock',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: DtflyTheme.textMuted),
              ),
              const SizedBox(height: 20),
              DtflyMockupPrimaryButton(
                texto: 'Prestar material',
                onTap: () => _abrirFlujo(UtileroFlujoKiosco.prestar),
              ),
              const SizedBox(height: 12),
              DtflyMockupPrimaryButton(
                texto: 'Gestionar inventario',
                onTap: widget.onIrInventario ?? () => _abrirFlujo(UtileroFlujoKiosco.recibir),
              ),
              const SizedBox(height: 12),
              DtflyMockupPrimaryButton(
                texto: '+ Agregar material con tu foto',
                onTap: () => UtileroAgregarMaterialDialog.mostrar(
                  context,
                  usuarioId: widget.usuarioId,
                  deporteId: widget.deporteId,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inventario disponible',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...UtileroMaterialCat.todas
                  .where((c) => c.id != 'mas')
                  .map((cat) {
                final cant = stock[cat.id] ?? 0;
                final bajo = cant <= UtileroMaterialCat.umbralStockBajo;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: widget.onIrInventario,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: bajo
                                ? const Color(0xFFC62828)
                                : DtflyTheme.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            UtileroMaterialIcon(categoria: cat, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    bajo ? 'Stock bajo' : '$cant disponibles',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: bajo
                                          ? const Color(0xFFC62828)
                                          : DtflyTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$cant',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: bajo
                                    ? const Color(0xFFC62828)
                                    : DtflyTheme.success,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: DtflyTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (agregados.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Materiales agregados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...agregados.map((m) {
                  final cat = UtileroMaterialCat.todas
                      .firstWhere((c) => c.id == 'mas');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: widget.onIrInventario,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: DtflyTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              UtileroMaterialIcon(
                                categoria: cat,
                                imagenUrl: m.imagenUrl,
                                imagenBase64: m.imagenBase64,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${m.cantidadDisponible}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AccesoRapidoUtilero extends StatelessWidget {
  const _AccesoRapidoUtilero({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.badge,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DtflyTheme.borderSubtle),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icono, color: const Color(0xFFC62828), size: 26),
                  if (badge != null)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
