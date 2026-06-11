import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_flujo_screen.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Inicio utilero — layout idéntico al mockup DT (header rojo + hoja blanca).
class UtileroKioscoHome extends StatefulWidget {
  const UtileroKioscoHome({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombre,
    this.onIrInventario,
    this.onIrPrestamos,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombre;
  final VoidCallback? onIrInventario;
  final VoidCallback? onIrPrestamos;

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
    await UtileroService.sincronizarAlertasInventario(widget.usuarioId);
    final perfil = await UtileroService.streamPerfil(widget.usuarioId).first;
    if (mounted) {
      setState(() {
        _fotoUrl = perfil.fotoPerfil;
        _deporteNombre = perfil.deporteNombre;
      });
    }
    await _recargar();
  }

  Future<void> _recargar() async {
    final r = await UtileroService.cargarResumen(widget.usuarioId);
    if (mounted) setState(() => _resumen = r);
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
      stream: InventarioService.streamMateriales(),
      builder: (context, snap) {
        final stock = snap.hasData
            ? UtileroInventarioKiosco.stockDesdeMateriales(snap.data!)
            : <String, int>{};

        return DtflyMockupDashboardLayout(
          saludo: '¡Hola, $_primerNombre!',
          subtitulo: _deporteNombre != null && _deporteNombre!.isNotEmpty
              ? 'Utilero · $_deporteNombre'
              : 'Utilero · Gestión de inventario',
          stats: _stats,
          fotoUrl: _fotoUrl,
          onRefresh: _recargar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                titulo: 'Prestar material',
                subtitulo: r != null && r.prestamosPendientes > 0
                    ? '${r.prestamosPendientes} devoluciones pendientes'
                    : 'Entregar implementos a un profesor',
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
                texto: '+ Agregar material (escaleras, otros…)',
                onTap: () => UtileroAgregarMaterialDialog.mostrar(
                  context,
                  usuarioId: widget.usuarioId,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inventario disponible',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...UtileroMaterialCat.todas.map((cat) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: bajo ? const Color(0xFFC62828) : DtflyTheme.borderSubtle,
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
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  Text(
                                    bajo ? 'Stock bajo' : '$cant disponibles',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: bajo ? const Color(0xFFC62828) : DtflyTheme.textSecondary,
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
                                color: bajo ? const Color(0xFFC62828) : DtflyTheme.success,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: DtflyTheme.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
