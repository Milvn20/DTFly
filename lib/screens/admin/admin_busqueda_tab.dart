import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/admin_busqueda.dart';
import 'package:flutter_application_1/screens/admin/admin_usuario_detalle_screen.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';

class AdminBusquedaTab extends StatefulWidget {
  const AdminBusquedaTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
    this.onIrUsuario,
  });

  final String adminId;
  final String adminEmail;
  final VoidCallback? onIrUsuario;

  @override
  State<AdminBusquedaTab> createState() => _AdminBusquedaTabState();
}

class _AdminBusquedaTabState extends State<AdminBusquedaTab> {
  final _ctrl = TextEditingController();
  AdminBusquedaTipo? _tipoFiltro;
  List<AdminBusquedaResultado> _resultados = [];
  bool _buscando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _buscando = true);
    final r = await AdminService.busquedaGlobal(
      _ctrl.text,
      tipoFiltro: _tipoFiltro,
    );
    if (mounted) {
      setState(() {
        _resultados = r;
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeader(
          titulo: 'Búsqueda global',
          subtitulo: 'Busca usuarios, materiales, préstamos, entrenamientos y más',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Escribe para buscar en todo el sistema...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscando
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _buscar,
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _tipoFiltro == null,
                      onSelected: (_) => setState(() => _tipoFiltro = null),
                    ),
                    for (final t in AdminBusquedaTipo.values)
                      FilterChip(
                        label: Text(adminTipoLabel(t)),
                        selected: _tipoFiltro == t,
                        onSelected: (_) => setState(() => _tipoFiltro = t),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_resultados.isEmpty && !_buscando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Escribe al menos 2 caracteres y pulsa buscar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resultados.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _resultados[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: adminAccent.withValues(alpha: 0.1),
                    child: Icon(_iconoTipo(r.tipo), color: adminAccent, size: 20),
                  ),
                  title: Text(r.titulo),
                  subtitle: Text('${adminTipoLabel(r.tipo)} · ${r.subtitulo}'),
                  trailing: r.extra != null ? Text(r.extra!, style: const TextStyle(fontSize: 11)) : null,
                  onTap: () {
                    if (r.tipo == AdminBusquedaTipo.usuario) {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUsuarioDetalleScreen(
                            usuarioId: r.id,
                            adminId: widget.adminId,
                            adminEmail: widget.adminEmail,
                          ),
                        ),
                      );
                      return;
                    }
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(adminTipoLabel(r.tipo)),
                        content: Text(
                          '${r.titulo}\n\n${r.subtitulo}'
                          '${r.extra != null ? '\n\n${r.extra}' : ''}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _iconoTipo(AdminBusquedaTipo t) {
    return switch (t) {
      AdminBusquedaTipo.usuario => Icons.person,
      AdminBusquedaTipo.material => Icons.inventory_2,
      AdminBusquedaTipo.prestamo => Icons.handshake,
      AdminBusquedaTipo.entrenamiento => Icons.fitness_center,
      AdminBusquedaTipo.partido => Icons.sports_soccer,
      AdminBusquedaTipo.reporte => Icons.summarize,
      AdminBusquedaTipo.solicitud => Icons.shopping_cart,
    };
  }
}
