import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/admin_usuario.dart';
import 'package:flutter_application_1/screens/admin/admin_usuario_detalle_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';

class AdminUsuariosTab extends StatefulWidget {
  const AdminUsuariosTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
  });

  final String adminId;
  final String adminEmail;

  @override
  State<AdminUsuariosTab> createState() => _AdminUsuariosTabState();
}

class _AdminUsuariosTabState extends State<AdminUsuariosTab> {
  final _buscar = TextEditingController();
  String? _rolFiltro;
  String? _deporteFiltro;
  bool? _soloActivos;

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _exportar(List<AdminUsuario> lista) async {
    await AdminService.exportarUsuariosCsv(lista);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista de usuarios descargada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          titulo: 'Gestión de usuarios',
          subtitulo: 'Todos los roles: jugadores, DT, utileros y administradores',
        ),
        AdminFilterBar(
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _buscar,
                decoration: const InputDecoration(
                  hintText: 'Buscar nombre, email...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            DropdownButton<String?>(
              value: _rolFiltro,
              hint: const Text('Rol'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los roles')),
                ...[
                  AppRoles.jugador,
                  AppRoles.entrenador,
                  AppRoles.utilero,
                  AppRoles.administrador,
                ].map(
                  (r) => DropdownMenuItem(value: r, child: Text(r)),
                ),
              ],
              onChanged: (v) => setState(() => _rolFiltro = v),
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
            DropdownButton<bool?>(
              value: _soloActivos,
              hint: const Text('Estado'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: true, child: Text('Activos')),
                DropdownMenuItem(value: false, child: Text('Bloqueados')),
              ],
              onChanged: (v) => setState(() => _soloActivos = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<AdminUsuario>>(
          stream: AdminService.streamUsuarios(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: adminAccent));
            }
            final todos = snap.data ?? [];
            final filtrados = AdminService.filtrarUsuarios(
              todos,
              query: _buscar.text,
              rol: _rolFiltro,
              deporteId: _deporteFiltro,
              soloActivos: _soloActivos,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('${filtrados.length} usuario(s)'),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _exportar(filtrados),
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: AdminDataTable(
                    columnas: const [
                      'Nombre',
                      'Email',
                      'Rol',
                      'Deporte',
                      'Estado',
                      'Acciones',
                    ],
                    filas: [
                      for (final u in filtrados)
                        [
                          Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(u.email, style: const TextStyle(fontSize: 12)),
                          AdminRolChip(rol: u.rol),
                          Text(u.deporteNombre ?? '—'),
                          Icon(
                            u.activo ? Icons.check_circle : Icons.block,
                            color: u.activo ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                tooltip: 'Ver perfil',
                                onPressed: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUsuarioDetalleScreen(
                                        usuarioId: u.id,
                                        adminId: widget.adminId,
                                        adminEmail: widget.adminEmail,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  u.activo ? Icons.block : Icons.check,
                                  size: 20,
                                  color: u.activo ? Colors.orange : Colors.green,
                                ),
                                tooltip: u.activo ? 'Bloquear' : 'Activar',
                                onPressed: () async {
                                  await AdminService.bloquearUsuario(
                                    usuarioId: u.id,
                                    bloquear: u.activo,
                                    adminId: widget.adminId,
                                    adminEmail: widget.adminEmail,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
