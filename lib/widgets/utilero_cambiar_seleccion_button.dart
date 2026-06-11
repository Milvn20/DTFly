import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/deportes_categoria.dart';

/// Botón para cambiar la selección deportiva del utilero.
class UtileroCambiarSeleccionButton extends StatelessWidget {
  const UtileroCambiarSeleccionButton({
    super.key,
    required this.deporteId,
    required this.onTap,
    this.compacto = false,
  });

  final String? deporteId;
  final VoidCallback onTap;
  final bool compacto;

  String get _etiqueta {
    if (deporteId == null || deporteId!.isEmpty) {
      return 'Elegir selección';
    }
    return DeportesCategoria.nombreVisible(deporteId);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: compacto
          ? Colors.white
          : const Color(0xFFC62828).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(compacto ? 14 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compacto ? 14 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compacto ? 9 : 10,
            horizontal: compacto ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compacto ? 14 : 12),
            border: Border.all(
              color: compacto
                  ? const Color(0xFFC62828)
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz,
                size: compacto ? 18 : 20,
                color: compacto ? const Color(0xFFC62828) : Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  compacto
                      ? 'Cambiar: $_etiqueta'
                      : 'Cambiar selección · $_etiqueta',
                  style: TextStyle(
                    color: compacto ? const Color(0xFFC62828) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compacto ? 12 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: compacto ? 18 : 20,
                color: compacto ? const Color(0xFFC62828) : Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
