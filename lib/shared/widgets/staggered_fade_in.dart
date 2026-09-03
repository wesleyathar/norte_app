import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Entrada em cascata (fade + slide-up) usada em listas e cards.
/// O atraso é `index * step`; respeita "reduzir animações" do sistema.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppMotion.normal,
    this.step = AppMotion.staggerStep,
    this.beginOffset = const Offset(0, 0.12),
  });

  final int index;
  final Widget child;
  final Duration duration;
  final Duration step;
  final Offset beginOffset;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (context.animationsDisabled) {
      _controller.value = 1;
      return;
    }
    // Limita o atraso para listas longas não deixarem itens parados.
    final delay = widget.step * widget.index.clamp(0, 12);
    _timer = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
