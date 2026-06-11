import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  }) async {
    final ref = await _db.collection(_colMateriales).add({
      'nombre': nombre,
      'categoria': categoria,
      'cantidadTotal': cantidad,
      'cantidadDisponible': cantidad,
      'cantidadDanada': 0,
      'unidad': unidad,
      if (imagenUrl != null && imagenUrl.isNotEmpty) 'imagenUrl': imagenUrl,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<String> subirImagenMaterial({
    required String materialId,
    required Uint8List bytes,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('inventario/$materialId.jpg');
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await storageRef.getDownloadURL();
    await _db.collection(_colMateriales).doc(materialId).update({
      'imagenUrl': url,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return url;
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
    await _db.collection(_colMateriales).doc(id).delete();
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
