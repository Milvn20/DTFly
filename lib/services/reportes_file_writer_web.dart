import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String?> guardarArchivoReporte(
  String nombreArchivo,
  String contenido,
) async {
  final bytes = utf8.encode(contenido);

  final mime = nombreArchivo.toLowerCase().endsWith('.xls')
      ? 'application/vnd.ms-excel;charset=utf-8'
      : 'text/csv;charset=utf-8';

  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = nombreArchivo
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);

  return 'Descargas/$nombreArchivo';
  }