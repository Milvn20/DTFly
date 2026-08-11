import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';

/// Registro de usuarios mediante Firebase Authentication + Firestore.
///
/// Firebase Authentication se encarga de las credenciales.
/// Firestore solamente almacena el perfil del usuario.
class UsuarioRegistroService {
  UsuarioRegistroService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String normalizarEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Comprueba si ya existe un perfil con ese correo en Firestore.
  ///
  /// La comprobación definitiva de existencia de la cuenta la realiza
  /// Firebase Authentication.
  static Future<bool> emailYaExiste(String email) async {
    final normalizado = normalizarEmail(email);

    final snap = await _db
        .collection('usuarios')
        .where('email', isEqualTo: normalizado)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    return snap.docs.isNotEmpty;
  }

  /// Crea la cuenta en Firebase Authentication y después
  /// crea el perfil correspondiente en Firestore.
  ///
  /// IMPORTANTE:
  /// La contraseña nunca se guarda en Firestore.
  static Future<String> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? deporteId,
  }) async {
    final emailNorm = normalizarEmail(email);

    UserCredential credential;

    try {
      // 1. Crear credenciales seguras en Firebase Authentication.
      credential = await _auth.createUserWithEmailAndPassword(
        email: emailNorm,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'No se pudo crear la cuenta.',
        );
      }

      final uid = user.uid;

      // 2. Crear únicamente el perfil en Firestore.
      final data = <String, dynamic>{
        'uid': uid,
        'nombre': nombre.trim(),
        'email': emailNorm,
        'rol': rol,
        'fecha_creacion': FieldValue.serverTimestamp(),
      };

      if (deporteId != null && deporteId.isNotEmpty) {
        data.addAll(DeporteUsuario.camposAlGuardar(deporteId));
      }

      await _db.collection('usuarios').doc(uid).set(data);

      return uid;
    } catch (error) {
      // Si Authentication creó la cuenta pero Firestore falló,
      // intentamos eliminar la cuenta para evitar una cuenta huérfana.
      if (error is! FirebaseAuthException ||
          error.code != 'email-already-in-use') {
        try {
          await _auth.currentUser?.delete();
        } catch (_) {
          // No ocultamos el error original.
        }
      }

      rethrow;
    }
  }

  static String mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Ese correo ya está registrado.';

        case 'invalid-email':
          return 'El correo electrónico no es válido.';

        case 'weak-password':
          return 'La contraseña es demasiado débil.';

        case 'operation-not-allowed':
          return 'El inicio de sesión por correo no está habilitado en Firebase.';

        case 'network-request-failed':
          return 'No hay conexión con el servidor. Revisa tu conexión a Internet.';

        case 'too-many-requests':
          return 'Demasiados intentos. Espera unos minutos e inténtalo nuevamente.';

        default:
          return 'No se pudo crear la cuenta (${error.code}).';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permiso para crear este usuario.';

        case 'unavailable':
          return 'Servicio no disponible. Revisa tu conexión.';

        case 'failed-precondition':
          return 'La configuración de la base de datos está incompleta.';

        default:
          return 'Error de Firebase: ${error.code}.';
      }
    }

    return 'No se pudo crear la cuenta. Inténtalo nuevamente.';
  }
 }