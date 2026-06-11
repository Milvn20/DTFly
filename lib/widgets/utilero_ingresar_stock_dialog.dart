import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/core/utilero_imagen_comprimir.dart';
import 'package:flutter_application_1/widgets/utilero_eliminar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Agregar unidades al stock desde inventario (tocar una categoría o material).
class UtileroIngresarStockDialog {
  UtileroIngresarStockDialog._();

  static Future<bool> mostrarPorCategoria(
    BuildContext context, {
    required UtileroMaterialCat categoria,
    required String usuarioId,
    required int disponible,
    required int total,
    String? deporteId,
    String? imagenUrl,
    String? imagenBase64,
  }) {
    return _mostrar(
      context,
      usuarioId: usuarioId,
      titulo: categoria.nombre,
      subtitulo: 'Agregar unidades que llegaron al club',
      disponible: disponible,
      total: total,
      icono: UtileroMaterialIcon(
        categoria: categoria,
        imagenUrl: imagenUrl,
        imagenBase64: imagenBase64,
        size: 40,
      ),
      onConfirmar: (cantidad) => UtileroInventarioKiosco.ingresarMaterial(
        cat: categoria,
        cantidad: cantidad,
        utileroId: usuarioId,
        deporteId: deporteId,
      ),
      materialNombre: categoria.nombre,
    );
  }

  static Future<bool> mostrarPorMaterial(
    BuildContext context, {
    required MaterialInventario material,
    required String usuarioId,
  }) {
    final cat = UtileroMaterialCat.resolver(
      '${material.categoria} ${material.nombre}',
    );
    return _mostrar(
      context,
      usuarioId: usuarioId,
      titulo: material.nombre,
      subtitulo: material.categoria,
      disponible: material.cantidadDisponible,
      total: material.cantidadTotal,
      materialId: material.id,
      imagenUrl: material.imagenUrl,
      imagenBase64: material.imagenBase64,
      categoria: cat,
      material: material,
      onConfirmar: (cantidad) async {
        await InventarioService.ingresarStock(
          materialId: material.id,
          cantidad: cantidad,
        );
        await UtileroService.registrarActividad(
          utileroId: usuarioId,
          accion: 'Recepción',
          descripcion: '$cantidad ${material.nombre.toLowerCase()} ingresados',
          material: material.nombre,
          cantidad: cantidad,
        );
      },
      materialNombre: material.nombre,
    );
  }

  static Future<bool> _mostrar(
    BuildContext context, {
    required String usuarioId,
    required String titulo,
    required String subtitulo,
    required int disponible,
    required int total,
    Widget? icono,
    UtileroMaterialCat? categoria,
    String? imagenUrl,
    String? imagenBase64,
    String? materialId,
    MaterialInventario? material,
    required Future<void> Function(int cantidad) onConfirmar,
    required String materialNombre,
  }) async {
    final cantidadCtrl = TextEditingController(text: '1');
    var fotoUrl = imagenUrl;
    var fotoBase64 = imagenBase64;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DtflyTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  icono ??
                      UtileroMaterialThumbnail(
                        categoria: categoria,
                        imagenUrl: fotoUrl,
                        imagenBase64: fotoBase64,
                        size: 40,
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DtflyTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (materialId != null &&
                  (fotoBase64 == null || fotoBase64!.trim().isEmpty) &&
                  (fotoUrl == null || fotoUrl!.trim().isEmpty)) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final img = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 256,
                      maxHeight: 256,
                      imageQuality: 60,
                    );
                    if (img == null) return;
                    final bytes = await comprimirImagenInventario(
                      await img.readAsBytes(),
                    );
                    try {
                      await InventarioService.subirImagenMaterial(
                        materialId: materialId,
                        bytes: bytes,
                      );
                      setSt(() => fotoBase64 = base64Encode(bytes));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Foto guardada')),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('No se pudo subir foto: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Agregar foto de este material'),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _ChipInfo('Disponible', '$disponible'),
                  const SizedBox(width: 8),
                  _ChipInfo('Total', '$total'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '¿Cuántas unidades llegaron?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_box_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Agregar al inventario'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              if (material != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx, false);
                    await UtileroEliminarMaterialDialog.confirmar(
                      context,
                      material: material,
                      usuarioId: usuarioId,
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Eliminar material'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final cantidad = int.tryParse(cantidadCtrl.text) ?? 0;
    cantidadCtrl.dispose();

    if (ok != true || cantidad <= 0) return false;

    try {
      await onConfirmar(cantidad);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$cantidad $materialNombre agregado(s) al stock'),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar: $e')),
        );
      }
      return false;
    }
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DtflyTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DtflyTheme.borderSubtle),
      ),
      child: Text(
        '$etiqueta: $valor',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
