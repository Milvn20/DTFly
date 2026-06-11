import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/screens/role_main_shell.dart';
import 'package:flutter_application_1/services/utilero_service.dart';

/// Tras el login del utilero: elige la selección que apoya (fútbol, básquet, etc.).
class UtileroSeleccionDeporteScreen extends StatelessWidget {
  const UtileroSeleccionDeporteScreen({
    super.key,
    required this.nombre,
    required this.usuarioEmail,
    required this.usuarioId,
    this.modoCambio = false,
    this.deporteActual,
  });

  final String nombre;
  final String usuarioEmail;
  final String usuarioId;
  /// Si es true, vuelve con el id elegido (cambiar selección sin cerrar sesión).
  final bool modoCambio;
  final String? deporteActual;

  Future<void> _elegirDeporte(
    BuildContext context,
    DeporteCategoria deporte,
  ) async {
    try {
      await UtileroService.guardarDeporteSeleccion(
        usuarioId: usuarioId,
        deporteId: deporte.id,
      );
      if (!context.mounted) return;
      if (modoCambio) {
        Navigator.pop(context, deporte.id);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleMainShell(
            nombre: nombre,
            rol: AppRoles.utilero,
            usuarioEmail: usuarioEmail,
            usuarioId: usuarioId,
            categoriaDeportiva: deporte.id,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la selección: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeportesCategoria.fondoSeleccion,
      appBar: modoCambio
          ? AppBar(
              title: const Text('Cambiar selección'),
              backgroundColor: DeportesCategoria.botonMaroon,
              foregroundColor: Colors.white,
            )
          : null,
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
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/dtfly_logo.png',
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports,
                          size: 56,
                          color: DeportesCategoria.botonMaroon,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '¡Hola, ${nombre.trim().split(RegExp(r'\s+')).first}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DeportesCategoria.botonMaroon,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: DeportesCategoria.botonMaroon,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      modoCambio
                          ? 'Elige otra selección para ver su inventario:'
                          : 'Seleccione su selección:',
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
                          return _DeporteTile(
                            deporte: deporte,
                            seleccionado: deporteActual == deporte.id,
                            onTap: () => _elegirDeporte(context, deporte),
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

class _DeporteTile extends StatelessWidget {
  const _DeporteTile({
    required this.deporte,
    required this.onTap,
    this.seleccionado = false,
  });

  final DeporteCategoria deporte;
  final VoidCallback onTap;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionado
          ? DeportesCategoria.botonMaroon.withValues(alpha: 0.85)
          : DeportesCategoria.botonMaroon,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: seleccionado
                ? Border.all(color: Colors.white, width: 3)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (seleccionado)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                ),
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
