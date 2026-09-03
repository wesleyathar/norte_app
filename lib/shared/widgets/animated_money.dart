import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';

/// Valor monetário que anima do zero (ou do valor anterior) até o atual.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    this.style,
    this.obscured = false,
    this.signed = false,
  });

  final double value;
  final TextStyle? style;
  final bool obscured;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    if (obscured) {
      return Text('R\$ ••••••', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: context.motion(AppMotion.chart),
      curve: AppMotion.curve,
      builder: (context, animated, _) => Text(
        signed
            ? Formatters.signed(animated)
            : Formatters.currency.format(animated),
        style: style,
      ),
    );
  }
}
