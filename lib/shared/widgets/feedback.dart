import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// Balança o conteúdo na horizontal (3x, 100ms cada) e pulsa em vermelho
/// sempre que [trigger] muda. Usado para erros de validação.
class ShakeOnError extends StatefulWidget {
  const ShakeOnError({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeOnError> createState() => _ShakeOnErrorState();
}

class _ShakeOnErrorState extends State<ShakeOnError>
    with SingleTickerProviderStateMixin {
  static const _cycles = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100 * _cycles),
  );

  @override
  void didUpdateWidget(ShakeOnError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      HapticFeedback.heavyImpact();
      if (!context.animationsDisabled) _controller.forward(from: 0);
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
      builder: (context, child) {
        final wave = _controller.isAnimating || _controller.isCompleted
            ? 1 - _controller.value
            : 0.0;
        final offset = 12 * wave * sin(_controller.value * _cycles * 2 * pi);

        return Transform.translate(
          offset: Offset(offset, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              border: Border.all(
                color: AppColors.negativeLight.withValues(alpha: wave),
                width: 2,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Marca de confirmação desenhada traço a traço, com vibração curta.
void showSuccessCheck(BuildContext context, String message) {
  HapticFeedback.lightImpact();

  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _SuccessCheckOverlay(
        message: message,
        onDone: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

class _SuccessCheckOverlay extends StatefulWidget {
  const _SuccessCheckOverlay({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_SuccessCheckOverlay> createState() => _SuccessCheckOverlayState();
}

class _SuccessCheckOverlayState extends State<_SuccessCheckOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 0.0-0.35 desenha o traço, 0.35-0.8 mantém, 0.8-1.0 desaparece.
    final draw = (_controller.value / 0.35).clamp(0.0, 1.0);
    final fade = _controller.value < 0.8
        ? 1.0
        : 1 - (_controller.value - 0.8) / 0.2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Center(
        child: Opacity(
          opacity: fade,
          child: Material(
            color: theme.colorScheme.inverseSurface,
            borderRadius: AppRadius.cardBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(48, 48),
                    painter: _CheckPainter(progress: draw),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.positiveDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.82, size.height * 0.28);

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
