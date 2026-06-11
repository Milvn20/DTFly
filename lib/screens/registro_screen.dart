import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/services/usuario_registro_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  String rolSeleccionado = AppRoles.jugador;
  String? deporteId;
  bool _guardando = false;

  static const String _pinEntrenador = 'Unab2026';
  static const String _pinUtilero = 'Unab2026';
  static const String _pinAdmin = 'Unabr2026';

  String? _validarFormulario() {
    final nombre = nombreController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (nombre.isEmpty) return 'Ingresa tu nombre completo';
    if (email.isEmpty || !email.contains('@')) {
      return 'Ingresa un correo válido';
    }
    if (password.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }

    if (rolSeleccionado == AppRoles.entrenador &&
        pinController.text != _pinEntrenador) {
      return 'PIN de entrenador incorrecto (solicítalo al coordinador)';
    }
    if (rolSeleccionado == AppRoles.utilero &&
        pinController.text != _pinUtilero) {
      return 'PIN de utilero incorrecto';
    }
    if (rolSeleccionado == AppRoles.administrador &&
        pinController.text != _pinAdmin) {
      return 'PIN de administrador incorrecto';
    }
    if (rolSeleccionado == AppRoles.jugador &&
        (deporteId == null || deporteId!.isEmpty)) {
      return 'Selecciona tu deporte';
    }
    return null;
  }

  Future<void> registrarUsuario() async {
    final errorValidacion = _validarFormulario();
    if (errorValidacion != null) {
      _mostrarMensaje(errorValidacion, esError: true);
      return;
    }

    final email = emailController.text.trim();

    setState(() => _guardando = true);
    try {
      final existe = await UsuarioRegistroService.emailYaExiste(email);
      if (existe) {
        _mostrarMensaje('Ese correo ya está registrado. Inicia sesión.', esError: true);
        return;
      }

      await UsuarioRegistroService.crearUsuario(
        nombre: nombreController.text,
        email: email,
        password: passwordController.text,
        rol: rolSeleccionado,
        deporteId: rolSeleccionado == AppRoles.jugador ? deporteId : null,
      );

      if (!mounted) return;
      _mostrarMensaje('Cuenta creada. Ya puedes iniciar sesión.', esError: false);
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Error al registrar: $e\n$st');
      if (!mounted) return;
      _mostrarMensaje(UsuarioRegistroService.mensajeError(e), esError: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String texto, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 5),
        backgroundColor: esError ? DtflyTheme.primary : DtflyTheme.success,
      ),
    );
  }

  bool get _requierePin =>
      rolSeleccionado == AppRoles.entrenador ||
      rolSeleccionado == AppRoles.utilero ||
      rolSeleccionado == AppRoles.administrador;

  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    pinController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.fromLTRB(4, 8, 14, 20),
                decoration: BoxDecoration(
                  color: DtflyTheme.secondary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(DtflyTheme.radiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    ClipOval(
                      child: Image.asset(
                        'assets/images/dtfly_logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.sports_soccer, color: Colors.white, size: 32),
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: nombreController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                ),
                TextField(
                  controller: emailController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  controller: passwordController,
                  enabled: !_guardando,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 20),
                const Text('Tipo de perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: AppRoles.jugador, child: Text('Jugador')),
                    DropdownMenuItem(value: AppRoles.entrenador, child: Text('Entrenador')),
                    DropdownMenuItem(value: AppRoles.utilero, child: Text('Utilero')),
                    DropdownMenuItem(
                      value: AppRoles.administrador,
                      child: Text('Administrador'),
                    ),
                  ],
                  onChanged: _guardando
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            rolSeleccionado = value;
                            pinController.clear();
                            if (value != AppRoles.jugador) {
                              deporteId = null;
                            }
                          });
                        },
                ),
                if (rolSeleccionado == AppRoles.jugador) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Deporte que practicas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: deporteId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecciona tu deporte',
                    ),
                    items: [
                      for (final d in DeportesCategoria.todas)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(d.nombre),
                        ),
                    ],
                    onChanged: _guardando
                        ? null
                        : (value) => setState(() => deporteId = value),
                  ),
                ],
                if (_requierePin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    enabled: !_guardando,
                    decoration: InputDecoration(
                      labelText: _pinLabel(rolSeleccionado),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DtflyTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: DtflyTheme.borderRadius,
                    ),
                  ),
                  onPressed: _guardando ? null : registrarUsuario,
                  child: _guardando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Finalizar registro'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pinLabel(String rol) {
    switch (rol) {
      case AppRoles.entrenador:
        return 'PIN de entrenador';
      case AppRoles.utilero:
        return 'PIN de utilero';
      case AppRoles.administrador:
        return 'PIN de administrador';
      default:
        return 'PIN';
    }
  }
}
