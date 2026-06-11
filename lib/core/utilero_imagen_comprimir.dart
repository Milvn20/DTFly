import 'dart:typed_data';
import 'dart:ui' as ui;

/// Comprime una foto del dispositivo para usarla como ícono en inventario (~128px).
Future<Uint8List> comprimirImagenInventario(Uint8List bytes) async {
  if (bytes.isEmpty) return bytes;
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 128,
      targetHeight: 128,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    if (data == null) return bytes;
    return data.buffer.asUint8List();
  } catch (_) {
    return bytes;
  }
}
