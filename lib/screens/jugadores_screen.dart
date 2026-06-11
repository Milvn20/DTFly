import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/screens/jugador/jugador_detalle_screen.dart';
import 'package:flutter_application_1/services/plantel_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class JugadoresScreen extends StatelessWidget {
  const JugadoresScreen({
    super.key,
    this.soloJugadores = false,
    this.categoriaDeportiva,
  });

  final bool soloJugadores;
  final String? categoriaDeportiva;

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    if (soloJugadores &&
        categoriaDeportiva != null &&
        categoriaDeportiva!.isNotEmpty) {
      return PlantelService.streamJugadoresPorDeporte(categoriaDeportiva);
    }
    final col = FirebaseFirestore.instance.collection('usuarios');
    if (soloJugadores) {
      return col
          .where('rol', whereIn: PlantelService.rolesJugador)
          .snapshots();
    }
    return col.snapshots();
  }

  String get _titulo {
    if (categoriaDeportiva != null && categoriaDeportiva!.isNotEmpty) {
      return 'Plantel · ${DeportesCategoria.nombreVisible(categoriaDeportiva)}';
    }
    return 'Lista de jugadores';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(
        title: Text(_titulo),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: DtflyTheme.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              if (categoriaDeportiva != null && categoriaDeportiva!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Jugadores de ${DeportesCategoria.nombreVisible(categoriaDeportiva)}',
                      style: const TextStyle(
                        color: DtflyTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: DtflyTheme.pagePadding(context).copyWith(bottom: 8),
                child: TextField(
                  decoration: DtflyTheme.loginFieldDecoration().copyWith(
                    hintText: 'Buscar jugador...',
                    prefixIcon: const Icon(Icons.search, color: DtflyTheme.textSecondary),
                  ),
                ),
              ),
              Expanded(
                child: categoriaDeportiva == null || categoriaDeportiva!.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Selecciona un deporte para ver el plantel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: DtflyTheme.textSecondary),
                          ),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _stream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: DtflyTheme.primary,
                              ),
                            );
                          }

                          final jugadores = snapshot.data!.docs;

                          if (jugadores.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No hay jugadores en '
                                  '${DeportesCategoria.nombreVisible(categoriaDeportiva)}.\n'
                                  'Los alumnos deben indicar su deporte al registrarse.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: DtflyTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: DtflyTheme.pagePadding(context),
                            itemCount: jugadores.length,
                            itemBuilder: (context, index) {
                              final jugador = jugadores[index].data();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: DtflyTheme.cardDecoration(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: DtflyTheme.borderRadius,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        DtflyTheme.primary.withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.person,
                                      color: DtflyTheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    jugador['nombre'] as String? ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: DtflyTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${jugador['carrera'] ?? ''} · '
                                    '${jugador['posicionDeportiva'] ?? '—'}',
                                    style: const TextStyle(
                                      color: DtflyTheme.textSecondary,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: DtflyTheme.textSecondary,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JugadorDetalleScreen(
                                          jugadorId: jugadores[index].id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
    );
  }
}
