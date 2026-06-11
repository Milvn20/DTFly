import 'package:flutter_application_1/core/deportes_categoria.dart';

/// Campo canónico `deporte` en Firestore (colección `usuarios` y `entrenamientos`).
class DeporteUsuario {
  DeporteUsuario._();

  static const String fieldDeporte = 'deporte';
  static const String fieldDeporteNombre = 'deporteNombre';

  /// ID del deporte desde un documento de usuario o entrenamiento.
  static String? idDesde(Map<String, dynamic> data) {
    final deporte = data[fieldDeporte] as String?;
    if (deporte != null && deporte.trim().isNotEmpty) return deporte.trim();
    final legacy = data['categoriaDeportiva'] as String?;
    if (legacy != null && legacy.trim().isNotEmpty) return legacy.trim();
    return null;
  }

  /// Nombre visible del deporte.
  static String nombreDesde(Map<String, dynamic> data) {
    final nombre = data[fieldDeporteNombre] as String?;
    if (nombre != null && nombre.trim().isNotEmpty) return nombre.trim();
    final legacy = data['categoriaDeportivaNombre'] as String?;
    if (legacy != null && legacy.trim().isNotEmpty) return legacy.trim();
    return DeportesCategoria.nombreVisible(idDesde(data));
  }

  /// Campos a persistir al asignar o cambiar deporte (jugador o DT).
  static Map<String, dynamic> camposAlGuardar(String deporteId) {
    final nombre = DeportesCategoria.nombreVisible(deporteId);
    return {
      fieldDeporte: deporteId,
      fieldDeporteNombre: nombre,
      'categoriaDeportiva': deporteId,
      'categoriaDeportivaNombre': nombre,
    };
  }

  static bool mismoDeporte(Map<String, dynamic> a, Map<String, dynamic> b) {
    final da = idDesde(a);
    final db = idDesde(b);
    if (da == null || db == null) return false;
    return da == db;
  }

  static const String mensajeEntrenamientoOtroDeporte =
      'No tienes permisos para unirte a este entrenamiento porque pertenece a otro deporte.';
}
