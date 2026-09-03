import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/tx_category.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/pressable.dart';

enum TxPeriod {
  last7('Últimos 7 dias'),
  thisMonth('Mês atual'),
  last30('Últimos 30 dias'),
  all('Tudo');

  const TxPeriod(this.label);
  final String label;
}

class TxFilters {
  const TxFilters({
    this.period = TxPeriod.thisMonth,
    this.categories = const {},
    this.minAmount,
    this.maxAmount,
  });

  final TxPeriod period;
  final Set<TxCategory> categories;
  final double? minAmount;
  final double? maxAmount;

  bool get isDefault =>
      period == TxPeriod.thisMonth &&
      categories.isEmpty &&
      minAmount == null &&
      maxAmount == null;

  int get activeCount =>
      (period == TxPeriod.thisMonth ? 0 : 1) +
      (categories.isEmpty ? 0 : 1) +
      (minAmount == null && maxAmount == null ? 0 : 1);
}

/// Modal de filtros: surge com scale-up (0.9 → 1.0) e fade-in.
Future<TxFilters?> showTransactionFilters(
  BuildContext context,
  TxFilters current,
) {
  return showGeneralDialog<TxFilters>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar filtros',
    barrierColor: Colors.black54,
    transitionDuration: context.motion(AppMotion.fast),
    pageBuilder: (_, _, _) => _FiltersDialog(initial: current),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _FiltersDialog extends StatefulWidget {
  const _FiltersDialog({required this.initial});

  final TxFilters initial;

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late TxPeriod _period = widget.initial.period;
  late Set<TxCategory> _categories = {...widget.initial.categories};
  late final TextEditingController _min = TextEditingController(
    text: widget.initial.minAmount?.toStringAsFixed(0) ?? '',
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.initial.maxAmount?.toStringAsFixed(0) ?? '',
  );

  int _shakeTrigger = 0;
  String? _error;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.'));

  void _apply() {
    final min = _parse(_min);
    final max = _parse(_max);

    if (min != null && max != null && min > max) {
      setState(() {
        _error = 'O valor mínimo não pode ser maior que o máximo.';
        _shakeTrigger++;
      });
      return;
    }

    Navigator.of(context).pop(
      TxFilters(
        period: _period,
        categories: _categories,
        minAmount: min,
        maxAmount: max,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          maxWidth: 480,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Filtros', style: theme.textTheme.titleLarge),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _period = TxPeriod.thisMonth;
                      _categories = {};
                      _min.clear();
                      _max.clear();
                      _error = null;
                    }),
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text('Período', style: theme.textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final period in TxPeriod.values)
                            ChoiceChip(
                              label: Text(period.label),
                              selected: _period == period,
                              onSelected: (_) =>
                                  setState(() => _period = period),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Categorias', style: theme.textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final category in TxCategory.values)
                            FilterChip(
                              label: Text(category.label),
                              avatar: Icon(category.icon, size: 18),
                              selected: _categories.contains(category),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _categories.add(category);
                                } else {
                                  _categories.remove(category);
                                }
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Valor (R\$)', style: theme.textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      ShakeOnError(
                        trigger: _shakeTrigger,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _min,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Mínimo',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextField(
                                controller: _max,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Máximo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Pressable(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
