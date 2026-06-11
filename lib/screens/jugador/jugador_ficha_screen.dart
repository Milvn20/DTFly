import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/services/usuario_perfil_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

class JugadorFichaScreen extends StatefulWidget {
  const JugadorFichaScreen({
    super.key,
    required this.usuarioId,
    required this.email,
    required this.nombreInicial,
  });

  final String usuarioId;
  final String email;
  final String nombreInicial;

  @override
  State<JugadorFichaScreen> createState() => _JugadorFichaScreenState();
}

class _JugadorFichaScreenState extends State<JugadorFichaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _edad;
  late final TextEditingController _anioTermino;
  late final TextEditingController _carrera;
  late final TextEditingController _posicion;
  late final TextEditingController _beca;
  String? _deporteId;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.nombreInicial);
    _edad = TextEditingController();
    _anioTermino = TextEditingController();
    _carrera = TextEditingController();
    _posicion = TextEditingController();
    _beca = TextEditingController();
    _cargar();
  }

  Future<void> _cargar() async {
    final snap = await UsuarioPerfilService.ref(widget.usuarioId).get();
    if (!snap.exists || !mounted) return;
    final d = snap.data()!;
    setState(() {
      _nombre.text = d['nombre'] as String? ?? widget.nombreInicial;
      final e = d['edad'];
      if (e != null) _edad.text = '$e';
      final a = d['anioTerminoCarrera'];
      if (a != null) _anioTermino.text = '$a';
      _carrera.text = d['carrera'] as String? ?? '';
      _posicion.text = d['posicionDeportiva'] as String? ?? '';
      _beca.text = d['tipoBeca'] as String? ?? '';
      _deporteId = UsuarioPerfilService.deporteIdDesde(d);
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _edad.dispose();
    _anioTermino.dispose();
    _carrera.dispose();
    _posicion.dispose();
    _beca.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deporteId == null || _deporteId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu deporte')),
      );
      return;
    }
    final edad = int.tryParse(_edad.text.trim());
    final anio = int.tryParse(_anioTermino.text.trim());
    try {
      await UsuarioPerfilService.guardarPerfilJugador(
        usuarioId: widget.usuarioId,
        nombre: _nombre.text.trim(),
        email: widget.email,
        edad: edad,
        anioTerminoCarrera: anio,
        carrera: _carrera.text.trim(),
        posicionDeportiva: _posicion.text.trim(),
        tipoBeca: _beca.text.trim(),
        deporteId: _deporteId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Mi ficha deportiva'),
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Correo'),
              subtitle: Text(widget.email),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _edad,
              decoration: const InputDecoration(
                labelText: 'Edad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _anioTermino,
              decoration: const InputDecoration(
                labelText: 'Año término de carrera (ej. 2027)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _carrera,
              decoration: const InputDecoration(
                labelText: 'Carrera que estudia',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _deporteId,
              decoration: const InputDecoration(
                labelText: 'Deporte',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final d in DeportesCategoria.todas)
                  DropdownMenuItem(value: d.id, child: Text(d.nombre)),
              ],
              onChanged: (v) => setState(() => _deporteId = v),
              validator: (v) => v == null ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _posicion,
              decoration: const InputDecoration(
                labelText: 'Posición en la selección',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beca,
              decoration: const InputDecoration(
                labelText: 'Tipo de beca deportiva',
                hintText: 'Ej: Completa, Parcial, Sin beca',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: DtflyTheme.secondary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
