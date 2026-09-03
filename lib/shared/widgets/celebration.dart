import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Dispara confetes + vibração sobre a tela atual.
/// Não faz nada se o usuário pediu para reduzir animações.
void showCelebration(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return;

  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) =>
        IgnorePointer(child: _ConfettiBurst(onDone: () => entry.remove())),
  );

  overlay.insert(entry);
  HapticFeedback.mediumImpact();
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2200);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  final _particles = _buildParticles();

  static List<_Particle> _buildParticles() {
    final random = Random();
    return List.generate(60, (_) {
      return _Particle(
        startX: random.nextDouble(),
        startY: -random.nextDouble() * 0.3,
        fallSpeed: 0.7 + random.nextDouble() * 0.6,
        drift: (random.nextDouble() - 0.5) * 0.35,
        size: 6 + random.nextDouble() * 8,
        spin: (random.nextDouble() - 0.5) * 8,
        color: AppColors
            .categoryPalette[random.nextInt(AppColors.categoryPalette.length)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.startX,
    required this.startY,
    required this.fallSpeed,
    required this.drift,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double startX;
  final double startY;
  final double fallSpeed;
  final double drift;
  final double size;
  final double spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = progress < 0.75 ? 1.0 : (1 - (progress - 0.75) / 0.25);

    for (final particle in particles) {
      final y = (particle.startY + progress * particle.fallSpeed) * size.height;
      if (y < -particle.size || y > size.height + particle.size) continue;

      final x =
          (particle.startX + sin(progress * pi * 2) * particle.drift) *
          size.width;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(progress * particle.spin);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = particle.color.withValues(alpha: fade),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Barra de progresso que preenche suavemente ao mudar de valor.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 10,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: context.motion(AppMotion.chart),
      curve: AppMotion.curve,
      builder: (context, animated, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: animated,
          minHeight: height,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}
