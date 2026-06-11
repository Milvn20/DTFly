import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/dtfly_theme.dart';

/// Scaffold secundario con AppBar oscura y fondo claro.
class DtflyDarkScaffold extends StatelessWidget {
  const DtflyDarkScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(
        backgroundColor: DtflyTheme.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: showBack,
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: DtflyTheme.contentMaxWidth(context)),
          child: body,
        ),
      ),
    );
  }
}

/// Tarjeta con borde suave, radio 12px y sombra.
class DtflyDarkCard extends StatelessWidget {
  const DtflyDarkCard({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.destacado = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DtflyTheme.cardDecoration(destacado: destacado),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DtflyTheme.borderRadius,
        child: card,
      ),
    );
  }
}
