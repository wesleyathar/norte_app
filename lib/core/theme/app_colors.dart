import 'package:flutter/material.dart';

/// Paleta base da marca. As cores derivadas vêm do [ColorScheme.fromSeed].
abstract final class AppColors {
  static const seed = Color(0xFF6C4DFF);

  /// Gradiente principal da marca (herói, botões, destaques).
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B8CFF), Color(0xFF6C4DFF), Color(0xFFB14DFF)],
  );

  /// Gradiente quente para acentos e cartões secundários.
  static const sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6FB5), Color(0xFFFF8A3D)],
  );

  /// Gradiente de fundo (aplicado atrás do conteúdo, bem sutil).
  static const auroraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF141326), Color(0xFF0C0B18)],
  );

  /// Superfícies profundas do tema escuro (dark-first caprichado).
  static const darkBackground = Color(0xFF0C0B18);
  static const darkSurface = Color(0xFF16152A);
  static const darkSurfaceHigh = Color(0xFF20203A);

  static const positiveLight = Color(0xFF00A870);

  static const positiveDark = Color(0xFF3DDCA0);

  static const negativeLight = Color(0xFFD93B47);
  static const negativeDark = Color(0xFFFF7A82);

  static const warningLight = Color(0xFFB8730A);
  static const warningDark = Color(0xFFFFC04D);

  /// Cores fixas usadas para diferenciar categorias em gráficos e chips.
  /// Escolhidas para permanecerem distinguíveis em tema claro e escuro.
  static const categoryPalette = <Color>[
    Color(0xFF2F5BFF),
    Color(0xFF00C48C),
    Color(0xFFFF8A3D),
    Color(0xFFAF52DE),
    Color(0xFF00B8D9),
    Color(0xFFFF5C8A),
    Color(0xFF6E7C99),
    Color(0xFFFFC04D),
  ];
}

/// Cores com significado semântico (entrada/saída/alerta) que precisam de
/// valores diferentes em tema claro e escuro.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.positive,
    required this.negative,
    required this.warning,
  });

  final Color positive;
  final Color negative;
  final Color warning;

  static const light = AppSemanticColors(
    positive: AppColors.positiveLight,
    negative: AppColors.negativeLight,
    warning: AppColors.warningLight,
  );

  static const dark = AppSemanticColors(
    positive: AppColors.positiveDark,
    negative: AppColors.negativeDark,
    warning: AppColors.warningDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
  }) {
    return AppSemanticColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
