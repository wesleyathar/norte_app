import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/budget.dart';
import '../../../shared/widgets/celebration.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final color = budget.isExceeded
        ? semantic.negative
        : budget.isNearLimit
        ? semantic.warning
        : budget.category.color;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.16),
                  child: Icon(budget.category.icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    budget.category.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  Formatters.percent.format(budget.progress),
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedProgressBar(value: budget.progress, color: color),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '${Formatters.currency.format(budget.spent)} de '
                  '${Formatters.currency.format(budget.limit)}',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  budget.isExceeded
                      ? 'Excedeu ${Formatters.currency.format(-budget.remaining)}'
                      : 'Restam ${Formatters.currency.format(budget.remaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, required this.onCelebrate});

  final Goal goal;
  final VoidCallback onCelebrate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final color = goal.isComplete
        ? semantic.positive
        : theme.colorScheme.primary;

    return Card(
      child: InkWell(
        borderRadius: AppRadius.cardBorder,
        onTap: goal.isComplete ? onCelebrate : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (goal.isComplete)
                    Icon(Icons.celebration, color: color, size: 20)
                  else
                    Text(
                      '${goal.monthsLeft} meses',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedProgressBar(value: goal.progress, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${Formatters.currency.format(goal.saved)} de '
                '${Formatters.currency.format(goal.target)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                goal.isComplete
                    ? 'Meta concluída. Toque para comemorar 🎉'
                    : 'Guarde ${Formatters.currency.format(goal.suggestedMonthlyContribution)} por mês para chegar no prazo',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
