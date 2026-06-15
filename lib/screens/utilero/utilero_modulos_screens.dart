import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/utilero_modulos.dart';
import 'package:flutter_application_1/models/utilero_perfil.dart';
import 'package:flutter_application_1/screens/utilero/utilero_inventario_anual_screen.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

const _rojo = Color(0xFFC62828);

/// Hub de herramientas del utilero universitario.
class UtileroHerramientasScreen extends StatelessWidget {
  const UtileroHerramientasScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombre,
    this.deporteId,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombre;
  final String? deporteId;

  void _ir(BuildContext context, Widget screen) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deporte = deporteId != null && deporteId!.isNotEmpty
        ? DeportesCategoria.nombreVisible(deporteId)
        : 'Todas';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas utilero'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Selección: $deporte',
            style: const TextStyle(color: DtflyTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          _Tile(
            icon: Icons.calendar_month_outlined,
            titulo: 'Calendario de entrenamientos',
            subtitulo: 'Sesiones programadas de tu selección',
            onTap: () => _ir(
              context,
              UtileroCalendarioScreen(
                usuarioId: usuarioId,
                deporteId: deporteId,
              ),
            ),
          ),
          _Tile(
            icon: Icons.checklist_rtl,
            titulo: 'Checklist pre-entrenamiento',
            subtitulo: 'Verificar material antes de la sesión',
            onTap: () => _ir(
              context,
              UtileroChecklistScreen(usuarioId: usuarioId),
            ),
          ),
          _Tile(
            icon: Icons.contact_phone_outlined,
            titulo: 'Contacto DT / profesores',
            subtitulo: 'Teléfono y correo de tu selección',
            onTap: () => _ir(
              context,
              UtileroContactoDtScreen(deporteId: deporteId),
            ),
          ),
          _Tile(
            icon: Icons.shopping_cart_outlined,
            titulo: 'Solicitudes de compra',
            subtitulo: 'Pedir material cuando falta stock',
            onTap: () => _ir(
              context,
              UtileroSolicitudesScreen(
                usuarioId: usuarioId,
                deporteId: deporteId,
              ),
            ),
          ),
          _Tile(
            icon: Icons.build_circle_outlined,
            titulo: 'Material dañado / reparación',
            subtitulo: 'Ver dañados y marcar como reparados',
            onTap: () => _ir(
              context,
              UtileroMaterialDanadoScreen(
                usuarioId: usuarioId,
                deporteId: deporteId,
              ),
            ),
          ),
          _Tile(
            icon: Icons.fact_check_outlined,
            titulo: 'Inventario físico',
            subtitulo: 'Conteo rápido e inventario anual formal',
            onTap: () => _ir(
              context,
              UtileroInventarioFisicoScreen(
                usuarioId: usuarioId,
                deporteId: deporteId,
              ),
            ),
          ),
          _Tile(
            icon: Icons.summarize_outlined,
            titulo: 'Reportes semanales',
            subtitulo: 'Exportar resumen para coordinación',
            onTap: () => _ir(
              context,
              UtileroReportesScreen(
                usuarioId: usuarioId,
                usuarioEmail: usuarioEmail,
                deporteId: deporteId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _rojo.withValues(alpha: 0.12),
          child: Icon(icon, color: _rojo),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class UtileroCalendarioScreen extends StatelessWidget {
  const UtileroCalendarioScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, "0")}:'
      '${d.minute.toString().padLeft(2, "0")}';

  @override
  Widget build(BuildContext context) {
    final seleccion = deporteId != null && deporteId!.isNotEmpty
        ? DeportesCategoria.nombreVisible(deporteId)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Entrenamiento>>(
        stream: UtileroService.streamEntrenamientosDeporte(deporteId: deporteId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _rojo));
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  seleccion != null
                      ? 'No hay entrenamientos de $seleccion '
                          'en los próximos 14 días.'
                      : 'No hay entrenamientos programados en los próximos días.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (seleccion != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Selección: $seleccion · ${lista.length} sesión(es)',
                    style: const TextStyle(
                      color: DtflyTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
              final e = lista[i];
              final hoy = DateTime.now();
              final esHoy = e.inicioProgramado.year == hoy.year &&
                  e.inicioProgramado.month == hoy.month &&
                  e.inicioProgramado.day == hoy.day;
              return Card(
                child: ListTile(
                  leading: Icon(
                    esHoy ? Icons.today : Icons.event,
                    color: esHoy ? _rojo : DtflyTheme.textSecondary,
                  ),
                  title: Text(
                    e.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_fmt(e.inicioProgramado)}\n'
                    '${e.cancha.isNotEmpty ? e.cancha : "Sin cancha"} · ${e.estado}',
                  ),
                  isThreeLine: true,
                ),
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
}

class UtileroChecklistScreen extends StatefulWidget {
  const UtileroChecklistScreen({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<UtileroChecklistScreen> createState() => _UtileroChecklistScreenState();
}

class _UtileroChecklistScreenState extends State<UtileroChecklistScreen> {
  String? _checklistId;

  Future<void> _nuevo() async {
    final id = await UtileroService.crearChecklist(
      utileroId: widget.usuarioId,
      titulo: 'Pre-entrenamiento ${DateTime.now().day}/${DateTime.now().month}',
    );
    if (mounted) setState(() => _checklistId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _nuevo,
            tooltip: 'Nuevo checklist',
          ),
        ],
      ),
      body: StreamBuilder<List<ChecklistUtileroSesion>>(
        stream: UtileroService.streamChecklists(widget.usuarioId),
        builder: (context, snap) {
          final list = snap.data ?? [];
          final activo = _checklistId != null
              ? list.where((c) => c.id == _checklistId).firstOrNull
              : list.where((c) => !c.completado).firstOrNull;

          if (activo == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crea un checklist para verificar el material '
                      'antes del entrenamiento.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _nuevo,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Iniciar checklist'),
                      style: FilledButton.styleFrom(backgroundColor: _rojo),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                activo.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${activo.marcados}/${activo.totalItems} completados',
                style: const TextStyle(color: DtflyTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ...activo.items.entries.map(
                (e) => CheckboxListTile(
                  value: e.value,
                  onChanged: (v) => UtileroService.actualizarItemChecklist(
                    checklistId: activo.id,
                    item: e.key,
                    marcado: v ?? false,
                  ),
                  title: Text(e.key),
                  activeColor: _rojo,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: activo.marcados == activo.totalItems
                    ? () async {
                        await UtileroService.completarChecklist(activo.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Checklist completado')),
                          );
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _rojo,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Marcar checklist como listo'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class UtileroContactoDtScreen extends StatelessWidget {
  const UtileroContactoDtScreen({super.key, this.deporteId});

  final String? deporteId;

  void _copiar(BuildContext context, String texto, String etiqueta) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$etiqueta copiado: $texto')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto DT'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<UtileroContactoDt>>(
        future: UtileroService.listarContactosDt(deporteId: deporteId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _rojo));
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return const Center(
              child: Text('No hay entrenadores registrados para esta selección.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final dt = lista[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dt.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (dt.deporteNombre != null &&
                          dt.deporteNombre!.isNotEmpty)
                        Text(
                          dt.deporteNombre!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DtflyTheme.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (dt.email.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.email_outlined),
                          title: Text(dt.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copiar(context, dt.email, 'Correo'),
                          ),
                        ),
                      if (dt.telefono != null && dt.telefono!.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(dt.telefono!),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copiar(context, dt.telefono!, 'Teléfono'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UtileroSolicitudesScreen extends StatefulWidget {
  const UtileroSolicitudesScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  @override
  State<UtileroSolicitudesScreen> createState() =>
      _UtileroSolicitudesScreenState();
}

class _UtileroSolicitudesScreenState extends State<UtileroSolicitudesScreen> {
  final _material = TextEditingController();
  final _cantidad = TextEditingController(text: '1');
  final _motivo = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _material.dispose();
    _cantidad.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final nombre = _material.text.trim();
    final cant = int.tryParse(_cantidad.text.trim()) ?? 0;
    if (nombre.isEmpty || cant <= 0) return;
    setState(() => _enviando = true);
    try {
      await UtileroService.crearSolicitudCompra(
        utileroId: widget.usuarioId,
        materialNombre: nombre,
        cantidad: cant,
        motivo: _motivo.text.trim().isEmpty
            ? 'Stock bajo / reposición'
            : _motivo.text.trim(),
        deporteId: widget.deporteId,
      );
      if (mounted) {
        _material.clear();
        _motivo.clear();
        _cantidad.text = '1';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de compra'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _material,
                  decoration: const InputDecoration(
                    labelText: 'Material a solicitar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cantidad,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar solicitud'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _rojo,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<SolicitudCompraUtilero>>(
              stream: UtileroService.streamSolicitudes(widget.usuarioId),
              builder: (context, snap) {
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('Sin solicitudes aún'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: DtflyTheme.borderSubtle),
                      ),
                      title: Text('${s.cantidad} × ${s.materialNombre}'),
                      subtitle: Text('${s.estado} · ${s.motivo}'),
                      trailing: Chip(
                        label: Text(s.estado),
                        backgroundColor: s.pendiente
                            ? _rojo.withValues(alpha: 0.12)
                            : DtflyTheme.success.withValues(alpha: 0.15),
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

class UtileroMaterialDanadoScreen extends StatelessWidget {
  const UtileroMaterialDanadoScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material dañado'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MaterialInventario>>(
        stream: InventarioService.streamMaterialesDeporte(deporteId),
        builder: (context, snap) {
          final todos = snap.data ?? [];
          final danados = todos.where((m) => m.tieneDanados).toList();
          if (danados.isEmpty) {
            return const Center(
              child: Text('No hay unidades dañadas en esta selección.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: danados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = danados[i];
              final cat = UtileroMaterialCat.resolver('${m.categoria} ${m.nombre}');
              return Card(
                child: ListTile(
                  leading: UtileroMaterialIcon(categoria: cat, size: 32),
                  title: Text(m.nombre),
                  subtitle: Text(
                    '${m.cantidadDanada} dañada(s) · ${m.ubicacionTexto.isEmpty ? "Sin ubicación" : m.ubicacionTexto}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await InventarioService.recuperarDanado(
                          materialId: m.id,
                          cantidad: 1,
                        );
                        await UtileroService.registrarActividad(
                          utileroId: usuarioId,
                          accion: 'Reparación',
                          descripcion: '1 ${m.nombre} reparado',
                          material: m.nombre,
                          cantidad: 1,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${m.nombre} reparado (+1 disp.)')),
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
                    child: const Text('Reparar 1'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UtileroInventarioFisicoScreen extends StatefulWidget {
  const UtileroInventarioFisicoScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  @override
  State<UtileroInventarioFisicoScreen> createState() =>
      _UtileroInventarioFisicoScreenState();
}

class _UtileroInventarioFisicoScreenState
    extends State<UtileroInventarioFisicoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario físico'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Conteo rápido'),
            Tab(text: 'Anual formal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _InventarioFisicoRapidoTab(
            usuarioId: widget.usuarioId,
            deporteId: widget.deporteId,
          ),
          UtileroInventarioAnualListaScreen(
            usuarioId: widget.usuarioId,
            deporteId: widget.deporteId,
          ),
        ],
      ),
    );
  }
}

class _InventarioFisicoRapidoTab extends StatefulWidget {
  const _InventarioFisicoRapidoTab({
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  @override
  State<_InventarioFisicoRapidoTab> createState() =>
      _InventarioFisicoRapidoTabState();
}

class _InventarioFisicoRapidoTabState extends State<_InventarioFisicoRapidoTab> {
  final _conteos = <String, TextEditingController>{};
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in _conteos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar(List<MaterialInventario> mats) async {
    setState(() => _guardando = true);
    try {
      final conteos = <String, int>{};
      final sistema = <String, int>{};
      for (final m in mats) {
        final ctrl = _conteos[m.id];
        conteos[m.nombre] = int.tryParse(ctrl?.text.trim() ?? '') ?? 0;
        sistema[m.nombre] = m.cantidadTotal;
      }
      await UtileroService.registrarInventarioFisico(
        utileroId: widget.usuarioId,
        conteos: conteos,
        sistema: sistema,
        deporteId: widget.deporteId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteo rápido registrado')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaterialInventario>>(
      stream: InventarioService.streamMaterialesDeporte(widget.deporteId),
      builder: (context, snap) {
          final mats = snap.data ?? [];
          if (mats.isEmpty) {
            return const Center(child: Text('No hay materiales en esta selección.'));
          }
          for (final m in mats) {
            _conteos.putIfAbsent(
              m.id,
              () => TextEditingController(text: '${m.cantidadTotal}'),
            );
          }
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cuenta las unidades reales y compáralas con el sistema.',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mats.length,
                  itemBuilder: (context, i) {
                    final m = mats[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              m.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('Sist: ${m.cantidadTotal}'),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: TextField(
                              controller: _conteos[m.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Conteo',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _guardando ? null : () => _guardar(mats),
                  style: FilledButton.styleFrom(
                    backgroundColor: _rojo,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Registrar conteo'),
                ),
              ),
            ],
          );
        },
    );
  }
}

class UtileroReportesScreen extends StatefulWidget {
  const UtileroReportesScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    this.deporteId,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String? deporteId;

  @override
  State<UtileroReportesScreen> createState() => _UtileroReportesScreenState();
}

class _UtileroReportesScreenState extends State<UtileroReportesScreen> {
  bool _generando = false;

  Future<void> _generar(String periodo) async {
    setState(() => _generando = true);
    try {
      final perfil = await UtileroService.streamPerfil(widget.usuarioId).first;
      final archivo = await UtileroService.generarReportePersonal(
        utileroId: widget.usuarioId,
        perfil: perfil,
        periodo: periodo,
        deporteId: widget.deporteId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              archivo.rutaArchivo != null
                  ? 'Reporte guardado: ${archivo.nombreArchivo}'
                  : 'Reporte generado: ${archivo.nombreArchivo}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: _rojo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Genera un archivo de texto con movimientos, stock y '
              'resumen del periodo para entregar a coordinación.',
            ),
            const SizedBox(height: 20),
            _BotonReporte(
              titulo: 'Reporte semanal',
              onTap: _generando ? null : () => _generar('SEMANAL'),
            ),
            _BotonReporte(
              titulo: 'Reporte mensual',
              onTap: _generando ? null : () => _generar('MENSUAL'),
            ),
            _BotonReporte(
              titulo: 'Reporte anual',
              onTap: _generando ? null : () => _generar('ANUAL'),
            ),
            if (_generando) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator(color: _rojo)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotonReporte extends StatelessWidget {
  const _BotonReporte({required this.titulo, required this.onTap});

  final String titulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.download_outlined),
        label: Text(titulo),
        style: OutlinedButton.styleFrom(
          foregroundColor: _rojo,
          side: const BorderSide(color: _rojo),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
