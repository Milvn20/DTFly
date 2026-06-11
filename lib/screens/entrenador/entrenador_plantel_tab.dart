import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/nota_dt.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/screens/jugadores_screen.dart';
import 'package:flutter_application_1/screens/partidos/partidos_gestion_screen.dart';
import 'package:flutter_application_1/services/nota_dt_service.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';

class EntrenadorPlantelTab extends StatelessWidget {
  const EntrenadorPlantelTab({
    super.key,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String? categoriaDeportiva;

  String _fmt(Partido p) =>
      '${p.fechaHora.day}/${p.fechaHora.month}/${p.fechaHora.year} '
      '${p.fechaHora.hour.toString().padLeft(2, '0')}:'
      '${p.fechaHora.minute.toString().padLeft(2, '0')}';

  Future<void> _agregarNotaSemanal(BuildContext context) async {
    final notaCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Expectativas de la semana'),
        content: TextField(
          controller: notaCtrl,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: '¿Qué esperas del plantel esta semana?',
            hintText: 'Ej: Llegar 10 minutos antes, mantener intensidad...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    final texto = notaCtrl.text.trim();
    notaCtrl.dispose();

    if (ok != true || !context.mounted) return;

    try {
      await NotaDtService.crearNotaSemanal(
        entrenadorEmail: entrenadorEmail,
        entrenadorUsuarioId: entrenadorUsuarioId,
        texto: texto,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota semanal publicada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo publicar: $e')),
        );
      }
    }
  }

  Future<void> _agregarPartido(BuildContext context) async {
    final rival = TextEditingController();
    final lugar = TextEditingController(text: 'Cancha / estadio');
    final notas = TextEditingController();
    DateTime fecha = DateTime.now().add(const Duration(days: 1));
    TimeOfDay hora = const TimeOfDay(hour: 15, minute: 0);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Agregar partido'),
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
                    decoration: const InputDecoration(labelText: 'Lugar'),
                  ),
                  TextField(
                    controller: notas,
                    decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                  ),
                  ListTile(
                    title: Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: fecha,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d != null) setSt(() => fecha = d);
                    },
                  ),
                  ListTile(
                    title: Text('Hora: ${hora.format(ctx)}'),
                    trailing: const Icon(Icons.access_time),
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
          );
        },
      ),
    );

    final rivalTxt = rival.text.trim();
    final lugarTxt = lugar.text.trim();
    final notasTxt = notas.text.trim();
    rival.dispose();
    lugar.dispose();
    notas.dispose();

    if (ok != true || !context.mounted) return;
    if (rivalTxt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el rival.')),
      );
      return;
    }

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    try {
      await PartidoService.crear(
        entrenadorEmail: entrenadorEmail,
        entrenadorUsuarioId: entrenadorUsuarioId,
        fechaHora: fechaHora,
        rival: rivalTxt,
        lugar: lugarTxt,
        notas: notasTxt,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partido agregado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _eliminarNota(BuildContext context, NotaDt nota) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text(
          '¿Eliminar esta nota de la semana? Los jugadores dejarán de verla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DtflyTheme.fieldRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await NotaDtService.eliminar(nota.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota eliminada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: DtflyCoachHeader(categoriaDeportiva: categoriaDeportiva),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Plantel y calendario',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Material(
                color: DtflyTheme.primary,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JugadoresScreen(
                          soloJugadores: true,
                          categoriaDeportiva: categoriaDeportiva,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Ver fichas de jugadores',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lo esperado esta semana',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _agregarNotaSemanal(context),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<NotaDt>>(
                stream: NotaDtService.streamSemanaEntrenador(entrenadorEmail),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('${snap.error}');
                  }
                  final notas = snap.data ?? [];
                  if (notas.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Agrega una nota para que los jugadores vean qué espera el DT esta semana.',
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final nota in notas)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.campaign, color: DtflyTheme.primary),
                            title: Text(
                              nota.texto,
                              style: const TextStyle(color: DtflyTheme.textPrimary),
                            ),
                            subtitle: const Text(
                              'Visible en Novedades del alumno',
                              style: TextStyle(color: DtflyTheme.textSecondary),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: DtflyTheme.fieldRed,
                              tooltip: 'Eliminar nota',
                              onPressed: () => _eliminarNota(context, nota),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Próximos partidos',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _agregarPartido(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartidosGestionScreen(
                            entrenadorEmail: entrenadorEmail,
                            entrenadorUsuarioId: entrenadorUsuarioId,
                          ),
                        ),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Partido>>(
                stream: PartidoService.streamProximos(entrenadorEmail),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('${snap.error}');
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Text(
                      'No hay partidos cargados. Pulsa «Agregar».',
                    );
                  }
                  return Column(
                    children: [
                      for (final p in list)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(
                              p.rival,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${_fmt(p)} · ${p.lugar}'
                              '${p.notas.isNotEmpty ? '\n${p.notas}' : ''}',
                            ),
                            isThreeLine: p.notas.isNotEmpty,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
