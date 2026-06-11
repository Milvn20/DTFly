import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/services/usuario_perfil_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Vista del entrenador: ficha completa de un jugador.
class JugadorDetalleScreen extends StatelessWidget {
  const JugadorDetalleScreen({super.key, required this.jugadorId});

  final String jugadorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Ficha del jugador'),
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: UsuarioPerfilService.streamUsuario(jugadorId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!.data()!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _fila('Nombre', d['nombre'] as String? ?? '—'),
              _fila('Email', d['email'] as String? ?? '—'),
              _fila('Rol', d['rol'] as String? ?? '—'),
              _fila('Edad', d['edad'] != null ? '${d['edad']}' : '—'),
              _fila(
                'Año término carrera',
                d['anioTerminoCarrera'] != null
                    ? '${d['anioTerminoCarrera']}'
                    : '—',
              ),
              _fila('Carrera', d['carrera'] as String? ?? '—'),
              _fila('Deporte', DeporteUsuario.nombreDesde(d)),
              _fila('Posición', d['posicionDeportiva'] as String? ?? '—'),
              _fila('Tipo de beca', d['tipoBeca'] as String? ?? '—'),
            ],
          );
        },
      ),
    );
  }

  Widget _fila(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
