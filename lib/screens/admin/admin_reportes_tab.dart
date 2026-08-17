import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/inventario_service.dart';

class AdminReportesTab extends StatefulWidget {
  const AdminReportesTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
  });

  final String adminId;
  final String adminEmail;

  @override
  State<AdminReportesTab> createState() => _AdminReportesTabState();
}

class _AdminReportesTabState extends State<AdminReportesTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          titulo: 'Reportes e informes',
          subtitulo: 'Descarga y consulta de reportes del sistema',
          acciones: [
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'usuarios') {
                  final users = await AdminService.streamUsuarios().first;
                  await AdminService.exportarUsuariosCsv(users);
                } else if (v == 'inventario') {
                  final mats = await InventarioService.streamMateriales().first;
                  await AdminService.exportarInventarioCsv(mats);
                } else if (v == 'prestamos') {
                  final p = await AdminService.streamTodosPrestamos().first;
                  await AdminService.exportarPrestamosCsv(p);
                }
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Descarga iniciada')),
                  );
                
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'usuarios', child: Text('Exportar usuarios (CSV)')),
                PopupMenuItem(value: 'inventario', child: Text('Exportar inventario (CSV)')),
                PopupMenuItem(value: 'prestamos', child: Text('Exportar préstamos (CSV)')),
              ],
              child: const Chip(
                avatar: Icon(Icons.download, size: 18),
                label: Text('Exportar datos'),
              ),
            ),
          ],
        ),
        const Text(
          'Reportes de entrenadores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<AdminReporteItem>>(
          stream: AdminService.streamReportes(),
          builder: (context, snap) {
            final reps = snap.data ?? [];
            return Card(
              child: AdminDataTable(
                columnas: const ['Título', 'Entrenador', 'Deporte', 'Fecha', 'Descargar'],
                vacio: 'Sin reportes registrados',
                filas: [
                  for (final r in reps)
                    [
                      Text(r.titulo),
                      Text(r.email, style: const TextStyle(fontSize: 12)),
                      Text(r.deporte ?? '—'),
                      Text(adminFmtFecha(r.creadoEn), style: const TextStyle(fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => AdminService.descargarReporte(r),
                      ),
                    ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Historial de préstamos recientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder(
          stream: AdminService.streamTodosPrestamos(limit: 50),
          builder: (context, snap) {
            final prest = snap.data ?? [];
            return Card(
              child: AdminDataTable(
                columnas: const ['Material', 'Cant.', 'Entregado a', 'Fecha', 'Estado'],
                filas: [
                  for (final p in prest)
                    [
                      Text(p.materialNombre),
                      Text('${p.cantidad}'),
                      Text(p.prestadoA),
                      Text(adminFmtFecha(p.prestadoEn), style: const TextStyle(fontSize: 12)),
                      Text(p.devuelto ? 'Devuelto' : 'Activo'),
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
