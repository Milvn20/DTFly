import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/prestamo_material.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_flujo_screen.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Lista de préstamos activos que aún deben devolverse.
class UtileroDevolucionesPendientesScreen extends StatelessWidget {
  const UtileroDevolucionesPendientesScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    this.deporteId,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String? deporteId;

  String _fechaCorta(DateTime d) {
    if (d.millisecondsSinceEpoch <= 0) return '—';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} $h:$m';
  }

  void _irADevolver(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroKioscoFlujoScreen(
          flujo: UtileroFlujoKiosco.devolver,
          usuarioId: usuarioId,
          usuarioEmail: usuarioEmail,
          deporteId: deporteId,
        ),
      ),
    );
  }

  Widget _buildLista(BuildContext context, List<PrestamoMaterial> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: DtflyTheme.success,
              ),
              const SizedBox(height: 12),
              const Text(
                'No hay devoluciones pendientes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final agrupado = <String, List<PrestamoMaterial>>{};
    for (final p in lista) {
      agrupado.putIfAbsent(p.materialNombre, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          '${lista.length} préstamo(s) por devolver',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in agrupado.entries) ...[
          _ResumenMaterial(
            materialNombre: entry.key,
            prestamos: entry.value,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        for (final p in lista) ...[
          _PrestamoPendienteTile(
            prestamo: p,
            fecha: _fechaCorta(p.prestadoEn),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _irADevolver(context),
          icon: const Icon(Icons.assignment_return),
          label: const Text('Registrar devolución'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC62828),
      appBar: AppBar(
        title: const Text('Devoluciones pendientes'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: DtflyTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StreamBuilder<List<PrestamoMaterial>>(
          stream: InventarioService.streamPrestamosActivos(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFC62828)),
              );
            }
            return StreamBuilder<List<MaterialInventario>>(
              stream: InventarioService.streamMaterialesDeporte(deporteId),
              builder: (context, matSnap) {
                final todos = snap.data ?? [];
                final matIds = (matSnap.data ?? []).map((m) => m.id).toSet();
                final lista =
                    todos.where((p) => matIds.contains(p.materialId)).toList();
                return _buildLista(context, lista);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResumenMaterial extends StatelessWidget {
  const _ResumenMaterial({
    required this.materialNombre,
    required this.prestamos,
  });

  final String materialNombre;
  final List<PrestamoMaterial> prestamos;

  @override
  Widget build(BuildContext context) {
    final total = prestamos.fold<int>(0, (s, p) => s + p.cantidad);
    final cat = UtileroMaterialCat.resolver(materialNombre);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          UtileroMaterialIcon(categoria: cat, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              materialNombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Text(
            'Devolver $total',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestamoPendienteTile extends StatelessWidget {
  const _PrestamoPendienteTile({
    required this.prestamo,
    required this.fecha,
  });

  final PrestamoMaterial prestamo;
  final String fecha;

  @override
  Widget build(BuildContext context) {
    final cat = UtileroMaterialCat.resolver(prestamo.materialNombre);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DtflyTheme.borderSubtle),
      ),
      child: Row(
        children: [
          UtileroMaterialIcon(categoria: cat, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${prestamo.cantidad} × ${prestamo.materialNombre}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Entregado a ${prestamo.prestadoA}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DtflyTheme.textSecondary,
                  ),
                ),
                Text(
                  fecha,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DtflyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pendiente',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
