import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/analytics.dart';
import '../../../domain/models/transaction.dart';

/// Receitas x despesas do mês, com swipe horizontal para navegar entre meses.
class MonthChartCard extends StatefulWidget {
  const MonthChartCard({
    super.key,
    required this.transactions,
    this.monthsBack = 5,
  });

  final List<Transaction> transactions;
  final int monthsBack;

  @override
  State<MonthChartCard> createState() => _MonthChartCardState();
}

class _MonthChartCardState extends State<MonthChartCard> {
  late final List<DateTime> _months = _buildMonths();
  late final PageController _controller = PageController(
    initialPage: _months.length - 1,
  );
  late int _current = _months.length - 1;

  List<DateTime> _buildMonths() {
    final now = DateTime.now();
    return [
      for (var i = widget.monthsBack; i >= 0; i--)
        DateTime(now.year, now.month - i),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = _current + delta;
    if (target < 0 || target >= _months.length) return;
    _controller.animateToPage(
      target,
      duration: context.motion(AppMotion.normal),
      curve: AppMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = _months[_current];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _current > 0 ? () => _go(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mês anterior',
                ),
                Expanded(
                  child: Text(
                    Formatters.capitalize(Formatters.monthYear.format(month)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _current < _months.length - 1
                      ? () => _go(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Próximo mês',
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _controller,
                itemCount: _months.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) => _MonthBars(
                  transactions: widget.transactions,
                  month: _months[index],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _Legend(),
          ],
        ),
      ),
    );
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.transactions, required this.month});

  final List<Transaction> transactions;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthTransactions = Analytics.inMonth(transactions, month);
    final series = Analytics.weeklySeries(monthTransactions, month);

    if (series.isEmpty) {
      return Center(
        child: Text('Sem dados neste mês', style: theme.textTheme.bodyMedium),
      );
    }

    final maxValue = series
        .map((b) => b.income > b.expense ? b.income : b.expense)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Semantics(
      label:
          'Gráfico de receitas e despesas por semana de '
          '${Formatters.monthYear.format(month)}',
      child: BarChart(
        BarChartData(
          maxY: maxValue == 0 ? 100 : maxValue * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    Formatters.compactCurrency.format(rod.toY),
                    theme.textTheme.labelSmall!,
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      series[index].label,
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < series.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  _rod(series[i].income, AppColors.positiveLight),
                  _rod(series[i].expense, AppColors.negativeLight),
                ],
              ),
          ],
        ),
        duration: context.motion(AppMotion.chart),
        curve: AppMotion.curve,
      ),
    );
  }

  BarChartRodData _rod(double value, Color color) => BarChartRodData(
    toY: value,
    width: 10,
    color: color,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: AppColors.positiveLight, label: 'Receitas'),
        SizedBox(width: AppSpacing.lg),
        _LegendDot(color: AppColors.negativeLight, label: 'Despesas'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
