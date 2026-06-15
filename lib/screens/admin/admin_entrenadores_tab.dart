import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/models/admin_usuario.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/screens/admin/admin_usuario_detalle_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';

class AdminEntrenadoresTab extends StatelessWidget {
  const AdminEntrenadoresTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
  });

  final String adminId;
  final String adminEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeader(
          titulo: 'Control de entrenadores',
          subtitulo: 'Planificación, sesiones y asistencia',
        ),
        StreamBuilder<List<AdminUsuario>>(
          stream: AdminService.streamUsuarios(),
          builder: (context, snap) {
            final dts = (snap.data ?? [])
                .where((u) => u.rolNormalizado == AppRoles.entrenador)
                .toList();
            return Card(
              child: AdminDataTable(
                columnas: const ['Nombre', 'Email', 'Deporte', 'Estado', 'Ver'],
                filas: [
                  for (final u in dts)
                    [
                      Text(u.nombre),
                      Text(u.email, style: const TextStyle(fontSize: 12)),
                      Text(u.deporteNombre ?? '—'),
                      Icon(u.activo ? Icons.check_circle : Icons.block, color: u.activo ? Colors.green : Colors.red, size: 18),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminUsuarioDetalleScreen(
                              usuarioId: u.id,
                              adminId: adminId,
                              adminEmail: adminEmail,
                            ),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Entrenamientos recientes', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<Entrenamiento>>(
          stream: AdminService.streamEntrenamientos(limit: 40),
          builder: (context, snap) {
            final ents = snap.data ?? [];
            return Card(
              child: AdminDataTable(
                columnas: const ['Título', 'Cancha', 'Estado', 'DT', 'Inicio'],
                filas: [
                  for (final e in ents)
                    [
                      Text(e.titulo),
                      Text(e.cancha),
                      Text(e.estado),
                      Text(e.entrenadorEmail, style: const TextStyle(fontSize: 11)),
                      Text(adminFmtFecha(e.inicioProgramado), style: const TextStyle(fontSize: 12)),
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
