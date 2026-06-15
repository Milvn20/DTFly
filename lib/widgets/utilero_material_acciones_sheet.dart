import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_eliminar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_ingresar_stock_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Acciones visibles al tocar un material: agregar stock o eliminar.
class UtileroMaterialAccionesSheet {
  UtileroMaterialAccionesSheet._();

  static Future<void> mostrar(
    BuildContext context, {
    required MaterialInventario material,
    required String usuarioId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(
                builder: (context) {
                  final cat = UtileroMaterialCat.resolver(
                    '${material.categoria} ${material.nombre}',
                  );
                  return UtileroMaterialIcon(
                    categoria: cat,
                    size: 48,
                    imagenUrl: material.imagenUrl,
                    imagenBase64: material.imagenBase64,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                material.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${material.cantidadDisponible} disponible(s) · ${material.cantidadTotal} total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: DtflyTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UtileroEliminarMaterialDialog.confirmar(
                      context,
                      material: material,
                      usuarioId: usuarioId,
                    );
                  },
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Eliminar material'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.add_box_outlined,
                  color: Color(0xFFC62828),
                ),
                title: const Text('Agregar stock'),
                subtitle: const Text('Sumar unidades que llegaron'),
                onTap: () {
                  Navigator.pop(ctx);
                  UtileroIngresarStockDialog.mostrarPorMaterial(
                    context,
                    material: material,
                    usuarioId: usuarioId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined, color: Color(0xFFC62828)),
                title: const Text('Ubicación en bodega'),
                subtitle: Text(
                  material.ubicacionTexto.isEmpty
                      ? 'Sin ubicación registrada'
                      : material.ubicacionTexto,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _editarUbicacion(context, material);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editarUbicacion(
  BuildContext context,
  MaterialInventario material,
) async {
  final ubicacion = TextEditingController(text: material.ubicacion ?? '');
  final pasillo = TextEditingController(text: material.pasillo ?? '');
  final estante = TextEditingController(text: material.estante ?? '');

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ubicación en bodega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ubicacion,
            decoration: const InputDecoration(
              labelText: 'Sector / pabellón',
            ),
          ),
          TextField(
            controller: pasillo,
            decoration: const InputDecoration(labelText: 'Pasillo'),
          ),
          TextField(
            controller: estante,
            decoration: const InputDecoration(labelText: 'Estante / casillero'),
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
  );

  final u = ubicacion.text;
  final p = pasillo.text;
  final e = estante.text;
  ubicacion.dispose();
  pasillo.dispose();
  estante.dispose();

  if (ok != true) return;

  try {
    await InventarioService.actualizarUbicacion(
      materialId: material.id,
      ubicacion: u,
      pasillo: p,
      estante: e,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación guardada')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

/// Varias entradas duplicadas en una categoría (ej. dos registros de balones).
class UtileroMaterialesCategoriaSheet {
  UtileroMaterialesCategoriaSheet._();

  static Future<void> mostrar(
    BuildContext context, {
    required UtileroMaterialCat categoria,
    required List<MaterialInventario> materiales,
    required String usuarioId,
    String? deporteId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                categoria.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${materiales.length} registro(s) — elige cuál gestionar',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: DtflyTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: materiales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final m = materiales[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: UtileroMaterialIcon(
                          categoria: categoria,
                          size: 32,
                          imagenUrl: m.imagenUrl,
                          imagenBase64: m.imagenBase64,
                        ),
                        title: Text(m.nombre),
                        subtitle: Text(
                          '${m.cantidadDisponible} disp. · ${m.cantidadTotal} total',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_box_outlined),
                              color: const Color(0xFFC62828),
                              tooltip: 'Agregar stock',
                              onPressed: () {
                                Navigator.pop(ctx);
                                UtileroIngresarStockDialog.mostrarPorMaterial(
                                  context,
                                  material: m,
                                  usuarioId: usuarioId,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: const Color(0xFFC62828),
                              tooltip: 'Eliminar',
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await UtileroEliminarMaterialDialog.confirmar(
                                  context,
                                  material: m,
                                  usuarioId: usuarioId,
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          UtileroMaterialAccionesSheet.mostrar(
                            context,
                            material: m,
                            usuarioId: usuarioId,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de materiales eliminables de la selección actual.
class UtileroEliminarMaterialListaScreen extends StatelessWidget {
  const UtileroEliminarMaterialListaScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Eliminar material'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MaterialInventario>>(
        stream: InventarioService.streamMaterialesDeporte(deporteId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828)),
            );
          }
          final materiales = snap.data ?? [];
          if (materiales.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay materiales en esta selección',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agrega material primero o cambia de selección deportiva.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC62828).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFC62828)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${materiales.length} material(es) en esta selección. '
                        'Pulsa ELIMINAR en el que quieras quitar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...materiales.map((m) {
                final cat = UtileroMaterialCat.resolver(
                  '${m.categoria} ${m.nombre}',
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              UtileroMaterialIcon(
                                categoria: cat,
                                size: 52,
                                imagenUrl: m.imagenUrl,
                                imagenBase64: m.imagenBase64,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.nombre,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      m.categoria,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: DtflyTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${m.cantidadDisponible} disponibles · '
                                      '${m.cantidadTotal} total',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  UtileroEliminarMaterialDialog.confirmar(
                                context,
                                material: m,
                                usuarioId: usuarioId,
                              ),
                              icon: const Icon(Icons.delete_forever_outlined),
                              label: const Text('ELIMINAR'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
