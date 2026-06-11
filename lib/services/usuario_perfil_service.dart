import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';

/// Campos de perfil del estudiante deportista en `usuarios/{id}`.
class UsuarioPerfilService {
  UsuarioPerfilService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> ref(String usuarioId) =>
      _db.collection('usuarios').doc(usuarioId);

  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamUsuario(
    String usuarioId,
  ) {
    return ref(usuarioId).snapshots();
  }

  /// ID del deporte del usuario (campo `deporte`).
  static String? deporteIdDesde(Map<String, dynamic> data) =>
      DeporteUsuario.idDesde(data);

  @Deprecated('Use deporteIdDesde')
  static String? categoriaDeportivaDesde(Map<String, dynamic> data) =>
      deporteIdDesde(data);

  static Future<void> guardarDeporteUsuario({
    required String usuarioId,
    required String deporteId,
  }) async {
    await ref(usuarioId).set(
      DeporteUsuario.camposAlGuardar(deporteId),
      SetOptions(merge: true),
    );
  }

  static Future<void> guardarCategoriaEntrenador({
    required String usuarioId,
    required String categoriaId,
    required String categoriaNombre,
  }) async {
    await guardarDeporteUsuario(usuarioId: usuarioId, deporteId: categoriaId);
  }

  static Future<void> guardarPerfilJugador({
    required String usuarioId,
    required String nombre,
    required String email,
    int? edad,
    int? anioTerminoCarrera,
    required String carrera,
    required String posicionDeportiva,
    required String tipoBeca,
    required String deporteId,
  }) async {
    await ref(usuarioId).set(
      {
        'nombre': nombre,
        'email': email,
        'edad': edad,
        'anioTerminoCarrera': anioTerminoCarrera,
        'carrera': carrera,
        'posicionDeportiva': posicionDeportiva,
        'tipoBeca': tipoBeca,
        ...DeporteUsuario.camposAlGuardar(deporteId),
        'perfilActualizadoEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
