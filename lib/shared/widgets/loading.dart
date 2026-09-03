import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// Spinner com gradiente varrido ("aurora"), usado como indicador padrão.
class AuroraSpinner extends StatefulWidget {
  const AuroraSpinner({super.key, this.size = 36, this.strokeWidth = 4});

  final double size;
  final double strokeWidth;

  @override
  State<AuroraSpinner> createState() => _AuroraSpinnerState();
}

class _AuroraSpinnerState extends State<AuroraSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _AuroraPainter(
              turns: _controller.value,
              strokeWidth: widget.strokeWidth,
              colors: [
                Theme.of(context).colorScheme.primary,
                AppColors.categoryPalette[1],
                AppColors.categoryPalette[3],
                Theme.of(context).colorScheme.primary,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.turns,
    required this.strokeWidth,
    required this.colors,
  });

  final double turns;
  final double strokeWidth;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(turns * 2 * pi),
      ).createShader(rect);

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      turns * 2 * pi,
      pi * 1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => oldDelegate.turns != turns;
}

/// Bloco cinza com onda de brilho, exibido enquanto os dados carregam.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppRadius.cardBorder,
  });

  const Skeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = const BorderRadius.all(Radius.circular(999));

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = _controller.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(shift - 1, 0),
              end: Alignment(shift + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder de uma linha de transação.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const Skeleton.circle(size: 40),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(height: 14),
                SizedBox(height: AppSpacing.sm),
                Skeleton(height: 12, width: 140),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          const Skeleton(height: 14, width: 72),
        ],
      ),
    );
  }
}
