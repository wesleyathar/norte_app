import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/analytics.dart';
import '../../domain/models/transaction.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../finance/finance_cubit.dart';
import 'widgets/balance_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/month_chart_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _obscured = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Olá 👋'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificações',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) {
          if (state.status == FinanceStatus.failure) {
            return _ErrorView(
              message: state.error ?? 'Algo deu errado.',
              onRetry: () => context.read<FinanceCubit>().load(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<FinanceCubit>().load(),
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            child: state.isLoading
                ? const _DashboardSkeleton()
                : _DashboardContent(
                    state: state,
                    obscured: _obscured,
                    onToggleObscured: () =>
                        setState(() => _obscured = !_obscured),
                  ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.state,
    required this.obscured,
    required this.onToggleObscured,
  });

  final FinanceState state;
  final bool obscured;
  final VoidCallback onToggleObscured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMonth = state.currentMonth;
    final recent = state.transactions.take(5).toList();
    final insights = _buildInsights(context, currentMonth);

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xxl),
      children: [
        StaggeredFadeIn(
          index: 0,
          child: BalanceCard(
            balance: state.totalBalance,
            income: Analytics.income(currentMonth),
            expense: Analytics.expense(currentMonth),
            obscured: obscured,
            onToggleObscured: onToggleObscured,
          ),
        ),
        const SectionHeader(title: 'Receitas x despesas'),
        StaggeredFadeIn(
          index: 1,
          child: MonthChartCard(transactions: state.transactions),
        ),
        const SectionHeader(title: 'Insights'),
        for (final (index, insight) in insights.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: StaggeredFadeIn(
              index: index + 2,
              child: InsightCard(insight: insight),
            ),
          ),
        SectionHeader(
          title: 'Últimas transações',
          action: TextButton(
            onPressed: () => context.go(Routes.transactions),
            child: const Text('Ver todas'),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final (index, transaction) in recent.indexed) ...[
                if (index > 0) const Divider(indent: AppSpacing.xxl),
                StaggeredFadeIn(
                  index: index + 5,
                  child: TransactionTile(transaction: transaction),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dados de demonstração. Conecte uma conta para ver os seus.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Insight> _buildInsights(
    BuildContext context,
    List<Transaction> currentMonth,
  ) {
    final semantic = context.semanticColors;
    final insights = <Insight>[];
    final byCategory = Analytics.byCategory(currentMonth);

    if (byCategory.isNotEmpty) {
      final top = byCategory.first;
      insights.add(
        Insight(
          icon: top.category.icon,
          title: 'Maior gasto do mês',
          summary:
              '${Formatters.currency.format(top.total)} em ${top.category.label}',
          detail:
              'Essa categoria representa a maior fatia das suas despesas neste mês. '
              'Abra a aba Insights para comparar com os meses anteriores.',
          color: top.category.color,
        ),
      );
    }

    final atRisk = state.budgets
        .where((b) => b.isExceeded || b.isNearLimit)
        .toList();
    if (atRisk.isNotEmpty) {
      final budget = atRisk.first;
      insights.add(
        Insight(
          icon: Icons.warning_amber_rounded,
          title: budget.isExceeded
              ? 'Orçamento estourado'
              : 'Orçamento no limite',
          summary:
              '${budget.category.label}: ${Formatters.percent.format(budget.progress)} usado',
          detail: budget.isExceeded
              ? 'Você passou ${Formatters.currency.format(budget.spent - budget.limit)} '
                    'do limite definido para ${budget.category.label}.'
              : 'Restam ${Formatters.currency.format(budget.remaining)} até o fim do mês.',
          color: budget.isExceeded ? semantic.negative : semantic.warning,
        ),
      );
    }

    if (state.goals.isNotEmpty) {
      final activeGoal = state.goals.firstWhere(
        (g) => !g.isComplete,
        orElse: () => state.goals.first,
      );
      insights.add(
        Insight(
          icon: Icons.flag_outlined,
          title: 'Meta em andamento',
          summary:
              '${activeGoal.name}: ${Formatters.percent.format(activeGoal.progress)} concluído',
          detail:
              'Guardando ${Formatters.currency.format(activeGoal.suggestedMonthlyContribution)} '
              'por mês você chega ao objetivo no prazo.',
          color: AppColors.categoryPalette[3],
        ),
      );
    }

    insights.add(
      Insight(
        icon: Icons.trending_up,
        title: 'Projeção de saldo',
        summary: Formatters.currency.format(
          Analytics.projectedBalance(currentMonth),
        ),
        detail: 'Estimativa para o fim do mês mantendo o ritmo atual de gastos diários.',
        color: semantic.positive,
      ),
    );

    return insights;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xxl),
      children: const [
        Skeleton(height: 168),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 20, width: 180),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 260),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 20, width: 120),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 76),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 76),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 76),
      ],
    );
  }
}
