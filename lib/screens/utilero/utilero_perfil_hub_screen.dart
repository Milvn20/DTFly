import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/actividad_utilero.dart';
import 'package:flutter_application_1/models/notificacion_utilero.dart';
import 'package:flutter_application_1/models/utilero_perfil.dart';
import 'package:flutter_application_1/screens/inventario/inventario_screen.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_widgets.dart';

/// Módulo de pantallas del perfil del utilero (PDF DTFly).
/// Cada panel se usa en [UtileroSeccionScreen] o en la pestaña Perfil.
class UtileroPerfilPanel extends StatefulWidget {
  const UtileroPerfilPanel({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombreInicial,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombreInicial;

  @override
  State<UtileroPerfilPanel> createState() => _UtileroPerfilPanelState();
}

class _UtileroPerfilPanelState extends State<UtileroPerfilPanel> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  bool _editando = false;
  bool _guardando = false;
  bool _guardandoDeporte = false;
  String? _deporteId;
  bool _perfilSincronizado = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _telefono.dispose();
    super.dispose();
  }

  void _syncFromPerfil(UtileroPerfil p) {
    _nombre.text = p.nombre.isNotEmpty ? p.nombre : widget.nombreInicial.split(' ').first;
    _apellido.text = p.apellido;
    _correo.text = p.correo.isNotEmpty ? p.correo : widget.usuarioEmail;
    _telefono.text = p.telefono;
    _deporteId = p.deporteId;
    _perfilSincronizado = true;
  }

