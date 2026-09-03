import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/analytics.dart';
import '../../domain/models/transaction.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../finance/finance_cubit.dart';
import 'widgets/category_pie_card.dart';
import 'widgets/monthly_trend_card.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: AuroraSpinner());
          }

          final now = DateTime.now();
          final all = state.transactions;
          final current = state.currentMonth;
          final previous = Analytics.inMonth(
            all,
            DateTime(now.year, now.month - 1),
          );

          final currentExpense = Analytics.expense(current);
          final previousExpense = Analytics.expense(previous);
          final delta = previousExpense == 0
              ? 0.0
              : (currentExpense - previousExpense) / previousExpense;

          return ListView(
            padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xxl),
            children: [
              StaggeredFadeIn(
                index: 0,
                child: _ComparisonCard(
                  income: Analytics.income(current),
                  expense: currentExpense,
                  delta: delta,
                ),
              ),
              const SectionHeader(title: 'Para onde foi o dinheiro'),
              StaggeredFadeIn(
                index: 1,
                child: CategoryPieCard(data: Analytics.byCategory(current)),
              ),
              const SectionHeader(title: 'Evolução dos últimos 6 meses'),
              StaggeredFadeIn(
                index: 2,
                child: MonthlyTrendCard(
                  series: Analytics.monthlySeries(all, 6),
                ),
              ),
              const SectionHeader(title: 'Sugestões'),
              for (final (index, suggestion) in _suggestions(
                current,
                currentExpense,
                delta,
              ).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: StaggeredFadeIn(index: index + 3, child: suggestion),
                ),
              Text(
                'Relatórios automáticos chegam toda segunda-feira e no dia 1º de cada mês.',
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

  List<Widget> _suggestions(
    List<Transaction> current,
    double currentExpense,
    double delta,
  ) {
    final assinaturas = Analytics.byCategory(current)
        .where((item) => item.category.label == 'Assinaturas')
        .firstOrNull;

    return [
      if (assinaturas != null)
        _SuggestionCard(
          icon: Icons.subscriptions_outlined,
          text:
              'Você gasta ${Formatters.currency.format(assinaturas.total)} por mês '
              'em assinaturas. Revisar as menos usadas libera esse valor para suas metas.',
        ),
      _SuggestionCard(
        icon: delta > 0 ? Icons.trending_up : Icons.trending_down,
        text: delta > 0
            ? 'Suas despesas subiram ${Formatters.percent.format(delta)} em relação ao mês passado.'
            : 'Suas despesas caíram ${Formatters.percent.format(delta.abs())} em relação ao mês passado. Continue assim.',
      ),
      _SuggestionCard(
        icon: Icons.savings_outlined,
        text:
            'Separando 10% do seu gasto atual (${Formatters.currency.format(currentExpense * 0.1)}) '
            'você acelera a reserva de emergência.',
      ),
    ];
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.income,
    required this.expense,
    required this.delta,
  });

  final double income;
  final double expense;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final worse = delta > 0;

    return Card(
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Recebido',
                    value: income,
                    color: semantic.positive,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Gasto',
                    value: expense,
                    color: semantic.negative,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  worse ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: worse ? semantic.negative : semantic.positive,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${Formatters.percent.format(delta.abs())} '
                  '${worse ? 'acima' : 'abaixo'} do mês anterior',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          Formatters.currency.format(value),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
