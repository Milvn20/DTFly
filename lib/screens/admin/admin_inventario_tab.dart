import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/utilero_modulos.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';
import 'package:flutter_application_1/widgets/utilero_eliminar_material_dialog.dart';

class AdminInventarioTab extends StatefulWidget {
  const AdminInventarioTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
  });

  final String adminId;
  final String adminEmail;

  @override
  State<AdminInventarioTab> createState() => _AdminInventarioTabState();
}

class _AdminInventarioTabState extends State<AdminInventarioTab> {
  String? _deporteFiltro;
  final _buscar = TextEditingController();

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  List<MaterialInventario> _filtrar(List<MaterialInventario> lista) {
    final q = _buscar.text.trim().toLowerCase();
    return lista.where((m) {
      if (_deporteFiltro != null &&
          _deporteFiltro!.isNotEmpty &&
          m.deporteId != _deporteFiltro &&
          !UtileroMaterialCat.materialEsCompartido(m)) {
        return false;
      }
      if (q.isEmpty) return true;
      return m.nombre.toLowerCase().contains(q) ||
          m.categoria.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _transferir(MaterialInventario m) async {
    String? destino = _deporteFiltro;
    destino = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Transferir a selección'),
        children: [
          for (final d in DeportesCategoria.todas)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d.id),
              child: Text(d.nombre),
            ),
        ],
      ),
    );
    if (destino == null) return;
    await AdminService.transferirMaterial(
      materialId: m.id,
      deporteDestinoId: destino,
      adminId: widget.adminId,
      adminEmail: widget.adminEmail,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material transferido')),
      );
    }
  }

  Future<void> _responderSolicitud(SolicitudCompraUtilero s, bool aprobar) async {
    final ctrl = TextEditingController(
      text: aprobar ? 'Aprobado por administración' : 'Rechazado',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprobar ? 'Aprobar solicitud' : 'Rechazar solicitud'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Respuesta'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;
    await AdminService.responderSolicitud(
      solicitudId: s.id,
      aprobar: aprobar,
      respuesta: ctrl.text,
      adminId: widget.adminId,
      adminEmail: widget.adminEmail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          titulo: 'Inventario global',
          subtitulo: 'Control total de materiales por selección deportiva',
          acciones: [
            FilledButton.icon(
              onPressed: () => UtileroAgregarMaterialDialog.mostrar(
                context,
                usuarioId: widget.adminId,
                deporteId: _deporteFiltro,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar material'),
              style: FilledButton.styleFrom(backgroundColor: adminAccent),
            ),
          ],
        ),
        AdminFilterBar(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _buscar,
                decoration: const InputDecoration(
                  hintText: 'Buscar material...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            DropdownButton<String?>(
              value: _deporteFiltro,
              hint: const Text('Deporte'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...DeportesCategoria.todas.map(
                  (d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)),
                ),
              ],
              onChanged: (v) => setState(() => _deporteFiltro = v),
            ),
            OutlinedButton.icon(
              onPressed: _deporteFiltro == null
                  ? null
                  : () async {
                      final n = await AdminService.asignarStockInicialDeporte(
                        deporteId: _deporteFiltro!,
                        adminId: widget.adminId,
                        adminEmail: widget.adminEmail,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$n materiales legacy asignados')),
                        );
                      }
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Migrar legacy'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<MaterialInventario>>(
          stream: InventarioService.streamMateriales(),
          builder: (context, snap) {
            final mats = _filtrar(snap.data ?? []);
            return Card(
              child: AdminDataTable(
                columnas: const [
                  'Material',
                  'Categoría',
                  'Disp.',
                  'Total',
                  'Dañado',
                  'Deporte',
                  'Acciones',
                ],
                filas: [
                  for (final m in mats)
                    [
                      Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(m.categoria),
                      Text('${m.cantidadDisponible}'),
                      Text('${m.cantidadTotal}'),
                      Text(
                        '${m.cantidadDanada}',
                        style: TextStyle(
                          color: m.cantidadDanada > 0 ? Colors.red : null,
                        ),
                      ),
                      Text(m.deporteNombre ?? '—'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 20),
                            tooltip: 'Transferir',
                            onPressed: () => _transferir(m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: adminAccent),
                            tooltip: 'Eliminar',
                            onPressed: () => UtileroEliminarMaterialDialog.confirmar(
                              context,
                              material: m,
                              usuarioId: widget.adminId,
                            ),
                          ),
                        ],
                      ),
                    ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Solicitudes de compra (utileros)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<SolicitudCompraUtilero>>(
          stream: AdminService.streamTodasSolicitudes(),
          builder: (context, snap) {
            final sols = snap.data ?? [];
            return Card(
              child: AdminDataTable(
                columnas: const ['Material', 'Cant.', 'Motivo', 'Estado', 'Acciones'],
                vacio: 'Sin solicitudes',
                filas: [
                  for (final s in sols.take(30))
                    [
                      Text(s.materialNombre),
                      Text('${s.cantidad}'),
                      Text(s.motivo, style: const TextStyle(fontSize: 12)),
                      Text(s.estado),
                      if (s.pendiente)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _responderSolicitud(s, true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _responderSolicitud(s, false),
                            ),
                          ],
                        )
                      else
                        const Text('—'),
                    ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
