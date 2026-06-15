import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/admin_auditoria.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';

class AdminAuditoriaTab extends StatelessWidget {
  const AdminAuditoriaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeader(
          titulo: 'Registro de auditoría',
          subtitulo: 'Quién creó, editó o eliminó en el sistema',
        ),
        StreamBuilder<List<AdminAuditoriaRegistro>>(
          stream: AdminService.streamAuditoria(),
          builder: (context, snap) {
            final logs = snap.data ?? [];
            return Card(
              child: AdminDataTable(
                columnas: const ['Fecha', 'Admin', 'Acción', 'Detalle', 'Entidad'],
                vacio: 'Sin registros de auditoría aún',
                filas: [
                  for (final l in logs)
                    [
                      Text(adminFmtFecha(l.creadoEn), style: const TextStyle(fontSize: 12)),
                      Text(l.adminEmail, style: const TextStyle(fontSize: 12)),
                      Text(l.accion, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(l.detalle, style: const TextStyle(fontSize: 12)),
                      Text(
                        l.entidadTipo != null ? '${l.entidadTipo}: ${l.entidadId ?? ''}' : '—',
                        style: const TextStyle(fontSize: 11),
                      ),
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
