import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/utilero_material.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/utilero_material_icon.dart';

/// Cabecera roja estilo mockup DTFly.
class UtileroKioscoHeader extends StatelessWidget {
  const UtileroKioscoHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: DtflyTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitulo!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón gigante tipo kiosco.
class UtileroKioscoBotonGigante extends StatelessWidget {
  const UtileroKioscoBotonGigante({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.onTap,
    this.color,
    this.subtitulo,
  });

  final String emoji;
  final String titulo;
  final String? subtitulo;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DtflyTheme.primary;
    return Material(
      color: c,
      borderRadius: DtflyTheme.borderRadius,
      elevation: 3,
      shadowColor: c.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: DtflyTheme.borderRadius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.9), size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de confirmación final.
class UtileroKioscoConfirmar extends StatelessWidget {
  const UtileroKioscoConfirmar({
    super.key,
    required this.texto,
    required this.onTap,
    this.color,
    this.icono,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icono;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DtflyTheme.success;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: cargando ? null : onTap,
        icon: cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Icon(icono ?? Icons.check_circle_outline, size: 28),
        label: Text(
          texto,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: DtflyTheme.borderRadius),
          elevation: 4,
        ),
      ),
    );
  }
}

/// Teclado numérico gigante.
class UtileroKioscoTeclado extends StatelessWidget {
  const UtileroKioscoTeclado({
    super.key,
    required this.valor,
    required this.onDigito,
    required this.onBorrar,
    required this.onConfirmar,
    this.habilitarConfirmar = true,
  });

