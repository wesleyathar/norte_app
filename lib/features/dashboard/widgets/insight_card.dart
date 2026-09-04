import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

class Insight {
  const Insight({
    required this.icon,
    required this.title,
    required this.summary,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String detail;
  final Color color;
}

/// Card de insight que expande ao toque para mostrar o detalhe.
class InsightCard extends StatefulWidget {
  const InsightCard({super.key, required this.insight});

  final Insight insight;

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insight = widget.insight;

    return Card(
      child: InkWell(
        borderRadius: AppRadius.cardBorder,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedSize(
            duration: context.motion(AppMotion.fast),
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            insight.color.withValues(alpha: 0.28),
                            insight.color.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(insight.icon, color: insight.color, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insight.summary,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: context.motion(AppMotion.fast),
                      curve: AppMotion.curve,
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(insight.detail, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
