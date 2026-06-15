import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_application_1/core/deporte_usuario.dart';
import 'package:flutter_application_1/models/actividad_utilero.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/models/notificacion_utilero.dart';
import 'package:flutter_application_1/models/utilero_modulos.dart';
import 'package:flutter_application_1/models/utilero_perfil.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/reportes_file_writer.dart';
import 'package:flutter_application_1/services/reportes_service.dart';

class UtileroResumenDashboard {
  const UtileroResumenDashboard({
    required this.materialesRegistrados,
    required this.materialesEntregados,
    required this.materialesDevueltos,
    required this.stockBajo,
    required this.materialesDanados,
    required this.entrenamientosSemana,
    required this.entregadosHoy,
    required this.devueltosHoy,
    required this.stockPorCategoria,
    required this.prestamosPendientes,
    required this.ultimasActividades,
  });

  final int materialesRegistrados;
  final int materialesEntregados;
  final int materialesDevueltos;
  final int stockBajo;
  final int materialesDanados;
  final int entrenamientosSemana;
  final int entregadosHoy;
  final int devueltosHoy;
  final Map<String, int> stockPorCategoria;
  final int prestamosPendientes;
  final List<ActividadUtilero> ultimasActividades;
}

class UtileroEstadisticas {
  const UtileroEstadisticas({
    required this.totalMovimientos,
    required this.promedioSemanal,
    required this.materialMayorRotacion,
    required this.masUtilizado,
    required this.masEntregado,
    required this.masDevuelto,
    required this.movimientoSemanal,
    required this.movimientoMensual,
  });

  final int totalMovimientos;
  final double promedioSemanal;
  final String materialMayorRotacion;
  final Map<String, int> masUtilizado;
  final Map<String, int> masEntregado;
  final Map<String, int> masDevuelto;
  final Map<String, int> movimientoSemanal;
  final Map<String, int> movimientoMensual;
}

class UtileroService {
  UtileroService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _colPerfil = 'utileros';
  static const String _colActividad = 'actividad_utilero';
  static const String _colNotif = 'notificaciones_utilero';
  static const String _colSolicitudes = 'solicitudes_compra_utilero';
  static const String _colChecklist = 'checklist_utilero';
  static const String _colInventarioFisico = 'inventario_fisico_utilero';
  static const String _colEmails = 'emails_utilero';
  static const int _umbralStockBajo = 2;

  static DocumentReference<Map<String, dynamic>> refPerfil(String usuarioId) =>
      _db.collection(_colPerfil).doc(usuarioId);

