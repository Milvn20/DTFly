import 'package:flutter/material.dart';

import 'package:flutter_application_1/services/utilero_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

import 'utilero_perfil_hub_screen.dart';

/// Pantallas secundarias del utilero (historial, estadísticas, etc.).
class UtileroSeccionScreen extends StatelessWidget {
  const UtileroSeccionScreen({
    super.key,
    required this.titulo,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombreInicial,
    required this.seccion,
  });

  final String titulo;
  final String usuarioId;
  final String usuarioEmail;
  final String nombreInicial;
  final UtileroSeccion seccion;

  static Future<void> abrir(
    BuildContext context, {
    required String titulo,
    required String usuarioId,
    required String usuarioEmail,
    required String nombreInicial,
    required UtileroSeccion seccion,
  }) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UtileroSeccionScreen(
          titulo: titulo,
          usuarioId: usuarioId,
          usuarioEmail: usuarioEmail,
          nombreInicial: nombreInicial,
          seccion: seccion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.backgroundGray,
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: DtflyTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: switch (seccion) {
        UtileroSeccion.historial => UtileroHistorialPanel(usuarioId: usuarioId),
        UtileroSeccion.estadisticas =>
          UtileroEstadisticasPanel(usuarioId: usuarioId),
        UtileroSeccion.notificaciones =>
          UtileroNotificacionesPanel(usuarioId: usuarioId),
        UtileroSeccion.configuracion => UtileroConfigPanel(usuarioId: usuarioId),
        UtileroSeccion.reportes => UtileroReportesPanel(
            usuarioId: usuarioId,
            usuarioEmail: usuarioEmail,
          ),
        UtileroSeccion.resumen => UtileroResumenPanel(
            usuarioId: usuarioId,
            nombre: nombreInicial,
          ),
      },
    );
  }
}

enum UtileroSeccion {
  historial,
  estadisticas,
  notificaciones,
  configuracion,
  reportes,
  resumen,
}

/// Pestaña «Perfil» del utilero (solo datos personales, sin tabs anidadas).
class UtileroPerfilTabContent extends StatelessWidget {
  const UtileroPerfilTabContent({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.nombreInicial,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String nombreInicial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: DtflyTheme.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi perfil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreInicial,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: UtileroPerfilPanel(
            usuarioId: usuarioId,
            usuarioEmail: usuarioEmail,
            nombreInicial: nombreInicial,
          ),
        ),
      ],
    );
  }
}

/// Panel de resumen general (desde menú Más).
class UtileroResumenPanel extends StatelessWidget {
  const UtileroResumenPanel({
    super.key,
    required this.usuarioId,
    required this.nombre,
  });

  final String usuarioId;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UtileroResumenDashboard>(
      future: UtileroService.cargarResumen(usuarioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar el resumen. Desliza hacia abajo para reintentar.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final r = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hola, ${nombre.split(' ').first}',
              style: DtflyTheme.panelTitle,
            ),
            const SizedBox(height: 12),
            _ResumenFila(
              icono: Icons.category,
              titulo: 'Materiales registrados',
              valor: '${r.materialesRegistrados}',
            ),
            _ResumenFila(
              icono: Icons.outbound,
              titulo: 'Entregados (total)',
              valor: '${r.materialesEntregados}',
            ),
            _ResumenFila(
              icono: Icons.assignment_return,
              titulo: 'Devueltos (total)',
              valor: '${r.materialesDevueltos}',
            ),
            _ResumenFila(
              icono: Icons.warning_amber,
              titulo: 'Stock bajo',
              valor: '${r.stockBajo}',
              alerta: r.stockBajo > 0,
            ),
            _ResumenFila(
              icono: Icons.broken_image_outlined,
              titulo: 'Material dañado',
              valor: '${r.materialesDanados} u.',
              alerta: r.materialesDanados > 0,
            ),
            _ResumenFila(
              icono: Icons.sports,
              titulo: 'Entrenamientos esta semana',
              valor: '${r.entrenamientosSemana}',
            ),
            _ResumenFila(
              icono: Icons.today,
              titulo: 'Entregados hoy',
              valor: '${r.entregadosHoy}',
            ),
            _ResumenFila(
              icono: Icons.schedule,
              titulo: 'Préstamos pendientes',
              valor: '${r.prestamosPendientes}',
              alerta: r.prestamosPendientes > 0,
            ),
          ],
        );
      },
    );
  }
}

class _ResumenFila extends StatelessWidget {
  const _ResumenFila({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.alerta = false,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alerta
              ? DtflyTheme.fieldRed.withValues(alpha: 0.15)
              : DtflyTheme.primary.withValues(alpha: 0.12),
          child: Icon(
            icono,
            color: alerta ? DtflyTheme.fieldRed : DtflyTheme.primary,
          ),
        ),
        title: Text(titulo),
        trailing: Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: alerta ? DtflyTheme.fieldRed : DtflyTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
