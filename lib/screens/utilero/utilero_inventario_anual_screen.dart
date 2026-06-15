import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/utilero_modulos.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

const _rojo = Color(0xFFC62828);

/// Lista de inventarios anuales formales del utilero.
class UtileroInventarioAnualListaScreen extends StatelessWidget {
  const UtileroInventarioAnualListaScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  Future<void> _nuevo(BuildContext context) async {
    try {
      final id = await UtileroService.crearInventarioAnual(
        utileroId: usuarioId,
        deporteId: deporteId,
      );
      if (!context.mounted) return;
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => UtileroInventarioAnualDetalleScreen(
            sesionId: id,
            usuarioId: usuarioId,
          ),
        ),
      );
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
    final seleccion = deporteId != null && deporteId!.isNotEmpty
        ? DeportesCategoria.nombreVisible(deporteId)
        : 'Todas las selecciones';

    return StreamBuilder<List<InventarioFisicoSesion>>(
      stream: UtileroService.streamInventariosFisicos(
        usuarioId,
        deporteId: deporteId,
        tipo: 'anual',
      ),
      builder: (context, snap) {
        final lista = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting && lista.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventario físico anual formal',
                    style: DtflyTheme.panelTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selección: $seleccion · Año ${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: DtflyTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Documento auditable para coordinación universitaria: '
                    'conteo material, firmas y exportación.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aún no hay inventarios anuales.\n'
                          'Crea el del año en curso con el botón inferior.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lista.length,
                      itemBuilder: (context, i) {
                        final s = lista[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: s.cerrado
                                  ? DtflyTheme.success.withValues(alpha: 0.15)
                                  : _rojo.withValues(alpha: 0.12),
                              child: Icon(
                                s.cerrado
                                    ? Icons.verified_outlined
                                    : Icons.edit_note,
                                color: s.cerrado
                                    ? DtflyTheme.success
                                    : _rojo,
                              ),
                            ),
                            title: Text(
                              'Inventario ${s.anio}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${s.deporteNombre ?? "Sin selección"} · '
                              '${s.items.length} ítems · '
                              '${s.totalDiferencias} dif. · '
                              '${s.cerrado ? "Cerrado" : "Borrador"}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UtileroInventarioAnualDetalleScreen(
                                    sesionId: s.id,
                                    usuarioId: usuarioId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _nuevo(context),
                icon: const Icon(Icons.add),
                label: Text('Iniciar inventario ${DateTime.now().year}'),
                style: FilledButton.styleFrom(
                  backgroundColor: _rojo,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Detalle editable del inventario anual (borrador → cierre formal).
class UtileroInventarioAnualDetalleScreen extends StatefulWidget {
  const UtileroInventarioAnualDetalleScreen({
    super.key,
    required this.sesionId,
    required this.usuarioId,
  });

  final String sesionId;
  final String usuarioId;

  @override
  State<UtileroInventarioAnualDetalleScreen> createState() =>
      _UtileroInventarioAnualDetalleScreenState();
}

class _UtileroInventarioAnualDetalleScreenState
    extends State<UtileroInventarioAnualDetalleScreen> {
  final _obs = TextEditingController();
  final _responsable = TextEditingController();
  final _firma = TextEditingController();
  final _itemObs = <String, TextEditingController>{};
  final _conteos = <String, TextEditingController>{};
  List<InventarioFisicoItem> _items = [];
  InventarioFisicoSesion? _sesion;
  bool _guardando = false;
  bool _cerrando = false;

  @override
  void dispose() {
    _obs.dispose();
    _responsable.dispose();
    _firma.dispose();
    for (final c in _itemObs.values) {
      c.dispose();
    }
    for (final c in _conteos.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _sync(InventarioFisicoSesion s) {
    if (_sesion?.id == s.id &&
        _sesion?.estado == s.estado &&
        _items.isNotEmpty) {
      return;
    }
    _sesion = s;
    _items = List.from(s.items);
    _obs.text = s.observacionesGenerales ?? '';
    _responsable.text = s.responsableVerificacion ?? '';
    _firma.text = s.firmaCoordinador ?? '';
    for (final i in _items) {
      _itemObs.putIfAbsent(
        i.materialId,
        () => TextEditingController(text: i.observacion ?? ''),
      );
      _conteos.putIfAbsent(
        i.materialId,
        () => TextEditingController(text: '${i.contado}'),
      );
    }
  }

  List<InventarioFisicoItem> _itemsActuales() {
    return _items
        .map(
          (i) => i.copyWith(
            contado: int.tryParse(
                  _conteos[i.materialId]?.text.trim() ?? '',
                ) ??
                i.contado,
            observacion: _itemObs[i.materialId]?.text ?? '',
          ),
        )
        .toList();
  }

  Future<void> _guardarBorrador() async {
    setState(() => _guardando = true);
    try {
      final items = _itemsActuales();
      await UtileroService.actualizarItemsInventarioFisico(
        sesionId: widget.sesionId,
        items: items,
        observacionesGenerales: _obs.text,
        responsableVerificacion: _responsable.text,
        firmaCoordinador: _firma.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrador guardado')),
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

  Future<void> _cerrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar inventario anual'),
        content: const Text(
          'Al cerrar queda registrado de forma formal. '
          'Se enviará un correo al utilero y al DT/coordinación '
          '(si hay contactos registrados). ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar inventario'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cerrando = true);
    try {
      await _guardarBorrador();
      await UtileroService.cerrarInventarioAnual(
        sesionId: widget.sesionId,
        utileroId: widget.usuarioId,
        responsableVerificacion: _responsable.text,
        firmaCoordinador: _firma.text,
        observacionesGenerales: _obs.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inventario cerrado. Correo encolado para envío.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cerrando = false);
    }
  }

  Future<void> _exportar() async {
    final s = _sesion;
    if (s == null) return;
    try {
      final perfil = await UtileroService.streamPerfil(widget.usuarioId).first;
      final arch = await UtileroService.exportarInventarioFisicoPdf(
        sesion: s.copyWithItems(_itemsActuales()),
        perfil: perfil,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportado: ${arch.nombreArchivo}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventarioFisicoSesion>>(
      stream: UtileroService.streamInventariosFisicos(widget.usuarioId),
      builder: (context, snap) {
        InventarioFisicoSesion? sesion;
        for (final x in snap.data ?? const <InventarioFisicoSesion>[]) {
          if (x.id == widget.sesionId) {
            sesion = x;
            break;
          }
        }
        final s = sesion;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inventario anual'),
              backgroundColor: _rojo,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        _sync(s);
        final cerrado = s.cerrado;
        final difs = _itemsActuales().where((i) => !i.coincide).length;

        return Scaffold(
          appBar: AppBar(
            title: Text('Inventario anual ${s.anio}'),
            backgroundColor: _rojo,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _exportar,
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Exportar documento',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: cerrado
                    ? DtflyTheme.success.withValues(alpha: 0.08)
                    : _rojo.withValues(alpha: 0.06),
                child: ListTile(
                  leading: Icon(
                    cerrado ? Icons.lock_outline : Icons.edit,
                    color: cerrado ? DtflyTheme.success : _rojo,
                  ),
                  title: Text(
                    cerrado ? 'Inventario cerrado' : 'Borrador en edición',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${s.deporteNombre ?? "—"} · ${_items.length} materiales · '
                    '$difs diferencia(s)',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Conteo por material', style: DtflyTheme.panelTitle),
              const SizedBox(height: 8),
              ..._items.map((item) {
                final ctrl = _itemObs[item.materialId];
                final conteoCtrl = _conteos[item.materialId];
                final actual = _itemsActuales().firstWhere(
                  (x) => x.materialId == item.materialId,
                  orElse: () => item,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text('Sistema: ${item.sistema}'),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 88,
                              child: TextField(
                                enabled: !cerrado,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Contado',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                controller: conteoCtrl,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Dif: ${actual.diferencia}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.coincide
                                    ? DtflyTheme.success
                                    : DtflyTheme.fieldRed,
                              ),
                            ),
                          ],
                        ),
                        if (ctrl != null) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: ctrl,
                            enabled: !cerrado,
                            decoration: const InputDecoration(
                              labelText: 'Observación',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text('Acta de cierre', style: DtflyTheme.panelTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _obs,
                enabled: !cerrado,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones generales',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _responsable,
                enabled: !cerrado,
                decoration: const InputDecoration(
                  labelText: 'Verificado por (utilero / ayudante)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _firma,
                enabled: !cerrado,
                decoration: const InputDecoration(
                  labelText: 'Firma coordinador / DT (nombre completo)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (!cerrado) ...[
                OutlinedButton(
                  onPressed: _guardando ? null : _guardarBorrador,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar borrador'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _cerrando ? null : _cerrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _rojo,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _cerrando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cerrar inventario anual'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _exportar,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar acta (HTML/PDF)'),
                ),
            ],
          ),
        );
      },
    );
  }
}

extension on InventarioFisicoSesion {
  InventarioFisicoSesion copyWithItems(List<InventarioFisicoItem> items) {
    return InventarioFisicoSesion(
      id: id,
      utileroId: utileroId,
      anio: anio,
      tipo: tipo,
      estado: estado,
      items: items,
      deporteId: deporteId,
      deporteNombre: deporteNombre,
      observacionesGenerales: observacionesGenerales,
      responsableVerificacion: responsableVerificacion,
      firmaCoordinador: firmaCoordinador,
      creadoEn: creadoEn,
      cerradoEn: cerradoEn,
    );
  }
}
