import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deporte_usuario.dart';

/// Plantel filtrado: solo jugadores con el mismo [deporte] que el DT.
class PlantelService {
  PlantelService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'usuarios';

  static const List<String> rolesJugador = [AppRoles.jugador, 'Estudiante'];

  static bool esJugador(Map<String, dynamic> data) {
    return AppRoles.normalize(data['rol'] as String?) == AppRoles.jugador;
  }

  static bool perteneceAPlantel(Map<String, dynamic> data, String? deporteDt) {
    if (deporteDt == null || deporteDt.isEmpty) return false;
    if (!esJugador(data)) return false;
    return DeporteUsuario.idDesde(data) == deporteDt;
  }

  static Query<Map<String, dynamic>> queryJugadoresPorDeporte(String deporte) {
    return _db
        .collection(_col)
        .where('rol', whereIn: rolesJugador)
        .where(DeporteUsuario.fieldDeporte, isEqualTo: deporte);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamJugadoresPorDeporte(
    String? deporte,
  ) {
    if (deporte == null || deporte.isEmpty) {
      return const Stream.empty();
    }
    return queryJugadoresPorDeporte(deporte).snapshots();
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      obtenerJugadoresPorDeporte(String? deporte) async {
    if (deporte == null || deporte.isEmpty) return [];
    final snap = await queryJugadoresPorDeporte(deporte).get();
    return snap.docs;
  }

  static Future<List<MapEntry<String, String>>> listarJugadores(
    String? deporte,
  ) async {
    final docs = await obtenerJugadoresPorDeporte(deporte);
    final list = docs
        .map(
          (d) => MapEntry(
            d.id,
            d.data()['nombre'] as String? ?? 'Jugador',
          ),
        )
        .toList();
    list.sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return list;
  }

  /// Migra `categoriaDeportiva` → `deporte` en registros antiguos.
  static Future<void> asegurarCampoDeporte(String usuarioId) async {
    final ref = _db.collection(_col).doc(usuarioId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (data[DeporteUsuario.fieldDeporte] != null &&
        (data[DeporteUsuario.fieldDeporte] as String).isNotEmpty) {
      return;
    }
    final legacyId = data['categoriaDeportiva'] as String?;
    if (legacyId == null || legacyId.isEmpty) return;
    await ref.set(DeporteUsuario.camposAlGuardar(legacyId), SetOptions(merge: true));
  }
}
