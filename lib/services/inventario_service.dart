import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/core/utilero_imagen_comprimir.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/prestamo_material.dart';

/// Inventario deportivo (`inventario`, `prestamos_inventario`).
class InventarioService {
  InventarioService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _colMateriales = 'inventario';
  static const String _colPrestamos = 'prestamos_inventario';

  static const categoriasSugeridas = [
    'Balones',
    'Conos',
    'Poleras',
    'Lentejas',
    'Petos',
    'Vallas',
    'Escaleras',
    'General',
  ];

  static Stream<List<MaterialInventario>> streamMateriales() {
    return _db.collection(_colMateriales).snapshots().map((s) {
      final list = s.docs.map(MaterialInventario.fromDoc).toList();
      list.sort((a, b) => a.nombre.compareTo(b.nombre));
      return list;
    });
  }

  /// Solo materiales de la selección elegida (fútbol, voleibol, etc.).
  static Stream<List<MaterialInventario>> streamMaterialesDeporte(String? deporteId) {
    return streamMateriales().map(
      (list) => list.where((m) => perteneceADeporte(m, deporteId)).toList(),
    );
  }

  static bool perteneceADeporte(MaterialInventario m, String? deporteId) {
    if (deporteId == null || deporteId.isEmpty) return true;
    if (m.compartidoGeneral || UtileroMaterialCat.materialEsCompartido(m)) {
      return true;
    }
    final d = m.deporteId;
    if (d == null || d.isEmpty) return false;
    return d == deporteId;
  }

  /// Materiales antiguos sin campo `deporte` (no aparecen en ninguna selección).
  static Stream<List<MaterialInventario>> streamMaterialesSinDeporte() {
    return streamMateriales().map(
      (list) => list
          .where((m) => m.deporteId == null || m.deporteId!.isEmpty)
          .toList(),
    );
  }

  static Future<int> contarMaterialesSinDeporte() async {
    final snap = await _db.collection(_colMateriales).get();
    var n = 0;
    for (final d in snap.docs) {
      final dep = DeporteUsuario.idDesde(d.data());
      if (dep == null || dep.isEmpty) n++;
    }
    return n;
  }

