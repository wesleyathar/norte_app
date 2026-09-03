import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/celebration.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../finance/finance_cubit.dart';
import 'widgets/budget_card.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: AuroraSpinner());
          }

          final budgets = state.budgets;
          final goals = state.goals;
          final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limit);
          final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);

          return ListView(
            padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xxl),
            children: [
              StaggeredFadeIn(
                index: 0,
                child: _MonthSummary(spent: totalSpent, limit: totalLimit),
              ),
              const SectionHeader(title: 'Por categoria'),
              for (final (index, budget) in budgets.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: StaggeredFadeIn(
                    index: index + 1,
                    child: BudgetCard(budget: budget),
                  ),
                ),
              const SectionHeader(title: 'Metas'),
              for (final (index, goal) in goals.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: StaggeredFadeIn(
                    index: index + budgets.length + 1,
                    child: GoalCard(
                      goal: goal,
                      onCelebrate: () => showCelebration(context),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Você recebe um alerta ao atingir 80% e 100% de cada orçamento.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.spent, required this.limit});

  final double spent;
  final double limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = limit == 0 ? 0.0 : spent / limit;
    final semantic = context.semanticColors;
    final color = progress >= 1
        ? semantic.negative
        : progress >= 0.8
        ? semantic.warning
        : theme.colorScheme.primary;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Formatters.capitalize(
                Formatters.monthYear.format(DateTime.now()),
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${Formatters.currency.format(spent)} de '
              '${Formatters.currency.format(limit)} orçados',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedProgressBar(value: progress, color: color, height: 12),
          ],
        ),
      ),
    );
  }
}
