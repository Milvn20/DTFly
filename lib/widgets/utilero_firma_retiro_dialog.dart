import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Diálogo de firma digital al retirar material (profesor / DT).
class UtileroFirmaRetiroDialog {
  UtileroFirmaRetiroDialog._();

  /// Devuelve PNG en base64, o null si cancela.
  static Future<String?> mostrar(
    BuildContext context, {
    required String nombreRetirador,
    required String materialResumen,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FirmaRetiroDialogBody(
        nombreRetirador: nombreRetirador,
        materialResumen: materialResumen,
      ),
    );
  }
}

class _FirmaRetiroDialogBody extends StatefulWidget {
  const _FirmaRetiroDialogBody({
    required this.nombreRetirador,
    required this.materialResumen,
  });

  final String nombreRetirador;
  final String materialResumen;

  @override
  State<_FirmaRetiroDialogBody> createState() => _FirmaRetiroDialogBodyState();
}

class _FirmaRetiroDialogBodyState extends State<_FirmaRetiroDialogBody> {
  final _boundaryKey = GlobalKey();
  final _puntos = <Offset>[];
  bool _capturando = false;

  bool get _tieneTrazo => _puntos.length > 4;

  void _limpiar() => setState(() => _puntos.clear());

  void _agregarPunto(Offset local) {
    setState(() => _puntos.add(local));
  }

  Future<String?> _exportarBase64() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return base64Encode(bytes.buffer.asUint8List());
  }

  Future<void> _confirmar() async {
    if (!_tieneTrazo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dibuja la firma antes de confirmar')),
      );
      return;
    }
    setState(() => _capturando = true);
    try {
      final b64 = await _exportarBase64();
      if (!mounted) return;
      if (b64 == null || b64.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la firma')),
        );
        return;
      }
      Navigator.pop(context, b64);
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Firma de retiro'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.nombreRetirador,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.materialResumen,
              style: const TextStyle(
                fontSize: 13,
                color: DtflyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: DtflyTheme.borderSubtle, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: GestureDetector(
                    onPanStart: (d) => _agregarPunto(d.localPosition),
                    onPanUpdate: (d) => _agregarPunto(d.localPosition),
                    child: CustomPaint(
                      painter: _FirmaPainter(_puntos),
                      size: Size.infinite,
                      child: _puntos.isEmpty
                          ? const Center(
                              child: Text(
                                'Firma aquí con el dedo o mouse',
                                style: TextStyle(
                                  color: DtflyTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _limpiar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Limpiar'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _capturando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _capturando ? null : _confirmar,
          child: _capturando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirmar préstamo'),
        ),
      ],
    );
  }
}

class _FirmaPainter extends CustomPainter {
  _FirmaPainter(this.puntos);

  final List<Offset> puntos;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.length < 2) return;
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < puntos.length - 1; i++) {
      final a = puntos[i];
      final b = puntos[i + 1];
      if ((a - b).distance > 40) continue;
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirmaPainter oldDelegate) =>
      oldDelegate.puntos.length != puntos.length;
}
