import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/patrimony.dart';
import '../../shared/widgets/animated_money.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../finance/finance_cubit.dart';

class PatrimonyPage extends StatelessWidget {
  const PatrimonyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patrimônio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: AuroraSpinner());
          }

          final assetAccounts = state.accounts
              .where((a) => !_isCard(a) && a.balance > 0)
              .toList();
          final cardAccounts = state.accounts.where(_isCard).toList();
          final manualAssets = state.patrimony.where((p) => p.isAsset).toList();
          final manualLiabilities = state.patrimony
              .where((p) => !p.isAsset)
              .toList();

          return ListView(
            padding: AppSpacing.screenPadding.copyWith(bottom: 96),
            children: [
              StaggeredFadeIn(
                index: 0,
                child: _NetWorthSummary(
                  netWorth: state.netWorth,
                  assets: state.assetsTotal,
                  liabilities: state.liabilitiesTotal,
                ),
              ),
              const SectionHeader(title: 'Ativos'),
              for (final account in assetAccounts)
                _BankRow(
                  name: account.bankName,
                  subtitle: account.type,
                  value: account.balance,
                  icon: Icons.account_balance_wallet_outlined,
                  color: context.semanticColors.positive,
                ),
              for (final item in manualAssets)
                _ManualRow(item: item),
              if (assetAccounts.isEmpty && manualAssets.isEmpty)
                const _EmptyHint(
                  text: 'Adicione investimentos, imóveis ou uma reserva.',
                ),
              const SectionHeader(title: 'Dívidas'),
              for (final account in cardAccounts)
                _BankRow(
                  name: account.bankName,
                  subtitle: 'Fatura ${account.type}',
                  value: account.balance.abs(),
                  icon: Icons.credit_card,
                  color: context.semanticColors.negative,
                ),
              for (final item in manualLiabilities)
                _ManualRow(item: item),
              if (cardAccounts.isEmpty && manualLiabilities.isEmpty)
                const _EmptyHint(
                  text: 'Cadastre empréstimos, financiamentos ou faturas.',
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Contas conectadas entram automaticamente. Deslize um item '
                'manual para removê-lo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _isCard(Account account) {
    final type = account.type.toLowerCase();
    return type.contains('cart') ||
        type.contains('crédito') ||
        type.contains('credito');
  }

  static Future<void> _openAddSheet(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _AddPatrimonySheet(),
      ),
    );
  }
}

class _NetWorthSummary extends StatelessWidget {
  const _NetWorthSummary({
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });

  final double netWorth;
  final double assets;
  final double liabilities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadius.heroBorder,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4DFF).withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patrimônio líquido',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedMoney(
            value: netWorth,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Ativos',
                  value: assets,
                  color: semantic.positive,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MiniStat(
                  label: 'Passivos',
                  value: liabilities,
                  color: semantic.negative,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.currency.format(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({
    required this.name,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String name;
  final String subtitle;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          Formatters.currency.format(value),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ManualRow extends StatelessWidget {
  const _ManualRow({required this.item});

  final PatrimonyItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.category.color;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.semanticColors.negative.withValues(alpha: 0.15),
          borderRadius: AppRadius.cardBorder,
        ),
        child: Icon(Icons.delete_outline, color: context.semanticColors.negative),
      ),
      onDismissed: (_) {
        context.read<FinanceCubit>().deletePatrimonyItem(item.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('${item.name} removido')));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(item.category.icon, color: color, size: 20),
          ),
          title: Text(
            item.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(item.category.label),
          trailing: Text(
            Formatters.currency.format(item.value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: item.isAsset
                  ? context.semanticColors.positive
                  : context.semanticColors.negative,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AddPatrimonySheet extends StatefulWidget {
  const _AddPatrimonySheet();

  @override
  State<_AddPatrimonySheet> createState() => _AddPatrimonySheetState();
}

class _AddPatrimonySheetState extends State<_AddPatrimonySheet> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  PatrimonyCategory _category = PatrimonyCategory.investimento;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  double? get _parsedValue {
    final raw = _valueController.text
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && _parsedValue != null;

  void _save() {
    final value = _parsedValue;
    if (value == null) return;
    final item = PatrimonyItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      value: value,
      category: _category,
    );
    context.read<FinanceCubit>().savePatrimonyItem(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        viewInsets + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Novo item de patrimônio',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex: Tesouro Selic, Apartamento, Financiamento',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: r'R$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Categoria',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in PatrimonyCategory.values)
                ChoiceChip(
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: _category == category
                        ? theme.colorScheme.onPrimary
                        : category.color,
                  ),
                  label: Text(category.label),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSave ? _save : null,
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
