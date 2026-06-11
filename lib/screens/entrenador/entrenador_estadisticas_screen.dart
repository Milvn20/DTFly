import 'package:flutter/material.dart';

import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class EntrenadorEstadisticasScreen extends StatelessWidget {
  const EntrenadorEstadisticasScreen({super.key, required this.entrenadorEmail});

  final String entrenadorEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<EntrenamientoStats>(
        future: EntrenamientoService.estadisticas(entrenadorEmail),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final s = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatCard(
                titulo: 'Total de entrenamientos',
                valor: '${s.total}',
                icono: Icons.event,
              ),
              _StatCard(
                titulo: 'Programados',
                valor: '${s.programados}',
                icono: Icons.schedule,
              ),
              _StatCard(
                titulo: 'En curso',
                valor: '${s.activos}',
                icono: Icons.play_circle_outline,
              ),
              _StatCard(
                titulo: 'Finalizados',
                valor: '${s.finalizados}',
                icono: Icons.check_circle_outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Los conteos se actualizan desde Firestore. La asistencia detallada por jugador se añadirá en una siguiente versión.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DtflyTheme.primary.withValues(alpha: 0.12),
          child: Icon(icono, color: DtflyTheme.primary),
        ),
        title: Text(titulo),
        trailing: Text(
          valor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DtflyTheme.primary,
          ),
        ),
      ),
    );
  }
}
