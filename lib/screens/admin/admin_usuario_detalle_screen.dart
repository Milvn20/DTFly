import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/admin_usuario.dart';
import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/observacion_jugador.dart';
import 'package:flutter_application_1/models/prestamo_material.dart';
import 'package:flutter_application_1/models/utilero_perfil.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/observacion_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

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
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _carrera = TextEditingController();
  String? _deporteId;
  bool _editando = false;
  bool _guardando = false;
  bool _synced = false;
  String? _syncedId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nombre.dispose();
    _telefono.dispose();
    _carrera.dispose();
    super.dispose();
  }

  void _sync(AdminUsuario u) {
    _nombre.text = u.nombre;
    _telefono.text = u.telefono ?? '';
    _carrera.text = u.carrera ?? '';
    _deporteId = u.deporteId;
    _synced = true;
  }

  Future<void> _guardar(AdminUsuario u) async {
    setState(() => _guardando = true);
    try {
      await AdminService.actualizarUsuario(
        usuarioId: u.id,
        nombre: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        carrera: _carrera.text.trim(),
        deporteId: _deporteId,
        adminId: widget.adminId,
        adminEmail: widget.adminEmail,
      );
      if (mounted) {
        setState(() {
          _editando = false;
          _guardando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editarRol(AdminUsuario u) async {
    const roles = [
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
              child: Row(
                children: [
                  AdminRolChip(rol: r),
                  if (u.rolNormalizado == r) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 18, color: Colors.green),
                  ],
                ],
              ),
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
  }

  Future<void> _bloquear(AdminUsuario u) async {
    await AdminService.bloquearUsuario(
      usuarioId: u.id,
      bloquear: u.activo,
      adminId: widget.adminId,
      adminEmail: widget.adminEmail,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(u.activo ? 'Usuario bloqueado' : 'Usuario activado')),
      );
    }
  }

  Future<void> _eliminar(AdminUsuario u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar a ${u.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: adminAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AdminService.eliminarUsuario(
      usuarioId: u.id,
      adminId: widget.adminId,
      adminEmail: widget.adminEmail,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminUsuario?>(
      stream: AdminService.streamUsuario(widget.usuarioId),
      builder: (context, snap) {
        final u = snap.data;
        if (u != null && !_editando && (_syncedId != u.id || !_synced)) {
          _sync(u);
          _syncedId = u.id;
        }

        return Scaffold(
          backgroundColor: DtflyTheme.background,
          appBar: AppBar(
            title: Text(u?.nombre ?? 'Usuario'),
            backgroundColor: DtflyTheme.secondary,
            foregroundColor: Colors.white,
            actions: [
              if (u != null && _editando) ...[
                TextButton(
                  onPressed: _guardando ? null : () => setState(() => _editando = false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: _guardando ? null : () => _guardar(u),
                  child: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ] else if (u != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar perfil',
                  onPressed: () => setState(() => _editando = true),
                ),
            ],
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
          ),
          body: u == null
              ? const Center(
                  child: CircularProgressIndicator(color: DtflyTheme.coachRed),
                )
              : Column(
                  children: [
                    _HeroUsuario(
                      usuario: u,
                      onCambiarRol: () => _editarRol(u),
                      onBloquear: () => _bloquear(u),
                      onEliminar: () => _eliminar(u),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _PerfilTab(
                            usuario: u,
                            editando: _editando,
                            nombre: _nombre,
                            telefono: _telefono,
                            carrera: _carrera,
                            deporteId: _deporteId,
                            onDeporteChanged: (v) => setState(() => _deporteId = v),
                          ),
                          _AsistenciasTab(usuarioId: u.id, rol: u.rolNormalizado),
                          _ObservacionesTab(usuarioId: u.id, rol: u.rolNormalizado),
                          _PrestamosTab(usuario: u),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _HeroUsuario extends StatelessWidget {
  const _HeroUsuario({
    required this.usuario,
    required this.onCambiarRol,
    required this.onBloquear,
    required this.onEliminar,
  });

  final AdminUsuario usuario;
  final VoidCallback onCambiarRol;
  final VoidCallback onBloquear;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: DtflyTheme.headerGradient,
        boxShadow: DtflyTheme.cardShadow,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Text(
                    usuario.iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          AdminRolChip(rol: usuario.rol),
                          _EstadoChip(activo: usuario.activo),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _AccionChip(
                    icon: Icons.swap_horiz,
                    label: 'Cambiar rol',
                    onTap: onCambiarRol,
                  ),
                  const SizedBox(width: 8),
                  _AccionChip(
                    icon: usuario.activo ? Icons.block : Icons.check_circle_outline,
                    label: usuario.activo ? 'Bloquear' : 'Activar',
                    onTap: onBloquear,
                  ),
                  const SizedBox(width: 8),
                  _AccionChip(
                    icon: Icons.delete_outline,
                    label: 'Eliminar',
                    onTap: onEliminar,
                    peligro: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (activo ? Colors.green : Colors.red).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activo ? 'Activo' : 'Bloqueado',
        style: TextStyle(
          color: activo ? Colors.green.shade100 : Colors.red.shade100,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AccionChip extends StatelessWidget {
  const _AccionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.peligro = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: peligro ? Colors.red.shade200 : Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: peligro ? Colors.red.withValues(alpha: 0.25) : Colors.white24,
      side: BorderSide.none,
      onPressed: onTap,
    );
  }
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab({
    required this.usuario,
    required this.editando,
    required this.nombre,
    required this.telefono,
    required this.carrera,
    required this.deporteId,
    required this.onDeporteChanged,
  });

  final AdminUsuario usuario;
  final bool editando;
  final TextEditingController nombre;
  final TextEditingController telefono;
  final TextEditingController carrera;
  final String? deporteId;
  final ValueChanged<String?> onDeporteChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SeccionCard(
          titulo: 'Información general',
          children: [
            if (editando) ...[
              TextField(
                controller: nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefono,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carrera,
                decoration: const InputDecoration(
                  labelText: 'Carrera / área',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: deporteId,
                decoration: const InputDecoration(
                  labelText: 'Deporte',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin deporte')),
                  ...DeportesCategoria.todas.map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)),
                  ),
                ],
                onChanged: onDeporteChanged,
              ),
            ] else ...[
              _InfoRow(icon: Icons.person_outline, label: 'Nombre', valor: usuario.nombre),
              _InfoRow(icon: Icons.email_outlined, label: 'Email', valor: usuario.email),
              _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', valor: usuario.telefono ?? '—'),
              _InfoRow(icon: Icons.sports_outlined, label: 'Deporte', valor: usuario.deporteNombre ?? '—'),
              _InfoRow(icon: Icons.school_outlined, label: 'Carrera', valor: usuario.carrera ?? '—'),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Registro',
                valor: adminFmtFecha(usuario.fechaCreacion),
              ),
            ],
          ],
        ),
        if (usuario.rolNormalizado == AppRoles.jugador) ...[
          const SizedBox(height: 16),
          _SeccionCard(
            titulo: 'Ficha deportiva',
            children: [
              _InfoRow(icon: Icons.cake_outlined, label: 'Edad', valor: usuario.edad?.toString() ?? '—'),
              _InfoRow(
                icon: Icons.sports_soccer,
                label: 'Posición',
                valor: usuario.posicionDeportiva ?? '—',
              ),
              _InfoRow(icon: Icons.card_membership, label: 'Beca', valor: usuario.tipoBeca ?? '—'),
            ],
          ),
        ],
        if (usuario.rolNormalizado == AppRoles.utilero) ...[
          const SizedBox(height: 16),
          StreamBuilder<UtileroPerfil>(
            stream: UtileroService.streamPerfil(usuario.id),
            builder: (context, snap) {
              final p = snap.data;
              if (p == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _SeccionCard(
                titulo: 'Perfil utilero',
                children: [
                  if (p.fotoPerfil != null)
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(p.fotoPerfil!),
                      ),
                    ),
                  if (p.fotoPerfil != null) const SizedBox(height: 12),
                  _InfoRow(icon: Icons.work_outline, label: 'Turno', valor: p.turno ?? '—'),
                  _InfoRow(icon: Icons.schedule, label: 'Horario', valor: _horario(p)),
                  _InfoRow(icon: Icons.warehouse_outlined, label: 'Bodega', valor: p.bodegaPrincipal ?? '—'),
                  _InfoRow(icon: Icons.business_outlined, label: 'Institución', valor: p.institucion ?? '—'),
                  const SizedBox(height: 8),
                  const Text('Actividad reciente', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: UtileroService.streamActividad(usuario.id, limite: 8),
                    builder: (context, actSnap) {
                      final acts = actSnap.data ?? [];
                      if (acts.isEmpty) {
                        return const Text('Sin actividad registrada', style: TextStyle(color: Colors.grey));
                      }
                      return Column(
                        children: [
                          for (final a in acts)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history, size: 18, color: adminAccent),
                              title: Text(a.accion, style: const TextStyle(fontSize: 13)),
                              subtitle: Text(a.descripcion, style: const TextStyle(fontSize: 11)),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
        if (usuario.rolNormalizado == AppRoles.entrenador) ...[
          const SizedBox(height: 16),
          _SeccionCard(
            titulo: 'Entrenador (DT)',
            children: [
              _InfoRow(
                icon: Icons.sports,
                label: 'Disciplina',
                valor: usuario.deporteNombre ?? 'Sin categoría asignada',
              ),
              _InfoRow(icon: Icons.email_outlined, label: 'Correo DT', valor: usuario.email),
            ],
          ),
        ],
      ],
    );
  }

  String _horario(UtileroPerfil p) {
    if (p.horarioInicio == null && p.horarioFin == null) return '—';
    return '${p.horarioInicio ?? '?'} – ${p.horarioFin ?? '?'}';
  }
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({required this.titulo, required this.children});
  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.valor,
  });

  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DtflyTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: DtflyTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _AsistenciasTab extends StatelessWidget {
  const _AsistenciasTab({required this.usuarioId, required this.rol});
  final String usuarioId;
  final String rol;

  @override
  Widget build(BuildContext context) {
    if (rol != AppRoles.jugador) {
      return _EmptyRolMensaje(
        icon: Icons.event_available,
        mensaje: 'Las asistencias aplican principalmente a jugadores.',
      );
    }
    return FutureBuilder<List<AsistenciaRegistro>>(
      future: AdminService.asistenciasDeJugador(usuarioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DtflyTheme.coachRed));
        }
        final lista = snap.data ?? [];
        if (lista.isEmpty) {
          return const _EmptyRolMensaje(
            icon: Icons.event_busy,
            mensaje: 'Sin asistencias registradas.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final a = lista[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: adminAccent.withValues(alpha: 0.1),
                  child: Icon(Icons.check, color: adminAccent, size: 20),
                ),
                title: Text(a.entrenamientoTitulo ?? 'Entrenamiento'),
                subtitle: Text('${a.estado} · ${adminFmtFecha(a.unidoEn)}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _ObservacionesTab extends StatelessWidget {
  const _ObservacionesTab({required this.usuarioId, required this.rol});
  final String usuarioId;
  final String rol;

  @override
  Widget build(BuildContext context) {
    if (rol != AppRoles.jugador) {
      return _EmptyRolMensaje(
        icon: Icons.rate_review_outlined,
        mensaje: 'Las observaciones del DT están vinculadas a jugadores.',
      );
    }
    return StreamBuilder<List<ObservacionJugador>>(
      stream: ObservacionService.streamPorJugador(usuarioId),
      builder: (context, snap) {
        final obs = snap.data ?? [];
        if (obs.isEmpty) {
          return const _EmptyRolMensaje(
            icon: Icons.notes_outlined,
            mensaje: 'Sin observaciones del entrenador.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: obs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final o = obs[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(o.tipo, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Text(o.rendimiento, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const Spacer(),
                        Text(adminFmtFecha(o.creadoEn), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(o.texto),
                  ],
                ),
              ),
            );
          },
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
        final email = usuario.email.toLowerCase();
        final nombre = usuario.nombre.toLowerCase();
        final relacionados = todos.where((p) {
          return p.entrenadorEmail.toLowerCase() == email ||
              p.prestadoA.toLowerCase().contains(nombre);
        }).toList();

        if (relacionados.isEmpty) {
          return _EmptyRolMensaje(
            icon: Icons.handshake_outlined,
            mensaje: usuario.rolNormalizado == AppRoles.utilero
                ? 'Sin préstamos gestionados por este utilero.'
                : 'Sin préstamos relacionados con este usuario.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: relacionados.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = relacionados[i];
            final activo = !p.devuelto;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (activo ? Colors.orange : Colors.green).withValues(alpha: 0.15),
                  child: Icon(
                    activo ? Icons.schedule : Icons.check,
                    color: activo ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                ),
                title: Text(p.materialNombre),
                subtitle: Text(
                  '${p.cantidad} u. · ${p.prestadoA}\n${adminFmtFecha(p.prestadoEn)}',
                ),
                isThreeLine: true,
                trailing: Text(
                  activo ? 'Activo' : 'Devuelto',
                  style: TextStyle(
                    color: activo ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyRolMensaje extends StatelessWidget {
  const _EmptyRolMensaje({required this.icon, required this.mensaje});
  final IconData icon;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DtflyTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
