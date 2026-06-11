import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/screens/partidos/partido_cierre_screen.dart';
import 'package:flutter_application_1/screens/partidos/partido_detalle_screen.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Gestión completa de partidos para el entrenador.
class PartidosGestionScreen extends StatefulWidget {
  const PartidosGestionScreen({
    super.key,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    this.soloLectura = false,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final bool soloLectura;
  final String? categoriaDeportiva;

  @override
  State<PartidosGestionScreen> createState() => _PartidosGestionScreenState();
}

class _PartidosGestionScreenState extends State<PartidosGestionScreen>
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
    return DtflyDarkScaffold(
      title: widget.soloLectura ? 'Calendario y resultados' : 'Gestión de partidos',
      showBack: true,
      floatingActionButton: widget.soloLectura
          ? null
          : FloatingActionButton(
              onPressed: () => _dialogoPartido(context),
              backgroundColor: DtflyTheme.primary,
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            indicatorColor: DtflyTheme.primary,
            labelColor: DtflyTheme.primary,
            unselectedLabelColor: DtflyTheme.textMuted,
            tabs: const [
              Tab(text: 'Próximos'),
              Tab(text: 'Resultados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ListaPartidos(
                  stream: widget.soloLectura
                      ? PartidoService.streamProximosGlobales()
                      : PartidoService.streamProximos(widget.entrenadorEmail),
                  vacio: 'No hay partidos programados.',
                  entrenadorEmail: widget.entrenadorEmail,
                  entrenadorUsuarioId: widget.entrenadorUsuarioId,
                  soloLectura: widget.soloLectura,
                  mostrarResultado: false,
                ),
                _ListaPartidos(
                  stream: widget.soloLectura
                      ? PartidoService.streamResultadosGlobales()
                      : PartidoService.streamResultados(widget.entrenadorEmail),
                  vacio: 'Aún no hay resultados registrados.',
                  entrenadorEmail: widget.entrenadorEmail,
                  entrenadorUsuarioId: widget.entrenadorUsuarioId,
                  soloLectura: widget.soloLectura,
                  mostrarResultado: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogoPartido(BuildContext context, [Partido? editar]) async {
    final rival = TextEditingController(text: editar?.rival ?? '');
    final lugar = TextEditingController(text: editar?.lugar ?? 'Cancha');
    final notas = TextEditingController(text: editar?.notas ?? '');
    DateTime fecha = editar?.fechaHora ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay hora = editar != null
        ? TimeOfDay(hour: editar.fechaHora.hour, minute: editar.fechaHora.minute)
        : const TimeOfDay(hour: 15, minute: 0);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(editar == null ? 'Agregar partido' : 'Editar partido'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rival,
                  decoration: const InputDecoration(labelText: 'Rival'),
                ),
                TextField(
                  controller: lugar,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                ),
                TextField(
                  controller: notas,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
                ListTile(
                  title: Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (d != null) setSt(() => fecha = d);
                  },
                ),
                ListTile(
                  title: Text('Hora: ${hora.format(ctx)}'),
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: hora);
                    if (t != null) setSt(() => hora = t);
                  },
                ),
              ],
            ),
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
      ),
    );

    final rivalTxt = rival.text.trim();
    final lugarTxt = lugar.text.trim();
    final notasTxt = notas.text.trim();
    rival.dispose();
    lugar.dispose();
    notas.dispose();
    if (ok != true || !mounted || rivalTxt.isEmpty) return;

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    try {
      if (editar == null) {
        await PartidoService.crear(
          entrenadorEmail: widget.entrenadorEmail,
          entrenadorUsuarioId: widget.entrenadorUsuarioId,
          fechaHora: fechaHora,
          rival: rivalTxt,
          lugar: lugarTxt,
          notas: notasTxt,
        );
      } else {
        await PartidoService.actualizar(
          id: editar.id,
          fechaHora: fechaHora,
          rival: rivalTxt,
          lugar: lugarTxt,
          notas: notasTxt,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _abrirCierrePartido(BuildContext context, Partido p) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoCierreScreen(
          partido: p,
          entrenadorEmail: widget.entrenadorEmail,
          entrenadorUsuarioId: widget.entrenadorUsuarioId,
          categoriaDeportiva: widget.categoriaDeportiva,
        ),
      ),
    );
  }
}

class _ListaPartidos extends StatelessWidget {
  const _ListaPartidos({
    required this.stream,
    required this.vacio,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    required this.soloLectura,
    required this.mostrarResultado,
  });

  final Stream<List<Partido>> stream;
  final String vacio;
  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final bool soloLectura;
  final bool mostrarResultado;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Partido>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(vacio, style: const TextStyle(color: DtflyTheme.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final p = list[i];
            return DtflyDarkCard(
              onTap: soloLectura && mostrarResultado
                  ? () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartidoDetalleScreen(partido: p),
                        ),
                      );
                    }
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs ${p.rival}',
                    style: const TextStyle(
                      color: DtflyTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmt(p.fechaHora)} · ${p.lugar}',
                    style: const TextStyle(color: DtflyTheme.textSecondary),
                  ),
                  if (mostrarResultado && p.resultadoTexto != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Resultado: ${p.resultadoTexto}',
                        style: const TextStyle(
                          color: DtflyTheme.accentOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  if (mostrarResultado && p.observacionFinal.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p.observacionFinal,
                      style: const TextStyle(color: DtflyTheme.textSecondary),
                    ),
                  ],
                  if (mostrarResultado && p.fotosUrls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.fotosUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.fotosUrls[i],
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!soloLectura && !mostrarResultado) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final state = context.findAncestorStateOfType<
                                _PartidosGestionScreenState>();
                            state?._dialogoPartido(context, p);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final state = context.findAncestorStateOfType<
                                _PartidosGestionScreenState>();
                            state?._abrirCierrePartido(context, p);
                          },
                          icon: const Icon(Icons.sports_soccer, size: 18),
                          label: const Text('Cerrar partido'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await PartidoService.eliminar(p.id);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                  if (!soloLectura && mostrarResultado) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        final state = context.findAncestorStateOfType<
                            _PartidosGestionScreenState>();
                        state?._abrirCierrePartido(context, p);
                      },
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Editar datos del partido'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
