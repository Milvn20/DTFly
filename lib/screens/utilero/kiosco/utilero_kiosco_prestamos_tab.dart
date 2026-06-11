import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/screens/utilero/kiosco/utilero_kiosco_flujo_screen.dart';
import 'package:flutter_application_1/widgets/dtfly_mockup_dashboard.dart';
import 'package:flutter_application_1/widgets/utilero_agregar_material_dialog.dart';

/// Pestaña Préstamos — mockup con botón rojo principal.
class UtileroKioscoPrestamosTab extends StatelessWidget {
  const UtileroKioscoPrestamosTab({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
  });

  final String usuarioId;
  final String usuarioEmail;

  void _abrir(BuildContext context, UtileroFlujoKiosco flujo) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroKioscoFlujoScreen(
          flujo: flujo,
          usuarioId: usuarioId,
          usuarioEmail: usuarioEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DtflyMockupDashboardLayout(
      saludo: 'Préstamos',
      subtitulo: 'Entregar o recibir material',
      stats: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DtflyMockupPrimaryButton(
            texto: '+ Prestar material',
            onTap: () => _abrir(context, UtileroFlujoKiosco.prestar),
          ),
          const SizedBox(height: 20),
          const Text(
            'Otras acciones',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _AccionTile(
            emoji: '➕',
            titulo: 'Agregar material nuevo',
            subtitulo: 'Con foto desde tu dispositivo',
            onTap: () => UtileroAgregarMaterialDialog.mostrar(
              context,
              usuarioId: usuarioId,
            ),
          ),
          const SizedBox(height: 10),
          _AccionTile(
            emoji: '📦',
            titulo: 'Recibir material',
            subtitulo: 'Ingresar stock de lo existente',
            onTap: () => _abrir(context, UtileroFlujoKiosco.recibir),
          ),
          const SizedBox(height: 10),
          _AccionTile(
            emoji: '↩️',
            titulo: 'Registrar devolución',
            subtitulo: 'Material que vuelve',
            onTap: () => _abrir(context, UtileroFlujoKiosco.devolver),
          ),
          const SizedBox(height: 10),
          _AccionTile(
            emoji: '🗑',
            titulo: 'Dar de baja',
            subtitulo: 'Material dañado',
            onTap: () => _abrir(context, UtileroFlujoKiosco.danado),
            peligro: true,
          ),
        ],
      ),
    );
  }
}

class _AccionTile extends StatelessWidget {
  const _AccionTile({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.peligro = false,
  });

  final String emoji;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: peligro ? const Color(0xFFC62828).withValues(alpha: 0.08) : const Color(0xFFC62828),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: peligro ? const Color(0xFFC62828) : Colors.white,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: peligro ? const Color(0xFF6B7280) : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: peligro ? const Color(0xFFC62828) : Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
