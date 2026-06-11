import 'package:flutter/material.dart';

/// Colores y estilos del módulo kiosco utilero (accesibilidad extrema).
class UtileroKioscoTheme {
  UtileroKioscoTheme._();

  static const Color primary = Color(0xFFC62828);
  static const Color primaryDark = Color(0xFF9B1C1C);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF2D9C5A);
  static const Color info = Color(0xFF2563EB);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color stockBajo = Color(0xFFDC2626);

  static const double botonMinAltura = 64;
  static const double textoMin = 18;
  static const double numeroGrande = 48;
  static const double radius = 16;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B1C1C), primary],
  );

  static TextStyle tituloPantalla = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle subtitulo = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle numeroStock = const TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.1,
  );
}
