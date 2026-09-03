import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

/// Moedas caindo em loop.
class CoinsIllustration extends StatefulWidget {
  const CoinsIllustration({super.key, this.size = 220});

  final double size;

  @override
  State<CoinsIllustration> createState() => _CoinsIllustrationState();
}

class _CoinsIllustrationState extends State<CoinsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.animationsDisabled && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CoinsPainter(progress: _controller.value, color: color),
      ),
    );
  }
}

class _CoinsPainter extends CustomPainter {
  const _CoinsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const columns = 5;
    for (var i = 0; i < columns; i++) {
      final phase = (progress + i / columns) % 1;
      final x = size.width * (0.15 + 0.175 * i);
      final y = size.height * phase;
      final fade = (1 - (phase - 0.5).abs() * 2).clamp(0.2, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        14,
        Paint()..color = color.withValues(alpha: fade * 0.85),
      );
      canvas.drawCircle(
        Offset(x, y),
        7,
        Paint()..color = Colors.white.withValues(alpha: fade * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_CoinsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Barras que crescem e diminuem, sugerindo um gráfico vivo.
class ChartIllustration extends StatefulWidget {
  const ChartIllustration({super.key, this.size = 220});

  final double size;

  @override
  State<ChartIllustration> createState() => _ChartIllustrationState();
}

class _ChartIllustrationState extends State<ChartIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.animationsDisabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
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
        size: Size(widget.size, widget.size),
        painter: _ChartPainter(
          progress: AppMotion.curve.transform(_controller.value),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.progress});

  final double progress;

  static const _heights = [0.35, 0.6, 0.45, 0.85, 0.7];

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 24.0;
    final gap =
        (size.width - barWidth * _heights.length) / (_heights.length + 1);

    for (var i = 0; i < _heights.length; i++) {
      final target = _heights[i];
      final height = size.height * target * (0.55 + 0.45 * progress);
      final left = gap + i * (barWidth + gap);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - height, barWidth, height),
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        Paint()
          ..color = AppColors
              .categoryPalette[i % AppColors.categoryPalette.length]
              .withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Escudo com anéis pulsando, para a mensagem de segurança.
class ShieldIllustration extends StatefulWidget {
  const ShieldIllustration({super.key, this.size = 220});

  final double size;

  @override
  State<ShieldIllustration> createState() => _ShieldIllustrationState();
}

class _ShieldIllustrationState extends State<ShieldIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.animationsDisabled && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _RingsPainter(progress: _controller.value, color: color),
          child: child,
        ),
        child: Center(
          child: Icon(
            Icons.shield_outlined,
            size: widget.size * 0.38,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = min(size.width, size.height) / 2;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1;
      canvas.drawCircle(
        center,
        maxRadius * (0.35 + 0.65 * phase),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - phase) * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
