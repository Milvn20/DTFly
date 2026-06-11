/// Valores de `rol` en Firestore (colección `usuarios`).
class AppRoles {
  AppRoles._();

  static const String entrenador = 'Entrenador';
  static const String jugador = 'Jugador';
  static const String utilero = 'Utilero';
  static const String administrador = 'Administrador';

  /// Compatibilidad con registros antiguos y mayúsculas/minúsculas en Firestore.
  static String normalize(String? raw) {
    if (raw == null || raw.isEmpty) return jugador;
    final key = raw.trim().toLowerCase();
    if (key == 'estudiante') return jugador;
    if (key == 'entrenador' || key == 'dt' || key == 'coach') {
      return entrenador;
    }
    if (key == 'jugador') return jugador;
    if (key == 'utilero') return utilero;
    if (key == 'administrador' || key == 'admin') return administrador;
    return raw.trim();
  }

  static bool isKnown(String rol) {
    return rol == entrenador ||
        rol == jugador ||
        rol == utilero ||
        rol == administrador;
  }
}
