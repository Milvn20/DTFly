import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/models/material_inventario.dart';
import 'package:flutter_application_1/services/inventario_service.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_kiosco_widgets.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';
import 'package:flutter_application_1/widgets/utilero_firma_retiro_dialog.dart';

/// Flujo guiado en máximo 3 pasos: persona (solo préstamo) → material → cantidad.
class UtileroKioscoFlujoScreen extends StatefulWidget {
  const UtileroKioscoFlujoScreen({
    super.key,
    required this.flujo,
    required this.usuarioId,
    required this.usuarioEmail,
    this.deporteId,
  });

  final UtileroFlujoKiosco flujo;
  final String usuarioId;
  final String usuarioEmail;
  final String? deporteId;

  @override
  State<UtileroKioscoFlujoScreen> createState() => _UtileroKioscoFlujoScreenState();
}

class _UtileroKioscoFlujoScreenState extends State<UtileroKioscoFlujoScreen> {
  int _paso = 0;
  UtileroPersonaEntrega? _persona;
  UtileroMaterialCat? _material;
  String _cantidadStr = '';
  bool _guardando = false;
  List<UtileroPersonaEntrega> _entrenadores = [];
  bool _cargandoPersonas = true;
  int _maxCantidad = 9999;
  Map<String, int> _prestadosPorCat = {};
  Map<String, int> _prestadosPorMaterialId = {};
  List<MaterialInventario> _materialesAgregados = [];
  List<MaterialInventario> _materialesFiltrados = [];
  String? _materialIdSeleccionado;
  String? _materialNombreSeleccionado;

  bool get _esPrestar => widget.flujo == UtileroFlujoKiosco.prestar;
  bool get _esDevolver => widget.flujo == UtileroFlujoKiosco.devolver;
  bool get _esDanado => widget.flujo == UtileroFlujoKiosco.danado;

  int get _totalPasos => _esPrestar ? 3 : 2;

  int get _pasoVisual => _esPrestar ? _paso + 1 : _paso;

  String get _tituloFlujo {
    switch (widget.flujo) {
      case UtileroFlujoKiosco.recibir:
        return 'Recibir material';
      case UtileroFlujoKiosco.prestar:
        return 'Prestar material';
      case UtileroFlujoKiosco.devolver:
        return 'Devolución';
      case UtileroFlujoKiosco.danado:
        return 'Material dañado';
    }
  }

  String get _etiquetaPaso {
    if (_esPrestar) {
      return switch (_paso) {
        0 => '¿A quién se entrega?',
        1 => '¿Qué material?',
        _ => '¿Cuántos?',
      };
    }
    return switch (_paso) {
      0 => '¿Qué material?',
      _ => '¿Cuántos?',
    };
  }

  @override
  void initState() {
    super.initState();
    _cargarMaterialesAgregados();
    if (_esPrestar) {
      _cargarEntrenadores();
    } else {
      _cargandoPersonas = false;
    }
    if (_esDevolver) {
      _cargarPrestados();
    }
  }

  Future<void> _cargarMaterialesAgregados() async {
    final mats =
        await InventarioService.streamMaterialesDeporte(widget.deporteId).first;
    if (mounted) {
      setState(() {
        _materialesFiltrados = mats;
        _materialesAgregados = UtileroInventarioKiosco.materialesAgregados(mats);
      });
    }
  }

  Future<void> _cargarPrestados() async {
    final porCat = await UtileroInventarioKiosco.prestadosPorCategoria(
      deporteId: widget.deporteId,
    );
    final porId = await UtileroInventarioKiosco.prestadosPorMaterialId(
      deporteId: widget.deporteId,
    );
    if (mounted) {
      setState(() {
        _prestadosPorCat = porCat;
        _prestadosPorMaterialId = porId;
      });
    }
  }

  Future<void> _cargarEntrenadores() async {
    final lista = await UtileroInventarioKiosco.listarEntrenadores();
    if (mounted) {
      setState(() {
        _entrenadores = lista;
        _cargandoPersonas = false;
      });
    }
  }

