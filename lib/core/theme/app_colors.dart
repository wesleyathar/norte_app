import 'package:flutter/material.dart';

/// Paleta base da marca. As cores derivadas vêm do [ColorScheme.fromSeed].
abstract final class AppColors {
  static const seed = Color(0xFF2F5BFF);

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
