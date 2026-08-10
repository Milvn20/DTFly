import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/screens/partidos/partido_cierre_screen.dart';
import 'package:flutter_application_1/screens/partidos/partido_detalle_screen.dart';
import 'package:flutter_application_1/screens/partidos/partido_form_screen.dart';
import 'package:flutter_application_1/screens/partidos/widgets/partido_tarjeta.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Gestión completa de partidos para el entrenador.
class PartidosGestionScreen extends StatefulWidget {
  const PartidosGestionScreen({
    super.key,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    this.entrenadorNombre = 'DT',
    this.soloLectura = false,
    this.categoriaDeportiva,
  });

  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String entrenadorNombre;
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

  Future<void> _abrirFormulario([Partido? editar]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoFormScreen(
          partido: editar,
          entrenadorEmail: widget.entrenadorEmail,
          entrenadorUsuarioId: widget.entrenadorUsuarioId,
          entrenadorNombre: widget.entrenadorNombre,
          categoriaDeportiva: widget.categoriaDeportiva,
        ),
      ),
    );
  }

  Future<void> _abrirCierrePartido(BuildContext context, Partido p) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoCierreScreen(
          partido: p,
          entrenadorEmail: widget.entrenadorEmail,
          entrenadorUsuarioId: widget.entrenadorUsuarioId,
          entrenadorNombre: widget.entrenadorNombre,
          categoriaDeportiva: widget.categoriaDeportiva,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deporte = DeportesCategoria.nombreVisible(widget.categoriaDeportiva);

    return DtflyDarkScaffold(
      title: widget.soloLectura ? 'Calendario y resultados' : 'Gestión de partidos',
      showBack: true,
      floatingActionButton: widget.soloLectura
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              backgroundColor: DtflyTheme.primary,
              icon: const Icon(Icons.event_available),
              label: const Text('Programar partido'),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.soloLectura)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DtflyTheme.secondary.withValues(alpha: 0.95),
                    DtflyTheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendario · $deporte',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Programa encuentros y se publican en el muro',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            indicatorColor: DtflyTheme.primary,
            labelColor: DtflyTheme.primary,
            unselectedLabelColor: DtflyTheme.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Próximos'),
              Tab(text: 'Resultados'),
            ],
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF1F5F9),
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ListaPartidos(
                    stream: widget.soloLectura
                        ? PartidoService.streamProximosGlobales()
                        : PartidoService.streamProximos(widget.entrenadorEmail),
                    vacio: 'No hay partidos programados.\nToca «Programar partido» para agregar uno.',
                    entrenadorEmail: widget.entrenadorEmail,
                    soloLectura: widget.soloLectura,
                    mostrarResultado: false,
                    onEditar: widget.soloLectura ? null : _abrirFormulario,
                    onCerrar: widget.soloLectura ? null : _abrirCierrePartido,
                  ),
                  _ListaPartidos(
                    stream: widget.soloLectura
                        ? PartidoService.streamResultadosGlobales()
                        : PartidoService.streamResultados(widget.entrenadorEmail),
                    vacio: 'Aún no hay resultados registrados.',
                    entrenadorEmail: widget.entrenadorEmail,
                    soloLectura: widget.soloLectura,
                    mostrarResultado: true,
                    onEditar: widget.soloLectura ? null : _abrirFormulario,
                    onCerrar: widget.soloLectura ? null : _abrirCierrePartido,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaPartidos extends StatelessWidget {
  const _ListaPartidos({
    required this.stream,
    required this.vacio,
    required this.entrenadorEmail,
    required this.soloLectura,
    required this.mostrarResultado,
    this.onEditar,
    this.onCerrar,
  });

  final Stream<List<Partido>> stream;
  final String vacio;
  final String entrenadorEmail;
  final bool soloLectura;
  final bool mostrarResultado;
  final void Function(Partido)? onEditar;
  final void Function(BuildContext, Partido)? onCerrar;

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
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vacio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DtflyTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = list[i];
            return PartidoTarjeta(
              partido: p,
              mostrarResultado: mostrarResultado,
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
              acciones: soloLectura
                  ? null
                  : _AccionesPartido(
                      mostrarResultado: mostrarResultado,
                      onEditar: onEditar == null ? null : () => onEditar!(p),
                      onCerrar: onCerrar == null
                          ? null
                          : () => onCerrar!(context, p),
                      onEliminar: () => PartidoService.eliminar(p.id),
                    ),
            );
          },
        );
      },
    );
  }
}

class _AccionesPartido extends StatelessWidget {
  const _AccionesPartido({
    required this.mostrarResultado,
    this.onEditar,
    this.onCerrar,
    required this.onEliminar,
  });

  final bool mostrarResultado;
  final VoidCallback? onEditar;
  final VoidCallback? onCerrar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (!mostrarResultado && onEditar != null)
          OutlinedButton.icon(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DtflyTheme.primary,
              side: const BorderSide(color: DtflyTheme.primary),
            ),
          ),
        if (!mostrarResultado && onCerrar != null)
          FilledButton.icon(
            onPressed: onCerrar,
            icon: const Icon(Icons.sports_soccer, size: 18),
            label: const Text('Cerrar partido'),
            style: FilledButton.styleFrom(
              backgroundColor: DtflyTheme.primary,
            ),
          ),
        if (mostrarResultado && onCerrar != null)
          OutlinedButton.icon(
            onPressed: onCerrar,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Editar datos'),
          ),
        if (!mostrarResultado)
          TextButton.icon(
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          ),
      ],
    );
  }
}
