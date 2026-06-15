import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/admin_busqueda.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

const adminSidebarColor = Color(0xFF2B2D42);
const adminAccent = DtflyTheme.coachRed;

/// Banner de bienvenida del panel admin (tarjeta en dashboard).
class AdminWelcomeBanner extends StatelessWidget {
  const AdminWelcomeBanner({
    super.key,
    required this.nombre,
    this.subtitulo,
  });

  final String nombre;
  final String? subtitulo;

  String get _primerNombre {
    final p = nombre.trim().split(RegExp(r'\s+')).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => '',
        );
    return p.isEmpty ? 'Administrador' : p;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DtflyTheme.headerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DtflyTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $_primerNombre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Panel de administración DTFly',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitulo!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de métrica del dashboard admin.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? adminAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DtflyTheme.borderSubtle),
        boxShadow: DtflyTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: c, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DtflyTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tabla estilo Excel para datos admin.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columnas,
    required this.filas,
    this.vacio = 'Sin datos',
  });

  final List<String> columnas;
  final List<List<Widget>> filas;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            vacio,
            style: const TextStyle(color: DtflyTheme.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width - 48,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            adminAccent.withValues(alpha: 0.08),
          ),
          columns: [
            for (final c in columnas)
              DataColumn(
                label: Text(
                  c,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
          rows: [
            for (final f in filas)
              DataRow(cells: [for (final c in f) DataCell(c)]),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección admin.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    style: const TextStyle(color: DtflyTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (acciones != null) ...acciones!,
        ],
      ),
    );
  }
}

/// Chip de rol con color.
class AdminRolChip extends StatelessWidget {
  const AdminRolChip({super.key, required this.rol});

  final String rol;

  Color get _color {
    final r = rol.toLowerCase();
    if (r.contains('entrenador') || r.contains('dt')) {
      return const Color(0xFF2563EB);
    }
    if (r.contains('utilero')) return const Color(0xFF7C3AED);
    if (r.contains('admin')) return adminAccent;
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rol,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Filtros en fila.
class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

String adminFmtFecha(DateTime? d) {
  if (d == null) return '—';
  return '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

String adminTipoLabel(AdminBusquedaTipo tipo) {
  return switch (tipo) {
    AdminBusquedaTipo.usuario => 'Usuario',
    AdminBusquedaTipo.material => 'Material',
    AdminBusquedaTipo.prestamo => 'Préstamo',
    AdminBusquedaTipo.entrenamiento => 'Entrenamiento',
    AdminBusquedaTipo.partido => 'Partido',
    AdminBusquedaTipo.reporte => 'Reporte',
    AdminBusquedaTipo.solicitud => 'Solicitud',
  };
}
