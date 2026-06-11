import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Diálogo para que el utilero registre material nuevo (escaleras, otros, etc.).
class UtileroAgregarMaterialDialog {
  UtileroAgregarMaterialDialog._();

  static Future<bool> mostrar(
    BuildContext context, {
    required String usuarioId,
  }) async {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    var categoria = UtileroMaterialCat.todas.first;
    var categoriaPersonalizada = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Agregar material al inventario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del material',
                    hintText: 'Ej: Escalera de coordinación',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UtileroMaterialCat>(
                  initialValue: categoria,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de material',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in UtileroMaterialCat.todas)
                      DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            UtileroMaterialIcon(categoria: c, size: 22),
                            const SizedBox(width: 10),
                            Text(c.nombre),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setSt(() {
                      categoria = v;
                      categoriaPersonalizada = v.id == 'otros';
                    });
                  },
                ),
                if (categoriaPersonalizada) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'En «Otros» puedes registrar implementos que no están en la lista '
                    '(cuerdas, arcos, etc.).',
                    style: TextStyle(fontSize: 12, color: DtflyTheme.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad inicial',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );

    final nombre = nombreCtrl.text.trim();
    final cantidad = int.tryParse(cantidadCtrl.text) ?? 0;
    nombreCtrl.dispose();
    cantidadCtrl.dispose();

    if (ok != true || nombre.isEmpty || cantidad <= 0) return false;

    try {
      await InventarioService.agregarMaterial(
        nombre: nombre,
        categoria: categoria.etiquetaFirestore,
        cantidad: cantidad,
      );
      await UtileroService.registrarActividad(
        utileroId: usuarioId,
        accion: 'Registró material',
        descripcion: '$nombre (${categoria.nombre})',
        material: nombre,
        cantidad: cantidad,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«$nombre» agregado al inventario')),
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
