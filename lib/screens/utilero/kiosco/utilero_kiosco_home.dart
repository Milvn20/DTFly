import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_devoluciones_pendientes_screen.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_flujo_screen.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_cambiar_seleccion_button.dart';
import 'package:flutter_application_1/widgets/utilero_inventario_acciones_bar.dart';
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
    if (mounted) {
      setState(() => _resumen = r);
    }
  }

  void _abrirEliminar(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroEliminarMaterialListaScreen(
          usuarioId: widget.usuarioId,
          deporteId: widget.deporteId,
        ),
      ),
    );
  }

  void _gestionarMaterial(
    BuildContext context,
    List<MaterialInventario> mats,
    UtileroMaterialCat cat,
  ) {
    final enCat = UtileroInventarioKiosco.materialesEnCategoria(mats, cat);
    if (enCat.isEmpty) {
      final agregadosCat = mats
          .where((m) => UtileroInventarioKiosco.esMaterialPersonalizado(m))
          .toList();
      if (agregadosCat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay registro de este material. Usa «Eliminar material» arriba '
              'o agrega stock desde Inventario.',
            ),
          ),
        );
      }
      return;
    }
    if (enCat.length == 1) {
      UtileroMaterialAccionesSheet.mostrar(
        context,
        material: enCat.first,
        usuarioId: widget.usuarioId,
      );
    } else {
      UtileroMaterialesCategoriaSheet.mostrar(
        context,
        categoria: cat,
        materiales: enCat,
        usuarioId: widget.usuarioId,
        deporteId: widget.deporteId,
      );
    }
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
                onIrMas: widget.onIrMas ?? () {},
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
                ),
                const SizedBox(height: 12),
              ],
              UtileroInventarioAccionesBar(
                usuarioId: widget.usuarioId,
                deporteId: widget.deporteId,
                onEliminarLista: () => _abrirEliminar(context),
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
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DtflyTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (final cat in UtileroMaterialCat.todas)
                          Builder(
                            builder: (context) {
                              final n = stock[cat.id] ?? 0;
                              final img = UtileroInventarioKiosco
                                  .imagenDeCategoria(mats, cat);
                              return InkWell(
                                onTap: () =>
                                    _gestionarMaterial(context, mats, cat),
                                onLongPress: () => _abrirEliminar(context),
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 72,
                                  child: Column(
                                    children: [
                                      UtileroMaterialIcon(
                                        categoria: cat,
                                        size: 28,
                                        imagenUrl: img.url,
                                        imagenBase64: img.base64,
                                      ),
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: DtflyTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ...agregados.map((m) {
                          final cat = UtileroMaterialCat.todas
                              .firstWhere((c) => c.id == 'mas');
                          return InkWell(
                            onTap: () => UtileroMaterialAccionesSheet.mostrar(
                              context,
                              material: m,
                              usuarioId: widget.usuarioId,
                            ),
                            onLongPress: () => _abrirEliminar(context),
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 72,
                              child: Column(
                                children: [
                                  UtileroMaterialIcon(
                                    categoria: cat,
                                    size: 28,
                                    imagenUrl: m.imagenUrl,
                                    imagenBase64: m.imagenBase64,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${m.cantidadDisponible}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFFC62828),
                                    ),
                                  ),
                                  Text(
                                    m.nombre,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: DtflyTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DtflyMockupPrimaryButton(
                      texto: '+ Agregar material',
                      onTap: () => UtileroAgregarMaterialDialog.mostrar(
                        context,
                        usuarioId: widget.usuarioId,
                        deporteId: widget.deporteId,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mantén pulsado un material para ir a eliminar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: DtflyTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}
