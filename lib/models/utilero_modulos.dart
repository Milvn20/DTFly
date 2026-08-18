import 'package:cloud_firestore/cloud_firestore.dart';

/// Solicitud de compra de material (colección `solicitudes_compra_utilero`).
class SolicitudCompraUtilero {
  const SolicitudCompraUtilero({
    required this.id,
    required this.utileroId,
    required this.materialNombre,
    required this.cantidad,
    required this.motivo,
    required this.estado,
    required this.creadoEn,
    this.deporteId,
    this.deporteNombre,
    this.respuesta,
  });

  final String id;
  final String utileroId;
  final String materialNombre;
  final int cantidad;
  final String motivo;
  /// pendiente | aprobada | rechazada
  final String estado;
  final DateTime? creadoEn;
  final String? deporteId;
  final String? deporteNombre;
  final String? respuesta;

  bool get pendiente => estado == 'pendiente';

  static SolicitudCompraUtilero fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return SolicitudCompraUtilero(
      id: doc.id,
      utileroId: d['utilero_id'] as String? ?? '',
      materialNombre: d['material_nombre'] as String? ?? '',
      cantidad: (d['cantidad'] as num?)?.toInt() ?? 1,
      motivo: d['motivo'] as String? ?? '',
      estado: d['estado'] as String? ?? 'pendiente',
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
      deporteId: d['deporte'] as String?,
      deporteNombre: d['deporteNombre'] as String?,
      respuesta: d['respuesta'] as String?,
    );
  }
}

/// Entrenador / DT visible para el utilero.
class UtileroContactoDt {
  const UtileroContactoDt({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.fotoUrl,
    this.deporteNombre,
  });

  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? fotoUrl;
  final String? deporteNombre;
}
 

/// Ítem de una sesión de inventario físico.
class InventarioFisicoItem {
  const InventarioFisicoItem({
    required this.materialId,
    required this.nombre,
    required this.sistema,
    required this.contado,
    this.observacion,
  });

  final String materialId;
  final String nombre;
  final int sistema;
  final int contado;
  final String? observacion;

  int get diferencia => contado - sistema;
  bool get coincide => diferencia == 0;

  Map<String, dynamic> toMap() => {
        'material_id': materialId,
        'nombre': nombre,
        'sistema': sistema,
        'contado': contado,
        'observacion': observacion ?? '',
      };

  static InventarioFisicoItem fromMap(Map<String, dynamic> m) {
    return InventarioFisicoItem(
      materialId: m['material_id'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      sistema: (m['sistema'] as num?)?.toInt() ?? 0,
      contado: (m['contado'] as num?)?.toInt() ?? 0,
      observacion: m['observacion'] as String?,
    );
  }

  InventarioFisicoItem copyWith({
    int? contado,
    String? observacion,
  }) {
    return InventarioFisicoItem(
      materialId: materialId,
      nombre: nombre,
      sistema: sistema,
      contado: contado ?? this.contado,
      observacion: observacion ?? this.observacion,
    );
  }
}

/// Sesión formal de inventario físico (anual o conteo rápido).
class InventarioFisicoSesion {
  const InventarioFisicoSesion({
    required this.id,
    required this.utileroId,
    required this.anio,
    required this.tipo,
    required this.estado,
    required this.items,
    this.deporteId,
    this.deporteNombre,
    this.observacionesGenerales,
    this.responsableVerificacion,
    this.firmaCoordinador,
    this.creadoEn,
    this.cerradoEn,
  });

  final String id;
  final String utileroId;
  final int anio;
  /// anual | rapido
  final String tipo;
  /// borrador | cerrado
  final String estado;
  final List<InventarioFisicoItem> items;
  final String? deporteId;
  final String? deporteNombre;
  final String? observacionesGenerales;
  final String? responsableVerificacion;
  final String? firmaCoordinador;
  final DateTime? creadoEn;
  final DateTime? cerradoEn;

  bool get cerrado => estado == 'cerrado';
  bool get esAnual => tipo == 'anual';
  int get totalDiferencias =>
      items.where((i) => !i.coincide).length;

  static InventarioFisicoSesion fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return InventarioFisicoSesion(
      id: doc.id,
      utileroId: d['utilero_id'] as String? ?? '',
      anio: (d['anio'] as num?)?.toInt() ?? DateTime.now().year,
      tipo: d['tipo'] as String? ?? 'rapido',
      estado: d['estado'] as String? ?? 'cerrado',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(InventarioFisicoItem.fromMap)
          .toList(),
      deporteId: d['deporte'] as String?,
      deporteNombre: d['deporteNombre'] as String?,
      observacionesGenerales: d['observaciones_generales'] as String?,
      responsableVerificacion: d['responsable_verificacion'] as String?,
      firmaCoordinador: d['firma_coordinador'] as String?,
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
      cerradoEn: (d['cerrado_en'] as Timestamp?)?.toDate(),
    );
  }
}
