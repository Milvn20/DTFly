/// Resultado unificado del buscador global del admin.
enum AdminBusquedaTipo {
  usuario,
  material,
  prestamo,
  entrenamiento,
  partido,
  reporte,
  solicitud,
}

class AdminBusquedaResultado {
  const AdminBusquedaResultado({
    required this.tipo,
    required this.id,
    required this.titulo,
    required this.subtitulo,
    this.extra,
  });

  final AdminBusquedaTipo tipo;
  final String id;
  final String titulo;
  final String subtitulo;
  final String? extra;
}
