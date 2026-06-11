import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Botón menú estilo SaaS — rojo deportivo con sombra suave.
class DtflyPillMenuButton extends StatelessWidget {
  const DtflyPillMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DtflyTheme.borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: DtflyTheme.primaryButtonGradient,
            borderRadius: DtflyTheme.borderRadius,
            boxShadow: DtflyTheme.buttonShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
