import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/services/utilero_inventario_kiosco.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_kiosco_widgets.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Flujo guiado en máximo 3 pasos: persona (solo préstamo) → material → cantidad.
class UtileroKioscoFlujoScreen extends StatefulWidget {
  const UtileroKioscoFlujoScreen({
    super.key,
    required this.flujo,
    required this.usuarioId,
    required this.usuarioEmail,
  });

  final UtileroFlujoKiosco flujo;
  final String usuarioId;
  final String usuarioEmail;

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
    if (_esPrestar) {
      _cargarEntrenadores();
    } else {
      _cargandoPersonas = false;
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

  Future<void> _cargarMaxCantidad() async {
    if (_material == null) return;
    if (_esPrestar || _esDanado) {
      final stock = await UtileroInventarioKiosco.materialesDeCategoria(_material!);
      var disp = 0;
      for (final m in stock) {
        disp += m.cantidadDisponible;
      }
      _maxCantidad = disp;
    } else if (_esDevolver) {
      _maxCantidad = await UtileroInventarioKiosco.prestadosActivos(_material!);
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

  void _avanzarMaterial(UtileroMaterialCat cat) async {
    setState(() {
      _material = cat;
      _cantidadStr = '';
      _paso++;
    });
    await _cargarMaxCantidad();
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

    setState(() => _guardando = true);
    try {
      switch (widget.flujo) {
        case UtileroFlujoKiosco.recibir:
          await UtileroInventarioKiosco.ingresarMaterial(
            cat: _material!,
            cantidad: _cantidad,
            utileroId: widget.usuarioId,
          );
        case UtileroFlujoKiosco.prestar:
          await UtileroInventarioKiosco.prestarMaterial(
            cat: _material!,
            cantidad: _cantidad,
            persona: _persona!,
            utileroId: widget.usuarioId,
          );
        case UtileroFlujoKiosco.devolver:
          await UtileroInventarioKiosco.devolverMaterial(
            cat: _material!,
            cantidad: _cantidad,
            utileroId: widget.usuarioId,
          );
        case UtileroFlujoKiosco.danado:
          await UtileroInventarioKiosco.darDeBaja(
            cat: _material!,
            cantidad: _cantidad,
            utileroId: widget.usuarioId,
          );
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
    if (pasoMaterial) return _buildPasoMaterial();
    return _buildPasoCantidad();
  }

  Widget _buildPasoPersona() {
    if (_cargandoPersonas) {
      return const Center(child: CircularProgressIndicator(color: DtflyTheme.primary));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UtileroKioscoPasos(pasoActual: 1, totalPasos: 3, etiqueta: _etiquetaPaso),
        const SizedBox(height: 20),
        ..._entrenadores.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: UtileroKioscoPersonaCard(
              persona: p,
              onTap: () => setState(() {
                _persona = p;
                _paso = 1;
              }),
            ),
          ),
        ),
        UtileroKioscoBotonGigante(
          emoji: '➕',
          titulo: 'OTRO',
          color: const Color(0xFF374151),
          onTap: _mostrarOtroProfesor,
        ),
      ],
    );
  }

  Widget _buildPasoMaterial() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UtileroKioscoPasos(
          pasoActual: _pasoVisual,
          totalPasos: _totalPasos,
          etiqueta: _etiquetaPaso,
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: UtileroMaterialCat.todas.map((cat) {
            return UtileroKioscoMaterialCard(
              categoria: cat,
              onTap: () => _avanzarMaterial(cat),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPasoCantidad() {
    final cat = _material!;
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
              UtileroMaterialIcon(categoria: cat, size: 48),
              const SizedBox(height: 8),
              Text(
                cat.nombre,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (_maxCantidad < 9999)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _esDevolver
                        ? 'En préstamo: $_maxCantidad'
                        : 'Disponibles: $_maxCantidad',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DtflyTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
