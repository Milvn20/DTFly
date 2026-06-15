import 'package:flutter/material.dart';

import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_material_acciones_sheet.dart';

/// Acciones de inventario: agregar y eliminar (siempre visibles).
class UtileroInventarioAccionesBar extends StatelessWidget {
  const UtileroInventarioAccionesBar({
    super.key,
    required this.usuarioId,
    this.deporteId,
    this.onEliminarLista,
  });

  final String usuarioId;
  final String? deporteId;
  final VoidCallback? onEliminarLista;

  void _agregar(BuildContext context) {
    UtileroAgregarMaterialDialog.mostrar(
      context,
      usuarioId: usuarioId,
      deporteId: deporteId,
    );
  }

  void _eliminar(BuildContext context) {
    if (onEliminarLista != null) {
      onEliminarLista!();
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroEliminarMaterialListaScreen(
          usuarioId: usuarioId,
          deporteId: deporteId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(14),
          elevation: 2,
          child: InkWell(
            onTap: () => _eliminar(context),
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.delete_forever_outlined, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eliminar material',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Elige qué implemento quitar del inventario',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _agregar(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC62828)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFFC62828), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Agregar material',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
