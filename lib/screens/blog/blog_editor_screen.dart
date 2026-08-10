import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/muro_tipo.dart';
import 'package:flutter_application_1/models/blog_publicacion.dart';
import 'package:flutter_application_1/services/blog_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_dark_scaffold.dart';

class BlogEditorScreen extends StatefulWidget {
  const BlogEditorScreen({
    super.key,
    this.publicacion,
    required this.autorEmail,
    required this.autorNombre,
    this.deporteId,
    this.permitirElegirSeleccion = false,
  });

  final BlogPublicacion? publicacion;
  final String autorEmail;
  final String autorNombre;
  final String? deporteId;
  final bool permitirElegirSeleccion;

  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> {
  final _titulo = TextEditingController();
  final _contenido = TextEditingController();
  bool _avisoImportante = false;
  bool _fijado = false;
  bool _compartidoTodas = false;
  MuroTipo _tipo = MuroTipo.avisoComunicado;
  String? _deporteSeleccionado;
  bool _guardando = false;
  Uint8List? _imagenBytes;
  String? _nombreImagen;
  String _imagenUrlActual = '';

  bool get _editando => widget.publicacion != null;

  @override
  void initState() {
    super.initState();
    final p = widget.publicacion;
    if (p != null) {
      _titulo.text = p.titulo;
      _contenido.text = p.contenido;
      _avisoImportante = p.esAvisoImportante;
      _fijado = p.fijado;
      _compartidoTodas = p.compartidoTodasSelecciones;
      _tipo = p.tipo;
      _deporteSeleccionado = p.compartidoTodasSelecciones
          ? DeportesCategoria.idGeneral
          : p.deporteId;
      _imagenUrlActual = p.imagenUrl;
    } else {
      _deporteSeleccionado = widget.deporteId;
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _contenido.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imagenBytes = bytes;
      _nombreImagen = file.name;
    });
  }

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    final contenido = _contenido.text.trim();
    if (titulo.isEmpty || contenido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título y contenido.')),
      );
      return;
    }

    if (!_compartidoTodas &&
        (_deporteSeleccionado == null || _deporteSeleccionado!.isEmpty) &&
        widget.permitirElegirSeleccion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una selección deportiva.')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final deporteId = _compartidoTodas ? null : _deporteSeleccionado;
      if (_editando) {
        await BlogService.actualizar(
          id: widget.publicacion!.id,
          titulo: titulo,
          contenido: contenido,
          tipo: _tipo,
          esAvisoImportante: _avisoImportante,
          fijado: _fijado,
          compartidoTodasSelecciones: _compartidoTodas,
          deporteId: deporteId,
          imagenBytes: _imagenBytes,
          nombreImagen: _nombreImagen,
        );
      } else {
        await BlogService.crear(
          titulo: titulo,
          contenido: contenido,
          autorEmail: widget.autorEmail,
          autorNombre: widget.autorNombre,
          tipo: _tipo,
          esAvisoImportante: _avisoImportante,
          fijado: _fijado,
          compartidoTodasSelecciones: _compartidoTodas,
          deporteId: deporteId,
          imagenBytes: _imagenBytes,
          nombreImagen: _nombreImagen,
        );
      }
      if (mounted) Navigator.pop(context);
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
    final mostrarSelectorDeporte =
        widget.permitirElegirSeleccion || widget.deporteId == null;

    return DtflyDarkScaffold(
      title: _editando ? 'Editar publicación' : 'Publicar en el muro',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (mostrarSelectorDeporte) ...[
            const Text(
              'Selección deportiva',
              style: TextStyle(
                color: DtflyTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _compartidoTodas,
              onChanged: (v) => setState(() {
                _compartidoTodas = v;
                if (v) {
                  _deporteSeleccionado = DeportesCategoria.idGeneral;
                }
              }),
              title: const Text(
                'Visible en todas las selecciones',
                style: TextStyle(color: DtflyTheme.textPrimary),
              ),
              activeThumbColor: DtflyTheme.coachRed,
            ),
            if (!_compartidoTodas)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in DeportesCategoria.todas)
                    ChoiceChip(
                      label: Text(d.nombre),
                      selected: _deporteSeleccionado == d.id,
                      onSelected: (_) =>
                          setState(() => _deporteSeleccionado = d.id),
                    ),
                ],
              )
            else
              Text(
                'Esta publicación aparecerá en el muro de todos los deportes.',
                style: TextStyle(color: DtflyTheme.textMuted.withValues(alpha: 0.9)),
              ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DtflyTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports, color: DtflyTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Muro de ${DeportesCategoria.nombreVisible(widget.deporteId)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Tipo de publicación',
            style: TextStyle(
              color: DtflyTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in MuroTipo.values)
                ChoiceChip(
                  label: Text(t.etiquetaCorta),
                  selected: _tipo == t,
                  avatar: Icon(
                    t.icono,
                    size: 16,
                    color: _tipo == t ? Colors.white : t.color,
                  ),
                  selectedColor: t.color,
                  labelStyle: TextStyle(
                    color: _tipo == t ? Colors.white : DtflyTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _tipo = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titulo,
            style: const TextStyle(color: DtflyTheme.textPrimary),
            decoration: _dec('Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contenido,
            minLines: 5,
            maxLines: 12,
            style: const TextStyle(color: DtflyTheme.textPrimary),
            decoration: _dec('Contenido'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _avisoImportante,
            onChanged: (v) => setState(() => _avisoImportante = v),
            title: const Text(
              'Marcar como aviso importante',
              style: TextStyle(color: DtflyTheme.textPrimary),
            ),
            activeThumbColor: DtflyTheme.coachRed,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _fijado,
            onChanged: (v) => setState(() => _fijado = v),
            title: const Text(
              'Fijar arriba del muro',
              style: TextStyle(color: DtflyTheme.textPrimary),
            ),
            activeThumbColor: DtflyTheme.coachRed,
          ),
          const SizedBox(height: 8),
          if (_imagenUrlActual.isNotEmpty && _imagenBytes == null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(_imagenUrlActual, height: 140, fit: BoxFit.cover),
            ),
          if (_imagenBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imagenBytes!, height: 140, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _elegirImagen,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Subir imagen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DtflyTheme.textPrimary,
              side: const BorderSide(color: DtflyTheme.borderSubtle),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: DtflyTheme.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _guardando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editando ? 'Guardar cambios' : 'Publicar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: DtflyTheme.textMuted),
      filled: true,
      fillColor: DtflyTheme.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DtflyTheme.borderSubtle),
      ),
    );
  }
}
