import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Encolhe para 0.95 ao pressionar e volta com efeito elástico.
///
/// Usa [Listener] em vez de GestureDetector para não disputar a arena de
/// gestos com o botão filho — o toque continua sendo tratado pelo child.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.pressedScale = 0.95});

  final Widget child;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    reverseDuration: AppMotion.slow,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (!context.animationsDisabled) _controller.forward();
      },
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.status == AnimationStatus.reverse
              ? AppMotion.elastic.transform(_controller.value)
              : AppMotion.curve.transform(_controller.value);
          return Transform.scale(
            scale: 1 - (1 - widget.pressedScale) * progress,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
