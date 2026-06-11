import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/screens/registro_screen.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_seleccion_categoria_screen.dart';
import 'package:flutter_application_1/screens/utilero/utilero_seleccion_deporte_screen.dart';
import 'package:flutter_application_1/screens/role_main_shell.dart';
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
      final resultado = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: passwordController.text)
          .get(const GetOptions(source: Source.server));

      if (resultado.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')),
        );
        return;
      }

      final doc = resultado.docs.first;
      final data = doc.data();
      final nombre = data['nombre'] as String? ?? '';
      final emailGuardado =
          (data['email'] as String?)?.trim() ?? email;
      final rol = AppRoles.normalize(data['rol'] as String?);

      if (!AppRoles.isKnown(rol)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol no válido: $rol')),
        );
        return;
      }

      if (!mounted) return;

      if (rol == AppRoles.utilero) {
        await UtileroService.asegurarPerfil(
          usuarioId: doc.id,
          nombre: nombre,
          correo: emailGuardado,
        );
        await UtileroService.registrarAuditoriaSesion(
          utileroId: doc.id,
          esInicio: true,
        );
        await UtileroService.sincronizarAlertasInventario(doc.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UtileroSeleccionDeporteScreen(
              nombre: nombre,
              usuarioEmail: emailGuardado,
              usuarioId: doc.id,
            ),
          ),
        );
        return;
      }

      if (rol == AppRoles.jugador) {
        await PlantelService.asegurarCampoDeporte(doc.id);
      }

      if (rol == AppRoles.entrenador) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EntrenadorSeleccionCategoriaScreen(
              nombre: nombre,
              usuarioEmail: emailGuardado,
              usuarioId: doc.id,
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleMainShell(
            nombre: nombre,
            rol: rol,
            usuarioEmail: emailGuardado,
            usuarioId: doc.id,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error login: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UsuarioRegistroService.mensajeError(e)),
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
