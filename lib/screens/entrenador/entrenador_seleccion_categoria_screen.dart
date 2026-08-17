import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/screens/role_main_shell.dart';
import 'package:flutter_application_1/services/usuario_perfil_service.dart';

/// Pantalla tras el login del entrenador: elige la disciplina a gestionar.
class EntrenadorSeleccionCategoriaScreen extends StatelessWidget {
  const EntrenadorSeleccionCategoriaScreen({
    super.key,
    required this.nombre,
    required this.usuarioEmail,
    required this.usuarioId,
  });

  final String nombre;
  final String usuarioEmail;
  final String usuarioId;

  Future<void> _elegirCategoria(
    BuildContext context,
    DeporteCategoria deporte,
  ) async {
    try {
      await UsuarioPerfilService.guardarCategoriaEntrenador(
        usuarioId: usuarioId,
        categoriaId: deporte.id,
        categoriaNombre: deporte.nombre,
      );
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleMainShell(
            nombre: nombre,
            rol: 'Entrenador',
            usuarioEmail: usuarioEmail,
            usuarioId: usuarioId,
            categoriaDeportiva: deporte.id,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la categoría')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeportesCategoria.fondoSeleccion,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/dtfly_logo_menu.png',
                      height: 88,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/dtfly_logo.png',
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.sports,
                          size: 56,
                          color: DeportesCategoria.botonMaroon,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: DeportesCategoria.botonMaroon,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Seleccione Entrenamiento:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = constraints.maxWidth;
                      final columnas = ancho >= 560 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnas,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1,
                        ),
                        itemCount: DeportesCategoria.todas.length,
                        itemBuilder: (context, index) {
                          final deporte = DeportesCategoria.todas[index];
                          return _CategoriaTile(
                            deporte: deporte,
                            onTap: () => _elegirCategoria(context, deporte),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriaTile extends StatelessWidget {
  const _CategoriaTile({
    required this.deporte,
    required this.onTap,
  });

  final DeporteCategoria deporte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DeportesCategoria.botonMaroon,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(deporte.icono, color: Colors.white, size: 48),
              const SizedBox(height: 10),
              Text(
                deporte.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
