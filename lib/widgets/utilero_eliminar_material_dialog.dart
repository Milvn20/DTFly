import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Confirmación y eliminación de un material del inventario.
class UtileroEliminarMaterialDialog {
  UtileroEliminarMaterialDialog._();

  static Future<bool> confirmar(
    BuildContext context, {
    required MaterialInventario material,
    required String usuarioId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar material'),
        content: Text(
          '¿Eliminar «${material.nombre}» del inventario?\n\n'
          'Stock actual: ${material.cantidadDisponible} disponible(s), '
          '${material.cantidadTotal} total.\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return false;

    try {
      await UtileroInventarioKiosco.eliminarMaterial(
        material: material,
        utileroId: usuarioId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('«${material.nombre}» eliminado del inventario'),
            backgroundColor: DtflyTheme.success,
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }
}
