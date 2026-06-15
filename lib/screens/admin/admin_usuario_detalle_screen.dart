import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/admin_usuario.dart';
import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/observacion_jugador.dart';
import 'package:flutter_application_1/models/prestamo_material.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/observacion_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';

class AdminUsuarioDetalleScreen extends StatefulWidget {
  const AdminUsuarioDetalleScreen({
    super.key,
    required this.usuarioId,
    required this.adminId,
    required this.adminEmail,
  });

  final String usuarioId;
  final String adminId;
  final String adminEmail;

  @override
  State<AdminUsuarioDetalleScreen> createState() =>
      _AdminUsuarioDetalleScreenState();
}

class _AdminUsuarioDetalleScreenState extends State<AdminUsuarioDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AdminUsuario? _usuario;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final u = await AdminService.obtenerUsuario(widget.usuarioId);
    if (mounted) setState(() => _usuario = u);
  }

  Future<void> _editarRol() async {
    final u = _usuario;
    if (u == null) return;
    final roles = [
      AppRoles.jugador,
      AppRoles.entrenador,
      AppRoles.utilero,
      AppRoles.administrador,
    ];
    final elegido = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cambiar rol'),
        children: [
          for (final r in roles)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text(r),
            ),
        ],
      ),
    );
    if (elegido == null) return;
    await AdminService.actualizarUsuario(
      usuarioId: u.id,
      rol: elegido,
      adminId: widget.adminId,
      adminEmail: widget.adminEmail,
    );
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuario;
    return Scaffold(
      appBar: AppBar(
        title: Text(u?.nombre ?? 'Usuario'),
        backgroundColor: adminSidebarColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Perfil'),
            Tab(text: 'Asistencias'),
            Tab(text: 'Observaciones'),
            Tab(text: 'Préstamos'),
          ],
        ),
        actions: [
          if (u != null)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'rol') await _editarRol();
                if (v == 'bloquear') {
                  await AdminService.bloquearUsuario(
                    usuarioId: u.id,
                    bloquear: u.activo,
                    adminId: widget.adminId,
                    adminEmail: widget.adminEmail,
                  );
                  await _cargar();
                }
                if (v == 'eliminar') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar usuario'),
                      content: Text('¿Eliminar a ${u.nombre}? No se puede deshacer.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: adminAccent),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await AdminService.eliminarUsuario(
                      usuarioId: u.id,
                      adminId: widget.adminId,
                      adminEmail: widget.adminEmail,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'rol', child: Text('Cambiar rol')),
                PopupMenuItem(
                  value: 'bloquear',
                  child: Text(u.activo ? 'Bloquear' : 'Activar'),
                ),
                const PopupMenuItem(value: 'eliminar', child: Text('Eliminar usuario')),
              ],
            ),
        ],
      ),
      body: u == null
          ? const Center(child: CircularProgressIndicator(color: adminAccent))
          : TabBarView(
              controller: _tabs,
              children: [
                _PerfilTab(usuario: u),
                _AsistenciasTab(usuarioId: u.id),
                _ObservacionesTab(usuarioId: u.id),
                _PrestamosTab(usuario: u),
              ],
            ),
    );
  }
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab({required this.usuario});
  final AdminUsuario usuario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AdminRolChip(rol: usuario.rol),
        const SizedBox(height: 16),
        _Campo('Nombre', usuario.nombre),
        _Campo('Email', usuario.email),
        _Campo('Deporte', usuario.deporteNombre ?? '—'),
        _Campo('Teléfono', usuario.telefono ?? '—'),
        _Campo('Carrera', usuario.carrera ?? '—'),
        _Campo('Estado', usuario.activo ? 'Activo' : 'Bloqueado'),
        _Campo('Registro', adminFmtFecha(usuario.fechaCreacion)),
        if (usuario.rolNormalizado == AppRoles.utilero) ...[
          const SizedBox(height: 24),
          const Text('Actividad utilero reciente', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: UtileroService.streamActividad(usuario.id, limite: 15),
            builder: (context, snap) {
              final acts = snap.data ?? [];
              if (acts.isEmpty) return const Text('Sin actividad');
              return Column(
                children: [
                  for (final a in acts)
                    ListTile(
                      dense: true,
                      title: Text(a.accion),
                      subtitle: Text(a.descripcion),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _AsistenciasTab extends StatelessWidget {
  const _AsistenciasTab({required this.usuarioId});
  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AsistenciaRegistro>>(
      future: AdminService.asistenciasDeJugador(usuarioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: adminAccent));
        }
        final lista = snap.data ?? [];
        return AdminDataTable(
          columnas: const ['Estado', 'Entrenamiento', 'Fecha'],
          vacio: 'Sin asistencias registradas',
          filas: [
            for (final a in lista)
              [
                Text(a.estado),
                Text(a.entrenamientoTitulo ?? '—'),
                Text(adminFmtFecha(a.unidoEn), style: const TextStyle(fontSize: 12)),
              ],
          ],
        );
      },
    );
  }
}

class _ObservacionesTab extends StatelessWidget {
  const _ObservacionesTab({required this.usuarioId});
  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ObservacionJugador>>(
      stream: ObservacionService.streamPorJugador(usuarioId),
      builder: (context, snap) {
        final obs = snap.data ?? [];
        return AdminDataTable(
          columnas: const ['Tipo', 'Rendimiento', 'Texto', 'Fecha'],
          vacio: 'Sin observaciones',
          filas: [
            for (final o in obs)
              [
                Text(o.tipo),
                Text(o.rendimiento),
                Text(o.texto, style: const TextStyle(fontSize: 12)),
                Text(adminFmtFecha(o.creadoEn), style: const TextStyle(fontSize: 12)),
              ],
          ],
        );
      },
    );
  }
}

class _PrestamosTab extends StatelessWidget {
  const _PrestamosTab({required this.usuario});
  final AdminUsuario usuario;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PrestamoMaterial>>(
      stream: AdminService.streamTodosPrestamos(),
      builder: (context, snap) {
        final todos = snap.data ?? [];
        final relacionados = todos.where((p) {
          final n = usuario.nombre.toLowerCase();
          return p.prestadoA.toLowerCase().contains(n) ||
              p.entrenadorEmail.toLowerCase() == usuario.email.toLowerCase();
        }).toList();

        return AdminDataTable(
          columnas: const ['Material', 'Cant.', 'Entregado a', 'Fecha', 'Estado'],
          vacio: 'Sin préstamos relacionados',
          filas: [
            for (final p in relacionados)
              [
                Text(p.materialNombre),
                Text('${p.cantidad}'),
                Text(p.prestadoA),
                Text(adminFmtFecha(p.prestadoEn), style: const TextStyle(fontSize: 12)),
                Text(p.devuelto ? 'Devuelto' : 'Activo'),
              ],
          ],
        );
      },
    );
  }
}
