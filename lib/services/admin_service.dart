import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_application_1/core/app_roles.dart';
import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/admin_auditoria.dart';
import 'package:flutter_application_1/models/admin_busqueda.dart';
import 'package:flutter_application_1/models/admin_perfil.dart';
import 'package:flutter_application_1/models/admin_usuario.dart';
import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/models/prestamo_material.dart';
import 'package:flutter_application_1/models/utilero_modulos.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/reportes_file_writer.dart';

/// Estadísticas globales del dashboard admin.
class AdminEstadisticasGlobales {
  const AdminEstadisticasGlobales({
    required this.totalUsuarios,
    required this.usuariosActivos,
    required this.entrenadores,
    required this.jugadores,
    required this.utileros,
    required this.administradores,
    required this.totalMateriales,
    required this.unidadesInventario,
    required this.prestadosActivos,
    required this.entrenamientos,
    required this.partidos,
    required this.stockBajo,
    required this.solicitudesPendientes,
    required this.materialesDanados,
    required this.reportesEntrenador,
  });

  final int totalUsuarios;
  final int usuariosActivos;
  final int entrenadores;
  final int jugadores;
  final int utileros;
  final int administradores;
  final int totalMateriales;
  final int unidadesInventario;
  final int prestadosActivos;
  final int entrenamientos;
  final int partidos;
  final int stockBajo;
  final int solicitudesPendientes;
  final int materialesDanados;
  final int reportesEntrenador;
}

/// Reporte almacenado en Firestore.
class AdminReporteItem {
  const AdminReporteItem({
    required this.id,
    required this.titulo,
    required this.origen,
    required this.email,
    this.contenido,
    this.nombreArchivo,
    this.creadoEn,
    this.deporte,
  });

  final String id;
  final String titulo;
  final String origen;
  final String email;
  final String? contenido;
  final String? nombreArchivo;
  final DateTime? creadoEn;
  final String? deporte;
}

/// Configuración global del sistema.
class AdminConfiguracionSistema {
  const AdminConfiguracionSistema({
    required this.deportesExtra,
    required this.categoriasInventarioExtra,
    required this.codigoValidezSegundos,
    required this.permitirRegistroAbierto,
  });

  final List<String> deportesExtra;
  final List<String> categoriasInventarioExtra;
  final int codigoValidezSegundos;
  final bool permitirRegistroAbierto;

  static AdminConfiguracionSistema vacio() => const AdminConfiguracionSistema(
        deportesExtra: [],
        categoriasInventarioExtra: [],
        codigoValidezSegundos: 60,
        permitirRegistroAbierto: true,
      );