  static Future<void> asegurarPerfil({
    required String usuarioId,
    required String nombre,
    required String correo,
  }) async {
    final ref = refPerfil(usuarioId);
    final snap = await ref.get();
    if (snap.exists) return;

    final partes = nombre.trim().split(RegExp(r'\s+'));
    final nombreP = partes.isNotEmpty ? partes.first : nombre;
    final apellidoP =
        partes.length > 1 ? partes.sublist(1).join(' ') : '';

    await ref.set({
      'nombre': nombreP,
      'apellido': apellidoP,
      'correo': correo.trim().toLowerCase(),
      'telefono': '',
      'foto_perfil': null,
      'cargo': 'Utilero',
      'fecha_ingreso': FieldValue.serverTimestamp(),
      'estado': 'Activo',
      'notif_email': true,
      'notif_sistema': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Stream<UtileroPerfil> streamPerfil(String usuarioId) {
    return refPerfil(usuarioId).snapshots().asyncMap((s) async {
      final usuarioSnap = await _db.collection('usuarios').doc(usuarioId).get();
      final datosUsuario = usuarioSnap.data();
      if (!s.exists) {
        return UtileroPerfil(
          id: usuarioId,
          nombre: '',
          apellido: '',
          correo: '',
          telefono: '',
          fotoPerfil: null,
          cargo: 'Utilero',
          fechaIngreso: null,
          estado: 'Activo',
          notifEmail: true,
          notifSistema: true,
          deporteId: datosUsuario != null
              ? DeporteUsuario.idDesde(datosUsuario)
              : null,
          deporteNombre: datosUsuario != null
              ? DeporteUsuario.nombreDesde(datosUsuario)
              : null,
        );
      }
      return UtileroPerfil.fromDoc(s, datosUsuario: datosUsuario);
    });
  }

  static Future<void> guardarDeporteSeleccion({
    required String usuarioId,
    required String deporteId,
  }) async {
    final campos = DeporteUsuario.camposAlGuardar(deporteId);
    await refPerfil(usuarioId).set(
      {
        ...campos,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _db.collection('usuarios').doc(usuarioId).set(
      campos,
      SetOptions(merge: true),
    );
    await registrarActividad(
      utileroId: usuarioId,
      accion: 'Actualizó selección',
      descripcion: DeporteUsuario.nombreDesde(campos),
      material: '—',
    );
  }

  static Future<void> guardarPerfil({
    required String usuarioId,
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    String? estado,
    String? deporteId,
    String? turno,
    String? horarioInicio,
    String? horarioFin,
    String? bodegaPrincipal,
    String? institucion,
  }) async {
    final payload = <String, dynamic>{
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'correo': correo.trim().toLowerCase(),
      'telefono': telefono.trim(),
      if (estado != null) 'estado': estado,
      if (turno != null) 'turno': turno.trim(),
      if (horarioInicio != null) 'horario_inicio': horarioInicio.trim(),
      if (horarioFin != null) 'horario_fin': horarioFin.trim(),
      if (bodegaPrincipal != null) 'bodega_principal': bodegaPrincipal.trim(),
      if (institucion != null) 'institucion': institucion.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (deporteId != null && deporteId.isNotEmpty) {
      payload.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    await refPerfil(usuarioId).set(payload, SetOptions(merge: true));

    final usuarioPayload = <String, dynamic>{
      'nombre': '$nombre $apellido'.trim(),
      'email': correo.trim().toLowerCase(),
      'telefono': telefono.trim(),
    };
    if (deporteId != null && deporteId.isNotEmpty) {
      usuarioPayload.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    await _db.collection('usuarios').doc(usuarioId).set(
      usuarioPayload,
      SetOptions(merge: true),
    );
    await registrarActividad(
      utileroId: usuarioId,
      accion: 'Actualizó perfil',
      descripcion: 'Datos personales modificados',
      material: '—',
      cantidad: 0,
      estado: 'Completado',
    );
  }

  static Future<String?> subirFotoPerfil({
    required String usuarioId,
    required Uint8List bytes,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('utileros/$usuarioId/foto_perfil.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await refPerfil(usuarioId).set(
      {'foto_perfil': url, 'updated_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await registrarActividad(
      utileroId: usuarioId,
      accion: 'Cambió foto',
      descripcion: 'Foto de perfil actualizada',
    );
    return url;
  }

  static Future<void> cambiarContrasena({
    required String usuarioId,
    required String actual,
    required String nueva,
  }) async {
    final snap = await _db.collection('usuarios').doc(usuarioId).get();
    if (!snap.exists) throw StateError('Usuario no encontrado');
    final guardada = snap.data()?['password'] as String? ?? '';
    if (guardada != actual) {
      throw StateError('La contraseña actual no es correcta');
    }
    if (nueva.length < 4) {
      throw StateError('La nueva contraseña debe tener al menos 4 caracteres');
    }
    await _db.collection('usuarios').doc(usuarioId).update({'password': nueva});
    await registrarActividad(
      utileroId: usuarioId,
      accion: 'Cambió contraseña',
      descripcion: 'Actualización de seguridad',
    );
  }

  static Future<void> guardarPreferenciasNotificacion({
    required String usuarioId,
    required bool email,
    required bool sistema,
  }) async {
    await refPerfil(usuarioId).set(
      {
        'notif_email': email,
        'notif_sistema': sistema,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> registrarActividad({
    required String utileroId,
    required String accion,
    required String descripcion,
    String material = '—',
    int cantidad = 0,
    String estado = 'Completado',
  }) async {
    final ahora = DateTime.now();
    await _db.collection(_colActividad).add({
      'utilero_id': utileroId,
      'accion': accion,
      'descripcion': descripcion,
      'material': material,
      'cantidad': cantidad,
      'estado': estado,
      'fecha': Timestamp.fromDate(ahora),
      'hora': '${ahora.hour.toString().padLeft(2, '0')}:'
          '${ahora.minute.toString().padLeft(2, '0')}',
      'ip': kIsWeb ? 'web' : 'app',
    });
  }

  static Future<void> registrarAuditoriaSesion({
    required String utileroId,
    required bool esInicio,
  }) async {
    await registrarActividad(
      utileroId: utileroId,
      accion: esInicio ? 'Inicio de sesión' : 'Cierre de sesión',
      descripcion: esInicio
          ? 'Acceso a la plataforma DTFly'
          : 'Salida de la plataforma',
    );
  }

  static Stream<List<ActividadUtilero>> streamActividad(
    String utileroId, {
    int limite = 100,
  }) {
    return _db
        .collection(_colActividad)
        .where('utilero_id', isEqualTo: utileroId)
        .orderBy('fecha', descending: true)
        .limit(limite)
        .snapshots()
        .map((s) => s.docs.map(ActividadUtilero.fromDoc).toList());
  }

  static Stream<List<NotificacionUtilero>> streamNotificaciones(
    String utileroId,
  ) {
    return _db
        .collection(_colNotif)
        .where('utilero_id', isEqualTo: utileroId)
        .orderBy('fecha', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(NotificacionUtilero.fromDoc).toList());
  }

  static Future<void> crearNotificacion({
    required String utileroId,
    required String titulo,
    required String mensaje,
    required String tipo,
  }) async {
    await _db.collection(_colNotif).add({
      'utilero_id': utileroId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'leida': false,
      'fecha': FieldValue.serverTimestamp(),
    });
    await _enviarEmailAlertaSiActivo(
      utileroId: utileroId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
    );
  }

  /// Encola un correo en Firestore; Cloud Functions lo envía por SMTP.
  static Future<void> encolarEmail({
    required String para,
    required String asunto,
    required String cuerpo,
    required String utileroId,
    required String tipo,
    String? html,
  }) async {
    final destino = para.trim().toLowerCase();
    if (destino.isEmpty || !destino.contains('@')) return;
    await _db.collection(_colEmails).add({
      'para': destino,
      'asunto': asunto.trim(),
      'cuerpo': cuerpo.trim(),
      if (html != null && html.isNotEmpty) 'html': html,
      'utilero_id': utileroId,
      'tipo': tipo,
      'estado': 'pendiente',
      'creado_en': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _enviarEmailAlertaSiActivo({
    required String utileroId,
    required String titulo,
    required String mensaje,
    required String tipo,
  }) async {
    try {
      final perfil = await streamPerfil(utileroId).first;
      if (!perfil.notifEmail) return;
      final correo = perfil.correo.trim();
      if (correo.isEmpty || !correo.contains('@')) return;

      final html = '''
<html><body style="font-family:sans-serif;padding:20px">
<h2 style="color:#C62828">DTFly — Alerta utilero</h2>
<p><strong>${_escHtml(titulo)}</strong></p>
<p>${_escHtml(mensaje)}</p>
<hr>
<p style="font-size:12px;color:#666">Tipo: ${_escHtml(tipo)} · Selección: ${_escHtml(perfil.deporteNombre ?? "—")}</p>
</body></html>''';

      await encolarEmail(
        para: correo,
        asunto: 'DTFly: $titulo',
        cuerpo: '$titulo\n\n$mensaje\n\n— DTFly Utilero',
        html: html,
        utileroId: utileroId,
        tipo: tipo,
      );
    } catch (_) {
      // No bloquear notificaciones in-app si falla el correo.
    }
  }

  static String _escHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static Future<void> marcarNotificacionLeida(String id) async {
    await _db.collection(_colNotif).doc(id).update({'leida': true});
  }

  static Future<void> marcarTodasLeidas(String utileroId) async {
    final snap = await _db
        .collection(_colNotif)
        .where('utilero_id', isEqualTo: utileroId)
        .where('leida', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'leida': true});
    }
    await batch.commit();
  }

  static Future<void> eliminarNotificacion(String id) async {
    await _db.collection(_colNotif).doc(id).delete();
  }

  static Future<void> sincronizarAlertasInventario(
    String utileroId, {
    String? deporteId,
  }) async {
    final mats =
        await InventarioService.streamMaterialesDeporte(deporteId).first;
    for (final m in mats) {
      if (m.cantidadDisponible <= _umbralStockBajo) {
        await _notificarSiNoExiste(
          utileroId: utileroId,
          tipo: 'stock_bajo',
          titulo: 'Stock bajo',
          mensaje: '${m.nombre}: quedan ${m.cantidadDisponible} ${m.unidad}',
        );
      }
      if (m.tieneDanados) {
        await _notificarSiNoExiste(
          utileroId: utileroId,
          tipo: 'material_danado',
          titulo: 'Material dañado',
          mensaje: '${m.nombre}: ${m.cantidadDanada} ${m.unidad} dañada(s)',
        );
      }
    }
    final prestamos = await InventarioService.streamPrestamosActivos().first;
    for (final p in prestamos) {
      await _notificarSiNoExiste(
        utileroId: utileroId,
        tipo: 'devolucion_pendiente',
        titulo: 'Devolución pendiente',
        mensaje: '${p.materialNombre} entregado a ${p.prestadoA}',
      );
    }
    final inicioSemana = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final entSnap = await _db
        .collection('entrenamientos')
        .where('inicioProgramado',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day),
            ))
        .limit(5)
        .get();
    if (entSnap.docs.isNotEmpty) {
      await _notificarSiNoExiste(
        utileroId: utileroId,
        tipo: 'entrenamiento',
        titulo: 'Entrenamientos programados',
        mensaje: '${entSnap.docs.length} sesión(es) esta semana',
      );
    }
  }

  static Future<void> _notificarSiNoExiste({
    required String utileroId,
    required String tipo,
    required String titulo,
    required String mensaje,
  }) async {
    final existente = await _db
        .collection(_colNotif)
        .where('utilero_id', isEqualTo: utileroId)
        .where('tipo', isEqualTo: tipo)
        .where('leida', isEqualTo: false)
        .limit(1)
        .get();
    if (existente.docs.isNotEmpty) return;
    await crearNotificacion(
      utileroId: utileroId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
    );
  }

  static Future<UtileroResumenDashboard> cargarResumen(
    String utileroId, {
    String? deporteId,
  }) async {
    final mats =
        await InventarioService.streamMaterialesDeporte(deporteId).first;
    final prestamosActivos =
        await InventarioService.streamPrestamosActivos().first;
    final historial = await InventarioService.streamHistorialPrestamos().first;

    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));

    var entregadosHoy = 0;
    var devueltosHoy = 0;
    var entregadosTotal = 0;
    var devueltosTotal = 0;

    for (final p in historial) {
      if (!p.prestadoEn.isBefore(inicioHoy)) entregadosHoy += p.cantidad;
      entregadosTotal += p.cantidad;
      if (p.devuelto && p.devueltoEn != null) {
        if (!p.devueltoEn!.isBefore(inicioHoy)) devueltosHoy += p.cantidad;
        devueltosTotal += p.cantidad;
      }
    }

    final matIds = mats.map((m) => m.id).toSet();
    final prestamosDeporte = prestamosActivos
        .where((p) => matIds.contains(p.materialId))
        .toList();

    final stockPorCategoria = <String, int>{};
    var stockBajo = 0;
    var unidadesDanadas = 0;
    for (final m in mats) {
      final key = _normalizarCategoria(m.categoria, m.nombre);
      stockPorCategoria[key] =
          (stockPorCategoria[key] ?? 0) + m.cantidadDisponible;
      if (m.cantidadDisponible <= _umbralStockBajo) stockBajo++;
      unidadesDanadas += m.cantidadDanada;
    }

    final entrenamientosSemana = await _db
        .collection('entrenamientos')
        .where('inicioProgramado',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day),
            ))
        .get()
        .then((s) => s.docs.length);

    final actividades = await streamActividad(utileroId, limite: 5).first;

    return UtileroResumenDashboard(
      materialesRegistrados: mats.length,
      materialesEntregados: entregadosTotal,
      materialesDevueltos: devueltosTotal,
      stockBajo: stockBajo,
      materialesDanados: unidadesDanadas,
      entrenamientosSemana: entrenamientosSemana,
      entregadosHoy: entregadosHoy,
      devueltosHoy: devueltosHoy,
      stockPorCategoria: stockPorCategoria,
      prestamosPendientes: prestamosDeporte.length,
      ultimasActividades: actividades,
    );
  }

  static String _normalizarCategoria(String categoria, String nombre) {
    final c = categoria.toLowerCase();
    final n = nombre.toLowerCase();
    if (c.contains('balon') || n.contains('balon')) return 'Balones';
    if (c.contains('cono') || n.contains('cono')) return 'Conos';
    if (c.contains('polera') || c.contains('camiseta') || n.contains('polera')) {
      return 'Poleras';
    }
    if (c.contains('peto') || n.contains('peto')) return 'Petos';
    if (c.contains('valla') || n.contains('valla')) return 'Vallas';
    if (n.contains('lenteja')) return 'Lentejas';
    return categoria.isEmpty ? nombre : categoria;
  }

  static Future<UtileroEstadisticas> cargarEstadisticas(String utileroId) async {
    final snap = await _db
        .collection(_colActividad)
        .where('utilero_id', isEqualTo: utileroId)
        .orderBy('fecha', descending: true)
        .limit(200)
        .get();
    final acts = snap.docs.map(ActividadUtilero.fromDoc).toList();

    final masUtilizado = <String, int>{};
    final masEntregado = <String, int>{};
    final masDevuelto = <String, int>{};
    final movSemanal = <String, int>{};
    final movMensual = <String, int>{};

    final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    for (final d in dias) {
      movSemanal[d] = 0;
    }

    for (final a in acts) {
      final mat = a.material;
      if (mat != '—') {
        masUtilizado[mat] = (masUtilizado[mat] ?? 0) + 1;
      }
      if (a.accion.contains('Entreg')) {
        masEntregado[mat] = (masEntregado[mat] ?? 0) + a.cantidad;
      }
      if (a.accion.contains('devoluc') || a.accion.contains('Devolv')) {
        masDevuelto[mat] = (masDevuelto[mat] ?? 0) + a.cantidad;
      }
      final dia = dias[(a.fecha.weekday - 1).clamp(0, 6)];
      movSemanal[dia] = (movSemanal[dia] ?? 0) + 1;
      final mes = '${a.fecha.month}/${a.fecha.year}';
      movMensual[mes] = (movMensual[mes] ?? 0) + 1;
    }

    String rotacion = '—';
    var maxR = 0;
    masUtilizado.forEach((k, v) {
      if (v > maxR) {
        maxR = v;
        rotacion = k;
      }
    });

    final semanas = acts.isEmpty
        ? 1.0
        : (DateTime.now()
                    .difference(acts.last.fecha)
                    .inDays
                    .clamp(1, 365) /
                7)
            .ceil()
            .toDouble();

    return UtileroEstadisticas(
      totalMovimientos: acts.length,
      promedioSemanal: acts.length / semanas,
      materialMayorRotacion: rotacion,
      masUtilizado: masUtilizado,
      masEntregado: masEntregado,
      masDevuelto: masDevuelto,
      movimientoSemanal: movSemanal,
      movimientoMensual: movMensual,
    );
  }

  static Future<ReporteArchivo> exportarHistorialExcel({
    required String utileroId,
    required List<ActividadUtilero> filas,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Fecha\tAcción\tMaterial\tCantidad\tEstado\tDescripción');
    for (final a in filas) {
      buffer.writeln(
        '${_fmtFecha(a.fecha)}\t${a.accion}\t${a.material}\t'
        '${a.cantidad}\t${a.estado}\t${a.descripcion}',
      );
    }
    final nombre = 'historial_utilero_${_slugFecha(DateTime.now())}.xls';
    final ruta = await guardarArchivoReporte(nombre, buffer.toString());
    return ReporteArchivo(
      nombreArchivo: nombre,
      rutaArchivo: ruta,
      entrenamientoTitulo: 'Historial utilero',
      total: filas.length,
      totalEntrenamientos: 0,
      presentes: 0,
      atrasados: 0,
      ausentes: 0,
    );
  }

  static Future<ReporteArchivo> exportarHistorialPdf({
    required UtileroPerfil perfil,
    required List<ActividadUtilero> filas,
  }) async {
    final rows = filas
        .map(
          (a) =>
              '<tr><td>${_fmtFecha(a.fecha)}</td><td>${a.accion}</td>'
              '<td>${a.material}</td><td>${a.cantidad}</td>'
              '<td>${a.estado}</td></tr>',
        )
        .join();
    final html = '''
<html><head><meta charset="utf-8"><title>Historial Utilero</title></head>
<body style="font-family:sans-serif;padding:24px">
<h1>Historial de actividad — ${perfil.nombreCompleto}</h1>
<p>Cargo: ${perfil.cargo} · ${perfil.correo}</p>
<table border="1" cellpadding="8" cellspacing="0" width="100%">
<tr><th>Fecha</th><th>Acción</th><th>Material</th><th>Cant.</th><th>Estado</th></tr>
$rows
</table></body></html>''';
    final nombre = 'historial_utilero_${_slugFecha(DateTime.now())}.html';
    final ruta = await guardarArchivoReporte(nombre, html);
    return ReporteArchivo(
      nombreArchivo: nombre,
      rutaArchivo: ruta,
      entrenamientoTitulo: 'Historial utilero',
      total: filas.length,
      totalEntrenamientos: 0,
      presentes: 0,
      atrasados: 0,
      ausentes: 0,
    );
  }

  static Future<ReporteArchivo> generarReportePersonal({
    required String utileroId,
    required UtileroPerfil perfil,
    required String periodo,
    String? deporteId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final ahora = DateTime.now();
    final inicio = desde ?? _inicioPeriodo(periodo, ahora);
    final fin = hasta ?? ahora;

    final resumen = await cargarResumen(utileroId, deporteId: deporteId);
    final acts = await _actividadEnRango(utileroId, inicio, fin);
    final stats = await cargarEstadisticas(utileroId);

    final buffer = StringBuffer()
      ..writeln('REPORTE $periodo — UTILERO DTFly')
      ..writeln('Generado: ${_fmtFecha(ahora)}')
      ..writeln('Periodo: ${_fmtFecha(inicio)} — ${_fmtFecha(fin)}')
      ..writeln('Nombre: ${perfil.nombreCompleto}')
      ..writeln('Correo: ${perfil.correo}')
      ..writeln('Teléfono: ${perfil.telefono}')
      ..writeln('Turno: ${perfil.turno ?? "—"}')
      ..writeln('Bodega: ${perfil.bodegaPrincipal ?? "—"}')
      ..writeln('Selección: ${perfil.deporteNombre ?? "—"}')
      ..writeln('')
      ..writeln('=== RESUMEN INVENTARIO ===')
      ..writeln('Materiales registrados: ${resumen.materialesRegistrados}')
      ..writeln('Stock bajo: ${resumen.stockBajo}')
      ..writeln('Unidades dañadas: ${resumen.materialesDanados}')
      ..writeln('Préstamos pendientes: ${resumen.prestamosPendientes}')
      ..writeln('Entregados hoy: ${resumen.entregadosHoy}')
      ..writeln('Devueltos hoy: ${resumen.devueltosHoy}')
      ..writeln('')
      ..writeln('=== MOVIMIENTOS EN PERIODO (${acts.length}) ===');
    for (final a in acts.take(80)) {
      buffer.writeln(
        '${_fmtFecha(a.fecha)} '
        '${a.fecha.hour.toString().padLeft(2, "0")}:'
        '${a.fecha.minute.toString().padLeft(2, "0")} · ${a.accion} · '
        '${a.material} x${a.cantidad} · ${a.descripcion}',
      );
    }
    buffer
      ..writeln('')
      ..writeln('Total movimientos histórico: ${stats.totalMovimientos}')
      ..writeln(
        'Material mayor rotación: ${stats.materialMayorRotacion}',
      );

    final nombre =
        'reporte_utilero_${periodo.toLowerCase()}_${_slugFecha(ahora)}.txt';
    final ruta = await guardarArchivoReporte(nombre, buffer.toString());
    return ReporteArchivo(
      nombreArchivo: nombre,
      rutaArchivo: ruta,
      entrenamientoTitulo: 'Reporte $periodo',
      total: acts.length,
      totalEntrenamientos: resumen.entrenamientosSemana,
      presentes: resumen.materialesEntregados,
      atrasados: resumen.prestamosPendientes,
      ausentes: resumen.stockBajo,
    );
  }

  static DateTime _inicioPeriodo(String periodo, DateTime ref) {
    switch (periodo.toUpperCase()) {
      case 'MENSUAL':
        return DateTime(ref.year, ref.month, 1);
      case 'ANUAL':
        return DateTime(ref.year, 1, 1);
      default:
        return ref.subtract(Duration(days: ref.weekday - 1));
    }
  }

  static Future<List<ActividadUtilero>> _actividadEnRango(
    String utileroId,
    DateTime desde,
    DateTime hasta,
  ) async {
    final finDia = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59);
    final all = await streamActividad(utileroId, limite: 300).first;
    return all
        .where(
          (a) => !a.fecha.isBefore(desde) && !a.fecha.isAfter(finDia),
        )
        .toList();
  }

  static Stream<List<Entrenamiento>> streamEntrenamientosDeporte({
    String? deporteId,
    int dias = 14,
  }) {
    final inicio = DateTime.now().subtract(const Duration(days: 1));
    final fin = DateTime.now().add(Duration(days: dias));
    return _db
        .collection('entrenamientos')
        .where(
          'inicioProgramado',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .snapshots()
        .asyncMap((s) async {
      final coachCache = <String, String?>{};
      final list = <Entrenamiento>[];

      for (final doc in s.docs) {
        final data = doc.data();
        final ent = Entrenamiento.fromDoc(doc);
        if (ent.inicioProgramado.isAfter(fin)) continue;

        if (deporteId == null || deporteId.isEmpty) {
          list.add(ent);
          continue;
        }

        var depEnt = DeporteUsuario.idDesde(data);
        if (depEnt == null || depEnt.isEmpty) {
          final coachId = data['entrenadorUsuarioId'] as String? ?? '';
          if (coachId.isNotEmpty) {
            if (coachCache.containsKey(coachId)) {
              depEnt = coachCache[coachId];
            } else {
              final u = await _db.collection('usuarios').doc(coachId).get();
              depEnt = u.exists
                  ? DeporteUsuario.idDesde(u.data() ?? {})
                  : null;
              coachCache[coachId] = depEnt;
            }
          }
        }
        if (depEnt == deporteId) list.add(ent);
      }

      list.sort((a, b) => a.inicioProgramado.compareTo(b.inicioProgramado));
      return list;
    });
  }

  static Future<List<UtileroContactoDt>> listarContactosDt({
    String? deporteId,
  }) async {
    final snap = await _db
        .collection('usuarios')
        .where('rol', whereIn: ['entrenador', 'Entrenador', 'DT'])
        .get();
    final list = <UtileroContactoDt>[];
    for (final d in snap.docs) {
      final data = d.data();
      final idDeporte = DeporteUsuario.idDesde(data);
      if (deporteId != null &&
          deporteId.isNotEmpty &&
          idDeporte != null &&
          idDeporte != deporteId) {
        continue;
      }
      list.add(
        UtileroContactoDt(
          id: d.id,
          nombre: data['nombre'] as String? ?? 'Profesor',
          email: data['email'] as String? ?? '',
          telefono: data['telefono'] as String?,
          fotoUrl: data['foto_perfil'] as String?,
          deporteNombre: DeporteUsuario.nombreDesde(data),
        ),
      );
    }
    list.sort((a, b) => a.nombre.compareTo(b.nombre));
    return list;
  }

  static Stream<List<SolicitudCompraUtilero>> streamSolicitudes(
    String utileroId,
  ) {
    return _db
        .collection(_colSolicitudes)
        .where('utilero_id', isEqualTo: utileroId)
        .limit(40)
        .snapshots()
        .map((s) {
      final list = s.docs.map(SolicitudCompraUtilero.fromDoc).toList()
        ..sort(
          (a, b) => (b.creadoEn ?? DateTime(2000))
              .compareTo(a.creadoEn ?? DateTime(2000)),
        );
      return list;
    });
  }

  static Future<void> crearSolicitudCompra({
    required String utileroId,
    required String materialNombre,
    required int cantidad,
    required String motivo,
    String? deporteId,
  }) async {
    final payload = <String, dynamic>{
      'utilero_id': utileroId,
      'material_nombre': materialNombre.trim(),
      'cantidad': cantidad,
      'motivo': motivo.trim(),
      'estado': 'pendiente',
      'creado_en': FieldValue.serverTimestamp(),
    };
    if (deporteId != null && deporteId.isNotEmpty) {
      payload.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    await _db.collection(_colSolicitudes).add(payload);
    await registrarActividad(
      utileroId: utileroId,
      accion: 'Solicitud de compra',
      descripcion: '$cantidad $materialNombre — $motivo',
      material: materialNombre,
      cantidad: cantidad,
    );
    await crearNotificacion(
      utileroId: utileroId,
      titulo: 'Solicitud enviada',
      mensaje: 'Pediste $cantidad $materialNombre',
      tipo: 'solicitud_compra',
    );
  }

  static List<String> itemsChecklistPredefinidos() => const [
        'Balones inflados',
        'Conos en bodega',
        'Petos limpios',
        'Poleras disponibles',
        'Botiquín / hielo',
        'Silbato / cronómetro',
        'Material de primeros auxilios',
        'Chalecos / petos de arquero',
      ];

  static Future<String> crearChecklist({
    required String utileroId,
    required String titulo,
    String? entrenamientoId,
  }) async {
    final items = {
      for (final i in itemsChecklistPredefinidos()) i: false,
    };
    final ref = await _db.collection(_colChecklist).add({
      'utilero_id': utileroId,
      'titulo': titulo,
      'items': items,
      'completado': false,
      if (entrenamientoId != null) 'entrenamiento_id': entrenamientoId,
      'creado_en': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<List<ChecklistUtileroSesion>> streamChecklists(
    String utileroId,
  ) {
    return _db
        .collection(_colChecklist)
        .where('utilero_id', isEqualTo: utileroId)
        .limit(20)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ChecklistUtileroSesion.fromDoc).toList()
        ..sort(
          (a, b) => (b.creadoEn ?? DateTime(2000))
              .compareTo(a.creadoEn ?? DateTime(2000)),
        );
      return list;
    });
  }

  static Future<void> actualizarItemChecklist({
    required String checklistId,
    required String item,
    required bool marcado,
  }) async {
    await _db.collection(_colChecklist).doc(checklistId).update({
      'items.$item': marcado,
    });
  }

  static Future<void> completarChecklist(String checklistId) async {
    await _db.collection(_colChecklist).doc(checklistId).update({
      'completado': true,
    });
  }

  static Future<void> registrarInventarioFisico({
    required String utileroId,
    required Map<String, int> conteos,
    required Map<String, int> sistema,
    String? deporteId,
  }) async {
    var diferencias = 0;
    final detalle = StringBuffer();
    final items = <Map<String, dynamic>>[];
    for (final e in conteos.entries) {
      final sys = sistema[e.key] ?? 0;
      if (e.value != sys) {
        diferencias++;
        detalle.writeln('${e.key}: contado ${e.value}, sistema $sys');
      }
      items.add({
        'material_id': e.key.hashCode.toString(),
        'nombre': e.key,
        'sistema': sys,
        'contado': e.value,
        'observacion': e.value != sys ? 'Diferencia en conteo rápido' : '',
      });
    }

    final payload = <String, dynamic>{
      'utilero_id': utileroId,
      'anio': DateTime.now().year,
      'tipo': 'rapido',
      'estado': 'cerrado',
      'items': items,
      'observaciones_generales': diferencias == 0
          ? 'Conteo rápido — coincide con sistema'
          : 'Conteo rápido — $diferencias diferencia(s)',
      'creado_en': FieldValue.serverTimestamp(),
      'cerrado_en': FieldValue.serverTimestamp(),
    };
    if (deporteId != null && deporteId.isNotEmpty) {
      payload.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    await _db.collection(_colInventarioFisico).add(payload);

    await registrarActividad(
      utileroId: utileroId,
      accion: 'Inventario físico',
      descripcion: diferencias == 0
          ? 'Conteo coincide con el sistema'
          : '$diferencias diferencia(s)\n$detalle',
      material: deporteId ?? '—',
      cantidad: conteos.length,
    );
  }

  static Stream<List<InventarioFisicoSesion>> streamInventariosFisicos(
    String utileroId, {
    String? deporteId,
    String? tipo,
  }) {
    return _db
        .collection(_colInventarioFisico)
        .where('utilero_id', isEqualTo: utileroId)
        .limit(40)
        .snapshots()
        .map((s) {
      var list = s.docs.map(InventarioFisicoSesion.fromDoc).toList();
      if (deporteId != null && deporteId.isNotEmpty) {
        list = list.where((x) => x.deporteId == deporteId).toList();
      }
      if (tipo != null && tipo.isNotEmpty) {
        list = list.where((x) => x.tipo == tipo).toList();
      }
      list.sort(
        (a, b) => (b.creadoEn ?? DateTime(2000))
            .compareTo(a.creadoEn ?? DateTime(2000)),
      );
      return list;
    });
  }

  static Future<String> crearInventarioAnual({
    required String utileroId,
    String? deporteId,
    int? anio,
  }) async {
    final year = anio ?? DateTime.now().year;
    final snap = await _db
        .collection(_colInventarioFisico)
        .where('utilero_id', isEqualTo: utileroId)
        .where('anio', isEqualTo: year)
        .where('tipo', isEqualTo: 'anual')
        .get();

    for (final d in snap.docs) {
      final data = d.data();
      final dep = data['deporte'] as String?;
      if (dep != deporteId) continue;
      if (data['estado'] == 'borrador') return d.id;
      if (data['estado'] == 'cerrado') {
        throw StateError(
          'Ya existe un inventario anual cerrado para $year. '
          'Puedes exportarlo desde el historial.',
        );
      }
    }

    final mats =
        await InventarioService.streamMaterialesDeporte(deporteId).first;
    if (mats.isEmpty) {
      throw StateError('No hay materiales en esta selección para inventariar.');
    }

    final items = mats
        .map(
          (m) => InventarioFisicoItem(
            materialId: m.id,
            nombre: m.nombre,
            sistema: m.cantidadTotal,
            contado: m.cantidadTotal,
          ).toMap(),
        )
        .toList();

    final payload = <String, dynamic>{
      'utilero_id': utileroId,
      'anio': year,
      'tipo': 'anual',
      'estado': 'borrador',
      'items': items,
      'observaciones_generales': '',
      'responsable_verificacion': '',
      'firma_coordinador': '',
      'creado_en': FieldValue.serverTimestamp(),
    };
    if (deporteId != null && deporteId.isNotEmpty) {
      payload.addAll(DeporteUsuario.camposAlGuardar(deporteId));
    }
    final ref = await _db.collection(_colInventarioFisico).add(payload);
    await registrarActividad(
      utileroId: utileroId,
      accion: 'Inventario anual iniciado',
      descripcion: 'Borrador $year · ${items.length} ítems',
      material: deporteId ?? '—',
      cantidad: items.length,
    );
    return ref.id;
  }

  static Future<void> actualizarItemsInventarioFisico({
    required String sesionId,
    required List<InventarioFisicoItem> items,
    String? observacionesGenerales,
    String? responsableVerificacion,
    String? firmaCoordinador,
  }) async {
    final ref = _db.collection(_colInventarioFisico).doc(sesionId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Sesión no encontrada');
    if (snap.data()?['estado'] == 'cerrado') {
      throw StateError('El inventario ya está cerrado y no se puede editar.');
    }
    await ref.update({
      'items': items.map((i) => i.toMap()).toList(),
      if (observacionesGenerales != null)
        'observaciones_generales': observacionesGenerales,
      if (responsableVerificacion != null)
        'responsable_verificacion': responsableVerificacion,
      if (firmaCoordinador != null) 'firma_coordinador': firmaCoordinador,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> cerrarInventarioAnual({
    required String sesionId,
    required String utileroId,
    required String responsableVerificacion,
    required String firmaCoordinador,
    String? observacionesGenerales,
  }) async {
    if (responsableVerificacion.trim().isEmpty) {
      throw StateError('Indica quién verificó el conteo físico.');
    }
    if (firmaCoordinador.trim().isEmpty) {
      throw StateError('Indica el nombre del coordinador / DT que firma.');
    }

    final ref = _db.collection(_colInventarioFisico).doc(sesionId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Sesión no encontrada');
    final sesion = InventarioFisicoSesion.fromDoc(snap);
    if (sesion.cerrado) throw StateError('Este inventario ya está cerrado.');

    await ref.update({
      'estado': 'cerrado',
      'responsable_verificacion': responsableVerificacion.trim(),
      'firma_coordinador': firmaCoordinador.trim(),
      'observaciones_generales': observacionesGenerales?.trim() ?? '',
      'cerrado_en': FieldValue.serverTimestamp(),
    });

    final cerrada = InventarioFisicoSesion.fromDoc(
      await ref.get(),
    );
    final perfil = await streamPerfil(utileroId).first;

    await registrarActividad(
      utileroId: utileroId,
      accion: 'Inventario anual cerrado',
      descripcion:
          '${cerrada.anio} · ${cerrada.totalDiferencias} diferencia(s) · '
          'Firma: $firmaCoordinador',
      material: cerrada.deporteNombre ?? cerrada.deporteId ?? '—',
      cantidad: cerrada.items.length,
    );

    await _notificarInventarioAnualCerrado(
      utileroId: utileroId,
      perfil: perfil,
      sesion: cerrada,
    );
  }

  static Future<void> _notificarInventarioAnualCerrado({
    required String utileroId,
    required UtileroPerfil perfil,
    required InventarioFisicoSesion sesion,
  }) async {
    final seleccion = sesion.deporteNombre ?? sesion.deporteId ?? '—';
    final titulo = 'Inventario anual ${sesion.anio} cerrado';
    final resumen = StringBuffer()
      ..writeln('Utilero: ${perfil.nombreCompleto}')
      ..writeln('Selección: $seleccion')
      ..writeln('Ítems revisados: ${sesion.items.length}')
      ..writeln('Diferencias: ${sesion.totalDiferencias}')
      ..writeln('Verificado por: ${sesion.responsableVerificacion}')
      ..writeln('Firma coordinación: ${sesion.firmaCoordinador}');
    if (sesion.observacionesGenerales?.isNotEmpty == true) {
      resumen.writeln('\nObservaciones:\n${sesion.observacionesGenerales}');
    }
    for (final i in sesion.items.where((x) => !x.coincide)) {
      resumen.writeln(
        '• ${i.nombre}: sistema ${i.sistema}, contado ${i.contado}',
      );
    }

    await _db.collection(_colNotif).add({
      'utilero_id': utileroId,
      'titulo': titulo,
      'mensaje': '${sesion.totalDiferencias} diferencia(s) registradas',
      'tipo': 'inventario_anual',
      'leida': false,
      'fecha': FieldValue.serverTimestamp(),
    });

    if (perfil.correo.trim().isNotEmpty && perfil.notifEmail) {
      await encolarEmail(
        para: perfil.correo,
        asunto: 'DTFly: $titulo — $seleccion',
        cuerpo: resumen.toString(),
        html: _htmlInventarioAnual(perfil: perfil, sesion: sesion),
        utileroId: utileroId,
        tipo: 'inventario_anual',
      );
    }

    final dts = await listarContactosDt(deporteId: sesion.deporteId);
    for (final dt in dts.take(3)) {
      if (dt.email.trim().isEmpty) continue;
      await encolarEmail(
        para: dt.email,
        asunto: 'DTFly: $titulo — $seleccion',
        cuerpo: resumen.toString(),
        html: _htmlInventarioAnual(perfil: perfil, sesion: sesion),
        utileroId: utileroId,
        tipo: 'inventario_anual_dt',
      );
    }
  }

  static String _htmlInventarioAnual({
    required UtileroPerfil perfil,
    required InventarioFisicoSesion sesion,
  }) {
    final filas = sesion.items
        .map(
          (i) =>
              '<tr><td>${_escHtml(i.nombre)}</td><td>${i.sistema}</td>'
              '<td>${i.contado}</td><td>${i.diferencia}</td>'
              '<td>${_escHtml(i.observacion ?? "")}</td></tr>',
        )
        .join();
    return '''
<html><body style="font-family:sans-serif;padding:24px">
<h1 style="color:#C62828">Inventario físico anual ${sesion.anio}</h1>
<p><strong>Utilero:</strong> ${_escHtml(perfil.nombreCompleto)}<br>
<strong>Selección:</strong> ${_escHtml(sesion.deporteNombre ?? "—")}<br>
<strong>Verificado por:</strong> ${_escHtml(sesion.responsableVerificacion ?? "—")}<br>
<strong>Firma coordinación:</strong> ${_escHtml(sesion.firmaCoordinador ?? "—")}</p>
<table border="1" cellpadding="6" cellspacing="0" width="100%">
<tr><th>Material</th><th>Sistema</th><th>Contado</th><th>Dif.</th><th>Obs.</th></tr>
$filas
</table>
<p>Diferencias totales: ${sesion.totalDiferencias}</p>
</body></html>''';
  }

  static Future<ReporteArchivo> exportarInventarioFisicoPdf({
    required InventarioFisicoSesion sesion,
    required UtileroPerfil perfil,
  }) async {
    final html = _htmlInventarioAnual(perfil: perfil, sesion: sesion);
    final tipo = sesion.esAnual ? 'anual' : 'rapido';
    final nombre =
        'inventario_fisico_${tipo}_${sesion.anio}_${_slugFecha(DateTime.now())}.html';
    final ruta = await guardarArchivoReporte(nombre, html);
    return ReporteArchivo(
      nombreArchivo: nombre,
      rutaArchivo: ruta,
      entrenamientoTitulo: 'Inventario físico ${sesion.anio}',
      total: sesion.items.length,
      totalEntrenamientos: 0,
      presentes: sesion.items.where((i) => i.coincide).length,
      atrasados: sesion.totalDiferencias,
      ausentes: 0,
    );
  }

  /// Prueba manual del envío de correos (Configuración utilero).
  static Future<void> enviarEmailPrueba(String utileroId) async {
    final perfil = await streamPerfil(utileroId).first;
    if (!perfil.notifEmail) {
      throw StateError('Activa las notificaciones por correo primero.');
    }
    if (perfil.correo.trim().isEmpty || !perfil.correo.contains('@')) {
      throw StateError('Agrega un correo válido en tu perfil.');
    }
    await encolarEmail(
      para: perfil.correo,
      asunto: 'DTFly: prueba de alertas por correo',
      cuerpo:
          'Hola ${perfil.nombreCompleto},\n\n'
          'Este es un correo de prueba del módulo utilero DTFly.\n'
          'Si lo recibes, el envío automático de alertas está configurado.',
      html: '''
<html><body style="font-family:sans-serif;padding:20px">
<h2 style="color:#C62828">DTFly — Correo de prueba</h2>
<p>Hola <strong>${_escHtml(perfil.nombreCompleto)}</strong>,</p>
<p>Si recibes este mensaje, las alertas por correo del utilero están activas.</p>
</body></html>''',
      utileroId: utileroId,
      tipo: 'prueba_email',
    );
  }

  static Stream<Map<String, dynamic>?> streamUltimoEmailEstado(
    String utileroId,
  ) {
    return _db
        .collection(_colEmails)
        .where('utilero_id', isEqualTo: utileroId)
        .limit(10)
        .snapshots()
        .map((s) {
      if (s.docs.isEmpty) return null;
      final docs = s.docs.toList()
        ..sort((a, b) {
          final ta = a.data()['creado_en'] as Timestamp?;
          final tb = b.data()['creado_en'] as Timestamp?;
          return (tb?.millisecondsSinceEpoch ?? 0)
              .compareTo(ta?.millisecondsSinceEpoch ?? 0);
        });
      return docs.first.data();
    });
  }

  static Future<int> contarNotificacionesNoLeidas(String utileroId) async {
    final snap = await _db
        .collection(_colNotif)
        .where('utilero_id', isEqualTo: utileroId)
        .where('leida', isEqualTo: false)
        .get();
    return snap.docs.length;
  }

  static String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  static String _slugFecha(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
}
