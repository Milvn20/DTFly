import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/screens/jugador/jugador_detalle_screen.dart';
import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Detalle de un entrenamiento finalizado: lista de alumnos que asistieron ese día.
class EntrenadorHistorialDetalleScreen extends StatelessWidget {
  const EntrenadorHistorialDetalleScreen({super.key, required this.entrenamiento});

  final Entrenamiento entrenamiento;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'atrasado':
        return 'Atrasado';
      case 'ausente':
        return 'Ausente';
      case 'presente':
      default:
        return 'Puntual';
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'atrasado':
        return Colors.orange.shade800;
      case 'ausente':
        return Colors.grey.shade700;
      default:
        return Colors.green.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Asistencia del entrenamiento'),
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entrenamiento.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Cancha: ${entrenamiento.cancha}'),
                    Text(
                      'Inicio programado: ${_fmt(entrenamiento.inicioProgramado)}',
                    ),
                    if (entrenamiento.finalizadoEn != null)
                      Text('Cerrado: ${_fmt(entrenamiento.finalizadoEn!)}'),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Alumnos registrados ese día',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<AsistenciaRegistro>>(
              stream: EntrenamientoService.streamAsistencias(entrenamiento.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                final lista = snap.data ?? [];
                if (lista.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay registros de asistencia para este entrenamiento. '
                      'Si nadie alcanzó a unirse con el código antes de finalizar, la lista quedará vacía.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final a = lista[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JugadorDetalleScreen(jugadorId: a.jugadorId),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: _colorEstado(a.estado).withOpacity(0.2),
                          child: Icon(Icons.person, color: _colorEstado(a.estado)),
                        ),
                        title: Text(
                          a.nombre.isEmpty ? 'Sin nombre' : a.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${a.email}\nSe unió: ${a.unidoEn != null ? _fmt(a.unidoEn!) : '—'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            _etiquetaEstado(a.estado),
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                          backgroundColor: _colorEstado(a.estado),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
