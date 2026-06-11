import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Menú lateral rápido del utilero (icono ☰ en inicio).
class UtileroMenuSheet {
  UtileroMenuSheet._();

  static Future<void> mostrar(
    BuildContext context, {
    required String nombre,
    String? deporteId,
    required VoidCallback onIrInventario,
    required VoidCallback onIrPrestamos,
    required VoidCallback onIrMas,
    required VoidCallback onCambiarSeleccion,
    required VoidCallback onAgregarMaterial,
    required VoidCallback onEliminarMaterial,
    required VoidCallback onCerrarSesion,
  }) {
    final deporte = deporteId != null && deporteId.isNotEmpty
        ? DeportesCategoria.nombreVisible(deporteId)
        : 'Sin selección';

    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                nombre.trim().split(RegExp(r'\s+')).first,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Selección: $deporte',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: DtflyTheme.textSecondary,
                ),
              ),
              const Divider(height: 20),
              _opcion(
                ctx,
                icon: Icons.home_outlined,
                titulo: 'Inicio',
                onTap: () => Navigator.pop(ctx),
              ),
              _opcion(
                ctx,
                icon: Icons.inventory_2_outlined,
                titulo: 'Inventario',
                onTap: () {
                  Navigator.pop(ctx);
                  onIrInventario();
                },
              ),
              _opcion(
                ctx,
                icon: Icons.handshake_outlined,
                titulo: 'Préstamos',
                onTap: () {
                  Navigator.pop(ctx);
                  onIrPrestamos();
                },
              ),
              _opcion(
                ctx,
                icon: Icons.swap_horiz,
                titulo: 'Cambiar selección',
                onTap: () {
                  Navigator.pop(ctx);
                  onCambiarSeleccion();
                },
              ),
              _opcion(
                ctx,
                icon: Icons.add_circle_outline,
                titulo: 'Agregar material',
                onTap: () {
                  Navigator.pop(ctx);
                  onAgregarMaterial();
                },
              ),
              _opcion(
                ctx,
                icon: Icons.delete_outline,
                titulo: 'Eliminar material',
                onTap: () {
                  Navigator.pop(ctx);
                  onEliminarMaterial();
                },
              ),
              _opcion(
                ctx,
                icon: Icons.dashboard_customize_outlined,
                titulo: 'Herramientas utilero',
                onTap: () {
                  Navigator.pop(ctx);
                  onIrMas();
                },
              ),
              const Divider(height: 12),
              _opcion(
                ctx,
                icon: Icons.door_front_door_outlined,
                titulo: 'Cerrar sesión',
                peligro: true,
                onTap: () {
                  Navigator.pop(ctx);
                  onCerrarSesion();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _opcion(
    BuildContext ctx, {
    required IconData icon,
    required String titulo,
    required VoidCallback onTap,
    bool peligro = false,
  }) {
    final color = peligro ? const Color(0xFFC62828) : DtflyTheme.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        titulo,
        style: TextStyle(
          color: color,
          fontWeight: peligro ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
