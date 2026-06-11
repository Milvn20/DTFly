import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/utilero_imagen_comprimir.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Pantalla para agregar material personalizado con foto desde el dispositivo.
class UtileroAgregarMaterialScreen extends StatefulWidget {
  const UtileroAgregarMaterialScreen({
    super.key,
    required this.usuarioId,
    this.deporteId,
  });

  final String usuarioId;
  final String? deporteId;

  @override
  State<UtileroAgregarMaterialScreen> createState() =>
      _UtileroAgregarMaterialScreenState();
}

class _UtileroAgregarMaterialScreenState
    extends State<UtileroAgregarMaterialScreen> {
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  Uint8List? _fotoBytes;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 60,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      final mini = await comprimirImagenInventario(bytes);
      if (!mounted) return;
      setState(() => _fotoBytes = mini);
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo abrir la galería: $e', error: true);
    }
  }

  void _mensaje(String t, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t),
        backgroundColor: error ? const Color(0xFFC62828) : DtflyTheme.success,
      ),
    );
  }

  Future<void> _agregar() async {
    final nombre = _nombreCtrl.text.trim();
    final cantidad = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;

    if (_fotoBytes == null || _fotoBytes!.isEmpty) {
      _mensaje('Selecciona una foto del material', error: true);
      return;
    }
    if (nombre.isEmpty) {
      _mensaje('Escribe el nombre del material', error: true);
      return;
    }
    if (cantidad <= 0) {
      _mensaje('Ingresa una cantidad válida', error: true);
      return;
    }

    final deporteId = widget.deporteId?.trim();
    if (deporteId == null || deporteId.isEmpty) {
      _mensaje('Selecciona una disciplina antes de agregar material', error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      await InventarioService.agregarMaterialPersonalizado(
        nombre: nombre,
        cantidad: cantidad,
        imagenBytes: _fotoBytes!,
        deporteId: deporteId,
      );
      if (!mounted) return;
      _mensaje('«$nombre» agregado al inventario');
      Navigator.pop(context, true);
      UtileroService.registrarActividad(
        utileroId: widget.usuarioId,
        accion: 'Registró material',
        descripcion: '$nombre (personalizado)',
        material: nombre,
        cantidad: cantidad,
      );
    } catch (e) {
      if (mounted) {
        _mensaje('$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(
        title: const Text('Agregar material'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Material nuevo',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.deporteId != null && widget.deporteId!.isNotEmpty
                  ? 'Se guardará solo en ${DeportesCategoria.nombreVisible(widget.deporteId)}. '
                      'Sube la foto de tu dispositivo; será el ícono del material.'
                  : 'Sube la foto de tu dispositivo. Esa imagen será el ícono '
                      'del material en el inventario, junto a balones, conos, etc.',
              style: const TextStyle(color: DtflyTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _guardando ? null : _elegirFoto,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC62828),
                      width: _fotoBytes == null ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _fotoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(
                            _fotoBytes!,
                            fit: BoxFit.cover,
                            width: 140,
                            height: 140,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 44,
                              color: Color(0xFFC62828),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Elegir foto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC62828),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Obligatorio · desde galería del dispositivo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DtflyTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nombreCtrl,
              enabled: !_guardando,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del material',
                hintText: 'Ej: Estacas, cuerdas, arcos…',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadCtrl,
              enabled: !_guardando,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad inicial',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _agregar,
                icon: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined),
                label: Text(
                  _guardando ? 'Guardando…' : 'Agregar al inventario',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  disabledBackgroundColor:
                      const Color(0xFFC62828).withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
