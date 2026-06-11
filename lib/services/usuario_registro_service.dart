import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';

/// Alta de usuarios en Firestore (colección `usuarios`).
class UsuarioRegistroService {
  UsuarioRegistroService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String normalizarEmail(String email) => email.trim().toLowerCase();

  static Future<bool> emailYaExiste(String email) async {
    final normalizado = normalizarEmail(email);
    final snap = await _db
        .collection('usuarios')
        .where('email', isEqualTo: normalizado)
        .limit(1)
        .get(const GetOptions(source: Source.server));
    return snap.docs.isNotEmpty;
  }

  static Future<String> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? deporteId,
  }) async {
    final emailNorm = normalizarEmail(email);
    final data = <String, dynamic>{
      'nombre': nombre.trim(),
      'email': emailNorm,
      'password': password,
      'rol': rol,
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
    if (deporteId != null && deporteId.isNotEmpty) {
      data.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    final ref = await _db.collection('usuarios').add(data);
    return ref.id;
  }

  static String mensajeError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Sin permiso en Firestore (${error.message ?? error.code})';
        case 'unavailable':
          return 'Servicio no disponible. Revisa tu conexión.';
        case 'failed-precondition':
          return 'Configuración de base de datos incompleta. '
              'Contacta al administrador.';
        case 'already-exists':
          return 'Ese correo ya está registrado.';
        default:
          return 'Error Firebase: ${error.code} — ${error.message ?? ''}';
      }
    }
    return 'Error: $error';
  }
}
