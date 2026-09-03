import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/transaction.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../finance/finance_cubit.dart';
import 'widgets/transaction_detail_sheet.dart';
import 'widgets/transaction_filters_dialog.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  TxFilters _filters = const TxFilters();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(List<Transaction> all) {
    final now = DateTime.now();
    return all.where((t) {
      switch (_filters.period) {
        case TxPeriod.last7:
          if (now.difference(t.date).inDays > 7) return false;
        case TxPeriod.last30:
          if (now.difference(t.date).inDays > 30) return false;
        case TxPeriod.thisMonth:
          if (t.date.year != now.year || t.date.month != now.month) {
            return false;
          }
        case TxPeriod.all:
          break;
      }

      if (_filters.categories.isNotEmpty &&
          !_filters.categories.contains(t.category)) {
        return false;
      }

      final absolute = t.amount.abs();
      if (_filters.minAmount != null && absolute < _filters.minAmount!) {
        return false;
      }
      if (_filters.maxAmount != null && absolute > _filters.maxAmount!) {
        return false;
      }

      if (_query.isNotEmpty) {
        final haystack =
            '${t.description} ${t.category.label} ${t.tags.join(' ')}'
                .toLowerCase();
        if (!haystack.contains(_query.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilters() async {
    final result = await showTransactionFilters(context, _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  Future<void> _openDetail(Transaction transaction) async {
    final cubit = context.read<FinanceCubit>();
    final updated = await showTransactionDetail(context, transaction);
    if (updated == null || !mounted) return;

    await cubit.saveTransaction(updated);
    if (!mounted) return;

    if (updated.category != transaction.category) {
      showSuccessCheck(
        context,
        'Categoria alterada para ${updated.category.label}',
      );
    }
  }

  Future<void> _delete(Transaction transaction) async {
    final cubit = context.read<FinanceCubit>();
    await cubit.deleteTransaction(transaction.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transação removida'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => cubit.saveTransaction(transaction),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FinanceCubit, FinanceState>(
      builder: (context, state) {
        final visible = _applyFilters(state.transactions);
        final rows = _flatten(_groupByDay(visible));
        final total = visible
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount.abs());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transações'),
            actions: [
              IconButton(
                onPressed: _openFilters,
                tooltip: 'Filtros',
                icon: Badge.count(
                  count: _filters.activeCount,
                  isLabelVisible: !_filters.isDefault,
                  child: const Icon(Icons.tune),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: AppSpacing.screenPadding,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por descrição, categoria ou tag',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(top: AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      '${visible.length} lançamentos',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Despesas: ${Formatters.currency.format(total)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.semanticColors.negative,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: state.isLoading
                    ? ListView.builder(
                        itemCount: 8,
                        itemBuilder: (context, _) => const SkeletonTile(),
                      )
                    : visible.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma transação encontrada',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          return StaggeredFadeIn(
                            index: index,
                            child: row.header != null
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.lg,
                                      AppSpacing.lg,
                                      AppSpacing.lg,
                                      AppSpacing.xs,
                                    ),
                                    child: Text(
                                      row.header!,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  )
                                : _SwipeableTransaction(
                                    transaction: row.transaction!,
                                    onEdit: () => _openDetail(row.transaction!),
                                    onDelete: () => _delete(row.transaction!),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Ontem';
    return Formatters.capitalize(Formatters.fullDate.format(day));
  }

  static List<({DateTime day, List<Transaction> items})> _groupByDay(
    List<Transaction> list,
  ) {
    final map = <DateTime, List<Transaction>>{};
    for (final transaction in list) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      map.putIfAbsent(day, () => []).add(transaction);
    }
    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final day in days) (day: day, items: map[day]!)];
  }

  /// Achata cabeçalhos e itens em uma lista única para o stagger contar
  /// 50ms por linha, e não por grupo de dia.
  static List<({String? header, Transaction? transaction})> _flatten(
    List<({DateTime day, List<Transaction> items})> groups,
  ) {
    return [
      for (final group in groups) ...[
        (header: _dayLabel(group.day), transaction: null),
        for (final transaction in group.items)
          (header: null, transaction: transaction),
      ],
    ];
  }
}

/// Deslizar para a direita edita, para a esquerda exclui.
class _SwipeableTransaction extends StatelessWidget {
  const _SwipeableTransaction({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Dismissible(
      key: ValueKey(transaction.id),
      background: _SwipeAction(
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.edit_outlined,
        label: 'Editar',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeAction(
        color: semantic.negative,
        icon: Icons.delete_outline,
        label: 'Excluir',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: TransactionTile(transaction: transaction, onTap: onEdit),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
