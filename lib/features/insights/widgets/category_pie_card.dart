import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/tx_category.dart';

/// Distribuição de gastos por categoria.
class CategoryPieCard extends StatefulWidget {
  const CategoryPieCard({super.key, required this.data});

  final List<({TxCategory category, double total})> data;

  @override
  State<CategoryPieCard> createState() => _CategoryPieCardState();
}

class _CategoryPieCardState extends State<CategoryPieCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = widget.data.take(5).toList();
    final othersTotal = widget.data
        .skip(5)
        .fold(0.0, (sum, item) => sum + item.total);
    final total = widget.data.fold(0.0, (sum, item) => sum + item.total);

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              'Sem despesas para exibir',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) => setState(() {
                      _touchedIndex =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                    }),
                  ),
                  sections: [
                    for (final (index, item) in top.indexed)
                      _section(
                        value: item.total,
                        color: item.category.color,
                        share: item.total / total,
                        highlighted: index == _touchedIndex,
                      ),
                    if (othersTotal > 0)
                      _section(
                        value: othersTotal,
                        color: theme.colorScheme.outline,
                        share: othersTotal / total,
                        highlighted: top.length == _touchedIndex,
                      ),
                  ],
                ),
                duration: context.motion(AppMotion.chart),
                curve: AppMotion.curve,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final item in top)
              _LegendRow(
                color: item.category.color,
                label: item.category.label,
                value: item.total,
                share: item.total / total,
              ),
            if (othersTotal > 0)
              _LegendRow(
                color: theme.colorScheme.outline,
                label: 'Outras',
                value: othersTotal,
                share: othersTotal / total,
              ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section({
    required double value,
    required Color color,
    required double share,
    required bool highlighted,
  }) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: highlighted ? 62 : 54,
      title: share < 0.07 ? '' : Formatters.percent.format(share),
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.share,
  });

  final Color color;
  final String label;
  final double value;
  final double share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            Formatters.currency.format(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 42,
            child: Text(
              Formatters.percent.format(share),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
