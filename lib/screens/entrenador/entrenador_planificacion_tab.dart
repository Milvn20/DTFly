import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';

class EntrenadorPlanificacionTab extends StatelessWidget {
  const EntrenadorPlanificacionTab({
    super.key,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String? categoriaDeportiva;

  String _fmtFechaHora(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

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
          child: StreamBuilder<List<Entrenamiento>>(
            stream: EntrenamientoService.streamProgramados(entrenadorEmail),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              final list = snap.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: list.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: DtflyTheme.coachRed,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: () => _abrirCrear(context),
                          borderRadius: BorderRadius.circular(28),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  '+ Crear entrenamiento',
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
                    );
                  }
                  final e = list[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: DtflyTheme.coachRed,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.titulo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${e.cancha} · ${_fmtFechaHora(e.inicioProgramado)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 36),
                              tooltip: 'Iniciar sesión',
                              onPressed: () => _iniciar(context, e.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.white70),
                              tooltip: 'Eliminar',
                              onPressed: () => _eliminar(context, e.id),
                            ),
                          ],
                        ),
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

  Future<void> _iniciar(BuildContext context, String id) async {
    try {
      await EntrenamientoService.activar(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrenamiento en curso. Código activo.')),
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

  Future<void> _eliminar(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text('¿Seguro? Solo si aún no se ha iniciado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await EntrenamientoService.eliminarProgramado(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado.')),
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

  Future<void> _abrirCrear(BuildContext context) async {
    final canchaCtrl = TextEditingController(text: 'Cancha principal');
    final tituloCtrl = TextEditingController(text: 'Entrenamiento');
    DateTime fecha = DateTime.now().add(const Duration(days: 1));
    TimeOfDay horaIni = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay horaFin = const TimeOfDay(hour: 19, minute: 30);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          Future<void> pickDate() async {
            final d = await showDatePicker(
              context: ctx,
              initialDate: fecha,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setSt(() => fecha = d);
          }

          Future<void> pickIni() async {
            final t = await showTimePicker(context: ctx, initialTime: horaIni);
            if (t != null) setSt(() => horaIni = t);
          }

          Future<void> pickFin() async {
            final t = await showTimePicker(context: ctx, initialTime: horaFin);
            if (t != null) setSt(() => horaFin = t);
          }

          return AlertDialog(
            title: const Text('Nuevo entrenamiento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  TextField(
                    controller: canchaCtrl,
                    decoration: const InputDecoration(labelText: 'Cancha / lugar'),
                  ),
                  ListTile(
                    title: Text(
                      'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: pickDate,
                  ),
                  ListTile(
                    title: Text(
                      'Inicio: ${horaIni.format(ctx)}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: pickIni,
                  ),
                  ListTile(
                    title: Text(
                      'Fin: ${horaFin.format(ctx)}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: pickFin,
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

    if (ok != true) {
      canchaCtrl.dispose();
      tituloCtrl.dispose();
      return;
    }
    if (!context.mounted) {
      canchaCtrl.dispose();
      tituloCtrl.dispose();
      return;
    }

    final ini = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      horaIni.hour,
      horaIni.minute,
    );
    final fin = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      horaFin.hour,
      horaFin.minute,
    );
    if (!fin.isAfter(ini)) {
      canchaCtrl.dispose();
      tituloCtrl.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La hora de fin debe ser después del inicio.')),
        );
      }
      return;
    }

    final tituloTxt = tituloCtrl.text.trim();
    final canchaTxt = canchaCtrl.text.trim();
    canchaCtrl.dispose();
    tituloCtrl.dispose();

    try {
      await EntrenamientoService.crearProgramado(
        entrenadorEmail: entrenadorEmail,
        entrenadorUsuarioId: entrenadorUsuarioId,
        cancha: canchaTxt,
        titulo: tituloTxt,
        inicio: ini,
        fin: fin,
        categoriaDeportiva: categoriaDeportiva,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrenamiento creado. Inícialo cuando corresponda.')),
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
}
