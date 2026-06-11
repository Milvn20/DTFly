import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_service.dart';

/// Operaciones de inventario para el kiosco del utilero.
class UtileroInventarioKiosco {
  UtileroInventarioKiosco._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static UtileroMaterialCat _resolverMaterial(MaterialInventario m) {
    return UtileroMaterialCat.resolver('${m.categoria} ${m.nombre}');
  }

  static Map<String, int> stockDesdeMateriales(List<MaterialInventario> mats) {
    final map = {for (final c in UtileroMaterialCat.todas) c.id: 0};
    for (final m in mats) {
      final cat = _resolverMaterial(m);
      map[cat.id] = (map[cat.id] ?? 0) + m.cantidadDisponible;
    }
    return map;
  }

  static Map<String, int> totalDesdeMateriales(List<MaterialInventario> mats) {
    final map = {for (final c in UtileroMaterialCat.todas) c.id: 0};
    for (final m in mats) {
      final cat = _resolverMaterial(m);
      map[cat.id] = (map[cat.id] ?? 0) + m.cantidadTotal;
    }
    return map;
  }

  static Future<List<MaterialInventario>> materialesDeCategoria(
    UtileroMaterialCat cat,
  ) async {
    final todos = await InventarioService.streamMateriales().first;
    return todos.where((m) => _resolverMaterial(m) == cat).toList();
  }

  static Future<MaterialInventario> asegurarMaterial(UtileroMaterialCat cat) async {
    final existentes = await materialesDeCategoria(cat);
    if (existentes.isNotEmpty) {
      existentes.sort((a, b) => b.cantidadTotal.compareTo(a.cantidadTotal));
      return existentes.first;
    }
    await InventarioService.agregarMaterial(
      nombre: cat.nombre,
      categoria: cat.etiquetaFirestore,
      cantidad: 0,
    );
    final nuevos = await materialesDeCategoria(cat);
    if (nuevos.isEmpty) {
      throw StateError('No se pudo crear ${cat.nombre}');
    }
    return nuevos.first;
  }

  static Future<List<UtileroPersonaEntrega>> listarEntrenadores() async {
    final snap = await _db
        .collection('usuarios')
        .where('rol', whereIn: [AppRoles.entrenador, 'Entrenador', 'DT'])
        .get();
    final list = snap.docs
        .map(
          (d) => UtileroPersonaEntrega(
            id: d.id,
            nombre: d.data()['nombre'] as String? ?? 'Profesor',
            email: d.data()['email'] as String? ?? '',
            fotoUrl: d.data()['foto_perfil'] as String?,
          ),
        )
        .toList();
    list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return list;
  }

  static Future<void> ingresarMaterial({
    required UtileroMaterialCat cat,
    required int cantidad,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat);
    await InventarioService.ingresarStock(materialId: mat.id, cantidad: cantidad);
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Recepción',
      descripcion: '$cantidad ${cat.nombre.toLowerCase()} ingresados',
      material: cat.nombre,
      cantidad: cantidad,
    );
  }

  static Future<void> prestarMaterial({
    required UtileroMaterialCat cat,
    required int cantidad,
    required UtileroPersonaEntrega persona,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat);
    await InventarioService.registrarPrestamo(
      materialId: mat.id,
      materialNombre: cat.nombre,
      cantidad: cantidad,
      prestadoA: persona.nombre,
      entrenadorEmail: persona.email.isNotEmpty ? persona.email : persona.nombre,
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Préstamo',
      descripcion: '$cantidad ${cat.nombre.toLowerCase()} a ${persona.nombre}',
      material: cat.nombre,
      cantidad: cantidad,
    );
  }

  static Future<void> devolverMaterial({
    required UtileroMaterialCat cat,
    required int cantidad,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat);
    await InventarioService.devolverCantidadMaterial(
      materialId: mat.id,
      cantidad: cantidad,
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Devolución',
      descripcion: '$cantidad ${cat.nombre.toLowerCase()} devueltos',
      material: cat.nombre,
      cantidad: cantidad,
    );
  }

  static Future<void> darDeBaja({
    required UtileroMaterialCat cat,
    required int cantidad,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat);
    await InventarioService.registrarDanado(
      materialId: mat.id,
      cantidad: cantidad,
      motivo: 'Baja por utilero',
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Material dañado',
      descripcion: '$cantidad ${cat.nombre.toLowerCase()} dados de baja',
      material: cat.nombre,
      cantidad: cantidad,
    );
  }

  static Future<int> prestadosActivos(UtileroMaterialCat cat) async {
    final mat = await asegurarMaterial(cat);
    final activos = await InventarioService.streamPrestamosActivos().first;
    return activos
        .where((p) => p.materialId == mat.id)
        .fold<int>(0, (s, p) => s + p.cantidad);
  }
}
