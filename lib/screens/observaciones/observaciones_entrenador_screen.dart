import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/observacion_jugador.dart';
import 'package:flutter_application_1/services/observacion_service.dart';
import 'package:flutter_application_1/services/plantel_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// El entrenador registra observaciones individuales, de entreno o partido.
class ObservacionesEntrenadorScreen extends StatelessWidget {
  const ObservacionesEntrenadorScreen({
    super.key,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String? categoriaDeportiva;

  Future<void> _nuevaObservacion(BuildContext context) async {
    final jugadores =
        await PlantelService.obtenerJugadoresPorDeporte(categoriaDeportiva);

    if (!context.mounted) return;
    if (jugadores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoriaDeportiva == null
                ? 'Selecciona un deporte para ver jugadores.'
                : 'No hay jugadores en tu plantel.',
          ),
        ),
      );
      return;
    }

    String? jugadorId;
    String jugadorNombre = '';
    var tipo = ObservacionTipo.individual;
    var rendimiento = ObservacionService.rendimientos[1];
    final texto = TextEditingController();
    final referencia = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nueva observación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: jugadorId,
                  decoration: const InputDecoration(labelText: 'Alumno'),
                  items: [
                    for (final d in jugadores)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(d.data()['nombre'] as String? ?? d.id),
                      ),
                  ],
                  onChanged: (v) {
                    setSt(() {
                      jugadorId = v;
                      final doc = jugadores.firstWhere((e) => e.id == v);
                      jugadorNombre =
                          doc.data()['nombre'] as String? ?? '';
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: ObservacionTipo.individual,
                      child: Text('Individual'),
                    ),
                    DropdownMenuItem(
                      value: ObservacionTipo.entrenamiento,
                      child: Text('Entrenamiento'),
                    ),
                    DropdownMenuItem(
                      value: ObservacionTipo.partido,
                      child: Text('Partido'),
                    ),
                  ],
                  onChanged: (v) => setSt(() => tipo = v ?? tipo),
                ),
                DropdownButtonFormField<String>(
                  initialValue: rendimiento,
                  decoration: const InputDecoration(labelText: 'Rendimiento'),
                  items: [
                    for (final r in ObservacionService.rendimientos)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                  onChanged: (v) => setSt(() => rendimiento = v ?? rendimiento),
                ),
                TextField(
                  controller: referencia,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                    hintText: 'Ej: Partido vs Norte',
                  ),
                ),
                TextField(
                  controller: texto,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                  ),
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

    final txt = texto.text.trim();
    final refTxt = referencia.text.trim();
    texto.dispose();
    referencia.dispose();
    if (ok != true || jugadorId == null || txt.isEmpty) return;

    await ObservacionService.crear(
      jugadorId: jugadorId!,
      jugadorNombre: jugadorNombre,
      entrenadorEmail: entrenadorEmail,
      entrenadorUsuarioId: entrenadorUsuarioId,
      tipo: tipo,
      texto: txt,
      rendimiento: rendimiento,
      referenciaTitulo: refTxt.isEmpty ? null : refTxt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DtflyDarkScaffold(
      title: 'Observaciones y seguimiento',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevaObservacion(context),
        backgroundColor: DtflyTheme.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: StreamBuilder<List<ObservacionJugador>>(
        stream: ObservacionService.streamPorEntrenador(entrenadorEmail),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Registra observaciones por alumno, entrenamiento o partido.',
                style: TextStyle(color: DtflyTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final o = list[i];
              return DtflyDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.jugadorNombre,
                            style: const TextStyle(
                              color: DtflyTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _RendimientoChip(rendimiento: o.rendimiento),
                      ],
                    ),
                    Text(
                      '${o.tipoEtiqueta}'
                      '${o.referenciaTitulo != null ? ' · ${o.referenciaTitulo}' : ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o.texto,
                      style: const TextStyle(color: DtflyTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: DtflyTheme.fieldRed,
                        ),
                        onPressed: () => ObservacionService.eliminar(o.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RendimientoChip extends StatelessWidget {
  const _RendimientoChip({required this.rendimiento});

  final String rendimiento;

  @override
  Widget build(BuildContext context) {
    Color c = DtflyTheme.accentOrange;
    if (rendimiento == 'excelente') c = Colors.greenAccent;
    if (rendimiento == 'mejorar') c = DtflyTheme.fieldRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rendimiento,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
