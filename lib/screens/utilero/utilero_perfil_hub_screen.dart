import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/actividad_utilero.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/notificacion_utilero.dart';
import 'package:flutter_application_1/models/utilero_perfil.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_devoluciones_pendientes_screen.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_stock_screen.dart';
import 'package:flutter_application_1/screens/utilero/utilero_modulos_screens.dart';
import 'package:flutter_application_1/screens/utilero/utilero_seccion_screen.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_cambiar_seleccion_button.dart';
import 'package:flutter_application_1/widgets/utilero_widgets.dart';

const _turnosBodega = <String>[
  'Mañana',
  'Tarde',
  'Completo',
  'Fin de semana',
];

/// Módulo de pantallas del perfil del utilero (PDF DTFly).
/// Cada panel se usa en [UtileroSeccionScreen] o en la pestaña Perfil.
class UtileroPerfilPanel extends StatefulWidget {
  const UtileroPerfilPanel({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombreInicial,
    this.deporteId,
    this.onCambiarSeleccion,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombreInicial;
  final String? deporteId;
  final VoidCallback? onCambiarSeleccion;

  @override
  State<UtileroPerfilPanel> createState() => _UtileroPerfilPanelState();
}

class _UtileroPerfilPanelState extends State<UtileroPerfilPanel> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _turno = TextEditingController();
  final _horarioInicio = TextEditingController();
  final _horarioFin = TextEditingController();
  final _bodega = TextEditingController();
  final _institucion = TextEditingController();
  String? _turnoSeleccionado;
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
    _turno.dispose();
    _horarioInicio.dispose();
    _horarioFin.dispose();
    _bodega.dispose();
    _institucion.dispose();
    super.dispose();
  }

  String _fmtHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

