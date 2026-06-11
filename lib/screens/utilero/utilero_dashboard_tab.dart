import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/material_categoria_visual.dart';
import 'package:flutter_application_1/screens/inventario/inventario_screen.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_widgets.dart';

/// Dashboard personal del utilero (resumen, alertas, actividad reciente).
class UtileroDashboardTab extends StatefulWidget {
  const UtileroDashboardTab({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombre,
    this.onIrPerfil,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombre;
  final VoidCallback? onIrPerfil;

  @override
  State<UtileroDashboardTab> createState() => _UtileroDashboardTabState();
}

class _UtileroDashboardTabState extends State<UtileroDashboardTab> {
  UtileroResumenDashboard? _resumen;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    await UtileroService.asegurarPerfil(
      usuarioId: widget.usuarioId,
      nombre: widget.nombre,
      correo: widget.usuarioEmail,
    );
    await UtileroService.sincronizarAlertasInventario(widget.usuarioId);
    final r = await UtileroService.cargarResumen(widget.usuarioId);
    if (mounted) {
      setState(() {
        _resumen = r;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final r = _resumen!;
    final stockOrdenado =
        MaterialCategoriaVisual.stockConDefaults(r.stockPorCategoria);

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '¡Hola, ${widget.nombre.split(' ').first}!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Stock disponible por material',
            style: TextStyle(color: DtflyTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...stockOrdenado.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UtileroMaterialStockTile(
                categoria: e.key,
                cantidad: e.value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (r.stockBajo > 0)
                UtileroAlertChip(
                  texto: 'Stock bajo ($r.stockBajo)',
                  icono: Icons.warning_amber,
                  esCritico: true,
                ),
              if (r.prestamosPendientes > 0)
                UtileroAlertChip(
                  texto: 'Devoluciones pendientes (${r.prestamosPendientes})',
                  icono: Icons.schedule,
                ),
              if (r.materialesDanados > 0)
                UtileroAlertChip(
                  texto: 'Material dañado (${r.materialesDanados} u.)',
                  icono: Icons.broken_image,
                  esCritico: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          UtileroResumenCompacto(
            materialesRegistrados: r.materialesRegistrados,
            materialesEntregados: r.materialesEntregados,
            materialesDevueltos: r.materialesDevueltos,
            stockBajo: r.stockBajo,
            materialesDanados: r.materialesDanados,
            entrenamientosSemana: r.entrenamientosSemana,
            entregadosHoy: r.entregadosHoy,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventarioScreen(
                          entrenadorEmail: widget.usuarioEmail,
                          utileroUsuarioId: widget.usuarioId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2, size: 20),
                  label: const Text('Inventario'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onIrPerfil != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onIrPerfil,
                    icon: const Icon(Icons.person, size: 20),
                    label: const Text('Perfil'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Actividad reciente', style: DtflyTheme.panelTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          if (r.ultimasActividades.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Aún no hay movimientos registrados.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else
            ...r.ultimasActividades.map(
              (a) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    MaterialCategoriaVisual.resolver(a.material).icono,
                    color: DtflyTheme.primary,
                    size: 22,
                  ),
                  title: Text(a.accion, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '${a.material} · ${a.descripcion}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${a.fecha.day}/${a.fecha.month}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
