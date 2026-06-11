import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Diálogo para registrar material nuevo. En «Más» se agrega foto personalizada.
class UtileroAgregarMaterialDialog {
  UtileroAgregarMaterialDialog._();

  static bool _esMas(UtileroMaterialCat cat) => cat.id == 'mas';

  static Future<bool> mostrar(
    BuildContext context, {
    required String usuarioId,
  }) async {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    var categoria = UtileroMaterialCat.todas.first;
    Uint8List? imagenBytes;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final esMas = _esMas(categoria);
          return AlertDialog(
            title: const Text('Agregar material al inventario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<UtileroMaterialCat>(
                    initialValue: categoria,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de material',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in UtileroMaterialCat.todas)
                        DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              UtileroMaterialIcon(categoria: c, size: 22),
                              const SizedBox(width: 10),
                              Text(c.nombre),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setSt(() {
                        categoria = v;
                        if (!_esMas(v)) imagenBytes = null;
                      });
                    },
                  ),
                  if (esMas) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'En «Más» puedes subir la foto que quieres ver al lado '
                      'del material en el inventario.',
                      style: TextStyle(
                        fontSize: 12,
                        color: DtflyTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            imageQuality: 85,
                          );
                          if (img == null) return;
                          final bytes = await img.readAsBytes();
                          setSt(() => imagenBytes = bytes);
                        },
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: DtflyTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFC62828),
                              width: imagenBytes == null ? 1.5 : 1,
                            ),
                          ),
                          child: imagenBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.memory(
                                    imagenBytes!,
                                    fit: BoxFit.cover,
                                    width: 96,
                                    height: 96,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Color(0xFFC62828),
                                      size: 32,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Agregar foto',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del material',
                        hintText: 'Ej: Cuerda, arco portable, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Nombre (opcional)',
                        hintText: 'Ej: ${categoria.nombre} talla M',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usará el ícono de ${categoria.nombre}. '
                      'Para foto propia elige «Más».',
                      style: TextStyle(
                        fontSize: 11,
                        color: DtflyTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad inicial',
                      border: OutlineInputBorder(),
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
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    final esMas = _esMas(categoria);
    var nombre = nombreCtrl.text.trim();
    if (!esMas && nombre.isEmpty) nombre = categoria.nombre;
    final cantidad = int.tryParse(cantidadCtrl.text) ?? 0;
    final bytes = imagenBytes;
    nombreCtrl.dispose();
    cantidadCtrl.dispose();

    if (ok != true || nombre.isEmpty || cantidad <= 0) return false;
    if (esMas && bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('En «Más» debes agregar una foto del material'),
          ),
        );
      }
      return false;
    }

    try {
      final materialId = await InventarioService.agregarMaterial(
        nombre: nombre,
        categoria: categoria.etiquetaFirestore,
        cantidad: cantidad,
      );
      if (bytes != null) {
        await InventarioService.subirImagenMaterial(
          materialId: materialId,
          bytes: bytes,
        );
      }
      await UtileroService.registrarActividad(
        utileroId: usuarioId,
        accion: 'Registró material',
        descripcion: '$nombre (${categoria.nombre})',
        material: nombre,
        cantidad: cantidad,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«$nombre» agregado al inventario')),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar: $e')),
        );
      }
      return false;
    }
  }
}
