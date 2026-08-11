import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/app_build_info.dart';
import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/screens/registro_screen.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_seleccion_categoria_screen.dart';
import 'package:flutter_application_1/screens/utilero/utilero_seleccion_deporte_screen.dart';
import 'package:flutter_application_1/screens/role_main_shell.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/plantel_service.dart';
import 'package:flutter_application_1/services/usuario_registro_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
  try {
    final email = UsuarioRegistroService.normalizarEmail(
      emailController.text,
    );
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo y contraseña.'),
        ),
      );
      return;
    }

    // 1. Autenticación segura mediante Firebase Authentication.
    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo obtener el usuario autenticado.',
      );
    }

    // 2. El UID de Firebase es ahora la identidad del usuario.
    final usuarioId = firebaseUser.uid;

    // 3. Obtener solamente el perfil desde Firestore.
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuarioId)
        .get();

    if (!doc.exists) {
      // Si existe en Authentication pero no tiene perfil,
      // cerramos la sesión para no dejar un estado inconsistente.
      await FirebaseAuth.instance.signOut();

      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'profile-not-found',
        message: 'No existe un perfil de usuario asociado a esta cuenta.',
      );
    }

    final data = doc.data() ?? {};

    final nombre = data['nombre'] as String? ?? '';
    final emailGuardado =
        (data['email'] as String?)?.trim() ?? email;
    final rol = AppRoles.normalize(data['rol'] as String?);

    if (!AppRoles.isKnown(rol)) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol no válido: $rol'),
        ),
      );
      return;
    }

    if (!mounted) return;

    // ============================
    // UTILERO
    // ============================

    if (rol == AppRoles.utilero) {
      await UtileroService.asegurarPerfil(
        usuarioId: usuarioId,
        nombre: nombre,
        correo: emailGuardado,
      );

      await UtileroService.registrarAuditoriaSesion(
        utileroId: usuarioId,
        esInicio: true,
      );

      await UtileroService.sincronizarAlertasInventario(usuarioId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UtileroSeleccionDeporteScreen(
            nombre: nombre,
            usuarioEmail: emailGuardado,
            usuarioId: usuarioId,
          ),
        ),
      );

      return;
    }

    // ============================
    // JUGADOR
    // ============================

    if (rol == AppRoles.jugador) {
      await PlantelService.asegurarCampoDeporte(usuarioId);
    }

    // ============================
    // ENTRENADOR
    // ============================

    if (rol == AppRoles.entrenador) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EntrenadorSeleccionCategoriaScreen(
            nombre: nombre,
            usuarioEmail: emailGuardado,
            usuarioId: usuarioId,
          ),
        ),
      );

      return;
    }

    // ============================
    // ADMINISTRADOR
    // ============================

    if (rol == AppRoles.administrador) {
      await AdminService.asegurarPerfilAdmin(
        adminId: usuarioId,
        nombre: nombre,
        correo: emailGuardado,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RoleMainShell(
            nombre: nombre,
            rol: rol,
            usuarioEmail: emailGuardado,
            usuarioId: usuarioId,
          ),
        ),
        (route) => false,
      );

      return;
    }

    // ============================
    // RESTO DE ROLES
    // ============================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoleMainShell(
          nombre: nombre,
          rol: rol,
          usuarioEmail: emailGuardado,
          usuarioId: usuarioId,
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    debugPrint('Error de autenticación: ${e.code}');

    if (!mounted) return;

    String mensaje;

    switch (e.code) {
      case 'invalid-email':
        mensaje = 'El correo electrónico no es válido.';
        break;

      case 'user-disabled':
        mensaje = 'Esta cuenta está deshabilitada.';
        break;

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        mensaje = 'Correo o contraseña incorrectos.';
        break;

      case 'too-many-requests':
        mensaje = 'Demasiados intentos. Espera unos minutos.';
        break;

      case 'network-request-failed':
        mensaje = 'No hay conexión con el servidor.';
        break;

      default:
        mensaje = 'No se pudo iniciar sesión.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  } on FirebaseException catch (e) {
    debugPrint('Error de Firebase: ${e.code}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'profile-not-found'
              ? 'La cuenta existe, pero su perfil de DTFly no está configurado.'
              : 'No se pudo cargar tu perfil.',
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error login: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo iniciar sesión. Inténtalo nuevamente.'),
      ),
    );
  }
}

  void _olvideContrasena() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperación de contraseña: próximamente'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 22),
                decoration: BoxDecoration(
                  gradient: DtflyTheme.headerGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(DtflyTheme.radiusLg),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'DTFly',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ClipOval(
                      child: Image.asset(
                        'assets/images/dtfly_logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 72,
                            height: 72,
                            color: Colors.white24,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Iniciar sesión',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Usuario',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildField(emailController),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Contraseña',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildField(passwordController, isObscure: true),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _olvideContrasena,
                      style: TextButton.styleFrom(foregroundColor: DtflyTheme.primary),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DtflyTheme.primaryButton(
                    label: 'Iniciar sesión',
                    onPressed: iniciarSesion,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistroScreen()),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: DtflyTheme.primary),
                    child: const Text('Regístrate'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Build ${AppBuildInfo.build} · ${AppBuildInfo.adminUiVersion}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: DtflyTheme.loginFieldDecoration(),
      style: const TextStyle(color: DtflyTheme.textPrimary, fontSize: 16),
    );
  }
}
