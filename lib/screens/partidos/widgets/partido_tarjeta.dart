import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/partido.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Tarjeta profesional de partido para listados del DT.
class PartidoTarjeta extends StatelessWidget {
  const PartidoTarjeta({
    super.key,
    required this.partido,
    required this.mostrarResultado,
    this.onTap,
    this.acciones,
  });

  final Partido partido;
  final bool mostrarResultado;
  final VoidCallback? onTap;
  final Widget? acciones;

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final esJugado = mostrarResultado && p.esJugado;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: esJugado
                  ? DtflyTheme.success.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FechaBadge(
                    fecha: p.fechaHora,
                    color: esJugado ? DtflyTheme.success : DtflyTheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _EstadoChip(jugado: esJugado),
                            const Spacer(),
                            Text(
                              '${p.fechaHora.hour.toString().padLeft(2, '0')}:'
                              '${p.fechaHora.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'vs ${p.rival}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.lugar.isNotEmpty ? p.lugar : 'Sin ubicación',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (p.notas.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            p.notas,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (esJugado && p.resultadoTexto != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: DtflyTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Resultado ',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        p.resultadoTexto!,
                        style: const TextStyle(
                          color: DtflyTheme.accentOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (esJugado && p.observacionFinal.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  p.observacionFinal,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
              if (esJugado && p.fotosUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: p.fotosUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.fotosUrls[i],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              if (acciones != null) ...[
                const SizedBox(height: 12),
                acciones!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FechaBadge extends StatelessWidget {
  const _FechaBadge({required this.fecha, required this.color});

  final DateTime fecha;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${fecha.day}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text(
            _mes(fecha.month),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static String _mes(int m) {
    const meses = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    return meses[m - 1];
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.jugado});

  final bool jugado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (jugado ? DtflyTheme.success : const Color(0xFF2563EB))
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        jugado ? 'JUGADO' : 'PROGRAMADO',
        style: TextStyle(
          color: jugado ? DtflyTheme.success : const Color(0xFF2563EB),
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