  Future<void> _cargarMaxCantidad({int? prestadosDirecto}) async {
    if (_material == null) return;
    if (_materialIdSeleccionado != null) {
      for (final m in _materialesAgregados) {
        if (m.id == _materialIdSeleccionado) {
          if (_esPrestar || _esDanado) {
            _maxCantidad = m.cantidadDisponible;
          } else if (_esDevolver) {
            _maxCantidad = prestadosDirecto ??
                _prestadosPorMaterialId[_materialIdSeleccionado] ??
                0;
          } else {
            _maxCantidad = 9999;
          }
          return;
        }
      }
    }
    if (_esPrestar || _esDanado) {
      final stock = await UtileroInventarioKiosco.materialesDeCategoria(
        _material!,
        deporteId: widget.deporteId,
      );
      var disp = 0;
      for (final m in stock) {
        disp += m.cantidadDisponible;
      }
      _maxCantidad = disp;
    } else if (_esDevolver) {
      if (prestadosDirecto != null) {
        _maxCantidad = prestadosDirecto;
      } else if (_materialIdSeleccionado != null) {
        _maxCantidad = _prestadosPorMaterialId[_materialIdSeleccionado] ?? 0;
      } else {
        _maxCantidad = _prestadosPorCat[_material!.id] ??
            await UtileroInventarioKiosco.prestadosActivos(
              _material!,
              deporteId: widget.deporteId,
            );
      }
    } else {
      _maxCantidad = 9999;
    }
  }

  int get _cantidad => int.tryParse(_cantidadStr) ?? 0;

  void _digito(String d) {
    if (_cantidadStr.length >= 4) return;
    setState(() {
      _cantidadStr = _cantidadStr == '0' ? d : '$_cantidadStr$d';
    });
  }

  void _borrar() => setState(() => _cantidadStr = '');

  void _avanzarMaterial(
    UtileroMaterialCat cat, {
    String? materialId,
    String? materialNombre,
    int? prestadosDirecto,
  }) async {
    setState(() {
      _material = cat;
      _materialIdSeleccionado = materialId;
      _materialNombreSeleccionado = materialNombre;
      _cantidadStr = '';
      _paso++;
    });
    await _cargarMaxCantidad(prestadosDirecto: prestadosDirecto);
    if (mounted) setState(() {});
  }