  static AdminConfiguracionSistema fromMap(Map<String, dynamic>? d) {
    if (d == null) return vacio();
    return AdminConfiguracionSistema(
      deportesExtra: (d['deportes_extra'] as List<dynamic>?)
              ?.map((e) => '$e')
              .toList() ??
          [],
      categoriasInventarioExtra:
          (d['categorias_inventario_extra'] as List<dynamic>?)
                  ?.map((e) => '$e')
                  .toList() ??
              [],
      codigoValidezSegundos:
          (d['codigo_validez_segundos'] as num?)?.toInt() ?? 60,
      permitirRegistroAbierto:
          d['permitir_registro_abierto'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'deportes_extra': deportesExtra,
        'categorias_inventario_extra': categoriasInventarioExtra,
        'codigo_validez_segundos': codigoValidezSegundos,
        'permitir_registro_abierto': permitirRegistroAbierto,
        'actualizado_en': FieldValue.serverTimestamp(),
      };
}

/// Operaciones del panel de administración DTFly.
class AdminService {
  AdminService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _colUsuarios = 'usuarios';
  static const String _colAuditoria = 'admin_auditoria';
  static const String _colConfig = 'configuracion_sistema';
  static const String _colReportes = 'reportes_entrenador';
  static const String _colSolicitudes = 'solicitudes_compra_utilero';
  static const String _colPerfilAdmin = 'admin_perfiles';

  static DocumentReference<Map<String, dynamic>> refPerfilAdmin(String adminId) =>
      _db.collection(_colPerfilAdmin).doc(adminId);

  // ─── Perfil administrador ───────────────────────────────────

  static Future<void> asegurarPerfilAdmin({
    required String adminId,
    required String nombre,
    required String correo,
  }) async {
    final ref = refPerfilAdmin(adminId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.set(
        {'ultimo_acceso': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return;
    }
    final partes = nombre.trim().split(RegExp(r'\s+'));
    await ref.set({
      'nombre': partes.isNotEmpty ? partes.first : nombre,
      'apellido': partes.length > 1 ? partes.sublist(1).join(' ') : '',
      'correo': correo.trim().toLowerCase(),
      'telefono': '',
      'cargo': 'Administrador DTFly',
      'notif_email': true,
      'notif_sistema': true,
      'fecha_ingreso': FieldValue.serverTimestamp(),
      'ultimo_acceso': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: correo,
      accion: 'Inicio de sesión',
      detalle: 'Acceso al panel administrativo',
    );
  }

  static Stream<AdminPerfil> streamPerfilAdmin(String adminId) {
    return refPerfilAdmin(adminId).snapshots().asyncMap((perfilSnap) async {
      final usuarioSnap = await _db.collection(_colUsuarios).doc(adminId).get();
      return AdminPerfil.fromDocs(
        adminId: adminId,
        perfilData: perfilSnap.data(),
        usuarioData: usuarioSnap.data(),
      );
    });
  }

  static Future<void> guardarPerfilAdmin({
    required String adminId,
    required String adminEmail,
    required String nombre,
    required String apellido,
    required String telefono,
    String? cargo,
    String? institucion,
  }) async {
    final nombreCompleto = '$nombre $apellido'.trim();
    await refPerfilAdmin(adminId).set(
      {
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'telefono': telefono.trim(),
        if (cargo != null) 'cargo': cargo.trim(),
        if (institucion != null) 'institucion': institucion.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _db.collection(_colUsuarios).doc(adminId).set(
      {
        'nombre': nombreCompleto,
        'telefono': telefono.trim(),
        if (institucion != null) 'institucion': institucion.trim(),
        'perfil_actualizado_en': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Actualizar perfil',
      detalle: 'Datos personales del administrador',
      entidadTipo: 'admin_perfil',
      entidadId: adminId,
    );
  }

  static Future<String?> subirFotoPerfilAdmin({
    required String adminId,
    required String adminEmail,
    required Uint8List bytes,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('admin_perfiles/$adminId/foto_perfil.jpg');
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await storageRef.getDownloadURL();
    await refPerfilAdmin(adminId).set(
      {
        'foto_perfil': url,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Cambiar foto de perfil',
      detalle: adminId,
      entidadTipo: 'admin_perfil',
      entidadId: adminId,
    );
    return url;
  }

  static Future<void> guardarPreferenciasAdmin({
    required String adminId,
    required String adminEmail,
    required bool notifEmail,
    required bool notifSistema,
  }) async {
    await refPerfilAdmin(adminId).set(
      {
        'notif_email': notifEmail,
        'notif_sistema': notifSistema,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Actualizar preferencias',
      detalle: 'Notificaciones del administrador',
    );
  }

  static Future<void> cambiarContrasenaAdmin({
    required String adminId,
    required String adminEmail,
    required String actual,
    required String nueva,
  }) async {
    final snap = await _db.collection(_colUsuarios).doc(adminId).get();
    if (!snap.exists) throw StateError('Usuario no encontrado');
    final guardada = snap.data()?['password'] as String? ?? '';
    if (guardada != actual) {
      throw StateError('La contraseña actual no es correcta');
    }
    if (nueva.length < 4) {
      throw StateError('La nueva contraseña debe tener al menos 4 caracteres');
    }
    await _db.collection(_colUsuarios).doc(adminId).update({'password': nueva});
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Cambiar contraseña',
      detalle: 'Actualización de seguridad',
    );
  }

  static Stream<List<AdminAuditoriaRegistro>> streamAuditoriaAdmin({
    required String adminId,
    int limit = 25,
  }) {
    return _db
        .collection(_colAuditoria)
        .where('admin_id', isEqualTo: adminId)
        .limit(limit)
        .snapshots()
        .map((s) {
      final list = s.docs.map(AdminAuditoriaRegistro.fromDoc).toList();
      list.sort(
        (a, b) => (b.creadoEn ?? DateTime(2000))
            .compareTo(a.creadoEn ?? DateTime(2000)),
      );
      return list;
    });
  }

  // ─── Usuarios ───────────────────────────────────────────────

  static Stream<List<AdminUsuario>> streamUsuarios() {
    return _db.collection(_colUsuarios).snapshots().map((s) {
      final list = s.docs.map(AdminUsuario.fromDoc).toList();
      list.sort((a, b) => a.nombre.compareTo(b.nombre));
      return list;
    });
  }

  static List<AdminUsuario> filtrarUsuarios(
    List<AdminUsuario> lista, {
    String? query,
    String? rol,
    String? deporteId,
    bool? soloActivos,
  }) {
    final q = query?.trim().toLowerCase() ?? '';
    return lista.where((u) {
      if (rol != null && rol.isNotEmpty && u.rolNormalizado != rol) {
        return false;
      }
      if (deporteId != null &&
          deporteId.isNotEmpty &&
          u.deporteId != deporteId) {
        return false;
      }
      if (soloActivos == true && !u.activo) return false;
      if (soloActivos == false && u.activo) return false;
      if (q.isEmpty) return true;
      return u.nombre.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.rol.toLowerCase().contains(q) ||
          (u.deporteNombre ?? '').toLowerCase().contains(q);
    }).toList();
  }

  static Future<AdminUsuario?> obtenerUsuario(String id) async {
    final snap = await _db.collection(_colUsuarios).doc(id).get();
    if (!snap.exists) return null;
    return AdminUsuario.fromDoc(snap);
  }

  static Stream<AdminUsuario?> streamUsuario(String id) {
    return _db.collection(_colUsuarios).doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AdminUsuario.fromDoc(snap);
    });
  }

  static Future<void> actualizarUsuario({
    required String usuarioId,
    String? nombre,
    String? rol,
    bool? activo,
    String? deporteId,
    String? telefono,
    String? carrera,
    required String adminId,
    required String adminEmail,
  }) async {
    final data = <String, dynamic>{
      'actualizado_en': FieldValue.serverTimestamp(),
    };
    if (nombre != null) data['nombre'] = nombre.trim();
    if (rol != null) data['rol'] = rol;
    if (activo != null) data['activo'] = activo;
    if (telefono != null) data['telefono'] = telefono.trim();
    if (carrera != null) data['carrera'] = carrera.trim();
    if (deporteId != null) {
      data.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    await _db.collection(_colUsuarios).doc(usuarioId).update(data);
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Editar usuario',
      detalle: 'Usuario $usuarioId actualizado',
      entidadTipo: 'usuario',
      entidadId: usuarioId,
    );
  }

  static Future<void> bloquearUsuario({
    required String usuarioId,
    required bool bloquear,
    required String adminId,
    required String adminEmail,
  }) async {
    await _db.collection(_colUsuarios).doc(usuarioId).update({
      'activo': !bloquear,
      'bloqueado_en': bloquear ? FieldValue.serverTimestamp() : null,
    });
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: bloquear ? 'Bloquear usuario' : 'Desbloquear usuario',
      detalle: usuarioId,
      entidadTipo: 'usuario',
      entidadId: usuarioId,
    );
  }

  static Future<void> eliminarUsuario({
    required String usuarioId,
    required String adminId,
    required String adminEmail,
  }) async {
    await _db.collection(_colUsuarios).doc(usuarioId).delete();
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Eliminar usuario',
      detalle: usuarioId,
      entidadTipo: 'usuario',
      entidadId: usuarioId,
    );
  }

  // ─── Estadísticas ───────────────────────────────────────────

  static Future<AdminEstadisticasGlobales> cargarEstadisticas() async {
    final results = await Future.wait([
      _db.collection(_colUsuarios).get(),
      _db.collection('inventario').get(),
      InventarioService.streamPrestamosActivos().first,
      _db.collection('entrenamientos').get(),
      _db.collection('partidos').get(),
      _db.collection(_colSolicitudes).where('estado', isEqualTo: 'pendiente').get(),
      _db.collection(_colReportes).get(),
    ]);

    final usuarios = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final inventario = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final prestamos = results[2] as List<PrestamoMaterial>;
    final entrenamientos = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final partidos = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final solicitudes = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final reportes = results[6] as QuerySnapshot<Map<String, dynamic>>;

    var entrenadores = 0;
    var jugadores = 0;
    var utileros = 0;
    var administradores = 0;
    var activos = 0;

    for (final d in usuarios.docs) {
      final u = AdminUsuario.fromDoc(d);
      if (u.activo) activos++;
      switch (u.rolNormalizado) {
        case AppRoles.entrenador:
          entrenadores++;
        case AppRoles.jugador:
          jugadores++;
        case AppRoles.utilero:
          utileros++;
        case AppRoles.administrador:
          administradores++;
      }
    }

    var unidades = 0;
    var stockBajo = 0;
    var danados = 0;
    for (final d in inventario.docs) {
      final m = MaterialInventario.fromDoc(d);
      unidades += m.cantidadTotal;
      if (m.cantidadDisponible <= UtileroMaterialCat.umbralStockBajo) {
        stockBajo++;
      }
      danados += m.cantidadDanada;
    }

    var prestados = 0;
    for (final p in prestamos) {
      prestados += p.cantidad;
    }

    return AdminEstadisticasGlobales(
      totalUsuarios: usuarios.docs.length,
      usuariosActivos: activos,
      entrenadores: entrenadores,
      jugadores: jugadores,
      utileros: utileros,
      administradores: administradores,
      totalMateriales: inventario.docs.length,
      unidadesInventario: unidades,
      prestadosActivos: prestados,
      entrenamientos: entrenamientos.docs.length,
      partidos: partidos.docs.length,
      stockBajo: stockBajo,
      solicitudesPendientes: solicitudes.docs.length,
      materialesDanados: danados,
      reportesEntrenador: reportes.docs.length,
    );
  }

  // ─── Inventario admin ───────────────────────────────────────

  static Future<void> transferirMaterial({
    required String materialId,
    required String deporteDestinoId,
    required String adminId,
    required String adminEmail,
  }) async {
    await _db.collection('inventario').doc(materialId).update({
      ...DeporteUsuario.camposAlGuardar(deporteDestinoId),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Transferir material',
      detalle: '$materialId → ${DeportesCategoria.nombreVisible(deporteDestinoId)}',
      entidadTipo: 'material',
      entidadId: materialId,
    );
  }

  static Future<int> asignarStockInicialDeporte({
    required String deporteId,
    required String adminId,
    required String adminEmail,
  }) async {
    final n = await InventarioService.asignarDeporteMaterialesLegacy(
      deporteId: deporteId,
    );
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Asignar stock legacy',
      detalle: '$n materiales → ${DeportesCategoria.nombreVisible(deporteId)}',
    );
    return n;
  }

  static Future<void> responderSolicitud({
    required String solicitudId,
    required bool aprobar,
    required String respuesta,
    required String adminId,
    required String adminEmail,
  }) async {
    await _db.collection(_colSolicitudes).doc(solicitudId).update({
      'estado': aprobar ? 'aprobada' : 'rechazada',
      'respuesta': respuesta.trim(),
      'respondido_en': FieldValue.serverTimestamp(),
      'admin_id': adminId,
    });
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: aprobar ? 'Aprobar solicitud' : 'Rechazar solicitud',
      detalle: solicitudId,
      entidadTipo: 'solicitud',
      entidadId: solicitudId,
    );
  }

  static Stream<List<SolicitudCompraUtilero>> streamTodasSolicitudes() {
    return _db.collection(_colSolicitudes).limit(200).snapshots().map((s) {
      final list = s.docs.map(SolicitudCompraUtilero.fromDoc).toList();
      list.sort(
        (a, b) => (b.creadoEn ?? DateTime(2000))
            .compareTo(a.creadoEn ?? DateTime(2000)),
      );
      return list;
    });
  }

  // ─── Entrenamientos / partidos ────────────────────────────────

  static Stream<List<Entrenamiento>> streamEntrenamientos({int limit = 100}) {
    return _db
        .collection('entrenamientos')
        .orderBy('inicioProgramado', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Entrenamiento.fromDoc).toList());
  }

  static Stream<List<Partido>> streamPartidos({int limit = 100}) {
    return _db
        .collection('partidos')
        .orderBy('fechaHora', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Partido.fromDoc).toList());
  }

  static Future<List<AsistenciaRegistro>> asistenciasDeJugador(
    String jugadorId, {
    int limit = 40,
  }) async {
    final ents = await _db
        .collection('entrenamientos')
        .orderBy('inicioProgramado', descending: true)
        .limit(limit)
        .get();
    final list = <AsistenciaRegistro>[];
    for (final e in ents.docs) {
      final a = await e.reference.collection('asistencias').doc(jugadorId).get();
      if (!a.exists) continue;
      final reg = AsistenciaRegistro.fromDoc(a);
      list.add(reg);
    }
    return list;
  }

  // ─── Reportes ─────────────────────────────────────────────────

  static Stream<List<AdminReporteItem>> streamReportes() {
    return _db.collection(_colReportes).limit(100).snapshots().map((s) {
      final list = s.docs.map((d) {
        final data = d.data();
        return AdminReporteItem(
          id: d.id,
          titulo: data['titulo'] as String? ?? 'Sin título',
          origen: 'Entrenador',
          email: data['entrenadorEmail'] as String? ?? '',
          contenido: data['contenido'] as String?,
          nombreArchivo: data['nombreArchivo'] as String?,
          creadoEn: (data['creadoEn'] as Timestamp?)?.toDate(),
          deporte: data['deporte'] as String?,
        );
      }).toList();
      list.sort(
        (a, b) => (b.creadoEn ?? DateTime(2000))
            .compareTo(a.creadoEn ?? DateTime(2000)),
      );
      return list;
    });
  }

  // ─── Búsqueda global ────────────────────────────────────────

  static Future<List<AdminBusquedaResultado>> busquedaGlobal(
    String query, {
    AdminBusquedaTipo? tipoFiltro,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    final resultados = <AdminBusquedaResultado>[];

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.usuario) {
      final users = await _db.collection(_colUsuarios).limit(300).get();
      for (final d in users.docs) {
        final u = AdminUsuario.fromDoc(d);
        final blob =
            '${u.nombre} ${u.email} ${u.rol} ${u.deporteNombre ?? ''}'
                .toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.usuario,
              id: u.id,
              titulo: u.nombre,
              subtitulo: '${u.rol} · ${u.email}',
              extra: u.deporteNombre,
            ),
          );
        }
      }
    }

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.material) {
      final mats = await _db.collection('inventario').limit(300).get();
      for (final d in mats.docs) {
        final m = MaterialInventario.fromDoc(d);
        final blob = '${m.nombre} ${m.categoria}'.toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.material,
              id: m.id,
              titulo: m.nombre,
              subtitulo: '${m.categoria} · ${m.cantidadDisponible} disp.',
              extra: m.deporteNombre,
            ),
          );
        }
      }
    }

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.prestamo) {
      final prest = await _db
          .collection('prestamos_inventario')
          .orderBy('prestadoEn', descending: true)
          .limit(100)
          .get();
      for (final d in prest.docs) {
        final p = PrestamoMaterial.fromDoc(d);
        final blob = '${p.materialNombre} ${p.prestadoA}'.toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.prestamo,
              id: p.id,
              titulo: p.materialNombre,
              subtitulo: '${p.prestadoA} · ${p.cantidad} uds.',
              extra: p.devuelto ? 'Devuelto' : 'Activo',
            ),
          );
        }
      }
    }

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.entrenamiento) {
      final ents = await _db
          .collection('entrenamientos')
          .orderBy('inicioProgramado', descending: true)
          .limit(80)
          .get();
      for (final d in ents.docs) {
        final e = Entrenamiento.fromDoc(d);
        final blob = '${e.titulo} ${e.cancha} ${e.entrenadorEmail}'.toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.entrenamiento,
              id: e.id,
              titulo: e.titulo,
              subtitulo: '${e.cancha} · ${e.estado}',
              extra: e.entrenadorEmail,
            ),
          );
        }
      }
    }

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.partido) {
      final parts = await _db
          .collection('partidos')
          .orderBy('fechaHora', descending: true)
          .limit(80)
          .get();
      for (final d in parts.docs) {
        final p = Partido.fromDoc(d);
        final blob = '${p.rival} ${p.lugar} ${p.entrenadorEmail}'.toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.partido,
              id: p.id,
              titulo: 'vs ${p.rival}',
              subtitulo: p.lugar,
              extra: p.estado,
            ),
          );
        }
      }
    }

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.reporte) {
      final reps = await _db.collection(_colReportes).limit(80).get();
      for (final d in reps.docs) {
        final data = d.data();
        final titulo = data['titulo'] as String? ?? '';
        final blob = '$titulo ${data['entrenadorEmail'] ?? ''}'.toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.reporte,
              id: d.id,
              titulo: titulo,
              subtitulo: data['entrenadorEmail'] as String? ?? '',
            ),
          );
        }
      }
    }

    if (tipoFiltro == null || tipoFiltro == AdminBusquedaTipo.solicitud) {
      final sols = await _db.collection(_colSolicitudes).limit(80).get();
      for (final d in sols.docs) {
        final s = SolicitudCompraUtilero.fromDoc(d);
        final blob = '${s.materialNombre} ${s.motivo} ${s.estado}'.toLowerCase();
        if (blob.contains(q)) {
          resultados.add(
            AdminBusquedaResultado(
              tipo: AdminBusquedaTipo.solicitud,
              id: s.id,
              titulo: s.materialNombre,
              subtitulo: '${s.estado} · ${s.cantidad} uds.',
            ),
          );
        }
      }
    }

    return resultados.take(50).toList();
  }

  static Stream<List<PrestamoMaterial>> streamTodosPrestamos({int limit = 200}) {
    return _db.collection('prestamos_inventario').limit(limit).snapshots().map(
      (s) {
        final list = s.docs.map(PrestamoMaterial.fromDoc).toList();
        list.sort((a, b) => b.prestadoEn.compareTo(a.prestadoEn));
        return list;
      },
    );
  }

  // ─── Configuración ──────────────────────────────────────────

  static Stream<AdminConfiguracionSistema> streamConfiguracion() {
    return _db.collection(_colConfig).doc('global').snapshots().map((s) {
      return AdminConfiguracionSistema.fromMap(s.data());
    });
  }

  static Future<void> guardarConfiguracion(
    AdminConfiguracionSistema config, {
    required String adminId,
    required String adminEmail,
  }) async {
    await _db.collection(_colConfig).doc('global').set(
          config.toMap(),
          SetOptions(merge: true),
        );
    await registrarAuditoria(
      adminId: adminId,
      adminEmail: adminEmail,
      accion: 'Actualizar configuración',
      detalle: 'Sistema global',
    );
  }

  // ─── Auditoría ──────────────────────────────────────────────

  static Future<void> registrarAuditoria({
    required String adminId,
    required String adminEmail,
    required String accion,
    required String detalle,
    String? entidadTipo,
    String? entidadId,
  }) async {
    await _db.collection(_colAuditoria).add({
      'admin_id': adminId,
      'admin_email': adminEmail,
      'accion': accion,
      'detalle': detalle,
      'entidad_tipo': entidadTipo,
      'entidad_id': entidadId,
      'creado_en': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<AdminAuditoriaRegistro>> streamAuditoria({int limit = 80}) {
    return _db.collection(_colAuditoria).limit(limit).snapshots().map((s) {
      final list = s.docs.map(AdminAuditoriaRegistro.fromDoc).toList();
      list.sort(
        (a, b) => (b.creadoEn ?? DateTime(2000))
            .compareTo(a.creadoEn ?? DateTime(2000)),
      );
      return list;
    });
  }

  // ─── Exportaciones ──────────────────────────────────────────

  static Future<String?> exportarUsuariosCsv(List<AdminUsuario> usuarios) {
    final sb = StringBuffer();
    sb.writeln('ID,Nombre,Email,Rol,Deporte,Activo');
    for (final u in usuarios) {
      sb.writeln(
        '${u.id},"${u.nombre}","${u.email}",${u.rol},'
        '"${u.deporteNombre ?? ''}",${u.activo}',
      );
    }
    return guardarArchivoReporte(
      'usuarios_dtfly_${DateTime.now().millisecondsSinceEpoch}.csv',
      sb.toString(),
    );
  }

  static Future<String?> exportarInventarioCsv(
    List<MaterialInventario> materiales,
  ) {
    final sb = StringBuffer();
    sb.writeln('ID,Nombre,Categoria,Disponible,Total,Danado,Deporte');
    for (final m in materiales) {
      sb.writeln(
        '${m.id},"${m.nombre}",${m.categoria},'
        '${m.cantidadDisponible},${m.cantidadTotal},'
        '${m.cantidadDanada},"${m.deporteNombre ?? ''}"',
      );
    }
    return guardarArchivoReporte(
      'inventario_dtfly_${DateTime.now().millisecondsSinceEpoch}.csv',
      sb.toString(),
    );
  }

  static Future<String?> exportarPrestamosCsv(
    List<PrestamoMaterial> prestamos,
  ) {
    final sb = StringBuffer();
    sb.writeln('ID,Material,Cantidad,PrestadoA,Email,Fecha,Devuelto');
    for (final p in prestamos) {
      sb.writeln(
        '${p.id},"${p.materialNombre}",${p.cantidad},'
        '"${p.prestadoA}","${p.entrenadorEmail}",'
        '${p.prestadoEn.toIso8601String()},${p.devuelto}',
      );
    }
    return guardarArchivoReporte(
      'prestamos_dtfly_${DateTime.now().millisecondsSinceEpoch}.csv',
      sb.toString(),
    );
  }

  static Future<String?> descargarReporte(AdminReporteItem reporte) {
    final contenido = reporte.contenido ?? '';
    final nombre = reporte.nombreArchivo ??
        'reporte_${reporte.id}.txt';
    return guardarArchivoReporte(nombre, contenido);
  }
}
