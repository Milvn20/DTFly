import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/prestamo_material.dart';
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
      if (esMaterialPersonalizado(m)) continue;
      final cat = _resolverMaterial(m);
      map[cat.id] = (map[cat.id] ?? 0) + m.cantidadDisponible;
    }
    return map;
  }

  static Map<String, int> totalDesdeMateriales(List<MaterialInventario> mats) {
    final map = {for (final c in UtileroMaterialCat.todas) c.id: 0};
    for (final m in mats) {
      if (esMaterialPersonalizado(m)) continue;
      final cat = _resolverMaterial(m);
      map[cat.id] = (map[cat.id] ?? 0) + m.cantidadTotal;
    }
    return map;
  }

  /// Primera imagen personalizada encontrada en una categoría.
  static ({String? url, String? base64}) imagenDeCategoria(
    List<MaterialInventario> mats,
    UtileroMaterialCat cat,
  ) {
    for (final m in mats) {
      if (_resolverMaterial(m) != cat) continue;
      final b64 = m.imagenBase64?.trim();
      if (b64 != null && b64.isNotEmpty) {
        return (url: m.imagenUrl, base64: b64);
      }
      final url = m.imagenUrl?.trim();
      if (url != null && url.isNotEmpty) return (url: url, base64: null);
    }
    return (url: null, base64: null);
  }

  /// Materiales con foto propia (se listan aparte en inventario).
  static List<MaterialInventario> materialesConImagen(
    List<MaterialInventario> mats,
  ) {
    return mats
        .where((m) => m.imagenUrl != null && m.imagenUrl!.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  /// Material agregado por el utilero (foto propia / esPersonalizado).
  static bool esMaterialPersonalizado(MaterialInventario m) {
    if (m.esPersonalizado) return true;
    final b64 = m.imagenBase64?.trim();
    if (b64 != null && b64.isNotEmpty) return true;
    if (m.tieneFotoPersonalizada && m.categoria == 'General') return true;
    final cat = _resolverMaterial(m);
    if (cat.id == 'mas' && m.categoria == 'General') return true;
    return false;
  }

  static List<MaterialInventario> materialesAgregados(
    List<MaterialInventario> mats,
  ) {
    return mats.where(esMaterialPersonalizado).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  /// Unidades en préstamo por categoría (para pantalla de devolución).
  static Future<Map<String, int>> prestadosPorCategoria({
    String? deporteId,
  }) async {
    final activos = await InventarioService.streamPrestamosActivos().first;
    final mats =
        await InventarioService.streamMaterialesDeporte(deporteId).first;
    return _prestadosAgrupados(activos, mats).porCategoria;
  }

  static Future<Map<String, int>> prestadosPorMaterialId({
    String? deporteId,
  }) async {
    final activos = await InventarioService.streamPrestamosActivos().first;
    final mats =
        await InventarioService.streamMaterialesDeporte(deporteId).first;
    return _prestadosAgrupados(activos, mats).porMaterialId;
  }

  static ({Map<String, int> porCategoria, Map<String, int> porMaterialId})
      _prestadosAgrupados(
    List<PrestamoMaterial> activos,
    List<MaterialInventario> mats,
  ) {
    final porCat = {for (final c in UtileroMaterialCat.todas) c.id: 0};
    final porId = <String, int>{};
    final matById = {for (final m in mats) m.id: m};

    for (final p in activos) {
      porId[p.materialId] = (porId[p.materialId] ?? 0) + p.cantidad;
      final mat = matById[p.materialId];
      final cat = mat != null
          ? _resolverMaterial(mat)
          : UtileroMaterialCat.resolver(p.materialNombre);
      porCat[cat.id] = (porCat[cat.id] ?? 0) + p.cantidad;
    }
    return (porCategoria: porCat, porMaterialId: porId);
  }

  static List<MaterialInventario> materialesEnCategoria(
    List<MaterialInventario> mats,
    UtileroMaterialCat cat,
  ) {
    return mats
        .where((m) => _resolverMaterial(m) == cat && !esMaterialPersonalizado(m))
        .toList()
      ..sort((a, b) => b.cantidadTotal.compareTo(a.cantidadTotal));
  }

  static MaterialInventario? materialPrincipalCategoria(
    List<MaterialInventario> mats,
    UtileroMaterialCat cat,
  ) {
    final list = mats
        .where((m) => _resolverMaterial(m) == cat && !esMaterialPersonalizado(m))
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.cantidadTotal.compareTo(a.cantidadTotal));
    return list.first;
  }

  static List<MaterialInventario> materialesEliminables(
    List<MaterialInventario> mats,
  ) {
    return mats.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  static Future<List<MaterialInventario>> materialesDeCategoria(
    UtileroMaterialCat cat, {
    String? deporteId,
  }) async {
    final todos =
        await InventarioService.streamMaterialesDeporte(deporteId).first;
    return todos.where((m) => _resolverMaterial(m) == cat).toList();
  }

  static Future<MaterialInventario> asegurarMaterial(
    UtileroMaterialCat cat, {
    String? deporteId,
  }) async {
    final existentes = await materialesDeCategoria(cat, deporteId: deporteId);
    if (existentes.isNotEmpty) {
      existentes.sort((a, b) => b.cantidadTotal.compareTo(a.cantidadTotal));
      return existentes.first;
    }
    await InventarioService.agregarMaterial(
      nombre: cat.nombre,
      categoria: cat.etiquetaFirestore,
      cantidad: 0,
      deporteId: deporteId,
    );
    final nuevos = await materialesDeCategoria(cat, deporteId: deporteId);
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

  static Future<void> ingresarStockPorId({
    required String materialId,
    required String materialNombre,
    required int cantidad,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    await InventarioService.ingresarStock(
      materialId: materialId,
      cantidad: cantidad,
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Recepción',
      descripcion: '$cantidad ${materialNombre.toLowerCase()} ingresados',
      material: materialNombre,
      cantidad: cantidad,
    );
  }

  static Future<void> ingresarMaterial({
    required UtileroMaterialCat cat,
    required int cantidad,
    required String utileroId,
    String? deporteId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat, deporteId: deporteId);
    await InventarioService.ingresarStock(materialId: mat.id, cantidad: cantidad);
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Recepción',
      descripcion: '$cantidad ${cat.nombre.toLowerCase()} ingresados',
      material: cat.nombre,
      cantidad: cantidad,
    );
  }

  static Future<void> prestarMaterialPorId({
    required String materialId,
    required String materialNombre,
    required int cantidad,
    required UtileroPersonaEntrega persona,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    await InventarioService.registrarPrestamo(
      materialId: materialId,
      materialNombre: materialNombre,
      cantidad: cantidad,
      prestadoA: persona.nombre,
      entrenadorEmail:
          persona.email.isNotEmpty ? persona.email : persona.nombre,
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Préstamo',
      descripcion:
          '$cantidad ${materialNombre.toLowerCase()} a ${persona.nombre}',
      material: materialNombre,
      cantidad: cantidad,
    );
  }

  static Future<void> prestarMaterial({
    required UtileroMaterialCat cat,
    required int cantidad,
    required UtileroPersonaEntrega persona,
    required String utileroId,
    String? deporteId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat, deporteId: deporteId);
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
    String? materialId,
    String? materialNombre,
    String? deporteId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    MaterialInventario? mat;
    if (materialId != null) {
      for (final m
          in await InventarioService.streamMaterialesDeporte(deporteId).first) {
        if (m.id == materialId) {
          mat = m;
          break;
        }
      }
    }
    final destino = mat ?? await asegurarMaterial(cat, deporteId: deporteId);
    final nombre = materialNombre ?? destino.nombre;
    await InventarioService.devolverCantidadMaterial(
      materialId: destino.id,
      cantidad: cantidad,
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Devolución',
      descripcion: '$cantidad ${nombre.toLowerCase()} devueltos',
      material: nombre,
      cantidad: cantidad,
    );
  }

  static Future<void> darDeBajaPorId({
    required String materialId,
    required String materialNombre,
    required int cantidad,
    required String utileroId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    await InventarioService.registrarDanado(
      materialId: materialId,
      cantidad: cantidad,
      motivo: 'Baja por utilero',
    );
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Material dañado',
      descripcion: '$cantidad ${materialNombre.toLowerCase()} dados de baja',
      material: materialNombre,
      cantidad: cantidad,
    );
  }

  static Future<void> darDeBaja({
    required UtileroMaterialCat cat,
    required int cantidad,
    required String utileroId,
    String? deporteId,
  }) async {
    if (cantidad <= 0) throw StateError('Ingresa una cantidad');
    final mat = await asegurarMaterial(cat, deporteId: deporteId);
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

  static Future<int> prestadosActivos(
    UtileroMaterialCat cat, {
    String? deporteId,
  }) async {
    final mat = await asegurarMaterial(cat, deporteId: deporteId);
    final activos = await InventarioService.streamPrestamosActivos().first;
    return activos
        .where((p) => p.materialId == mat.id)
        .fold<int>(0, (s, p) => s + p.cantidad);
  }

  static Future<void> eliminarMaterial({
    required MaterialInventario material,
    required String utileroId,
  }) async {
    await InventarioService.eliminarMaterial(material.id);
    await UtileroService.registrarActividad(
      utileroId: utileroId,
      accion: 'Eliminó material',
      descripcion: material.nombre,
      material: material.nombre,
      cantidad: material.cantidadTotal,
    );
  }
}