  Future<void> _elegirHora(TextEditingController ctrl) async {
    TimeOfDay inicial = const TimeOfDay(hour: 8, minute: 0);
    final txt = ctrl.text.trim();
    if (txt.contains(':')) {
      final p = txt.split(':');
      if (p.length >= 2) {
        final h = int.tryParse(p[0]);
        final m = int.tryParse(p[1]);
        if (h != null && m != null) inicial = TimeOfDay(hour: h, minute: m);
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
    );
    if (picked != null && mounted) {
      setState(() => ctrl.text = _fmtHora(picked));
    }
  }

  void _syncFromPerfil(UtileroPerfil p) {
    _nombre.text = p.nombre.isNotEmpty ? p.nombre : widget.nombreInicial.split(' ').first;
    _apellido.text = p.apellido;
    _correo.text = p.correo.isNotEmpty ? p.correo : widget.usuarioEmail;
    _telefono.text = p.telefono;
    _turno.text = p.turno ?? '';
    _horarioInicio.text = p.horarioInicio ?? '';
    _horarioFin.text = p.horarioFin ?? '';
    _bodega.text = p.bodegaPrincipal ?? '';
    _institucion.text = p.institucion ?? '';
    _turnoSeleccionado = p.turno?.isNotEmpty == true ? p.turno : null;
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
        turno: _turnoSeleccionado ?? _turno.text,
        horarioInicio: _horarioInicio.text,
        horarioFin: _horarioFin.text,
        bodegaPrincipal: _bodega.text,
        institucion: _institucion.text,
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

  void _ir(BuildContext context, Widget screen) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
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
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FutureBuilder<UtileroResumenDashboard>(
                  future: UtileroService.cargarResumen(
                    widget.usuarioId,
                    deporteId: widget.deporteId ?? _deporteId,
                  ),
                  builder: (context, rSnap) {
                    if (!rSnap.hasData) {
                      return const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final r = rSnap.data!;
                    return _AlertasPerfilUtilero(
                      resumen: r,
                      onStockBajo: () => _ir(context, UtileroMaterialDanadoScreen(
                        usuarioId: widget.usuarioId,
                        deporteId: widget.deporteId ?? _deporteId,
                      )),
                      onDevoluciones: () => _ir(context, UtileroDevolucionesPendientesScreen(
                        usuarioId: widget.usuarioId,
                        usuarioEmail: widget.usuarioEmail,
                        deporteId: widget.deporteId ?? _deporteId,
                      )),
                      onEntrenamientos: () => _ir(context, UtileroCalendarioScreen(
                        usuarioId: widget.usuarioId,
                        deporteId: widget.deporteId ?? _deporteId,
                      )),
                      onNotificaciones: () => UtileroSeccionScreen.abrir(
                        context,
                        titulo: 'Notificaciones',
                        usuarioId: widget.usuarioId,
                        usuarioEmail: widget.usuarioEmail,
                        nombreInicial: widget.nombreInicial,
                        seccion: UtileroSeccion.notificaciones,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MaterialesLegacyBanner(
                  deporteId: widget.deporteId ?? _deporteId,
                ),
                const SizedBox(height: 8),
                Text('Accesos rápidos', style: DtflyTheme.panelTitle),
                const SizedBox(height: 8),
            
                _AccesosRapidosPerfil(
                  onCalendario: () => _ir(context, UtileroCalendarioScreen(
                    usuarioId: widget.usuarioId,
                    deporteId: widget.deporteId ?? _deporteId,
                  )),  
                

                  onHistorial: () => UtileroSeccionScreen.abrir(
                    context,
                    titulo: 'Historial',
                    usuarioId: widget.usuarioId,
                    usuarioEmail: widget.usuarioEmail,
                    nombreInicial: widget.nombreInicial,
                    seccion: UtileroSeccion.historial,
                  ),
                  onContactoDt: () => _ir(context, UtileroContactoDtScreen(
                    deporteId: widget.deporteId ?? _deporteId,
                  )),
                  onReportes: () => _ir(context, UtileroReportesScreen(
                    usuarioId: widget.usuarioId,
                    usuarioEmail: widget.usuarioEmail,
                    deporteId: widget.deporteId ?? _deporteId,
                  )),
                  onHerramientas: () => _ir(context, UtileroHerramientasScreen(
                    usuarioId: widget.usuarioId,
                    usuarioEmail: widget.usuarioEmail,
                    nombre: widget.nombreInicial,
                    deporteId: widget.deporteId ?? _deporteId,
                  )),
                ),
                const SizedBox(height: 16),
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
                    if (widget.onCambiarSeleccion != null) ...[
                      const SizedBox(height: 10),
                      UtileroCambiarSeleccionButton(
                        deporteId: widget.deporteId ?? _deporteId,
                        onTap: widget.onCambiarSeleccion!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: DtflyTheme.surfaceMuted,
                          backgroundImage: p?.fotoPerfil != null
                              ? NetworkImage(p!.fotoPerfil!)
                              : null,
                          child: p?.fotoPerfil == null
                              ? const Icon(Icons.person, size: 34)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: DtflyTheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _cambiarFoto,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p?.nombreCompleto ?? widget.nombreInicial,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${p?.cargo ?? "Utilero"} · ${p?.activo == true ? "Activo" : "Inactivo"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DtflyTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ExpansionTile(
                initiallyExpanded: false,
                title: const Text('Datos laborales'),
                children: [
                  _infoTileCompact(
                    'Turno',
                    p?.turno?.isNotEmpty == true ? p!.turno! : '—',
                  ),
                  _infoTileCompact(
                    'Horario',
                    p?.horarioInicio?.isNotEmpty == true
                        ? '${p!.horarioInicio} – ${p.horarioFin ?? ""}'
                        : '—',
                  ),
                  _infoTileCompact(
                    'Institución',
                    p?.institucion?.isNotEmpty == true ? p!.institucion! : '—',
                  ),
                  _infoTileCompact(
                    'Bodega',
                    p?.bodegaPrincipal?.isNotEmpty == true
                        ? p!.bodegaPrincipal!
                        : '—',
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                title: const Text('Datos personales'),
                children: [
                  if (_editando) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nombre,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                          ),
                          TextField(
                            controller: _apellido,
                            decoration: const InputDecoration(
                              labelText: 'Apellido',
                            ),
                          ),
                          TextField(
                            controller: _correo,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                            ),
                          ),
                          TextField(
                            controller: _telefono,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          TextField(
                            controller: _institucion,
                            decoration: const InputDecoration(
                              labelText: 'Institución',
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            initialValue:
                                _turnosBodega.contains(_turnoSeleccionado)
                                    ? _turnoSeleccionado
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Turno',
                            ),
                            items: [
                              for (final t in _turnosBodega)
                                DropdownMenuItem(value: t, child: Text(t)),
                            ],
                            onChanged: (v) => setState(() {
                              _turnoSeleccionado = v;
                              _turno.text = v ?? '';
                            }),
                          ),
                          TextField(
                            controller: _bodega,
                            decoration: const InputDecoration(
                              labelText: 'Bodega',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _elegirHora(_horarioInicio),
                                  child: Text(
                                    _horarioInicio.text.isEmpty
                                        ? 'Hora inicio'
                                        : _horarioInicio.text,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _elegirHora(_horarioFin),
                                  child: Text(
                                    _horarioFin.text.isEmpty
                                        ? 'Hora fin'
                                        : _horarioFin.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _infoTileCompact(
                      'Correo',
                      p?.correo ?? widget.usuarioEmail,
                    ),
                    _infoTileCompact(
                      'Teléfono',
                      p?.telefono.isNotEmpty == true ? p!.telefono : '—',
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _guardando
                                ? null
                                : () =>
                                    setState(() => _editando = !_editando),
                            child: Text(_editando ? 'Cancelar' : 'Editar'),
                          ),
                        ),
                        if (_editando) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: _guardando ? null : _guardar,
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen de tu selección',
              style: DtflyTheme.panelTitle,
            ),
            if (widget.deporteId != null || _deporteId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  DeportesCategoria.nombreVisible(
                    widget.deporteId ?? _deporteId,
                  ),
                  style: const TextStyle(
                    color: DtflyTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            FutureBuilder<UtileroResumenDashboard>(
              future: UtileroService.cargarResumen(
                widget.usuarioId,
                deporteId: widget.deporteId ?? _deporteId,
              ),
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
                    Chip(label: Text('Prestados hoy: ${r.entregadosHoy}')),
                    Chip(label: Text('Devueltos hoy: ${r.devueltosHoy}')),
                    Chip(
                      label: Text('Pendientes: ${r.prestamosPendientes}'),
                      backgroundColor: r.prestamosPendientes > 0
                          ? DtflyTheme.fieldRed.withValues(alpha: 0.15)
                          : null,
                    ),
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
                    Chip(
                      label: Text(
                        'Entrenamientos semana: ${r.entrenamientosSemana}',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
            ),
          ),
        );
      },
    );
  }



  Widget _infoTileCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DtflyTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialesLegacyBanner extends StatefulWidget {
  const _MaterialesLegacyBanner({this.deporteId});

  final String? deporteId;

  @override
  State<_MaterialesLegacyBanner> createState() => _MaterialesLegacyBannerState();
}

class _MaterialesLegacyBannerState extends State<_MaterialesLegacyBanner> {
  bool _migrando = false;

  Future<void> _asignarSeleccion(BuildContext context, int cantidad) async {
    final dep = widget.deporteId;
    if (dep == null || dep.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una selección deportiva primero')),
      );
      return;
    }
    final nombre = DeportesCategoria.nombreVisible(dep);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Asignar materiales antiguos'),
        content: Text(
          'Hay $cantidad material(es) sin selección.\n\n'
          '¿Asignarlos todos a $nombre?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _migrando = true);
    try {
      final n = await InventarioService.asignarDeporteMaterialesLegacy(
        deporteId: dep,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$n material(es) asignados a $nombre')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _migrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaterialInventario>>(
      stream: InventarioService.streamMaterialesSinDeporte(),
      builder: (context, snap) {
        final n = snap.data?.length ?? 0;
        if (n == 0) return const SizedBox.shrink();
        return Card(
          color: DtflyTheme.accentOrange.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$n material(es) sin selección',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Registros antiguos que no aparecen en tu inventario actual.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _migrando
                      ? null
                      : () => _asignarSeleccion(context, n),
                  child: _migrando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Asignar a mi selección actual'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertasPerfilUtilero extends StatelessWidget {
  const _AlertasPerfilUtilero({
    required this.resumen,
    required this.onStockBajo,
    required this.onDevoluciones,
    required this.onEntrenamientos,
    required this.onNotificaciones,
  });

  final UtileroResumenDashboard resumen;
  final VoidCallback onStockBajo;
  final VoidCallback onDevoluciones;
  final VoidCallback onEntrenamientos;
  final VoidCallback onNotificaciones;

  @override
  Widget build(BuildContext context) {
    final alertas = <Widget>[];

    if (resumen.prestamosPendientes > 0) {
      alertas.add(_AlertaTile(
        icono: Icons.assignment_return,
        titulo: '${resumen.prestamosPendientes} devolución(es) pendiente(s)',
        color: DtflyTheme.fieldRed,
        onTap: onDevoluciones,
      ));
    }
    if (resumen.stockBajo > 0) {
      alertas.add(_AlertaTile(
        icono: Icons.warning_amber_outlined,
        titulo: '${resumen.stockBajo} material(es) con stock bajo',
        color: DtflyTheme.accentOrange,
        onTap: onStockBajo,
      ));
    }
    if (resumen.materialesDanados > 0) {
      alertas.add(_AlertaTile(
        icono: Icons.build_circle_outlined,
        titulo: '${resumen.materialesDanados} unidad(es) dañada(s)',
        color: DtflyTheme.fieldRed,
        onTap: onStockBajo,
      ));
    }
    if (resumen.entrenamientosSemana > 0) {
      alertas.add(_AlertaTile(
        icono: Icons.calendar_month_outlined,
        titulo: '${resumen.entrenamientosSemana} entrenamiento(s) esta semana',
        color: DtflyTheme.primary,
        onTap: onEntrenamientos,
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Alertas del día', style: DtflyTheme.panelTitle),
                ),
                TextButton.icon(
                  onPressed: onNotificaciones,
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: const Text('Ver todas'),
                ),
              ],
            ),
            if (alertas.isEmpty)
              const ListTile(
                leading: Icon(Icons.check_circle_outline, color: DtflyTheme.success),
                title: Text('Todo en orden por ahora'),
                subtitle: Text('Sin devoluciones urgentes ni stock crítico'),
              )
            else
              ...alertas,
          ],
        ),
      ),
    );
  }
}

class _AlertaTile extends StatelessWidget {
  const _AlertaTile({
    required this.icono,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icono, color: color, size: 20),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _AccesosRapidosPerfil extends StatelessWidget {
  const _AccesosRapidosPerfil({
    required this.onCalendario,
    required this.onHistorial,
    required this.onContactoDt,
    required this.onReportes,
    required this.onHerramientas,
  });

  final VoidCallback onCalendario;
  final VoidCallback onHistorial;
  final VoidCallback onContactoDt;
  final VoidCallback onReportes;
  final VoidCallback onHerramientas;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icono, String label, VoidCallback onTap})>[
      (icono: Icons.calendar_month_outlined, label: 'Calendario', onTap: onCalendario),
      (icono: Icons.history, label: 'Historial', onTap: onHistorial),
      (icono: Icons.contact_phone_outlined, label: 'Contacto DT', onTap: onContactoDt),
      (icono: Icons.summarize_outlined, label: 'Reportes', onTap: onReportes),
      (icono: Icons.dashboard_customize_outlined, label: 'Herramientas', onTap: onHerramientas),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: [
        for (final item in items)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: item.onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DtflyTheme.borderSubtle),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icono, color: DtflyTheme.primary),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
            const Divider(height: 24),
            Text('Correo de alertas', style: DtflyTheme.panelTitle),
            const Text(
              'Requiere Cloud Functions (plan Blaze). Sin eso queda encolado en Firestore.',
              style: TextStyle(fontSize: 13, color: DtflyTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Map<String, dynamic>?>(
              stream: UtileroService.streamUltimoEmailEstado(widget.usuarioId),
              builder: (context, emailSnap) {
                final e = emailSnap.data;
                if (e == null) {
                  return const ListTile(
                    dense: true,
                    leading: Icon(Icons.mail_outline),
                    title: Text('Sin correos encolados aún'),
                  );
                }
                final estado = e['estado'] as String? ?? '—';
                final asunto = e['asunto'] as String? ?? '';
                final error = e['error'] as String?;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    estado == 'enviado'
                        ? Icons.check_circle_outline
                        : estado == 'error'
                            ? Icons.error_outline
                            : Icons.schedule,
                    color: estado == 'enviado'
                        ? DtflyTheme.success
                        : estado == 'error'
                            ? DtflyTheme.fieldRed
                            : DtflyTheme.textSecondary,
                  ),
                  title: Text('Último: $estado'),
                  subtitle: Text(
                    error?.isNotEmpty == true ? error! : asunto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await UtileroService.enviarEmailPrueba(widget.usuarioId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Correo de prueba encolado. Revisa tu bandeja en 1-2 min.',
                        ),
                      ),
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
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Enviar correo de prueba'),
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
                builder: (_) => UtileroKioscoStockScreen(
                  usuarioId: usuarioId,
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
