import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/utilero/utilero_agregar_material_screen.dart';

/// Abre la pantalla de agregar material personalizado con foto.
class UtileroAgregarMaterialDialog {
  UtileroAgregarMaterialDialog._();

  static Future<bool> mostrar(
    BuildContext context, {
    required String usuarioId,
  }) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroAgregarMaterialScreen(usuarioId: usuarioId),
      ),
    );
    return ok == true;
  }
}
