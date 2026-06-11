import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/screens/entrenador/entrenador_historial_detalle_screen.dart';
import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class EntrenadorHistorialScreen extends StatelessWidget {
  const EntrenadorHistorialScreen({super.key, required this.entrenadorEmail});

  final String entrenadorEmail;

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Entrenamiento>>(
        stream: EntrenamientoService.streamHistorial(entrenadorEmail),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Aún no hay entrenamientos finalizados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${e.cancha}\nInicio: ${_fmt(e.inicioProgramado)}'
                    '${e.finalizadoEn != null ? '\nCerrado: ${_fmt(e.finalizadoEn!)}' : ''}'
                    '\nToca para ver la lista de asistencia',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EntrenadorHistorialDetalleScreen(entrenamiento: e),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
