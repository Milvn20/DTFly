import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/material_categoria_visual.dart';
import 'package:flutter_application_1/models/material_inventario.dart'
    show EstadoStockMaterial, MaterialInventario;
import 'package:flutter_application_1/models/prestamo_material.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Inventario deportivo: stock, préstamos y entregas.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({
    super.key,
    required this.entrenadorEmail,
    this.utileroUsuarioId,
  });

  final String entrenadorEmail;
  final String? utileroUsuarioId;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _agregarMaterial() async {
    final nombre = TextEditingController();
    final cantidad = TextEditingController(text: '1');
    var categoria = InventarioService.categoriasSugeridas.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Agregar material'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre (ej: Balones)',
                ),
              ),
              TextField(
                controller: cantidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  for (final c in InventarioService.categoriasSugeridas)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setSt(() => categoria = v ?? categoria),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    final n = nombre.text.trim();
    final q = int.tryParse(cantidad.text) ?? 0;
    nombre.dispose();
    cantidad.dispose();
    if (ok != true || n.isEmpty || q <= 0) return;

    await InventarioService.agregarMaterial(
      nombre: n,
      categoria: categoria,
      cantidad: q,
    );
    await _logUtilero(
      accion: 'Registró material',
      descripcion: '$n ($categoria)',
      material: n,
      cantidad: q,
    );
  }

  Future<void> _editarCantidad(MaterialInventario m) async {
    final ctrl = TextEditingController(text: '${m.cantidadTotal}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stock: ${m.nombre}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad total'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
    final q = int.tryParse(ctrl.text) ?? m.cantidadTotal;
    ctrl.dispose();
    if (ok == true) {
      await InventarioService.actualizarCantidad(id: m.id, cantidadTotal: q);
      await _logUtilero(
        accion: 'Actualizó inventario',
        descripcion: 'Stock ${m.nombre} → $q',
        material: m.nombre,
        cantidad: q,
      );
    }
  }

  Future<void> _registrarDanado(MaterialInventario m) async {
    final cantidad = TextEditingController(text: '1');
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Marcar dañado: ${m.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Disponible: ${m.cantidadDisponible} ${m.unidad}',
              style: const TextStyle(color: DtflyTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidad,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad dañada'),
            ),
            TextField(
              controller: motivo,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DtflyTheme.fieldRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Registrar dañado'),
          ),
        ],
      ),
    );
    final q = int.tryParse(cantidad.text) ?? 0;
    final mot = motivo.text.trim();
    cantidad.dispose();
    motivo.dispose();
    if (ok != true || q <= 0) return;
    try {
      await InventarioService.registrarDanado(
        materialId: m.id,
        cantidad: q,
        motivo: mot,
      );
      await _logUtilero(
        accion: 'Registró material dañado',
        descripcion: mot.isEmpty ? '$q ${m.unidad}' : mot,
        material: m.nombre,
        cantidad: q,
        estado: EstadoStockMaterial.danado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material marcado como dañado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _recuperarDanado(MaterialInventario m) async {
    final cantidad = TextEditingController(text: '${m.cantidadDanada}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reparar: ${m.nombre}'),
        content: TextField(
          controller: cantidad,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Cantidad a volver a disponible (máx. ${m.cantidadDanada})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recuperar'),
          ),
        ],
      ),
    );
    final q = int.tryParse(cantidad.text) ?? 0;
    cantidad.dispose();
    if (ok != true || q <= 0) return;
    try {
      await InventarioService.recuperarDanado(materialId: m.id, cantidad: q);
      await _logUtilero(
        accion: 'Recuperó material dañado',
        descripcion: '$q ${m.unidad} reintegrado al stock',
        material: m.nombre,
        cantidad: q,
        estado: EstadoStockMaterial.disponible,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock disponible actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _logUtilero({
    required String accion,
    required String descripcion,
    required String material,
    int cantidad = 0,
    String estado = 'Completado',
  }) async {
    final uid = widget.utileroUsuarioId;
    if (uid == null) return;
    await UtileroService.registrarActividad(
      utileroId: uid,
      accion: accion,
      descripcion: descripcion,
      material: material,
      cantidad: cantidad,
      estado: estado,
    );
  }

  Future<void> _registrarPrestamo(List<MaterialInventario> materiales) async {
    if (materiales.isEmpty) return;
    String? materialId = materiales.first.id;
    final prestadoA = TextEditingController();
    final cantidad = TextEditingController(text: '1');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Registrar préstamo / entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: materialId,
                decoration: const InputDecoration(labelText: 'Material'),
                items: [
                  for (final m in materiales)
                    DropdownMenuItem(
                      value: m.id,
                      child: Text('${m.nombre} (disp: ${m.cantidadDisponible})'),
                    ),
                ],
                onChanged: (v) => setSt(() => materialId = v),
              ),
              TextField(
                controller: prestadoA,
                decoration: const InputDecoration(
                  labelText: 'Entregado a',
                ),
              ),
              TextField(
                controller: cantidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    final mat = materiales.firstWhere((e) => e.id == materialId);
    final q = int.tryParse(cantidad.text) ?? 1;
    final a = prestadoA.text.trim();
    prestadoA.dispose();
    cantidad.dispose();
    if (ok != true || a.isEmpty) return;

    try {
      await InventarioService.registrarPrestamo(
        materialId: mat.id,
        materialNombre: mat.nombre,
        cantidad: q,
        prestadoA: a,
        entrenadorEmail: widget.entrenadorEmail,
      );
      await _logUtilero(
        accion: 'Entregó material',
        descripcion: 'A $a',
        material: mat.nombre,
        cantidad: q,
        estado: EstadoStockMaterial.prestado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préstamo registrado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DtflyDarkScaffold(
      title: 'Inventario deportivo',
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarMaterial,
        backgroundColor: DtflyTheme.secondary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            indicatorColor: DtflyTheme.primary,
            labelColor: DtflyTheme.primary,
            unselectedLabelColor: DtflyTheme.textMuted,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Stock'),
              Tab(text: 'Préstamos'),
              Tab(text: 'Dañados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                StreamBuilder<List<MaterialInventario>>(
                  stream: InventarioService.streamMateriales(),
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'Agrega balones, conos, petos y más.',
                          style: TextStyle(color: DtflyTheme.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OutlinedButton.icon(
                              onPressed: () => _registrarPrestamo(list),
                              icon: const Icon(Icons.outbound),
                              label: const Text('Registrar préstamo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DtflyTheme.primary,
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                          );
                        }
                        final m = list[i - 1];
                        final bajo = m.cantidadDisponible <= 2;
                        return DtflyDarkCard(
                          destacado: bajo || m.tieneDanados,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _MaterialIcono(categoria: m.categoria, nombre: m.nombre),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.nombre,
                                          style: const TextStyle(
                                            color: DtflyTheme.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          m.categoria,
                                          style: const TextStyle(
                                            color: DtflyTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: DtflyTheme.textMuted,
                                    ),
                                    onPressed: () => _editarCantidad(m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: DtflyTheme.fieldRed),
                                    onPressed: () async {
                                      await InventarioService.eliminarMaterial(m.id);
                                      await _logUtilero(
                                        accion: 'Eliminó material',
                                        descripcion: m.nombre,
                                        material: m.nombre,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _StockEstadosRow(material: m),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (bajo)
                                    const _EstadoChip(
                                      label: 'Stock bajo',
                                      color: DtflyTheme.fieldRed,
                                    ),
                                  if (m.tieneDanados)
                                    _EstadoChip(
                                      label: 'Dañado: ${m.cantidadDanada}',
                                      color: DtflyTheme.accentOrange,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: m.cantidadDisponible > 0
                                        ? () => _registrarDanado(m)
                                        : null,
                                    icon: const Icon(Icons.broken_image_outlined,
                                        size: 18),
                                    label: const Text('Dañado'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: DtflyTheme.fieldRed,
                                    ),
                                  ),
                                  if (m.tieneDanados)
                                    TextButton.icon(
                                      onPressed: () => _recuperarDanado(m),
                                      icon: const Icon(Icons.build_outlined, size: 18),
                                      label: const Text('Reparar'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                StreamBuilder<List<PrestamoMaterial>>(
                  stream: InventarioService.streamPrestamosActivos(),
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay préstamos activos.',
                          style: TextStyle(color: DtflyTheme.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return DtflyDarkCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              p.materialNombre,
                              style: const TextStyle(
                                color: DtflyTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${p.cantidad} → ${p.prestadoA}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: TextButton(
                              onPressed: () => _devolverPrestamo(p),
                              child: const Text('Devolver'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                StreamBuilder<List<MaterialInventario>>(
                  stream: InventarioService.streamMaterialesDanados(),
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay material registrado como dañado.',
                          style: TextStyle(color: DtflyTheme.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final m = list[i];
                        return DtflyDarkCard(
                          destacado: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _MaterialIcono(categoria: m.categoria, nombre: m.nombre),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: DtflyTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${m.cantidadDanada} ${m.unidad}',
                                    style: const TextStyle(
                                      color: DtflyTheme.fieldRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _StockEstadosRow(material: m),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _recuperarDanado(m),
                                      icon: const Icon(Icons.build, size: 18),
                                      label: const Text('Reparar / disponible'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _devolverPrestamo(PrestamoMaterial p) async {
    final danados = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Devolver: ${p.materialNombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cantidad prestada: ${p.cantidad}'),
            const SizedBox(height: 12),
            TextField(
              controller: danados,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unidades dañadas al devolver (0–${p.cantidad})',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar devolución'),
          ),
        ],
      ),
    );
    final d = int.tryParse(danados.text) ?? 0;
    danados.dispose();
    if (ok != true) return;
    try {
      await InventarioService.marcarDevuelto(
        prestamoId: p.id,
        cantidadDanadaAlDevolver: d,
      );
      await _logUtilero(
        accion: d > 0 ? 'Devolución con daño' : 'Registró devolución',
        descripcion: d > 0
            ? '${p.prestadoA}: $d dañado(s), ${p.cantidad - d} OK'
            : 'Devuelto por ${p.prestadoA}',
        material: p.materialNombre,
        cantidad: p.cantidad,
        estado: d > 0 ? EstadoStockMaterial.danado : EstadoStockMaterial.disponible,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devolución registrada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _MaterialIcono extends StatelessWidget {
  const _MaterialIcono({required this.categoria, required this.nombre});

  final String categoria;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final v = MaterialCategoriaVisual.resolver(
      categoria.isNotEmpty ? categoria : nombre,
    );
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: v.colorFondo,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        v.imagenAsset,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(v.icono, color: v.colorIcono, size: 26),
      ),
    );
  }
}

class _StockEstadosRow extends StatelessWidget {
  const _StockEstadosRow({required this.material});

  final MaterialInventario material;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EstadoMini(
            label: 'Disponible',
            valor: material.cantidadDisponible,
            color: DtflyTheme.accent,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _EstadoMini(
            label: 'Prestado',
            valor: material.prestados,
            color: DtflyTheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _EstadoMini(
            label: 'Dañado',
            valor: material.cantidadDanada,
            color: DtflyTheme.accentOrange,
          ),
        ),
      ],
    );
  }
}

class _EstadoMini extends StatelessWidget {
  const _EstadoMini({
    required this.label,
    required this.valor,
    required this.color,
  });

  final String label;
  final int valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: DtflyTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
