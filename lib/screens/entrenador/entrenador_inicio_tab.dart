import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/screens/jugador/jugador_detalle_screen.dart';
import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';
import 'package:flutter_application_1/widgets/muro_acceso_button.dart';

/// Inicio del DT: sesión en curso con código en vivo y cuenta regresiva.
class EntrenadorInicioTab extends StatelessWidget {
  const EntrenadorInicioTab({
    super.key,
    required this.entrenadorEmail,
    required this.entrenadorNombre,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String entrenadorNombre;
  final String? categoriaDeportiva;

  String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
          child: StreamBuilder<Entrenamiento?>(
            stream: EntrenamientoService.streamActivo(entrenadorEmail),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error al cargar sesión:\n${snap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final activo = snap.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  MuroAccesoButton(
                    deporteId: categoriaDeportiva,
                    autorEmail: entrenadorEmail,
                    autorNombre: entrenadorNombre,
                    soloLectura: false,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Entrenamiento en curso',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (activo == null) ...[
                    const Text(
                      'No hay sesión abierta. Ve a Planificación, crea un entrenamiento e inícialo.',
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _EntrenadorRedRow(
                      title:
                          '${activo.cancha} · ${_fmtHora(activo.inicioProgramado)}–${_fmtHora(activo.finProgramado)}',
                      subtitle: activo.titulo,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'La sesión está abierta para que los jugadores se unan con el código.',
                    ),
                    const SizedBox(height: 12),
                    _LiveCodigoPanel(entrenamiento: activo),
                    const SizedBox(height: 20),
                    _ListaAsistenciaViva(entrenamientoId: activo.id),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(28),
                      child: InkWell(
                        onTap: () => _confirmarFinalizar(context, activo.id),
                        borderRadius: BorderRadius.circular(28),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Finalizar entrenamiento',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Próximos programados',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: EntrenamientoService.streamProgramados(
                      entrenadorEmail,
                    ),
                    builder: (context, pSnap) {
                      if (!pSnap.hasData || pSnap.data!.isEmpty) {
                        return const Text('No tienes entrenamientos programados.');
                      }
                      final list = pSnap.data!;
                      return Column(
                        children: [
                          for (final e in list.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EntrenadorRedRow(
                                title:
                                    '${e.cancha} · ${_fmtHora(e.inicioProgramado)}',
                                subtitle: e.titulo,
                                onTap: () => _iniciarRapido(context, e.id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _iniciarRapido(BuildContext context, String id) async {
    try {
      await EntrenamientoService.activar(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión iniciada. Código generado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar: $e')),
        );
      }
    }
  }

  Future<void> _confirmarFinalizar(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar entrenamiento'),
        content: const Text(
          'Se cerrará la sesión y el código dejará de ser válido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await EntrenamientoService.finalizar(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrenamiento finalizado.')),
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

class _ListaAsistenciaViva extends StatefulWidget {
  const _ListaAsistenciaViva({required this.entrenamientoId});

  final String entrenamientoId;

  @override
  State<_ListaAsistenciaViva> createState() => _ListaAsistenciaVivaState();
}

class _ListaAsistenciaVivaState extends State<_ListaAsistenciaViva> {
  final _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  static String _fmtHora(DateTime? d) {
    if (d == null) return '--:--';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'atrasado':
        return 'Atrasado';
      case 'ausente':
        return 'Ausente';
      case 'presente':
      default:
        return 'Puntual';
    }
  }

  static Color _colorEstado(String estado) {
    switch (estado) {
      case 'atrasado':
        return Colors.orange.shade800;
      case 'ausente':
        return DtflyTheme.coachRed;
      default:
        return Colors.green.shade800;
    }
  }

  static bool _esPuntual(String estado) => estado == 'presente' || estado == 'puntual';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AsistenciaRegistro>>(
      stream: EntrenamientoService.streamAsistencias(widget.entrenamientoId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Error asistencias: ${snap.error}');
        }
        final lista = snap.data ?? [];
        final puntuales = lista.where((a) => _esPuntual(a.estado)).length;
        final atrasados = lista.where((a) => a.estado == 'atrasado').length;
        final ausentes = lista.where((a) => a.estado == 'ausente').length;
        final query = _busquedaCtrl.text.trim().toLowerCase();
        final filtrada = query.isEmpty
            ? lista
            : lista.where((a) {
                return a.nombre.toLowerCase().contains(query) ||
                    a.email.toLowerCase().contains(query);
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: DtflyTheme.coachRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Resumen de entrenamiento',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ResumenEstadoCard(
                    valor: puntuales,
                    label: 'presentes',
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResumenEstadoCard(
                    valor: atrasados,
                    label: 'atrasados',
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResumenEstadoCard(
                    valor: ausentes,
                    label: 'ausentes',
                    color: DtflyTheme.coachRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lista de jugadores',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(
                  width: 138,
                  height: 34,
                  child: TextField(
                    controller: _busquedaCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar jugador...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lista.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aún no hay registros. Al iniciar el entrenamiento se cargará el plantel como ausente.',
                  ),
                ),
              )
            else if (filtrada.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay jugadores que coincidan con la búsqueda.'),
                ),
              )
            else
              ...filtrada.map((a) {
                final color = _colorEstado(a.estado);
                final esAusente = a.estado == 'ausente';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: DtflyTheme.textSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JugadorDetalleScreen(jugadorId: a.jugadorId),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_outline, color: Colors.white),
                    ),
                    title: Text(
                      a.nombre.isEmpty ? 'Sin nombre' : a.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      esAusente ? 'Sin registro' : a.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          esAusente ? 'Sin Registro' : _fmtHora(a.unidoEn),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _etiquetaEstado(a.estado),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                          onSelected: (nuevo) async {
                            try {
                              await EntrenamientoService
                                  .actualizarEstadoAsistencia(
                                entrenamientoId: widget.entrenamientoId,
                                jugadorId: a.jugadorId,
                                estado: nuevo,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Estado actualizado'),
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
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: 'presente',
                              child: Text('Marcar puntual'),
                            ),
                            PopupMenuItem(
                              value: 'atrasado',
                              child: Text('Marcar atrasado'),
                            ),
                            PopupMenuItem(
                              value: 'ausente',
                              child: Text('Marcar ausente'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _ResumenEstadoCard extends StatelessWidget {
  const _ResumenEstadoCard({
    required this.valor,
    required this.label,
    required this.color,
  });

  final int valor;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: color == DtflyTheme.coachRed
                  ? Colors.white
                  : color.withValues(alpha: 0.95),
              fontWeight: FontWeight.w300,
              fontSize: 34,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCodigoPanel extends StatefulWidget {
  const _LiveCodigoPanel({required this.entrenamiento});

  final Entrenamiento entrenamiento;

  @override
  State<_LiveCodigoPanel> createState() => _LiveCodigoPanelState();
}

class _LiveCodigoPanelState extends State<_LiveCodigoPanel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entrenamiento;
    final base = e.codigoActualizadoEn ?? DateTime.now();
    final validez = Duration(seconds: e.codigoValidezSegundos);
    final proxima = base.add(validez);
    final restante = proxima.difference(DateTime.now());
    final segundos = restante.isNegative ? 0 : restante.inSeconds;

    return Material(
      color: DtflyTheme.coachRed,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Código de unión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              e.codigoUnion.isEmpty ? '…' : e.codigoUnion,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Próxima rotación automática en $segundos s (válido ${e.codigoValidezSegundos} s)',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntrenadorRedRow extends StatelessWidget {
  const _EntrenadorRedRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.coachRed,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