  final String valor;
  final ValueChanged<String> onDigito;
  final VoidCallback onBorrar;
  final VoidCallback onConfirmar;
  final bool habilitarConfirmar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: DtflyTheme.surfaceCard,
            borderRadius: DtflyTheme.borderRadius,
            border: Border.all(color: DtflyTheme.borderSubtle, width: 2),
          ),
          child: Text(
            valor.isEmpty ? '0' : valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: DtflyTheme.textPrimary,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _fila(['1', '2', '3']),
        const SizedBox(height: 10),
        _fila(['4', '5', '6']),
        const SizedBox(height: 10),
        _fila(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _tecla('C', onBorrar, color: DtflyTheme.textSecondary)),
            const SizedBox(width: 10),
            Expanded(child: _tecla('0', () => onDigito('0'))),
            const SizedBox(width: 10),
            Expanded(
              child: _tecla(
                '✓',
                habilitarConfirmar ? onConfirmar : null,
                color: DtflyTheme.success,
                textoBlanco: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fila(List<String> digitos) {
    return Row(
      children: [
        for (var i = 0; i < digitos.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _tecla(digitos[i], () => onDigito(digitos[i]))),
        ],
      ],
    );
  }

  Widget _tecla(
    String label,
    VoidCallback? onTap, {
    Color? color,
    bool textoBlanco = false,
  }) {
    final habilitado = onTap != null;
    return Material(
      color: habilitado
          ? (color ?? DtflyTheme.surfaceCard)
          : DtflyTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      elevation: habilitado ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color ?? DtflyTheme.borderSubtle,
              width: color != null ? 0 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == '✓' ? 28 : 26,
              fontWeight: FontWeight.bold,
              color: textoBlanco
                  ? Colors.white
                  : (habilitado
                      ? DtflyTheme.textPrimary
                      : DtflyTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de material seleccionable.
class UtileroKioscoMaterialCard extends StatelessWidget {
  const UtileroKioscoMaterialCard({
    super.key,
    required this.categoria,
    required this.onTap,
    this.seleccionado = false,
    this.subtitulo,
    this.imagenUrl,
    this.imagenBase64,
    this.compacto = true,
  });

  final UtileroMaterialCat categoria;
  final VoidCallback onTap;
  final bool seleccionado;
  final String? subtitulo;
  final String? imagenUrl;
  final String? imagenBase64;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final iconSize = compacto ? 22.0 : 40.0;
    final fontSize = compacto ? 11.0 : 18.0;
    final padding = compacto ? 8.0 : 16.0;
    return Material(
      color: seleccionado ? categoria.color.withValues(alpha: 0.12) : DtflyTheme.surfaceCard,
      borderRadius: BorderRadius.circular(compacto ? 10 : 14),
      elevation: seleccionado ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(compacto ? 10 : 14),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compacto ? 10 : 14),
            border: Border.all(
              color: seleccionado ? categoria.color : DtflyTheme.borderSubtle,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UtileroMaterialIcon(
                categoria: categoria,
                size: iconSize,
                imagenUrl: imagenUrl,
                imagenBase64: imagenBase64,
              ),
              SizedBox(height: compacto ? 4 : 8),
              Text(
                categoria.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: seleccionado ? categoria.color : DtflyTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitulo!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compacto ? 9 : 13,
                    fontWeight: FontWeight.w600,
                    color: subtitulo!.toLowerCase().contains('devolver')
                        ? const Color(0xFFC62828)
                        : DtflyTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de persona (profesor).
class UtileroKioscoPersonaCard extends StatelessWidget {
  const UtileroKioscoPersonaCard({
    super.key,
    required this.persona,
    required this.onTap,
  });

  final UtileroPersonaEntrega persona;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.surfaceCard,
      borderRadius: DtflyTheme.borderRadius,
      elevation: 2,
      child: InkWell(
        borderRadius: DtflyTheme.borderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: DtflyTheme.borderRadius,
            border: Border.all(color: DtflyTheme.borderSubtle),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: DtflyTheme.primary.withValues(alpha: 0.15),
                backgroundImage:
                    persona.fotoUrl != null ? NetworkImage(persona.fotoUrl!) : null,
                child: persona.fotoUrl == null
                    ? const Text('👨‍🏫', style: TextStyle(fontSize: 28))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  persona.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DtflyTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 28, color: DtflyTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de stock con alerta.
class UtileroKioscoStockCard extends StatelessWidget {
  const UtileroKioscoStockCard({
    super.key,
    required this.categoria,
    required this.disponible,
    this.onTap,
  });

  final UtileroMaterialCat categoria;
  final int disponible;
  final VoidCallback? onTap;

  bool get _stockBajo => disponible <= UtileroMaterialCat.umbralStockBajo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DtflyTheme.surfaceCard,
      borderRadius: DtflyTheme.borderRadius,
      elevation: 2,
      child: InkWell(
        borderRadius: DtflyTheme.borderRadius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: DtflyTheme.borderRadius,
            border: Border.all(
              color: _stockBajo ? DtflyTheme.primary : DtflyTheme.borderSubtle,
              width: _stockBajo ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UtileroMaterialIcon(categoria: categoria, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    categoria.nombre.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: categoria.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$disponible',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: DtflyTheme.textPrimary,
                  height: 1.1,
                ).copyWith(
                  color: _stockBajo ? DtflyTheme.primary : DtflyTheme.textPrimary,
                ),
              ),
              const Text(
                'Disponibles',
                style: TextStyle(
                  fontSize: 18,
                  color: DtflyTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_stockBajo) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DtflyTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔴', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'STOCK BAJO',
                        style: TextStyle(
                          color: DtflyTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de pasos (1/3, 2/3...).
class UtileroKioscoPasos extends StatelessWidget {
  const UtileroKioscoPasos({
    super.key,
    required this.pasoActual,
    required this.totalPasos,
    required this.etiqueta,
  });

  final int pasoActual;
  final int totalPasos;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          etiqueta.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DtflyTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPasos, (i) {
            final activo = i < pasoActual;
            return Container(
              width: 40,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: activo ? DtflyTheme.primary : DtflyTheme.borderSubtle,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Tarjeta de historial.
class UtileroKioscoHistorialCard extends StatelessWidget {
  const UtileroKioscoHistorialCard({
    super.key,
    required this.emoji,
    required this.texto,
    required this.hora,
    this.color,
  });

  final String emoji;
  final String texto;
  final String hora;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DtflyTheme.surfaceCard,
        borderRadius: DtflyTheme.borderRadius,
        border: Border.all(color: color ?? DtflyTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DtflyTheme.textPrimary,
              ),
            ),
          ),
          Text(
            hora,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DtflyTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
