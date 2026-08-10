import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/models/admin_perfil.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Perfil del administrador logueado: datos, foto, contraseña y actividad.
class AdminPerfilScreen extends StatefulWidget {
  const AdminPerfilScreen({
    super.key,
    required this.adminId,
    required this.adminEmail,
    required this.adminNombre,
  });

  final String adminId;
  final String adminEmail;
  final String adminNombre;

  @override
  State<AdminPerfilScreen> createState() => _AdminPerfilScreenState();
}

class _AdminPerfilScreenState extends State<AdminPerfilScreen> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _cargo = TextEditingController();
  final _institucion = TextEditingController();
  bool _editando = false;
  bool _guardando = false;
  bool _sincronizado = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _cargo.dispose();
    _institucion.dispose();
    super.dispose();
  }

  void _sync(AdminPerfil p) {
    _nombre.text = p.nombre;
    _apellido.text = p.apellido;
    _telefono.text = p.telefono;
    _cargo.text = p.cargo;
    _institucion.text = p.institucion ?? '';
    _sincronizado = true;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await AdminService.guardarPerfilAdmin(
        adminId: widget.adminId,
        adminEmail: widget.adminEmail,
        nombre: _nombre.text,
        apellido: _apellido.text,
        telefono: _telefono.text,
        cargo: _cargo.text,
        institucion: _institucion.text,
      );
      if (!mounted) return;
      setState(() {
        _editando = false;
        _guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      await AdminService.subirFotoPerfilAdmin(
        adminId: widget.adminId,
        adminEmail: widget.adminEmail,
        bytes: bytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la foto: $e')),
        );
      }
    }
  }

  Future<void> _cambiarContrasena() async {
    final actual = TextEditingController();
    final nueva = TextEditingController();
    final confirmar = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actual,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nueva,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmar,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (nueva.text != confirmar.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
      }
      return;
    }
    try {
      await AdminService.cambiarContrasenaAdmin(
        adminId: widget.adminId,
        adminEmail: widget.adminEmail,
        actual: actual.text,
        nueva: nueva.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      actual.dispose();
      nueva.dispose();
      confirmar.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => setState(() => _editando = true),
            )
          else ...[
            TextButton(
              onPressed: _guardando ? null : () => setState(() => _editando = false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: StreamBuilder<AdminPerfil>(
        stream: AdminService.streamPerfilAdmin(widget.adminId),
        builder: (context, snap) {
          final perfil = snap.data;
          if (perfil != null && !_sincronizado) {
            _sync(perfil);
          }
          if (snap.connectionState == ConnectionState.waiting && perfil == null) {
            return const Center(
              child: CircularProgressIndicator(color: DtflyTheme.coachRed),
            );
          }
          final p = perfil;
          if (p == null) {
            return const Center(child: Text('No se pudo cargar el perfil'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeroPerfil(
                perfil: p,
                onCambiarFoto: _cambiarFoto,
              ),
              const SizedBox(height: 20),
              _SeccionTitulo('Datos personales'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _campo(
                        label: 'Nombre',
                        controller: _nombre,
                        enabled: _editando,
                      ),
                      const SizedBox(height: 12),
                      _campo(
                        label: 'Apellido',
                        controller: _apellido,
                        enabled: _editando,
                      ),
                      const SizedBox(height: 12),
                      _campo(
                        label: 'Teléfono',
                        controller: _telefono,
                        enabled: _editando,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _campo(
                        label: 'Cargo',
                        controller: _cargo,
                        enabled: _editando,
                      ),
                      const SizedBox(height: 12),
                      _campo(
                        label: 'Institución',
                        controller: _institucion,
                        enabled: _editando,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SeccionTitulo('Cuenta'),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Correo'),
                      subtitle: Text(p.correo),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Rol'),
                      subtitle: Text(AppRoles.administrador),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Registro'),
                      subtitle: Text(adminFmtFecha(p.fechaIngreso)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.login_outlined),
                      title: const Text('Último acceso'),
                      subtitle: Text(adminFmtFecha(p.ultimoAcceso)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Contraseña'),
                      subtitle: const Text('••••••••'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _cambiarContrasena,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SeccionTitulo('Preferencias'),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notificaciones por correo'),
                      value: p.notifEmail,
                      activeThumbColor: DtflyTheme.coachRed,
                      onChanged: (v) => AdminService.guardarPreferenciasAdmin(
                        adminId: widget.adminId,
                        adminEmail: widget.adminEmail,
                        notifEmail: v,
                        notifSistema: p.notifSistema,
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Notificaciones en el sistema'),
                      value: p.notifSistema,
                      activeThumbColor: DtflyTheme.coachRed,
                      onChanged: (v) => AdminService.guardarPreferenciasAdmin(
                        adminId: widget.adminId,
                        adminEmail: widget.adminEmail,
                        notifEmail: p.notifEmail,
                        notifSistema: v,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SeccionTitulo('Mi actividad reciente'),
              const SizedBox(height: 8),
              Card(
                child: StreamBuilder(
                  stream: AdminService.streamAuditoriaAdmin(
                    adminId: widget.adminId,
                    limit: 12,
                  ),
                  builder: (context, auditSnap) {
                    final acts = auditSnap.data ?? [];
                    if (acts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Sin acciones registradas aún.',
                          style: TextStyle(color: DtflyTheme.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final a in acts) ...[
                          ListTile(
                            dense: true,
                            leading: Icon(Icons.history, color: adminAccent, size: 20),
                            title: Text(a.accion, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${a.detalle}\n${adminFmtFecha(a.creadoEn)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                          ),
                          if (a != acts.last) const Divider(height: 1, indent: 56),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboard = TextInputType.text,
  }) {
    if (!enabled) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: DtflyTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(controller.text.isEmpty ? '—' : controller.text,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _HeroPerfil extends StatelessWidget {
  const _HeroPerfil({
    required this.perfil,
    required this.onCambiarFoto,
  });

  final AdminPerfil perfil;
  final VoidCallback onCambiarFoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DtflyTheme.headerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DtflyTheme.cardShadow,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCambiarFoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      perfil.fotoPerfil != null ? NetworkImage(perfil.fotoPerfil!) : null,
                  child: perfil.fotoPerfil == null
                      ? Text(
                          perfil.nombreCompleto.isNotEmpty
                              ? perfil.nombreCompleto[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: DtflyTheme.coachRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil.nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  perfil.cargo,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 8),
                const AdminRolChip(rol: AppRoles.administrador),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
