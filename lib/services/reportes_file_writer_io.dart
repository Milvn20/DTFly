import 'dart:io';

Future<String?> guardarArchivoReporte(String nombreArchivo, String contenido) async {
  final directorio = await _directorioReportes();
  final archivo = File('${directorio.path}${Platform.pathSeparator}$nombreArchivo');
  await archivo.writeAsString(contenido, flush: true);
  return archivo.path;
}

Future<Directory> _directorioReportes() async {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  final candidatos = <Directory>[
    if (Platform.isAndroid)
      Directory('/storage/emulated/0/Download')
    else if (home != null)
      Directory('$home${Platform.pathSeparator}Downloads'),
    if (home != null) Directory('$home${Platform.pathSeparator}Documents'),
    Directory.systemTemp,
  ];

  for (final base in candidatos) {
    try {
      if (!await base.exists()) continue;
      final dir = Directory('${base.path}${Platform.pathSeparator}DTFlyReportes');
      await dir.create(recursive: true);
      return dir;
    } catch (_) {
      // Si una carpeta no es escribible, se intenta la siguiente.
    }
  }

  final fallback = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}DTFlyReportes');
  await fallback.create(recursive: true);
  return fallback;
}