  Future<void> _guardarDeporte(String? deporteId) async {
    if (deporteId == null || deporteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una disciplina deportiva')),
      );
      return;
    }
    setState(() => _guardandoDeporte = true);
    try {
      await UtileroService.guardarDeporteSeleccion(
        usuarioId: widget.usuarioId,
        deporteId: deporteId,
      );
      if (mounted) {
        setState(() => _deporteId = deporteId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selección guardada: ${DeportesCategoria.nombreVisible(deporteId)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardandoDeporte = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await UtileroService.guardarPerfil(
        usuarioId: widget.usuarioId,
        nombre: _nombre.text,
        apellido: _apellido.text,
        correo: _correo.text,
        telefono: _telefono.text,
        deporteId: _deporteId,
      );
      if (mounted) {
        setState(() => _editando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    try {
      await UtileroService.subirFotoPerfil(
        usuarioId: widget.usuarioId,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UtileroPerfil>(
      stream: UtileroService.streamPerfil(widget.usuarioId),
      builder: (context, snap) {
        final p = snap.data;
        if (p != null && !_perfilSincronizado) {
          _syncFromPerfil(p);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Selección deportiva', style: DtflyTheme.panelTitle),
                    const SizedBox(height: 4),
                    const Text(
                      'Indica a qué selección apoyas (fútbol, básquetbol, etc.)',
                      style: TextStyle(
                        fontSize: 13,
                        color: DtflyTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _deporteId,
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports),
                      ),
                      items: [
                        for (final d in DeportesCategoria.todas)
                          DropdownMenuItem(
                            value: d.id,
                            child: Row(
                              children: [
                                Icon(d.icono, size: 20, color: DtflyTheme.primary),
                                const SizedBox(width: 10),
                                Text(d.nombre),
                              ],
                            ),
                          ),
                      ],
                      onChanged: _guardandoDeporte
                          ? null
                          : (v) => setState(() => _deporteId = v),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _guardandoDeporte
                          ? null
                          : () => _guardarDeporte(_deporteId),
                      icon: _guardandoDeporte
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _deporteId == null
                            ? 'Guardar selección'
                            : 'Guardar: ${DeportesCategoria.nombreVisible(_deporteId)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: DtflyTheme.surfaceMuted,
                    backgroundImage: p?.fotoPerfil != null
                        ? NetworkImage(p!.fotoPerfil!)
                        : null,
                    child: p?.fotoPerfil == null
                        ? const Icon(Icons.person, size: 52)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: _cambiarFoto,
                      icon: const Icon(Icons.camera_alt, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoTile('Cargo', p?.cargo ?? 'Utilero'),
            _infoTile(
              'Selección actual',
              p?.deporteNombre?.isNotEmpty == true
                  ? p!.deporteNombre!
                  : 'Sin selección — elige una arriba',
            ),
            _infoTile(
              'Fecha de ingreso',
              p?.fechaIngreso != null
                  ? '${p!.fechaIngreso!.day}/${p.fechaIngreso!.month}/${p.fechaIngreso!.year}'
                  : '—',
            ),
            _infoTile(
              'Estado',
              p?.estado ?? 'Activo',
              trailing: Chip(
                label: Text(p?.activo == true ? 'Activo' : 'Inactivo'),
                backgroundColor: (p?.activo ?? true)
                    ? DtflyTheme.accent.withValues(alpha: 0.2)
                    : DtflyTheme.fieldRed.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 16),
            if (_editando) ...[
              TextField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _apellido,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: _correo,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              TextField(
                controller: _telefono,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
            ] else ...[
              _infoTile('Nombre', p?.nombreCompleto ?? widget.nombreInicial),
              _infoTile('Correo', p?.correo ?? widget.usuarioEmail),
              _infoTile('Teléfono', p?.telefono.isNotEmpty == true ? p!.telefono : '—'),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _guardando
                        ? null
                        : () => setState(() => _editando = !_editando),
                    child: Text(_editando ? 'Cancelar' : 'Editar perfil'),
                  ),
                ),
                if (_editando) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventarioScreen(
                      entrenadorEmail: widget.usuarioEmail,
                      utileroUsuarioId: widget.usuarioId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.inventory_2),
              label: const Text('Acceso rápido al inventario'),
            ),
            const SizedBox(height: 24),
            Text('Resumen en tiempo real', style: DtflyTheme.panelTitle),
            const SizedBox(height: 8),
            FutureBuilder<UtileroResumenDashboard>(
              future: UtileroService.cargarResumen(widget.usuarioId),
              builder: (context, rSnap) {
                if (!rSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final r = rSnap.data!;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Registrados: ${r.materialesRegistrados}')),
                    Chip(label: Text('Entregados: ${r.materialesEntregados}')),
                    Chip(label: Text('Devueltos: ${r.materialesDevueltos}')),
                    Chip(
                      label: Text('Stock bajo: ${r.stockBajo}'),
                      backgroundColor:
                          DtflyTheme.fieldRed.withValues(alpha: 0.15),
                    ),
                    if (r.materialesDanados > 0)
                      Chip(
                        label: Text('Dañados: ${r.materialesDanados} u.'),
                        backgroundColor:
                            DtflyTheme.accentOrange.withValues(alpha: 0.2),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _infoTile(String label, String value, {Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 12, color: DtflyTheme.textMuted)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing,
      ),
    );
  }
}

class UtileroHistorialPanel extends StatefulWidget {
  const UtileroHistorialPanel({super.key, required this.usuarioId});
  final String usuarioId;

  @override
  State<UtileroHistorialPanel> createState() => _UtileroHistorialPanelState();
}

class _UtileroHistorialPanelState extends State<UtileroHistorialPanel> {
  final _buscar = TextEditingController();
  String _filtroAccion = 'Todas';
  DateTime? _desde;

  static const _filtros = <({String etiqueta, String clave})>[
    (etiqueta: 'Todas', clave: 'Todas'),
    (etiqueta: 'Registros', clave: 'Registr'),
    (etiqueta: 'Entregas', clave: 'Entreg'),
    (etiqueta: 'Actualizaciones', clave: 'Actualiz'),
    (etiqueta: 'Devoluciones', clave: 'devoluc'),
    (etiqueta: 'Sesiones', clave: 'sesión'),
  ];

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  List<ActividadUtilero> _filtrar(List<ActividadUtilero> lista) {
    final q = _buscar.text.trim().toLowerCase();
    return lista.where((a) {
      if (_filtroAccion != 'Todas' &&
          !a.accion.toLowerCase().contains(_filtroAccion.toLowerCase())) {
        return false;
      }
      if (_desde != null && a.fecha.isBefore(_desde!)) return false;
      if (q.isEmpty) return true;
      return a.accion.toLowerCase().contains(q) ||
          a.material.toLowerCase().contains(q) ||
          a.descripcion.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.backgroundGray,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                controller: _buscar,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar actividad',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _filtros)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(f.etiqueta),
                          selected: _filtroAccion == f.clave,
                          onSelected: (_) => setState(() => _filtroAccion = f.clave),
                        ),
                      ),
                    ActionChip(
                      label: Text(
                        _desde == null
                            ? 'Filtrar por fecha'
                            : 'Desde ${_desde!.day}/${_desde!.month}',
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _desde = d);
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final lista = await UtileroService.streamActividad(widget.usuarioId).first;
                        final filas = _filtrar(lista);
                        final perfil = await UtileroService.streamPerfil(widget.usuarioId).first;
                        final arch = await UtileroService.exportarHistorialPdf(
                          perfil: perfil,
                          filas: filas,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exportado: ${arch.nombreArchivo}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final lista = await UtileroService.streamActividad(widget.usuarioId).first;
                        final arch = await UtileroService.exportarHistorialExcel(
                          utileroId: widget.usuarioId,
                          filas: _filtrar(lista),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exportado: ${arch.nombreArchivo}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Excel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ActividadUtilero>>(
            stream: UtileroService.streamActividad(widget.usuarioId),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se pudo cargar el historial.\nVerifica tu conexión e intenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DtflyTheme.textSecondary),
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final lista = _filtrar(snap.data ?? []);
              if (lista.isEmpty) {
                return const Center(child: Text('Sin actividad registrada'));
              }
              return ListView.builder(
                itemCount: lista.length,
                itemBuilder: (context, i) {
                  final a = lista[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(a.accion),
                      subtitle: Text('${a.material} · ${a.descripcion}'),
                      trailing: Text(
                        '${a.fecha.day}/${a.fecha.month}/${a.fecha.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}

class UtileroEstadisticasPanel extends StatelessWidget {
  const UtileroEstadisticasPanel({super.key, required this.usuarioId});
  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UtileroEstadisticas>(
      future: UtileroService.cargarEstadisticas(usuarioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudieron cargar las estadísticas.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final s = snap.data!;
        return Material(
          color: DtflyTheme.backgroundGray,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: UtileroStatCard(
                    icono: Icons.swap_horiz,
                    titulo: 'Total movimientos',
                    valor: '${s.totalMovimientos}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: UtileroStatCard(
                    icono: Icons.calendar_view_week,
                    titulo: 'Promedio semanal',
                    valor: s.promedioSemanal.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            Card(
              child: ListTile(
                title: const Text('Material con mayor rotación'),
                trailing: Text(
                  s.materialMayorRotacion,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            UtileroBarChart(titulo: 'Material más utilizado', datos: s.masUtilizado),
            UtileroBarChart(titulo: 'Material más entregado', datos: s.masEntregado),
            UtileroBarChart(titulo: 'Material más devuelto', datos: s.masDevuelto),
            UtileroBarChart(titulo: 'Movimiento semanal', datos: s.movimientoSemanal),
            UtileroBarChart(titulo: 'Movimiento mensual', datos: s.movimientoMensual),
          ],
          ),
        );
      },
    );
  }
}

class UtileroNotificacionesPanel extends StatelessWidget {
  const UtileroNotificacionesPanel({super.key, required this.usuarioId});
  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => UtileroService.marcarTodasLeidas(usuarioId),
                  child: const Text('Marcar todas leídas'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => UtileroService.sincronizarAlertasInventario(usuarioId),
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar alertas',
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<NotificacionUtilero>>(
            stream: UtileroService.streamNotificaciones(usuarioId),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('Error al cargar notificaciones'));
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Center(child: Text('Sin notificaciones'));
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final n = list[i];
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => UtileroService.eliminarNotificacion(n.id),
                    background: Container(
                      color: DtflyTheme.fieldRed,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      color: n.leida ? null : DtflyTheme.primary.withValues(alpha: 0.06),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(n.titulo, style: TextStyle(
                          fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                        )),
                        subtitle: Text(n.mensaje),
                        trailing: n.leida
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () =>
                                    UtileroService.marcarNotificacionLeida(n.id),
                              ),
                        onTap: () => UtileroService.marcarNotificacionLeida(n.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class UtileroConfigPanel extends StatefulWidget {
  const UtileroConfigPanel({super.key, required this.usuarioId});
  final String usuarioId;

  @override
  State<UtileroConfigPanel> createState() => _UtileroConfigPanelState();
}

class _UtileroConfigPanelState extends State<UtileroConfigPanel> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _notifEmail = true;
  bool _notifSistema = true;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UtileroPerfil>(
      stream: UtileroService.streamPerfil(widget.usuarioId),
      builder: (context, snap) {
        final p = snap.data;
        if (p != null) {
          _notifEmail = p.notifEmail;
          _notifSistema = p.notifSistema;
        }
        return Material(
          color: DtflyTheme.backgroundGray,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Cambiar contraseña', style: DtflyTheme.panelTitle),
            TextField(
              controller: _actual,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            TextField(
              controller: _nueva,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
            TextField(
              controller: _confirmar,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar nueva'),
            ),
            FilledButton(
              onPressed: () async {
                if (_nueva.text != _confirmar.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Las contraseñas no coinciden')),
                  );
                  return;
                }
                try {
                  await UtileroService.cambiarContrasena(
                    usuarioId: widget.usuarioId,
                    actual: _actual.text,
                    nueva: _nueva.text,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña actualizada')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('Actualizar contraseña'),
            ),
            const Divider(height: 32),
            Text('Notificaciones', style: DtflyTheme.panelTitle),
            SwitchListTile(
              title: const Text('Notificaciones por correo'),
              value: _notifEmail,
              onChanged: (v) async {
                setState(() => _notifEmail = v);
                await UtileroService.guardarPreferenciasNotificacion(
                  usuarioId: widget.usuarioId,
                  email: v,
                  sistema: _notifSistema,
                );
              },
            ),
            SwitchListTile(
              title: const Text('Notificaciones en el sistema'),
              value: _notifSistema,
              onChanged: (v) async {
                setState(() => _notifSistema = v);
                await UtileroService.guardarPreferenciasNotificacion(
                  usuarioId: widget.usuarioId,
                  email: _notifEmail,
                  sistema: v,
                );
              },
            ),
          ],
          ),
        );
      },
    );
  }
}

class UtileroReportesPanel extends StatelessWidget {
  const UtileroReportesPanel({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
  });

  final String usuarioId;
  final String usuarioEmail;

  Future<void> _generar(BuildContext context, String periodo) async {
    final perfil = await UtileroService.streamPerfil(usuarioId).first;
    try {
      final arch = await UtileroService.generarReportePersonal(
        utileroId: usuarioId,
        perfil: perfil,
        periodo: periodo,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte $periodo: ${arch.nombreArchivo}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.backgroundGray,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reportes personales', style: DtflyTheme.panelTitle),
        const Text(
          'Incluye materiales gestionados, entregas, devoluciones e incidencias.',
          style: DtflyTheme.panelBody,
        ),
        const SizedBox(height: 16),
        _reporteBtn(context, 'Semanal', 'SEMANAL'),
        _reporteBtn(context, 'Mensual', 'MENSUAL'),
        _reporteBtn(context, 'Anual', 'ANUAL'),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => InventarioScreen(
                  entrenadorEmail: usuarioEmail,
                  utileroUsuarioId: usuarioId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.inventory_2),
          label: const Text('Ver inventario y movimientos'),
        ),
      ],
      ),
    );
  }

  Widget _reporteBtn(BuildContext context, String label, String periodo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: () => _generar(context, periodo),
        icon: const Icon(Icons.download),
        label: Text('Reporte $label'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
