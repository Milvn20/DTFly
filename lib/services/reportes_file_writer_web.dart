import 'dart:convert';
import 'dart:html' as html;

Future<String?> guardarArchivoReporte(String nombreArchivo, String contenido) async {
  final bytes = utf8.encode(contenido);
  final mime = nombreArchivo.toLowerCase().endsWith('.xls')
      ? 'application/vnd.ms-excel;charset=utf-8'
      : 'text/csv;charset=utf-8';
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = nombreArchivo
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return 'Descargas/$nombreArchivo';
}