  Future<void> _confirmar() async {
    if (_material == null || _cantidad <= 0) {
      _mensaje('Ingresa una cantidad válida', error: true);
      return;
    }
    if ((_esPrestar || _esDanado) && _cantidad > _maxCantidad) {
      _mensaje('Máximo disponible: $_maxCantidad', error: true);
      return;
    }
    if (_esDevolver && _cantidad > _maxCantidad) {
      _mensaje('En préstamo: $_maxCantidad', error: true);
      return;
    }
    if (_esPrestar && _persona == null) {
      _mensaje('Selecciona a quién entregar', error: true);
      return;
    }

    String? firmaBase64;
    if (_esPrestar && _persona != null) {
      final nombreMat =
          _materialNombreSeleccionado ?? _material!.nombre;
      firmaBase64 = await UtileroFirmaRetiroDialog.mostrar(
        context,
        nombreRetirador: _persona!.nombre,
        materialResumen: '$_cantidad × $nombreMat',
      );
      if (firmaBase64 == null) return;
    }

    setState(() => _guardando = true);
    try {
      switch (widget.flujo) {
        case UtileroFlujoKiosco.recibir:
          if (_materialIdSeleccionado != null &&
              _materialNombreSeleccionado != null) {
            await UtileroInventarioKiosco.ingresarStockPorId(
              materialId: _materialIdSeleccionado!,
              materialNombre: _materialNombreSeleccionado!,
              cantidad: _cantidad,
              utileroId: widget.usuarioId,
            );
          } else {
            await UtileroInventarioKiosco.ingresarMaterial(
              cat: _material!,
              cantidad: _cantidad,
              utileroId: widget.usuarioId,
              deporteId: widget.deporteId,
            );
          }
        case UtileroFlujoKiosco.prestar:
          if (_materialIdSeleccionado != null &&
              _materialNombreSeleccionado != null) {
            await UtileroInventarioKiosco.prestarMaterialPorId(
              materialId: _materialIdSeleccionado!,
              materialNombre: _materialNombreSeleccionado!,
              cantidad: _cantidad,
              persona: _persona!,
              utileroId: widget.usuarioId,
              firmaRetiroBase64: firmaBase64,
            );
          } else {
            await UtileroInventarioKiosco.prestarMaterial(
              cat: _material!,
              cantidad: _cantidad,
              persona: _persona!,
              utileroId: widget.usuarioId,
              deporteId: widget.deporteId,
              firmaRetiroBase64: firmaBase64,
            );
          }
        case UtileroFlujoKiosco.devolver:
          await UtileroInventarioKiosco.devolverMaterial(
            cat: _material!,
            cantidad: _cantidad,
            utileroId: widget.usuarioId,
            materialId: _materialIdSeleccionado,
            materialNombre: _materialNombreSeleccionado,
            deporteId: widget.deporteId,
          );
        case UtileroFlujoKiosco.danado:
          if (_materialIdSeleccionado != null &&
              _materialNombreSeleccionado != null) {
            await UtileroInventarioKiosco.darDeBajaPorId(
              materialId: _materialIdSeleccionado!,
              materialNombre: _materialNombreSeleccionado!,
              cantidad: _cantidad,
              utileroId: widget.usuarioId,
            );
          } else {
            await UtileroInventarioKiosco.darDeBaja(
              cat: _material!,
              cantidad: _cantidad,
              utileroId: widget.usuarioId,
              deporteId: widget.deporteId,
            );
          }
      }
      if (!mounted) return;
      _mensaje('¡Listo!');
      Navigator.pop(context);
    } catch (e) {
      _mensaje('$e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String t, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t, style: const TextStyle(fontSize: 18)),
        backgroundColor: error ? DtflyTheme.primary : DtflyTheme.success,
      ),
    );
  }

  Future<void> _mostrarOtroProfesor() async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otro responsable', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 22),
          decoration: const InputDecoration(
            hintText: 'Nombre del profesor',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (nombre != null && nombre.isNotEmpty && mounted) {
      setState(() {
        _persona = UtileroPersonaEntrega(id: 'otro', nombre: nombre, email: '');
        _paso = 1;
      });
    }
  }

  Color get _colorConfirmar {
    if (_esDevolver) return DtflyTheme.secondary;
    if (_esDanado) return DtflyTheme.primary;
    return DtflyTheme.success;
  }

