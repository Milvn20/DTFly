import 'package:flutter/material.dart';

import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_coach_header.dart';

class JugadorInicioTab extends StatefulWidget {
  const JugadorInicioTab({
    super.key,
    required this.usuarioId,
    required this.usuarioEmail,
    required this.saludo,
    required this.nombreParaAsistencia,
  });

  final String usuarioId;
  final String usuarioEmail;
  final String saludo;
  final String nombreParaAsistencia;

  @override
  State<JugadorInicioTab> createState() => _JugadorInicioTabState();
}

class _JugadorInicioTabState extends State<JugadorInicioTab> {
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    setState(() => _cargando = true);
    try {
      final id = await EntrenamientoService.unirseConCodigo(
        codigo: _codigoCtrl.text,
        jugadorUsuarioId: widget.usuarioId,
        nombreJugador: widget.nombreParaAsistencia,
        emailJugador: widget.usuarioEmail,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Listo! Te registraste en el entrenamiento ($id).'),
        ),
      );
      _codigoCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        children: [
          _JugadorHeader(titulo: widget.saludo),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DtflyTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: DtflyTheme.coachRed,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unirse al entrenamiento',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ingresa el código que muestra tu profesor. La app guardará tu asistencia y marcará si llegaste puntual o atrasado.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codigoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Código de unión',
                    hintText: 'Ej: ABC12XY',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _cargando ? null : _unirse,
                  icon: const Icon(Icons.check_circle_outline),
                  style: FilledButton.styleFrom(
                    backgroundColor: DtflyTheme.coachRed,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  label: _cargando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrar mi asistencia'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFAFAFAF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Validación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Código dinámico')),
                    Chip(label: Text('GPS · próximamente')),
                    Chip(label: Text('Selfie · próximamente')),
                    Chip(label: Text('QR respaldo')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JugadorHeader extends StatelessWidget {
  const _JugadorHeader({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        color: DtflyTheme.coachRed,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const DtflyCoachLogo(size: 58),
        ],
      ),
    );
  }
}
