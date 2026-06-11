import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/services/observacion_service.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/services/plantel_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

/// Cierre de partido: resultado, fotos y observaciones (general + por jugador).
class PartidoCierreScreen extends StatefulWidget {
  const PartidoCierreScreen({
    super.key,
    required this.partido,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    this.categoriaDeportiva,
  });

  final Partido partido;
  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String? categoriaDeportiva;

  @override
  State<PartidoCierreScreen> createState() => _PartidoCierreScreenState();
}

class _FotoNueva {
  _FotoNueva({required this.bytes, required this.nombre});
  final Uint8List bytes;
  final String nombre;
}

class _ObservacionDraft {
  String? jugadorId;
  String jugadorNombre = '';
  final texto = TextEditingController();
  String rendimiento = ObservacionService.rendimientos[1];
}

class _PartidoCierreScreenState extends State<PartidoCierreScreen> {
  final _golesLocal = TextEditingController();
  final _golesRival = TextEditingController();
  final _observacionGeneral = TextEditingController();

  final List<String> _fotosExistentes = [];
  final List<_FotoNueva> _fotosNuevas = [];
  final List<_ObservacionDraft> _observaciones = [];

  List<MapEntry<String, String>> _jugadores = [];
  bool _cargandoJugadores = true;
  bool _guardando = false;

  bool get _editando => widget.partido.esJugado;

  @override
  void initState() {
    super.initState();
    final p = widget.partido;
    if (p.golesLocal != null) _golesLocal.text = '${p.golesLocal}';
    if (p.golesRival != null) _golesRival.text = '${p.golesRival}';
    _observacionGeneral.text = p.observacionFinal;
    _fotosExistentes.addAll(p.fotosUrls);
    _cargarJugadores();
  }

  Future<void> _cargarJugadores() async {
    try {
      final list =
          await PlantelService.listarJugadores(widget.categoriaDeportiva);
      if (mounted) {
        setState(() {
          _jugadores = list;
          _cargandoJugadores = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoJugadores = false);
    }
  }

  @override
  void dispose() {
    _golesLocal.dispose();
    _golesRival.dispose();
    _observacionGeneral.dispose();
    for (final o in _observaciones) {
      o.texto.dispose();
    }
    super.dispose();
  }

  Future<void> _agregarFotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (files.isEmpty) return;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      setState(() {
        _fotosNuevas.add(_FotoNueva(bytes: bytes, nombre: f.name));
      });
    }
  }

  void _agregarObservacionJugador() {
    setState(() => _observaciones.add(_ObservacionDraft()));
  }

  Future<void> _guardar() async {
    final gl = int.tryParse(_golesLocal.text.trim());
    final gr = int.tryParse(_golesRival.text.trim());
    if (gl == null || gr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica los goles de ambos equipos.')),
      );
      return;
    }

    final obsJugadores = <ObservacionPartidoJugador>[];
    for (final draft in _observaciones) {
      final txt = draft.texto.text.trim();
      if (txt.isEmpty || draft.jugadorId == null) continue;
      obsJugadores.add(ObservacionPartidoJugador(
        jugadorId: draft.jugadorId!,
        jugadorNombre: draft.jugadorNombre,
        texto: txt,
        rendimiento: draft.rendimiento,
      ));
    }

