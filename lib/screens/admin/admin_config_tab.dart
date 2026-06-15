import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/screens/admin/admin_widgets.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/inventario_service.dart';

class AdminConfigTab extends StatefulWidget {
  const AdminConfigTab({
    super.key,
    required this.adminId,
    required this.adminEmail,
  });

  final String adminId;
  final String adminEmail;

  @override
  State<AdminConfigTab> createState() => _AdminConfigTabState();
}

class _AdminConfigTabState extends State<AdminConfigTab> {
  final _deporteExtra = TextEditingController();
  final _categoriaExtra = TextEditingController();
  AdminConfiguracionSistema? _config;

  @override
  void dispose() {
    _deporteExtra.dispose();
    _categoriaExtra.dispose();
    super.dispose();
  }

  Future<void> _guardar(AdminConfiguracionSistema cfg) async {
    await AdminService.guardarConfiguracion(
      cfg,
      adminId: widget.adminId,
      adminEmail: widget.adminEmail,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminConfiguracionSistema>(
      stream: AdminService.streamConfiguracion(),
      builder: (context, snap) {
        final cfg = snap.data ?? AdminConfiguracionSistema.vacio();
        _config = cfg;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminSectionHeader(
              titulo: 'Configuración del sistema',
              subtitulo: 'Selecciones deportivas, categorías y reglas básicas',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecciones deportivas base', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final d in DeportesCategoria.todas)
                          Chip(label: Text(d.nombre)),
                        for (final e in cfg.deportesExtra)
                          Chip(
                            label: Text(e),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              final lista = [...cfg.deportesExtra]..remove(e);
                              _guardar(cfg.copyWith(deportesExtra: lista));
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _deporteExtra,
                            decoration: const InputDecoration(
                              hintText: 'Nueva selección deportiva',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final t = _deporteExtra.text.trim();
                            if (t.isEmpty) return;
                            _guardar(cfg.copyWith(
                              deportesExtra: [...cfg.deportesExtra, t],
                            ));
                            _deporteExtra.clear();
                          },
                          style: FilledButton.styleFrom(backgroundColor: adminAccent),
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categorías de inventario', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final c in InventarioService.categoriasSugeridas)
                          Chip(label: Text(c)),
                        for (final e in cfg.categoriasInventarioExtra)
                          Chip(
                            label: Text(e),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              final lista = [...cfg.categoriasInventarioExtra]..remove(e);
                              _guardar(cfg.copyWith(categoriasInventarioExtra: lista));
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _categoriaExtra,
                            decoration: const InputDecoration(
                              hintText: 'Nueva categoría',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final t = _categoriaExtra.text.trim();
                            if (t.isEmpty) return;
                            _guardar(cfg.copyWith(
                              categoriasInventarioExtra: [...cfg.categoriasInventarioExtra, t],
                            ));
                            _categoriaExtra.clear();
                          },
                          style: FilledButton.styleFrom(backgroundColor: adminAccent),
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Validez código entrenamiento (segundos)'),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: '${cfg.codigoValidezSegundos}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onFieldSubmitted: (v) {
                              final n = int.tryParse(v) ?? 60;
                              _guardar(cfg.copyWith(codigoValidezSegundos: n));
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Permitir registro abierto'),
                      subtitle: const Text('Usuarios pueden registrarse desde la app'),
                      value: cfg.permitirRegistroAbierto,
                      activeColor: adminAccent,
                      onChanged: (v) => _guardar(cfg.copyWith(permitirRegistroAbierto: v)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension on AdminConfiguracionSistema {
  AdminConfiguracionSistema copyWith({
    List<String>? deportesExtra,
    List<String>? categoriasInventarioExtra,
    int? codigoValidezSegundos,
    bool? permitirRegistroAbierto,
  }) {
    return AdminConfiguracionSistema(
      deportesExtra: deportesExtra ?? this.deportesExtra,
      categoriasInventarioExtra:
          categoriasInventarioExtra ?? this.categoriasInventarioExtra,
      codigoValidezSegundos: codigoValidezSegundos ?? this.codigoValidezSegundos,
      permitirRegistroAbierto:
          permitirRegistroAbierto ?? this.permitirRegistroAbierto,
    );
  }
}