  String get _textoConfirmar {
    switch (widget.flujo) {
      case UtileroFlujoKiosco.recibir:
        return '➕ INGRESAR AL INVENTARIO';
      case UtileroFlujoKiosco.prestar:
        return '✅ CONFIRMAR PRÉSTAMO';
      case UtileroFlujoKiosco.devolver:
        return '↩️ REGISTRAR DEVOLUCIÓN';
      case UtileroFlujoKiosco.danado:
        return '🗑 DAR DE BAJA MATERIAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFC62828),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        title: Text(_tituloFlujo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    if (_esPrestar && _paso == 0) return _buildPasoPersona();
    final pasoMaterial = _esPrestar ? _paso == 1 : _paso == 0;
    if (pasoMaterial) {
      return _buildPanelBlanco(_buildPasoMaterial());
    }
    return _buildPanelBlanco(_buildPasoCantidad());
  }

  Widget _buildPanelBlanco(Widget child) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: child,
    );
  }

  Widget _buildPasoPersona() {
    if (_cargandoPersonas) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        UtileroKioscoPasos(
          pasoActual: 1,
          totalPasos: 3,
          etiqueta: _etiquetaPaso,
          sobreFondoRojo: true,
        ),
        const SizedBox(height: 24),
        ..._entrenadores.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UtileroKioscoPersonaCard(
              persona: p,
              onTap: () => setState(() {
                _persona = p;
                _paso = 1;
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        UtileroKioscoBotonGigante(
          emoji: '➕',
          titulo: 'OTRO',
          color: const Color(0xFF374151),
          onTap: _mostrarOtroProfesor,
        ),
      ],
    );
  }

  String? _subtituloMaterial(UtileroMaterialCat cat) {
    if (_esDevolver) {
      final n = _prestadosPorCat[cat.id] ?? 0;
      if (n > 0) return 'Devolver: $n';
      return 'Sin préstamos';
    }
    return null;
  }

  Widget _buildPasoMaterial() {
    final columnas = MediaQuery.sizeOf(context).width >= 400 ? 3 : 2;
    final cats = UtileroMaterialCat.todas.where((c) => c.id != 'mas').toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        UtileroKioscoPasos(
          pasoActual: _pasoVisual,
          totalPasos: _totalPasos,
          etiqueta: _etiquetaPaso,
        ),
        if (_esDevolver) ...[
          const SizedBox(height: 10),
          const Text(
            'Selecciona qué hay que devolver',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: DtflyTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: cats.map((cat) {
            final prestados = _prestadosPorCat[cat.id] ?? 0;
            final deshabilitado = _esDevolver && prestados <= 0;
            final img = UtileroInventarioKiosco.imagenDeCategoria(
              _materialesFiltrados,
              cat,
            );
            return Opacity(
              opacity: deshabilitado ? 0.45 : 1,
              child: UtileroKioscoMaterialCard(
                categoria: cat,
                imagenUrl: img.url,
                imagenBase64: img.base64,
                subtitulo: _subtituloMaterial(cat),
                onTap: deshabilitado
                    ? () {}
                    : () => _avanzarMaterial(
                          cat,
                          prestadosDirecto: _esDevolver ? prestados : null,
                        ),
              ),
            );
          }).toList(),
        ),
        if (_materialesAgregados.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _esDevolver ? 'Materiales agregados' : 'Tus materiales agregados',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ..._materialesAgregados.map((m) {
            final cat =
                UtileroMaterialCat.todas.firstWhere((c) => c.id == 'mas');
            final prestados = _prestadosPorMaterialId[m.id] ?? 0;
            final deshabilitado = _esDevolver && prestados <= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: deshabilitado ? 0.45 : 1,
                child: UtileroKioscoMaterialCard(
                  categoria: cat,
                  imagenUrl: m.imagenUrl,
                  imagenBase64: m.imagenBase64,
                  subtitulo: _esDevolver
                      ? (prestados > 0
                          ? 'Devolver: $prestados'
                          : 'Sin préstamos')
                      : '${m.nombre} · ${m.cantidadDisponible} disp.',
                  onTap: deshabilitado
                      ? () {}
                      : () => _avanzarMaterial(
                            cat,
                            materialId: m.id,
                            materialNombre: m.nombre,
                            prestadosDirecto: _esDevolver ? prestados : null,
                          ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPasoCantidad() {
    final cat = _material!;
    final titulo = _materialNombreSeleccionado ?? cat.nombre;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UtileroKioscoPasos(
          pasoActual: _pasoVisual,
          totalPasos: _totalPasos,
          etiqueta: _etiquetaPaso,
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              UtileroMaterialIcon(categoria: cat, size: 40),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_maxCantidad < 9999)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _esDevolver
                        ? 'Hay que devolver: $_maxCantidad'
                        : 'Disponibles: $_maxCantidad',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _esDevolver
                          ? const Color(0xFFC62828)
                          : DtflyTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_esPrestar)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Al confirmar se pedirá la firma del profesor en pantalla.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: DtflyTheme.textSecondary,
              ),
            ),
          ),
        UtileroKioscoTeclado(
          valor: _cantidadStr,
          onDigito: _digito,
          onBorrar: _borrar,
          onConfirmar: _cantidad > 0 ? _confirmar : () {},
          habilitarConfirmar: _cantidad > 0 && !_guardando,
        ),
        const SizedBox(height: 20),
        UtileroKioscoConfirmar(
          texto: _textoConfirmar,
          color: _colorConfirmar,
          cargando: _guardando,
          onTap: _cantidad > 0 ? _confirmar : null,
        ),
      ],
    );
  }
}