    setState(() => _guardando = true);
    try {
      await PartidoService.registrarCierrePartido(
        partidoId: widget.partido.id,
        entrenadorEmail: widget.entrenadorEmail,
        entrenadorUsuarioId: widget.entrenadorUsuarioId,
        rival: widget.partido.rival,
        golesLocal: gl,
        golesRival: gr,
        observacionFinal: _observacionGeneral.text,
        fotosUrlsExistentes: _fotosExistentes,
        fotosNuevas: _fotosNuevas.map((f) => f.bytes).toList(),
        nombresFotosNuevas: _fotosNuevas.map((f) => f.nombre).toList(),
        observacionesJugadores: obsJugadores,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editando
                  ? 'Datos del partido actualizados.'
                  : 'Partido cerrado correctamente.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DtflyDarkScaffold(
      title: _editando ? 'Editar cierre del partido' : 'Cerrar partido',
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(
                'vs ${widget.partido.rival}',
                style: const TextStyle(
                  color: DtflyTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                widget.partido.lugar,
                style: const TextStyle(color: DtflyTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              const Text('Resultado final', style: DtflyTheme.panelTitle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _golesLocal,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Goles local'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DtflyTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _golesRival,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Goles rival'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Observación del partido', style: DtflyTheme.panelTitle),
              const SizedBox(height: 4),
              const Text(
                'Comentario general visible para el plantel (opcional).',
                style: TextStyle(color: DtflyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _observacionGeneral,
                minLines: 3,
                maxLines: 8,
                decoration: _dec('¿Cómo fue el partido?'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text('Fotos del partido', style: DtflyTheme.panelTitle),
                  ),
                  TextButton.icon(
                    onPressed: _agregarFotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Subir'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_fotosExistentes.isEmpty && _fotosNuevas.isEmpty)
                const Text(
                  'Puedes subir varias fotos del encuentro.',
                  style: TextStyle(color: DtflyTheme.textMuted),
                ),
              if (_fotosExistentes.isNotEmpty || _fotosNuevas.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _fotosExistentes.length; i++)
                        _MiniFoto(
                          url: _fotosExistentes[i],
                          onQuitar: () => setState(() => _fotosExistentes.removeAt(i)),
                        ),
                      for (var i = 0; i < _fotosNuevas.length; i++)
                        _MiniFoto(
                          bytes: _fotosNuevas[i].bytes,
                          onQuitar: () => setState(() => _fotosNuevas.removeAt(i)),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Observaciones por jugador',
                      style: DtflyTheme.panelTitle,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _cargandoJugadores ? null : _agregarObservacionJugador,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Opcional: evalúa a quien quieras al cerrar el partido.',
                style: TextStyle(color: DtflyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (_cargandoJugadores)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_jugadores.isEmpty)
                const Text(
                  'No hay jugadores registrados para asignar observaciones.',
                  style: TextStyle(color: DtflyTheme.textSecondary),
                )
              else
                for (var i = 0; i < _observaciones.length; i++)
                  _ObservacionJugadorCard(
                    key: ValueKey('obs_$i'),
                    draft: _observaciones[i],
                    jugadores: _jugadores,
                    onChanged: () => setState(() {}),
                    onEliminar: () {
                      setState(() {
                        _observaciones[i].texto.dispose();
                        _observaciones.removeAt(i);
                      });
                    },
                  ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: DtflyTheme.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_editando ? 'Guardar cambios' : 'Guardar cierre del partido'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: DtflyTheme.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DtflyTheme.borderSubtle),
      ),
    );
  }
}

class _MiniFoto extends StatelessWidget {
  const _MiniFoto({
    this.url,
    this.bytes,
    required this.onQuitar,
  });

  final String? url;
  final Uint8List? bytes;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 96,
              height: 96,
              child: bytes != null
                  ? Image.memory(bytes!, fit: BoxFit.cover)
                  : Image.network(url!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onQuitar,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservacionJugadorCard extends StatelessWidget {
  const _ObservacionJugadorCard({
    super.key,
    required this.draft,
    required this.jugadores,
    required this.onChanged,
    required this.onEliminar,
  });

  final _ObservacionDraft draft;
  final List<MapEntry<String, String>> jugadores;
  final VoidCallback onChanged;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return DtflyDarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jugador',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DtflyTheme.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: DtflyTheme.fieldRed),
                onPressed: onEliminar,
                tooltip: 'Quitar',
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            value: draft.jugadorId,
            decoration: const InputDecoration(
              labelText: 'Seleccionar alumno',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final j in jugadores)
                DropdownMenuItem(value: j.key, child: Text(j.value)),
            ],
            onChanged: (id) {
              if (id == null) return;
              draft.jugadorId = id;
              draft.jugadorNombre =
                  jugadores.firstWhere((e) => e.key == id).value;
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: draft.rendimiento,
            decoration: const InputDecoration(
              labelText: 'Rendimiento',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final r in ObservacionService.rendimientos)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) {
              if (v != null) {
                draft.rendimiento = v;
                onChanged();
              }
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.texto,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Observación',
              border: OutlineInputBorder(),
              hintText: 'Ej: Buen despliegue, mejorar presión...',
            ),
          ),
        ],
      ),
    );
  }
}
