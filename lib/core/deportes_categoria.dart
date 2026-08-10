import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Disciplinas deportivas que un entrenador puede gestionar en DTFly.
class DeporteCategoria {
  const DeporteCategoria({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  final String id;
  final String nombre;
  final IconData icono;
}

class DeportesCategoria {
  DeportesCategoria._();

  /// Material marcado así aparece en todas las selecciones deportivas.
  static const String idGeneral = 'general';

  static const DeporteCategoria opcionGeneral = DeporteCategoria(
    id: idGeneral,
    nombre: 'General',
    icono: Icons.public,
  );

  /// Colores del mockup de selección de entrenamiento.
  static const Color botonMaroon = DtflyTheme.primary;
  static const Color fondoSeleccion = DtflyTheme.background;

  static const List<DeporteCategoria> todas = [
    DeporteCategoria(
      id: 'futbol',
      nombre: 'Fútbol',
      icono: Icons.sports_soccer,
    ),
    DeporteCategoria(
      id: 'balon_mano',
      nombre: 'Balonmano',
      icono: Icons.sports_handball,
    ),
    DeporteCategoria(
      id: 'basquetbol',
      nombre: 'Básquetbol',
      icono: Icons.sports_basketball,
    ),
    DeporteCategoria(
      id: 'voleibol',
      nombre: 'Voleibol',
      icono: Icons.sports_volleyball,
    ),
    DeporteCategoria(
      id: 'natacion',
      nombre: 'Natación',
      icono: Icons.pool,
    ),
    DeporteCategoria(
      id: 'tenis',
      nombre: 'Tenis',
      icono: Icons.sports_tennis,
    ),
    DeporteCategoria(
      id: 'rugby_varones',
      nombre: 'Rugby varones',
      icono: Icons.sports_rugby,
    ),
  ];

  static DeporteCategoria? porId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final d in todas) {
      if (d.id == id) return d;
    }
    return null;
  }

  static String nombreVisible(String? id) {
    if (id == idGeneral) return 'General (todas las selecciones)';
    return porId(id)?.nombre ?? (id?.isNotEmpty == true ? id! : 'Sin categoría');
  }

  /// Opciones para asignar material: General + cada disciplina.
  static List<DeporteCategoria> opcionesInventario({String? seleccionActual}) {
    final lista = <DeporteCategoria>[opcionGeneral, ...todas];
    if (seleccionActual == null ||
        seleccionActual.isEmpty ||
        seleccionActual == idGeneral) {
      return lista;
    }
    if (lista.any((d) => d.id == seleccionActual)) return lista;
    return lista;
  }
}