  /// Asigna la selección actual a materiales legacy (todos o por ids).
  static Future<int> asignarDeporteMaterialesLegacy({
    required String deporteId,
    List<String>? soloIds,
  }) async {
    if (deporteId.isEmpty) {
      throw StateError('Selecciona una disciplina primero.');
    }
    final campos = _camposDeporte(deporteId);
    final snap = await _db.collection(_colMateriales).get();
    final batch = _db.batch();
    var n = 0;
    for (final d in snap.docs) {
      if (soloIds != null && !soloIds.contains(d.id)) continue;
      final dep = DeporteUsuario.idDesde(d.data());
      if (dep != null && dep.isNotEmpty) continue;
      batch.update(d.reference, {
        ...campos,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      n++;
    }
    if (n == 0) return 0;
    await batch.commit();
    return n;
  }

  static Map<String, dynamic> _camposDeporte(String? deporteId) {
    if (deporteId == null || deporteId.isEmpty) return {};
    return DeporteUsuario.camposAlGuardar(deporteId);
  }

  static Stream<List<MaterialInventario>> streamMaterialesDanados() {
    return streamMateriales().map(
      (list) => list.where((m) => m.tieneDanados).toList(),
    );
  }

  static Future<String> agregarMaterial({
    required String nombre,
    required String categoria,
    required int cantidad,
    String unidad = 'unidad',
    String? imagenUrl,
    Uint8List? imagenBytes,
    String? deporteId,
    bool compartidoGeneral = false,
  }) async {
    String? imagenBase64;
    if (imagenBytes != null && imagenBytes.isNotEmpty) {
      final mini = await comprimirImagenInventario(imagenBytes);
      imagenBase64 = base64Encode(mini);
    }
    final ref = await _db.collection(_colMateriales).add({
      'nombre': nombre,
      'categoria': categoria,
      'cantidadTotal': cantidad,
      'cantidadDisponible': cantidad,
      'cantidadDanada': 0,
      'unidad': unidad,
      if (imagenUrl != null && imagenUrl.isNotEmpty) 'imagenUrl': imagenUrl,
      if (imagenBase64 != null && imagenBase64.isNotEmpty)
        'imagenBase64': imagenBase64,
      if (compartidoGeneral) ...{
        'compartido_todas_selecciones': true,
        'deporte': DeportesCategoria.idGeneral,
        'deporte_nombre': 'General',
      } else
        ..._camposDeporte(deporteId),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Material creado por el utilero con foto propia (miniatura en Firestore).
  static Future<String> agregarMaterialPersonalizado({
    required String nombre,
    required int cantidad,
    required Uint8List imagenBytes,
    String? deporteId,
    bool compartidoGeneral = false,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      throw StateError('Ingresa el nombre del material');
    }
    if (cantidad <= 0) {
      throw StateError('Ingresa una cantidad mayor a cero');
    }
    if (imagenBytes.isEmpty) {
      throw StateError('Selecciona una foto del material');
    }
    final imagenBase64 = base64Encode(imagenBytes);

    if (!compartidoGeneral &&
        (deporteId == null || deporteId.isEmpty)) {
      throw StateError('Selecciona una disciplina o General');
    }

    final ref = await _db.collection(_colMateriales).add({
      'nombre': limpio,
      'categoria': 'General',
      'cantidadTotal': cantidad,
      'cantidadDisponible': cantidad,
      'cantidadDanada': 0,
      'unidad': 'unidad',
      'imagenBase64': imagenBase64,
      'esPersonalizado': true,
      if (compartidoGeneral) ...{
        'compartido_todas_selecciones': true,
        'deporte': DeportesCategoria.idGeneral,
        'deporte_nombre': 'General',
      } else
        ..._camposDeporte(deporteId),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  static Future<String> subirImagenMaterial({
    required String materialId,
    required Uint8List bytes,
  }) async {
    final miniatura = await comprimirImagenInventario(bytes);
    final imagenBase64 = base64Encode(miniatura);
    await _db.collection(_colMateriales).doc(materialId).update({
      'imagenBase64': imagenBase64,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return '';
  }

  static Future<void> actualizarCantidad({
    required String id,
    required int cantidadTotal,
  }) async {
    final ref = _db.collection(_colMateriales).doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    final d = snap.data()!;
    final danada = (d['cantidadDanada'] as num?)?.toInt() ?? 0;
    final prestados = _prestadosDesde(d);
    final noDisponible = prestados + danada;
    final disponible = cantidadTotal - noDisponible;
    await ref.update({
      'cantidadTotal': cantidadTotal,
      'cantidadDisponible': disponible < 0 ? 0 : disponible,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  static int _prestadosDesde(Map<String, dynamic> d) {
    final total = (d['cantidadTotal'] as num?)?.toInt() ?? 0;
    final disp = (d['cantidadDisponible'] as num?)?.toInt() ?? 0;
    final danada = (d['cantidadDanada'] as num?)?.toInt() ?? 0;
    final p = total - disp - danada;
    return p < 0 ? 0 : p;
  }

  /// Mueve unidades de disponible → dañado.
  static Future<void> registrarDanado({
    required String materialId,
    required int cantidad,
    String motivo = '',
  }) async {
    final ref = _db.collection(_colMateriales).doc(materialId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Material no encontrado');
      final d = snap.data()!;
      final disp = (d['cantidadDisponible'] as num?)?.toInt() ?? 0;
      final danada = (d['cantidadDanada'] as num?)?.toInt() ?? 0;
      if (disp < cantidad) {
        throw StateError(
          'Solo hay $disp disponible(s) para marcar como dañado',
        );
      }
      tx.update(ref, {
        'cantidadDisponible': disp - cantidad,
        'cantidadDanada': danada + cantidad,
        'ultimoMotivoDanado': motivo,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Repara material: dañado → disponible.
  static Future<void> recuperarDanado({
    required String materialId,
    required int cantidad,
  }) async {
    final ref = _db.collection(_colMateriales).doc(materialId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Material no encontrado');
      final d = snap.data()!;
      final disp = (d['cantidadDisponible'] as num?)?.toInt() ?? 0;
      final danada = (d['cantidadDanada'] as num?)?.toInt() ?? 0;
      if (danada < cantidad) {
        throw StateError('Solo hay $danada unidad(es) dañada(s)');
      }
      tx.update(ref, {
        'cantidadDisponible': disp + cantidad,
        'cantidadDanada': danada - cantidad,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Al devolver préstamo, opción de marcar unidades devueltas como dañadas.
  static Future<void> marcarDevuelto({
    required String prestamoId,
    int cantidadDanadaAlDevolver = 0,
  }) async {
    final prestRef = _db.collection(_colPrestamos).doc(prestamoId);
    final snap = await prestRef.get();
    if (!snap.exists) return;
    final d = snap.data()!;
    if (d['devuelto'] == true) return;

    final materialId = d['materialId'] as String;
    final cantidad = (d['cantidad'] as num?)?.toInt() ?? 1;
    final danadaDev = cantidadDanadaAlDevolver.clamp(0, cantidad);
    final aDisponible = cantidad - danadaDev;
    final matRef = _db.collection(_colMateriales).doc(materialId);

    await _db.runTransaction((tx) async {
      final matSnap = await tx.get(matRef);
      if (matSnap.exists) {
        final md = matSnap.data()!;
        final disp = (md['cantidadDisponible'] as num?)?.toInt() ?? 0;
        final total = (md['cantidadTotal'] as num?)?.toInt() ?? 0;
        final danada = (md['cantidadDanada'] as num?)?.toInt() ?? 0;
        final nuevoDisp = disp + aDisponible;
        final nuevoDanada = danada + danadaDev;
        tx.update(matRef, {
          'cantidadDisponible':
              nuevoDisp > total - nuevoDanada ? total - nuevoDanada : nuevoDisp,
          'cantidadDanada': nuevoDanada,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      }
      tx.update(prestRef, {
        'devuelto': true,
        'devueltoEn': FieldValue.serverTimestamp(),
        if (danadaDev > 0) 'unidadesDanadas': danadaDev,
      });
    });
  }

  static Future<void> eliminarMaterial(String id) async {
    final activos = await streamPrestamosActivos().first;
    final enPrestamo = activos
        .where((p) => p.materialId == id)
        .fold<int>(0, (s, p) => s + p.cantidad);
    if (enPrestamo > 0) {
      throw StateError(
        'Hay $enPrestamo unidad(es) en préstamo. Registra la devolución antes de eliminar.',
      );
    }
    await _db.collection(_colMateriales).doc(id).delete();
  }

  static Future<void> actualizarUbicacion({
    required String materialId,
    String? ubicacion,
    String? pasillo,
    String? estante,
  }) async {
    await _db.collection(_colMateriales).doc(materialId).update({
      if (ubicacion != null) 'ubicacion': ubicacion.trim(),
      if (pasillo != null) 'pasillo': pasillo.trim(),
      if (estante != null) 'estante': estante.trim(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<PrestamoMaterial>> streamPrestamosActivos() {
    return _db
        .collection(_colPrestamos)
        .where('devuelto', isEqualTo: false)
        .snapshots()
        .map((s) {
      final list = s.docs.map(PrestamoMaterial.fromDoc).toList();
      list.sort((a, b) => b.prestadoEn.compareTo(a.prestadoEn));
      return list;
    });
  }

  static Stream<List<PrestamoMaterial>> streamHistorialPrestamos() {
    return _db
        .collection(_colPrestamos)
        .orderBy('prestadoEn', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(PrestamoMaterial.fromDoc).toList());
  }

  static Future<void> registrarPrestamo({
    required String materialId,
    required String materialNombre,
    required int cantidad,
    required String prestadoA,
    required String entrenadorEmail,
    String notas = '',
    String? firmaRetiroBase64,
    String? firmadoPor,
  }) async {
    final matRef = _db.collection(_colMateriales).doc(materialId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(matRef);
      if (!snap.exists) throw StateError('Material no encontrado');
      final disp =
          (snap.data()!['cantidadDisponible'] as num?)?.toInt() ?? 0;
      if (disp < cantidad) {
        throw StateError('Stock insuficiente (disponible: $disp)');
      }
      tx.update(matRef, {
        'cantidadDisponible': disp - cantidad,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });

    await _db.collection(_colPrestamos).add({
      'materialId': materialId,
      'materialNombre': materialNombre,
      'cantidad': cantidad,
      'prestadoA': prestadoA,
      'entrenadorEmail': entrenadorEmail,
      'notas': notas,
      'devuelto': false,
      'prestadoEn': FieldValue.serverTimestamp(),
      if (firmaRetiroBase64 != null && firmaRetiroBase64.isNotEmpty)
        'firma_retiro_base64': firmaRetiroBase64,
      if (firmadoPor != null && firmadoPor.isNotEmpty) 'firmado_por': firmadoPor,
      if (firmaRetiroBase64 != null && firmaRetiroBase64.isNotEmpty)
        'firmado_en': FieldValue.serverTimestamp(),
    });
  }

  /// Suma unidades al stock disponible (recepción de material).
  static Future<void> ingresarStock({
    required String materialId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) return;
    final ref = _db.collection(_colMateriales).doc(materialId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Material no encontrado');
      final d = snap.data()!;
      final total = (d['cantidadTotal'] as num?)?.toInt() ?? 0;
      final disp = (d['cantidadDisponible'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'cantidadTotal': total + cantidad,
        'cantidadDisponible': disp + cantidad,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Devuelve cantidad desde préstamos activos (más antiguos primero).
  static Future<void> devolverCantidadMaterial({
    required String materialId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) return;

    var restante = cantidad;
    final activos = (await streamPrestamosActivos().first)
        .where((p) => p.materialId == materialId)
        .toList()
      ..sort((a, b) => a.prestadoEn.compareTo(b.prestadoEn));

    for (final p in activos) {
      if (restante <= 0) break;
      if (p.cantidad <= restante) {
        await marcarDevuelto(prestamoId: p.id);
        restante -= p.cantidad;
      } else {
        await _devolverParcialPrestamo(
          prestamoId: p.id,
          materialId: materialId,
          cantidadDevuelta: restante,
          cantidadPrestamo: p.cantidad,
        );
        restante = 0;
      }
    }

    if (restante > 0) {
      throw StateError(
        'Solo hay ${cantidad - restante} en préstamo para devolver',
      );
    }
  }

  static Future<void> _devolverParcialPrestamo({
    required String prestamoId,
    required String materialId,
    required int cantidadDevuelta,
    required int cantidadPrestamo,
  }) async {
    final prestRef = _db.collection(_colPrestamos).doc(prestamoId);
    final matRef = _db.collection(_colMateriales).doc(materialId);
    final nuevaCantidadPrestamo = cantidadPrestamo - cantidadDevuelta;

    await _db.runTransaction((tx) async {
      final matSnap = await tx.get(matRef);
      if (matSnap.exists) {
        final md = matSnap.data()!;
        final disp = (md['cantidadDisponible'] as num?)?.toInt() ?? 0;
        tx.update(matRef, {
          'cantidadDisponible': disp + cantidadDevuelta,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      }
      if (nuevaCantidadPrestamo <= 0) {
        tx.update(prestRef, {
          'devuelto': true,
          'devueltoEn': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(prestRef, {'cantidad': nuevaCantidadPrestamo});
      }
    });
  }
}
