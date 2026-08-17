import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/estadistica_deportiva.dart';
import 'package:flutter_application_1/services/estadistica_deportiva_service.dart';
import 'package:flutter_application_1/services/plantel_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Estadísticas deportivas: registro (DT) o visualización (jugador).
class EstadisticasDeportivasScreen extends StatelessWidget {
  const EstadisticasDeportivasScreen({
    super.key,
    required this.entrenadorEmail,
    this.jugadorId,
    this.soloLectura = false,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String? jugadorId;
  final bool soloLectura;
  final String? categoriaDeportiva;

  Future<void> _registrar(BuildContext context) async {
    final jugadores =
        await PlantelService.obtenerJugadoresPorDeporte(categoriaDeportiva);
    if (!context.mounted || jugadores.isEmpty) return;

    String? selId;
    var jugadorNombre = '';
    var tipo = EstadisticaDeportivaService.tiposComunes.first;
    var periodo = 'semanal';
    final valor = TextEditingController();
    final unidad = TextEditingController(text: 'unidad');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Registrar estadística'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selId,
                  decoration: const InputDecoration(labelText: 'Jugador'),
                  items: [
                    for (final d in jugadores)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(d.data()['nombre'] as String? ?? ''),
                      ),
                  ],
                  onChanged: (v) {
                    setSt(() {
                      selId = v;
                      final doc = jugadores.firstWhere((e) => e.id == v);
                      jugadorNombre = doc.data()['nombre'] as String? ?? '';
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final t in EstadisticaDeportivaService.tiposComunes)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setSt(() => tipo = v ?? tipo),
                ),
                DropdownButtonFormField<String>(
                  initialValue: periodo,
                  decoration: const InputDecoration(labelText: 'Periodo'),
                  items: [
                    for (final p in EstadisticaDeportivaService.periodos)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setSt(() => periodo = v ?? periodo),
                ),
                TextField(
                  controller: valor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor'),
                ),
                TextField(
                  controller: unidad,
                  decoration: const InputDecoration(labelText: 'Unidad'),
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

    final v = double.tryParse(valor.text) ?? 0;
    final unidadTxt = unidad.text.trim();
    valor.dispose();
    unidad.dispose();
    if (ok != true || selId == null) return;

    await EstadisticaDeportivaService.registrar(
      jugadorId: selId!,
      jugadorNombre: jugadorNombre,
      entrenadorEmail: entrenadorEmail,
      deporte: categoriaDeportiva,
      tipo: tipo,
      valor: v,
      unidad: unidadTxt,
      periodo: periodo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = jugadorId;

    return DtflyDarkScaffold(
      title: soloLectura ? 'Mi rendimiento deportivo' : 'Estadísticas deportivas',
      floatingActionButton: soloLectura
          ? null
          : FloatingActionButton(
              onPressed: () => _registrar(context),
              backgroundColor: DtflyTheme.primary,
              child: const Icon(Icons.add_chart),
            ),
      body: id == null
          ? _VistaEntrenador(entrenadorEmail: entrenadorEmail)
          : StreamBuilder<ResumenEstadisticasJugador>(
        stream: EstadisticaDeportivaService.streamResumenJugador(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final resumen = snap.data;
          if (resumen == null || resumen.registrosRecientes.isEmpty) {
            return Center(
              child: Text(
                soloLectura
                    ? 'Tu entrenador aún no registró estadísticas deportivas.'
                    : 'Registra goles, minutos, intensidad y más.',
                style: const TextStyle(color: DtflyTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (resumen.promedioSemanal.isNotEmpty) ...[
                const Text(
                  'Progreso semanal',
                  style: TextStyle(
                    color: DtflyTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...resumen.promedioSemanal.entries.map(
                  (e) => _StatBar(label: e.key, valor: e.value, max: 100),
                ),
                const SizedBox(height: 20),
              ],
              if (resumen.promedioMensual.isNotEmpty) ...[
                const Text(
                  'Progreso mensual',
                  style: TextStyle(
                    color: DtflyTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...resumen.promedioMensual.entries.map(
                  (e) => _StatBar(
                    label: e.key,
                    valor: e.value,
                    max: resumen.promedioMensual.values.fold<double>(
                          0,
                          (a, b) => a > b ? a : b,
                        ) *
                        1.2 +
                        1,
                    color: DtflyTheme.accentOrange,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Registros recientes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final r in resumen.registrosRecientes)
                DtflyDarkCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${r.tipo}: ${r.valor} ${r.unidad}',
                      style: const TextStyle(
                        color: DtflyTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${r.periodo} · ${_fmtFecha(r.fechaRegistro)}',
                      style: const TextStyle(color: DtflyTheme.textMuted),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VistaEntrenador extends StatelessWidget {
  const _VistaEntrenador({required this.entrenadorEmail});

  final String entrenadorEmail;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EstadisticaDeportiva>>(
      stream: EstadisticaDeportivaService.streamPorEntrenador(entrenadorEmail),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'Registra estadísticas por jugador con el botón +.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            return DtflyDarkCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r.jugadorNombre,
                  style: const TextStyle(
                    color: DtflyTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${r.tipo}: ${r.valor} ${r.unidad} (${r.periodo})',
                  style: const TextStyle(color: DtflyTheme.textSecondary),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _fmtFecha(DateTime d) =>
    '${d.day}/${d.month}/${d.year}';

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.valor,
    required this.max,
    this.color = DtflyTheme.coachRed,
  });

  final String label;
  final double valor;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (valor / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: DtflyTheme.textSecondary)),
              Text(
                valor.toStringAsFixed(1),
                style: const TextStyle(
                  color: DtflyTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: DtflyTheme.surfaceElevated,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
