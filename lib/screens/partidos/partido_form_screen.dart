import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/services/partido_service.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Formulario profesional para programar o editar un partido (DT).
class PartidoFormScreen extends StatefulWidget {
  const PartidoFormScreen({
    super.key,
    this.partido,
    required this.entrenadorEmail,
    required this.entrenadorUsuarioId,
    required this.entrenadorNombre,
    this.categoriaDeportiva,
  });

  final Partido? partido;
  final String entrenadorEmail;
  final String entrenadorUsuarioId;
  final String entrenadorNombre;
  final String? categoriaDeportiva;

  bool get editando => partido != null;

  @override
  State<PartidoFormScreen> createState() => _PartidoFormScreenState();
}

class _PartidoFormScreenState extends State<PartidoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rival = TextEditingController();
  final _lugar = TextEditingController();
  final _notas = TextEditingController();

  late DateTime _fecha;
  late TimeOfDay _hora;
  bool _guardando = false;

  static const _lugaresRapidos = [
    'Cancha principal',
    'Cancha auxiliar',
    'Gimnasio',
    'Sede externa',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.partido;
    _rival.text = p?.rival ?? '';
    _lugar.text = p?.lugar ?? 'Cancha principal';
    _notas.text = p?.notas ?? '';
    _fecha = p?.fechaHora ?? DateTime.now().add(const Duration(days: 3));
    _hora = p != null
        ? TimeOfDay(hour: p.fechaHora.hour, minute: p.fechaHora.minute)
        : const TimeOfDay(hour: 15, minute: 0);
  }

  @override
  void dispose() {
    _rival.dispose();
    _lugar.dispose();
    _notas.dispose();
    super.dispose();
  }

  DeporteCategoria? get _deporte =>
      DeportesCategoria.porId(widget.categoriaDeportiva);

  DateTime get _fechaHora => DateTime(
        _fecha.year,
        _fecha.month,
        _fecha.day,
        _hora.hour,
        _hora.minute,
      );

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Fecha del partido',
    );
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _elegirHora() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _hora,
      helpText: 'Hora de inicio',
    );
    if (t != null) setState(() => _hora = t);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      if (widget.editando) {
        await PartidoService.actualizar(
          id: widget.partido!.id,
          fechaHora: _fechaHora,
          rival: _rival.text.trim(),
          lugar: _lugar.text.trim(),
          notas: _notas.text.trim(),
          entrenadorEmail: widget.entrenadorEmail,
          entrenadorNombre: widget.entrenadorNombre,
          categoriaDeportiva: widget.categoriaDeportiva,
        );
      } else {
        await PartidoService.crear(
          entrenadorEmail: widget.entrenadorEmail,
          entrenadorUsuarioId: widget.entrenadorUsuarioId,
          entrenadorNombre: widget.entrenadorNombre,
          categoriaDeportiva: widget.categoriaDeportiva,
          fechaHora: _fechaHora,
          rival: _rival.text.trim(),
          lugar: _lugar.text.trim(),
          notas: _notas.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editando
                ? 'Partido actualizado. El muro se sincronizó automáticamente.'
                : 'Partido programado y publicado en el muro de tu selección.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deporte = _deporte;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _EncabezadoFormulario(
            editando: widget.editando,
            deporte: deporte,
            categoriaLabel: DeportesCategoria.nombreVisible(widget.categoriaDeportiva),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  _VistaPreviaPartido(
                    rival: _rival.text,
                    fechaHora: _fechaHora,
                    lugar: _lugar.text,
                    deporte: deporte,
                  ),
                  const SizedBox(height: 24),
                  _SeccionTitulo(
                    icono: Icons.groups_outlined,
                    titulo: 'Equipo rival',
                    subtitulo: 'Nombre del oponente para el calendario y el muro',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _rival,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    decoration: _dec(
                      hint: 'Ej: Universidad de Chile, Instituto Nacional…',
                      icon: Icons.sports_soccer,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el nombre del rival';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _SeccionTitulo(
                    icono: Icons.event_outlined,
                    titulo: 'Fecha y hora',
                    subtitulo: 'Cuándo se juega el encuentro',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SelectorFechaHora(
                          icono: Icons.calendar_month,
                          etiqueta: 'Fecha',
                          valor: _fmtFecha(_fecha),
                          onTap: _elegirFecha,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SelectorFechaHora(
                          icono: Icons.schedule,
                          etiqueta: 'Hora',
                          valor: _hora.format(context),
                          onTap: _elegirHora,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SeccionTitulo(
                    icono: Icons.location_on_outlined,
                    titulo: 'Ubicación',
                    subtitulo: 'Lugar del partido o entrenamiento oficial',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _lugar,
                    onChanged: (_) => setState(() {}),
                    decoration: _dec(
                      hint: 'Cancha, gimnasio o sede',
                      icon: Icons.place_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in _lugaresRapidos)
                        ActionChip(
                          label: Text(l),
                          onPressed: () {
                            setState(() => _lugar.text = l);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SeccionTitulo(
                    icono: Icons.notes_outlined,
                    titulo: 'Notas para el plantel',
                    subtitulo: 'Indicaciones, convocatoria o detalles extra (opcional)',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notas,
                    minLines: 3,
                    maxLines: 5,
                    decoration: _dec(
                      hint: 'Ej: Llegar 45 min antes, uniforme alternativo, punto de encuentro…',
                      icon: Icons.edit_note,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.campaign_outlined, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Al guardar, el partido aparecerá en tu calendario y se publicará automáticamente en el Muro Deportivo de tu selección.',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(widget.editando ? Icons.save : Icons.event_available),
            label: Text(
              widget.editando ? 'Guardar cambios' : 'Programar partido',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: DtflyTheme.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: DtflyTheme.textMuted) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DtflyTheme.primary, width: 1.5),
      ),
    );
  }

  static String _fmtFecha(DateTime d) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}

class _EncabezadoFormulario extends StatelessWidget {
  const _EncabezadoFormulario({
    required this.editando,
    required this.categoriaLabel,
    this.deporte,
  });

  final bool editando;
  final String categoriaLabel;
  final DeporteCategoria? deporte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      editando ? 'Editar partido' : 'Programar partido',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        deporte?.icono ?? Icons.sports_soccer,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editando
                                ? 'Actualiza los datos del encuentro'
                                : 'Nuevo encuentro oficial',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: DtflyTheme.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoriaLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VistaPreviaPartido extends StatelessWidget {
  const _VistaPreviaPartido({
    required this.rival,
    required this.fechaHora,
    required this.lugar,
    this.deporte,
  });

  final String rival;
  final DateTime fechaHora;
  final String lugar;
  final DeporteCategoria? deporte;

  @override
  Widget build(BuildContext context) {
    final rivalTxt = rival.trim().isEmpty ? 'Rival por definir' : rival.trim();
    final lugarTxt = lugar.trim().isEmpty ? 'Ubicación por confirmar' : lugar.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: DtflyTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DtflyTheme.primary,
                  DtflyTheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${fechaHora.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                Text(
                  _mesCorto(fechaHora.month),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRÓXIMO PARTIDO',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      deporte?.icono ?? Icons.sports_soccer,
                      size: 18,
                      color: DtflyTheme.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'vs $rivalTxt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${fechaHora.hour.toString().padLeft(2, '0')}:'
                      '${fechaHora.minute.toString().padLeft(2, '0')} hrs',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lugarTxt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vista previa · así se verá en el muro',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _mesCorto(int m) {
    const meses = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    return meses[m - 1];
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DtflyTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: DtflyTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitulo,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectorFechaHora extends StatelessWidget {
  const _SelectorFechaHora({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 18, color: DtflyTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    etiqueta,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
