import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';

/// Evolução de receitas e despesas nos últimos meses.
class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({super.key, required this.series});

  final List<({DateTime month, double income, double expense})> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = series
        .expand((point) => [point.income, point.expense])
        .fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          height: 210,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxValue == 0 ? 100 : maxValue * 1.15,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= series.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          Formatters.dayMonth
                              .format(series[index].month)
                              .split(' ')
                              .last,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        Formatters.compactCurrency.format(spot.y),
                        theme.textTheme.labelSmall!.copyWith(
                          color: spot.bar.color,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                _line([
                  for (final (i, p) in series.indexed)
                    FlSpot(i.toDouble(), p.income),
                ], AppColors.positiveLight),
                _line([
                  for (final (i, p) in series.indexed)
                    FlSpot(i.toDouble(), p.expense),
                ], AppColors.negativeLight),
              ],
            ),
            duration: context.motion(AppMotion.chart),
            curve: AppMotion.curve,
          ),
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    color: color,
    isCurved: true,
    curveSmoothness: 0.25,
    barWidth: 3,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
  );
}
