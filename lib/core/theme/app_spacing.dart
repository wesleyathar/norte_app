import 'package:flutter/widgets.dart';

/// Escala de espaçamento em múltiplos de 4.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const screenPadding = EdgeInsets.symmetric(horizontal: lg);
}

abstract final class AppRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(20);
  static const xl = Radius.circular(28);

  static const cardBorder = BorderRadius.all(lg);
  static const heroBorder = BorderRadius.all(xl);
  static const sheetBorder = BorderRadius.vertical(top: xl);
}
