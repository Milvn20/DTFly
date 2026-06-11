import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

class DtflyNavItem {
  const DtflyNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Barra de navegación inferior (mockup: blanca con ícono rojo activo).
class DtflyBottomNav extends StatelessWidget {
  const DtflyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.light = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DtflyNavItem> items;
  /// Estilo mockup: fondo blanco, activo rojo, inactivo gris oscuro.
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DtflyTheme.radiusLg)),
        child: ColoredBox(
          color: light ? Colors.white : DtflyTheme.secondary,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavEntry(
                        icon: items[i].icon,
                        label: items[i].label,
                        selected: currentIndex == i,
                        onTap: () => onTap(i),
                        light: light,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final activeColor = light ? const Color(0xFFC62828) : Colors.white;
    final inactiveColor = light ? DtflyTheme.textPrimary : DtflyTheme.navUnselected;
    final color = selected ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: DtflyTheme.borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (light)
              Icon(icon, color: color, size: 26)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? DtflyTheme.primary.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(DtflyTheme.radiusPill),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
