import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/animated_money.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.obscured,
    required this.onToggleObscured,
  });

  final double balance;
  final double income;
  final double expense;
  final bool obscured;
  final VoidCallback onToggleObscured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Saldo consolidado',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleObscured,
                  tooltip: obscured ? 'Mostrar valores' : 'Ocultar valores',
                  icon: Icon(
                    obscured ? Icons.visibility_off : Icons.visibility,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            AnimatedMoney(
              value: balance,
              obscured: obscured,
              style: theme.textTheme.displaySmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _Flow(
                    label: 'Receitas',
                    value: income,
                    color: AppColors.positiveLight,
                    icon: Icons.arrow_downward,
                    obscured: obscured,
                  ),
                ),
                Expanded(
                  child: _Flow(
                    label: 'Despesas',
                    value: expense,
                    color: AppColors.negativeLight,
                    icon: Icons.arrow_upward,
                    obscured: obscured,
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

class _Flow extends StatelessWidget {
  const _Flow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.obscured,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            AnimatedMoney(
              value: value,
              obscured: obscured,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
