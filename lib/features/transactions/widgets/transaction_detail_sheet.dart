import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/ml/transaction_categorizer.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/tx_category.dart';
import '../../../features/finance/finance_cubit.dart';
import '../../../shared/widgets/pressable.dart';

/// Abre o detalhe da transação. Retorna a versão editada ou `null` se cancelado.
Future<Transaction?> showTransactionDetail(
  BuildContext context,
  Transaction transaction,
) {
  final prediction =
      context.read<FinanceCubit>().predictCategory(transaction.description);
  return showModalBottomSheet<Transaction>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TransactionDetailSheet(
      transaction: transaction,
      prediction: prediction,
    ),
  );
}

class _TransactionDetailSheet extends StatefulWidget {
  const _TransactionDetailSheet({
    required this.transaction,
    this.prediction,
  });

  final Transaction transaction;
  final CategoryPrediction? prediction;

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  late TxCategory _category = widget.transaction.category;
  late final TextEditingController _noteController = TextEditingController(
    text: widget.transaction.note,
  );

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      widget.transaction.copyWith(
        category: _category == widget.transaction.category ? null : _category,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = widget.transaction;
    final semantic = context.semanticColors;
    final amountColor = transaction.isExpense
        ? semantic.negative
        : semantic.positive;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(transaction.description, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Formatters.signed(transaction.amount),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoRow(
              icon: Icons.event,
              label: Formatters.fullDate.format(transaction.date),
            ),
            _InfoRow(
              icon: Icons.account_balance_outlined,
              label: transaction.accountName,
            ),
            if (transaction.autoCategorized)
              const _InfoRow(
                icon: Icons.auto_awesome,
                label: 'Categorizado automaticamente',
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Categoria', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            _SuggestionChip(
              prediction: widget.prediction,
              currentCategory: _category,
              onApply: (category) => setState(() => _category = category),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in TxCategory.values)
                  ChoiceChip(
                    label: Text(category.label),
                    avatar: Icon(category.icon, size: 18),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Adicione um contexto para este lançamento',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Pressable(
              child: FilledButton(
                onPressed: _save,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.prediction,
    required this.currentCategory,
    required this.onApply,
  });

  final CategoryPrediction? prediction;
  final TxCategory currentCategory;
  final ValueChanged<TxCategory> onApply;

  @override
  Widget build(BuildContext context) {
    final prediction = this.prediction;
    if (prediction == null ||
        !prediction.isConfident ||
        prediction.category == currentCategory) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final percent = (prediction.confidence * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ActionChip(
        avatar: const Icon(Icons.auto_awesome, size: 18),
        label: Text(
          'IA sugere ${prediction.category.label} · $percent%',
          style: theme.textTheme.labelMedium,
        ),
        onPressed: () => onApply(prediction.category),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
