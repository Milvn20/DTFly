import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/models/admin_usuario.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/screens/admin/admin_usuario_detalle_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';

class AdminJugadoresTab extends StatelessWidget {
  const AdminJugadoresTab({
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
          titulo: 'Control de jugadores',
          subtitulo: 'Fichas, asistencia y participación',
        ),
        StreamBuilder<List<AdminUsuario>>(
          stream: AdminService.streamUsuarios(),
          builder: (context, snap) {
            final jugadores = (snap.data ?? [])
                .where((u) => u.rolNormalizado == AppRoles.jugador)
                .toList();
            return Card(
              child: AdminDataTable(
                columnas: const ['Nombre', 'Email', 'Deporte', 'Carrera', 'Ver ficha'],
                filas: [
                  for (final u in jugadores)
                    [
                      Text(u.nombre),
                      Text(u.email, style: const TextStyle(fontSize: 12)),
                      Text(u.deporteNombre ?? '—'),
                      Text(u.carrera ?? '—', style: const TextStyle(fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.person_search),
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
        const Text('Partidos recientes', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<Partido>>(
          stream: AdminService.streamPartidos(limit: 30),
          builder: (context, snap) {
            final parts = snap.data ?? [];
            return Card(
              child: AdminDataTable(
                columnas: const ['Rival', 'Lugar', 'Estado', 'DT', 'Fecha'],
                filas: [
                  for (final p in parts)
                    [
                      Text(p.rival),
                      Text(p.lugar),
                      Text(p.estado),
                      Text(p.entrenadorEmail, style: const TextStyle(fontSize: 11)),
                      Text(adminFmtFecha(p.fechaHora), style: const TextStyle(fontSize: 12)),
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
