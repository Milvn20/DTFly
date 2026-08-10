import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';
import 'package:flutter_application_1/screens/muro/muro_deportivo_screen.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Botón destacado estilo mockup para abrir el Muro Deportivo.
class MuroAccesoButton extends StatelessWidget {
  const MuroAccesoButton({
    super.key,
    required this.deporteId,
    required this.autorEmail,
    required this.autorNombre,
    this.soloLectura = true,
    this.onTap,
  });

  final String? deporteId;
  final String autorEmail;
  final String autorNombre;
  final bool soloLectura;
  final VoidCallback? onTap;

  String get _etiquetaSeleccion {
    if (deporteId == null || deporteId!.isEmpty) {
      return 'tu selección';
    }
    return DeportesCategoria.nombreVisible(deporteId);
  }

  void _abrir(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MuroDeportivoScreen(
          soloLectura: soloLectura,
          autorEmail: autorEmail,
          autorNombre: autorNombre,
          deporteId: deporteId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrir(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 110,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DtflyTheme.primary,
                      DtflyTheme.primary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MURO DEPORTIVO',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ver muro de $_etiquetaSeleccion',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        soloLectura
                            ? 'Avisos, partidos, resultados y logros de tu DT'
                            : 'Publica novedades para tu plantel',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
