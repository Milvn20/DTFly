import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/actividad_utilero.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';
import 'package:flutter_application_1/widgets/utilero_dtfly_widgets.dart';

/// Historial simplificado — estilo lista DT.
class UtileroKioscoHistorialTab extends StatelessWidget {
  const UtileroKioscoHistorialTab({
    super.key,
    required this.usuarioId,
    this.mostrarCabecera = true,
  });

  final String usuarioId;
  final bool mostrarCabecera;

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _texto(ActividadUtilero a) {
    final n = a.cantidad;
    final acc = a.accion.toLowerCase();
    if (acc.contains('préstamo') || acc.contains('prestamo')) {
      return '$n ${a.material} prestados';
    }
    if (acc.contains('devol')) return '$n ${a.material} devueltos';
    if (acc.contains('dañado') || acc.contains('danado')) {
      return '$n ${a.material} dañados';
    }
    if (acc.contains('recep') || acc.contains('inventario')) {
      return '$n ${a.material} ingresados';
    }
    return a.descripcion.isNotEmpty ? a.descripcion : a.accion;
  }

  static bool _esMovimiento(ActividadUtilero a) {
    final acc = a.accion.toLowerCase();
    return acc.contains('préstamo') ||
        acc.contains('prestamo') ||
        acc.contains('devol') ||
        acc.contains('dañado') ||
        acc.contains('danado') ||
        acc.contains('recep') ||
        acc.contains('inventario');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DtflyTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarCabecera)
            SafeArea(
              bottom: false,
              child: DtflyCoachHeader(
                saludo: 'Historial',
                subtitulo: 'Últimos movimientos',
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ActividadUtilero>>(
              stream: UtileroService.streamActividad(usuarioId, limite: 60),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: DtflyTheme.primary),
                  );
                }
                final items = (snap.data ?? []).where(_esMovimiento).toList();
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin movimientos aún',
                      style: TextStyle(fontSize: 16, color: DtflyTheme.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = items[i];
                    final cat = UtileroMaterialCat.resolver(a.material);
                    return DtflyMaterialRow(
                      categoria: cat,
                      titulo: _texto(a),
                      subtitulo: a.accion,
                      trailing: Text(
                        _hora(a.fecha),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: DtflyTheme.textSecondary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
