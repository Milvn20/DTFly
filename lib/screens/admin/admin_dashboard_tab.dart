import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/admin/admin_navigation.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
    required this.adminNombre,
    required this.onIrTab,
    required this.onIrSeccion,
    this.onAbrirPerfil,
    this.onAbrirMuro,
  });

  final String adminId;
  final String adminEmail;
  final String adminNombre;
  /// Cambia pestaña inferior: 1=Gestión, 2=Inventario.
  final void Function(int tabIndex) onIrTab;
  final void Function(AdminSeccion seccion) onIrSeccion;
  final VoidCallback? onAbrirPerfil;
  final VoidCallback? onAbrirMuro;

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  AdminEstadisticasGlobales? _stats;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final s = await AdminService.cargarEstadisticas();
    if (mounted) {
      setState(() {
        _stats = s;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: DtflyTheme.coachRed),
        ),
      );
    }

    final s = _stats!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onAbrirPerfil != null) ...[
          AdminPerfilResumenCard(
            adminId: widget.adminId,
            onAbrirPerfil: widget.onAbrirPerfil!,
          ),
          const SizedBox(height: 16),
        ],
        AdminSectionHeader(
          titulo: 'Estadísticas globales',
          subtitulo: 'Vista general del sistema deportivo universitario',
          acciones: [
            IconButton(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 700 ? 2 : 1;
            final cards = [
              AdminStatCard(
                icono: Icons.people,
                valor: '${s.usuariosActivos}/${s.totalUsuarios}',
                etiqueta: 'Usuarios activos',
              ),
              AdminStatCard(
                icono: Icons.inventory_2,
                valor: '${s.totalMateriales}',
                etiqueta: 'Materiales registrados',
                color: const Color(0xFF7C3AED),
              ),
              AdminStatCard(
                icono: Icons.handshake,
                valor: '${s.prestadosActivos}',
                etiqueta: 'Unidades prestadas',
                color: const Color(0xFF2563EB),
              ),
              AdminStatCard(
                icono: Icons.fitness_center,
                valor: '${s.entrenamientos}',
                etiqueta: 'Entrenamientos',
                color: const Color(0xFF059669),
              ),
              AdminStatCard(
                icono: Icons.sports_soccer,
                valor: '${s.partidos}',
                etiqueta: 'Partidos',
              ),
              AdminStatCard(
                icono: Icons.warning_amber,
                valor: '${s.stockBajo}',
                etiqueta: 'Alertas stock bajo',
                color: const Color(0xFFD97706),
              ),
              AdminStatCard(
                icono: Icons.shopping_cart,
                valor: '${s.solicitudesPendientes}',
                etiqueta: 'Solicitudes pendientes',
                color: const Color(0xFFDC2626),
              ),
              AdminStatCard(
                icono: Icons.summarize,
                valor: '${s.reportesEntrenador}',
                etiqueta: 'Reportes DT',
              ),
              AdminStatCard(
                icono: Icons.build_circle,
                valor: '${s.materialesDanados}',
                etiqueta: 'Unidades dañadas',
              ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: cols == 1
                        ? c.maxWidth
                        : (c.maxWidth - 12) / 2,
                    child: card,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Accesos rápidos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickBtn(
              'Gestionar usuarios',
              Icons.people,
              () => widget.onIrTab(1),
            ),
            _QuickBtn(
              'Inventario global',
              Icons.inventory_2,
              () => widget.onIrTab(2),
            ),
            _QuickBtn(
              'Muro deportivo',
              Icons.dashboard_customize_outlined,
              () => widget.onAbrirMuro?.call(),
            ),
            _QuickBtn(
              'Búsqueda global',
              Icons.search,
              () => widget.onIrSeccion(AdminSeccion.busqueda),
            ),
            _QuickBtn(
              'Reportes',
              Icons.summarize,
              () => widget.onIrSeccion(AdminSeccion.reportes),
            ),
            _QuickBtn(
              'Entrenadores',
              Icons.sports,
              () => widget.onIrSeccion(AdminSeccion.entrenadores),
            ),
            _QuickBtn(
              'Jugadores',
              Icons.school,
              () => widget.onIrSeccion(AdminSeccion.jugadores),
            ),
            _QuickBtn(
              'Auditoría',
              Icons.history,
              () => widget.onIrSeccion(AdminSeccion.auditoria),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribución de roles',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _RolBar('Entrenadores', s.entrenadores, s.totalUsuarios),
                _RolBar('Jugadores', s.jugadores, s.totalUsuarios),
                _RolBar('Utileros', s.utileros, s.totalUsuarios),
                _RolBar('Administradores', s.administradores, s.totalUsuarios),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: DtflyTheme.coachRed,
        side: const BorderSide(color: DtflyTheme.coachRed),
      ),
    );
  }
}

class _RolBar extends StatelessWidget {
  const _RolBar(this.label, this.count, this.total);
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              color: DtflyTheme.coachRed,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
